{

=head1 NAME

Net::Blogger::API::Core - Blogger API methods

=head1 SYNOPSIS

 It's very dark in here because this is a black box. 

=head1 DESCRIPTION

Net::Blogger::API::Core defined methods that correspond to the 
Blogger API.

It is inherited by I<Net::Blogger::Engine::Base.pm>

=cut

package Net::Blogger::API::Core;
use strict;

$Net::Blogger::API::Core::VERSION   = '1.0';
@Net::Blogger::API::Core::ISA       = qw ( Exporter );
@Net::Blogger::API::Core::EXPORT    = qw ();
@Net::Blogger::API::Core::EXPORT_OK = qw ();

use Exporter;

=head1 Blogger API METHODS

=head2 $pkg->getUsersBlogs()

Fetch the I<blogid>, I<url> and I<blogName> for each of the Blogger blogs 
the current user is registered to.

Returns an array ref of hashes.

=cut

sub getUsersBlogs {
    my $self  = shift;
    my $blogs = [];
    
    my $call = $self->_Client->call(
				    "blogger.getUsersBlogs",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    );

    ($call) ? return $call->result() : return [];
}

=head2 $pkg->newPost(\%args)

Add a new post to the Blogger server. 

Valid arguments are :

=over 4

=item *

B<postbody> (required)

Scalar ref.

=item *

B<publish> 

Boolean.

=back

If the length of I<postbody> exceeds maximum length allowed by the Blogger servers 
-- 65,536 characters -- currently  the text will be chunked into smaller pieces are 
each piece will be posted separately.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an array containing one, or more, post ids.

=cut

sub newPost {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! $self->check_newPost($args)) { 
      return 0; 
    }

    if ($self->check_exceedsMaxLength($args)) { 
      return $self->_PostInChunks(%$args); 
    }

    my $postbody = $args->{'postbody'};
    my $publish  = ($args->{'publish'}) ? 1 : 0;

    my $call = $self->_Client->call(
				    "blogger.newPost",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(string=>$$postbody),
				    $self->_Type(boolean=>$publish),
				    );
    
    return ($call) ? $call->result() : return 0;
}

=head2 $pkg->getPost($postid)

Returns a hash ref, containing the following keys : userid, postid, 
content and dateCreated.

=cut

sub getPost {
    my $self   = shift;
    my $postid = shift;

    if (! $self->check_getPost($postid)) { 
      return 0;
    }
    
    my $call = $self->_Client->call(
				    "blogger.getPost",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$postid),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    );

    if (! $call) { return 0; }

    my $post = $call->result();

    # See KNOWN ISSUES

    if ($post eq "0") {
	$self->LastError("Unable to locate post.");
	return 0;
    }

    return $post;
}

=head2 $pkg->getRecentPosts(\%args)

Fetch the latest (n) number of posts for a given blog. The most recent posts 
are returned first.

Valid arguments are 

=over 4

=item *

B<numposts>

Int. If no argument is passed to the method, default is 1.

"NumberOfPosts is limited to 20 at this time. Let me know if this 
gets annoying. Letting this number get too high could result in some 
expensive db access, so I want to be careful with it." --Ev

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false, followed by an array of hash refs. Each hash ref 
contains the following keys : postid,content,userid,dateCreated

=cut

sub getRecentPosts {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! $self->check_getRecentPosts($args)) { 
      return (0); 
    }

    my $call = $self->_Client->call(
				    "blogger.getRecentPosts",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(int=>$args->{'numposts'}),
				  );

    my @posts = ($call) ? (1,@{$call->result()}) : (0,undef);
    return @posts;
}

=head2 $pkg->editPost(\%args)

Update the Blogger database. Set the body of entry $postid to $body.

Valid arguments are :

=over 4

=item *

B<postbody> (required)

Scalar ref or a valid filehandle.

=item *

B<postid>

String. I<required>

=item *

B<publish> 

Boolean.

=back

If the length of I<postbody> exceeds maximum length allowed by the Blogger servers 
-- 65,536 characters -- currently  the text will be chunked into smaller pieces are 
each piece will be posted separately.

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an array containing one, or more, post ids.

=cut

sub editPost {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! $self->check_editPost($args)) { 
      return 0; 
    }

    if ($self->check_exceedsMaxLength($args)) { 
      return $self->_PostInChunks(%$args); 
    }

    my $postbody = $args->{'postbody'};
    my $postid   = $args->{'postid'};
    
    if (($self->MaxPostLength()) && (length($$postbody) > $self->MaxPostLength())) {
	return $self->_PostInChunks(%$args);
    }

    my $publish = ($args->{'publish'}) ? 1 : 0;

    my $ok = undef;

    my $call= $self->_Client->call(
				   "blogger.editPost",
				   $self->_Type(string=>$self->AppKey()),
				   $self->_Type(string=>$postid),
				   $self->_Type(string=>$self->Username()),
				   $self->_Type(string=>$self->Password()),
				   $self->_Type(string=>$$postbody),
				   $self->_Type(boolean=>$publish),
				   );

    ($call) ? return $call->result() : return 0;
}

