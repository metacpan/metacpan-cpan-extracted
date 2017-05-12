{

=head1 NAME

Net::Blogger::Engine::Slash - Adds support for the Slashcode SOAP API.

=head1 SYNOPSIS

  # Create object.
  my $blogger = Net::Blogger->new(engine=>"slash",debug=>1);

  # Same old, same old.
  $blogger->Username(1234);
  $blogger->Password("*****");
  $blogger->Proxy("http://use.perl.org/journal.pl");

  # Hey, this is different!
  $blogger->Uri("http://use.perl.org/Slash/Journal/SOAP");

  # This (the good old Blogger API) ...
  $blogger->newPost(postbody=>\"hello\nworld");

  # ...is the same as (slashcode API) ...
  $blogger->slash()->add_entry(subject=>"hello",body=>"world");

=head1 DESCRIPTION

Net::Blogger::Engine::Slash allows a program to interact with the Slashcode 
SOAP API using the Blogger API. Neat, huh?

=cut

package Net::Blogger::Engine::Slash;
use strict;

use Exporter;
use Net::Blogger::Engine::Base;

use CGI qw (unescape);

$Net::Blogger::Engine::Slash::VERSION   = '1.0';

@Net::Blogger::Engine::Slash::ISA       = qw ( Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Slash::EXPORT    = qw ();
@Net::Blogger::Engine::Slash::EXPORT_OK = qw ();

=head1 Blogger API OBJECT METHODS

=cut

=head2 $pkg->getUserBlogs()

=cut

sub getUserBlogs {
  my $self = shift;

  if ((! $self->{'__blogs'}) || (! $self->{'__blogs'}->[0]->{'blogName'})) {
    
    my $post = $self->slash()->get_entries($self->Username(),1);

    if (ref($post) eq "ARRAY") {
      $post = $post->[0];
      
      $post->{'url'} =~ /^((.*)\/~(.*)\/journal)\/(\d+)$/;

      my $url  = $1;
      my $name = &CGI::unescape($3);
      
      # hack
      $self->{'__blogs'} = [
			    {
			     blogid   => $self->Username(),
			     url      => $url,
			     blogName => $name."'s journal",
			    },
			   ];
    } 

    # hack hack hack
    else { $self->{'__blogs'} = [{ blogid => $self->Username() }]; }
  }

  return $self->{'__blogs'};
}

=head2 $pkg->newPost(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub newPost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

  if (! $self->check_newPost($args)) { 
    return 0; 
  }

  return $self->slash()->add_entry(&_bloggerpost2slash($args->{'postbody'}));
}

=head2 $pkg->getPost($postid)

=cut

sub getPost {
  my $self   = shift;
  my $postid = shift;

  if (! $self->check_getPost($postid)) { 
    return 0;
  }

  my $post = $self->slash()->get_entry($postid);

  return ($post) ? &_slashpost2blogger($post) : 0;
}

=head2 $pkg->getRecentPosts(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub getRecentPosts {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

  if (! $self->check_getRecentPosts($args)) { 
    return (0); 
  }
  
  my $posts = $self->slash()->get_entries($self->Username(),$args->{'numposts'});

  if (! $posts ) { 
    return (0); 
  }
  
  map { $_ = &_slashpost2blogger($_); } @$posts;

  return (1,@$posts);
}

=head2 $pkg->editPost(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub editPost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

  if (! $self->check_editPost($args)) {
    return 0;
  }

  return $self->slash()->modify_entry($args->{'postid'},&_bloggerpost2slash($args->{'postbody'}));
}

=head2 $pkg->deletePost(\%args)

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

=cut

sub deletePost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  if (! $self->check_deletePost($args)) {
    return 0;
  }

  return $self->slash()->delete_entry($args->{'postid'});
}

=head2 $pkg->setTemplate()

This method is not supported by the I<Slash> engine.

=cut

sub setTemplate {
  my $self = shift;
  $self->LastError("This method is not supported by the Slash engine.");
  return undef;
}

=head2 $pkg->getTemplate()

This method is not supported by the I<Slash> engine.

=cut

sub getTemplate {
  my $self = shift;
  $self->LastError("This method is not supported by the Slash engine.");
  return undef;
}

=head1 Slashcode API METHODS

=cut

=head2 $pkg->slash()

Returns an object. Woot!

=cut

sub slash {
  my $self = shift;

  if (! $self->{'__slash'}) {

    require Net::Blogger::Engine::Slash::slashcode;
    my $slash = Net::Blogger::Engine::Slash::slashcode->new(debug=>$self->{debug});

    # Note that the order in which these items 
    # are passed matters. This is so that the 
    # $slash object has a valid username/password
    # when it creates the cookie required by the
    # Slash server.

    map { $slash->$_($self->$_()); } qw (BlogId Username Password Proxy Uri);
    $self->{'__slash'} = $slash;
  }

  return $self->{'__slash'};
}

sub _bloggerpost2slash {
  my @post = split("\n",${$_[0]});
  
  return (
	  subject => $post[0],
	  body    => ((scalar(@post) > 1) ? join("\n",@post[1..$#post]) : $post[0]),
	 );
}

sub _slashpost2blogger {
  my $post = shift;
  return {
	  postid      => $post->{'id'},
	  userid      => $post->{'uid'},
	  dateCreated => $post->{'date'},
	  content     => join("\n",$post->{'subject'},$post->{'body'}),
	 };
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Slash::slashcode>

=head1 LICENSE

Copyright (c) 2002-2005, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