=head2 $pkg->deletePost(\%args) 

Delete a post from the Blogger server.

Valid arguments are

=over 4

=item *

B<postid> 

String. I<required>

=item *

B<publish> 

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=cut

sub deletePost {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! $self->check_deletePost($args)) { 
      return 0; 
    }
    
    my $postid  = $args->{'postid'};
    my $publish = ($args->{'publish'}) ? 1 : 0;

    my $call = $self->_Client->call(
				    "blogger.deletePost",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$postid),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(boolean=>$publish),
				    );

    ($call) ? return $call->result() : return 0;
}

=head2 $pkg->setTemplate(\%args)

Set the body of the template matching type I<$type>.

 <quote src = "ev">
  template is the HTML (XML, whatever -- Blogger can output any sort 
  of text). Must contain opening and closing <Blogger> tags to be 
  valid and accepted.
 </quote>

Valid arguments are 

=over 4

=item *

B<template>

Scalar ref. I<required>

=item *

B<type>

String. I<required>

Valid types are "main" and "archiveIndex"

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=cut

sub setTemplate {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };

    if (! $self->check_setTemplate($args)) {
      return 0;
    }

    my $call = $self->_Client->call(
				    "blogger.setTemplate",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(string=>${$args->{'template'}}),
				    $self->_Type(string=>$args->{'type'}),
				    );

    ($call) ? return $call->result() : return 0;
}

=head2 $pkg->getTemplate(\%args)

Fetch the body of the template matching type I<$type>.

Valid types are 

=over 4

=item *

B<type>

String. I<required>

Valid types are "main" and "archiveIndex"

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a string.

=cut

sub getTemplate {
    my $self = shift;
    my $args = (ref($_[0]) eq "HASH") ? shift : { @_ };
    
    if (! $self->check_getTemplate($args)) {
      return 0;
    }

    my $call = $self->_Client->call(
				    "blogger.getTemplate",
				    $self->_Type(string=>$self->AppKey()),
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    $self->_Type(string=>$args->{'type'}),
				    );

    ($call) ? return $call->result() : return 0;
}

sub check_exceedsMaxLength {
  my $self = shift;
  my $args = shift;

  if (! $self->MaxPostLength()) {
    return 0;
  }

  if (length(${$args->{'postbody'}}) < $self->MaxPostLength()) {
    return 0;
  }

  return 1;
}

sub check_newPost {
  my $self = shift;
  my $args = shift;

  if (ref($args->{'postbody'}) ne "SCALAR") {
    $self->LastError("You must pass postbody as a scalar reference.");
    return 0;
  }
    
  return 1;
}

sub check_getPost {
  my $self   = shift;
  my $postid = shift;

  if (! $postid) {
    $self->LastError("You must specify a postid.");
    return 0;
  }

  return 1;
}

sub check_getRecentPosts {
  my $self = shift;
  my $args = shift;

  my $num   = (defined $args->{'numposts'}) ? $args->{'numposts'} : 1;
  
  unless ($num =~ /^(\d+)$/) {
    $self->LastError("Argument $args->{'numposts'} isn't numeric.");
    return 0;
  }
  
  unless (($num >= 1) && ($num <= 20)) {
    $self->LastError("You must specify 'numposts' as an integer between 1 and 20.");
    return (0);
  }
  
  return 1;
}

sub check_editPost {
  my $self = shift;
  my $args = shift;

  if (! $args->{'postid'}) { 
    $self->LastError("You must specify a postid.");
    return 0; 
  }
  
  if (ref($args->{'postbody'}) ne "SCALAR") {
    $self->LastError("You must pass postbody as a scalar reference.");
    return 0;
  }
  
    return 1;
}

sub check_deletePost {
  my $self = shift;
  my $args = shift;

  if (! $args->{'postid'}) {
    $self->LastError("No post id.");
    return 0;
  }
  
  return 1;
}

sub check_setTemplate {
  my $self = shift;
  my $args = shift;

  if (ref($args->{'template'}) ne "SCALAR") {
    $self->LastError("You must pass template as a scalar reference.");
    return 0;
  }
  
  unless ($args->{'type'} =~ /^(main|archiveIndex)$/) {
    $self->LastError("Valid template types are 'main' and 'archiveIndex'.");
    return 0;
  }

  # see also : The Perl Cookbook, chapter 6.15
  unless (${$args->{'template'}} =~ /(<Blogger>)[^<]*(?:(?! <\/?Blogger>)<[^<]*)*(<\/Blogger>)/m) {
    $self->LastError("Your template must contain opening and closing <Blogger> tags.");
    return 0;
  }
  
  return 1;
}

sub check_getTemplate {
  my $self = shift;
  my $args = shift;

  unless ($args->{'type'} =~ /^(main|archiveIndex)$/) {
    $self->LastError("Valid template types are 'main' and 'archiveIndex'.");
    return 0;
  }

  return 1;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

L<Net::Blogger::Engine::Base>

L<Net::Blogger::API::Extended>

=head1 LICENSE

Copyright (c) 2001-2005 Aaron Straup Cope.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

return 1;

}
