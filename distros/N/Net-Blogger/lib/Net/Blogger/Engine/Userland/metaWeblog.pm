{

=head1 NAME

Net::Blogger::Engine::Userland::metaWeblog - UserLand metaWeblog API engine

=head1 SYNOPSIS

 my $radio = Blogger->new(engine=>"radio");
 $radio->Proxy(PROXY);
 $radio->Username(USERNAME);
 $radio->Password(PASSWORD);

 $radio->metaWeblog()->newPost(
	   		       title=>"hello",
			       description=>"world",
			       publish=>1,
			      );

=head1 DESCRIPTION

Implements the UserLand metaWeblog API functionality.

This package is meant to be subclassed. It should not be used on it's own.

=cut

package Net::Blogger::Engine::Userland::metaWeblog;
use strict;

$Net::Blogger::Engine::Userland::metaWeblog::VERSION   = '1.0';

@Net::Blogger::Engine::Userland::metaWeblog::ISA       = qw ( Exporter Net::Blogger::Engine::Base );
@Net::Blogger::Engine::Userland::metaWeblog::EXPORT    = qw ();
@Net::Blogger::Engine::Userland::metaWeblog::EXPORT_OK = qw ();

use Exporter;
use Net::Blogger::Engine::Base;

=head1 OBJECTS METHODS

=head2 $pkg->newPost(\%args)

Valid arguments are :

=over 4

=item *

B<title>

String.

=item *

B<link>

=item *

B<description>

String.

=item *

B<categories>

Array reference.

=item *

B<publish>

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns an int, or false.

=head2 $pkg->getRecentPosts(\%args)

Returns the most recent posts

Valid arguments are:

=over

=item numberOfPosts

The maximum number of posts to return

=back

=cut

sub getRecentPosts {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};
  my $call = $self->_Client()->call(
				    "metaWeblog.getRecentPosts",
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
                    $self->_Type(int=>$args->{'numberOfPosts'}),
				    );

    my @posts = ($call) ? (1,@{$call->result()}) : (0,undef);
    return @posts;
};

sub newPost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  my $publish = 0;

  if (exists $args->{publish}) {
    $publish = $args->{publish};
    delete $args->{publish};
  }

  if (($args->{categories}) && (ref($args->{categories}) ne "ARRAY")) {
    $self->LastError("Categories must be passed as an array reference.");
    return 0;
  }

  my $call = $self->_Client->call(
				  "metaWeblog.newPost",
				  $self->_Type(string=>$self->BlogId()),
				  $self->_Type(string=>$self->Username()),
				  $self->_Type(string=>$self->Password()),
				  $self->_Type(hash=>$args),
				  $self->_Type(boolean=>$publish),
				 );

  return ($call) ? $call->result() : return 0;
}

=head2 $pkg->newMediaObject(\%args)

Valid argument are :

=over

=item *

B<file>

String. Path to the file you're trying to upload.

If this argument is present the package will try to load I<MIME::Base64>
for automagic encoding.

=item *

B<name>

String. "It may be used to determine the name of the file that stores the object,
or to display it in a list of objects. It determines how the weblog refers to
the object. If the name is the same as an existing object stored in the weblog,
it replaces the existing object." [1]

If a I<file> argument is present and no I<name> argument is defined, this property
will be defined using the I<File::Basename::basename> function.

=item *

B<type>

String. "It indicates the type of the object, it's a standard MIME type,
like audio/mpeg or image/jpeg or video/quicktime." [1]

If a I<file> argument is present and no I<type> argument is defined, the package
will try setting this property using the I<File::MMagic> package.

=item *

B<bits>

Base64-encoded binary value. The content of the object.

If a I<file> argument is present, the package will try setting this property
using the I<MIME::Base64> package.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a hash reference, or undef.

=cut

sub newMediaObject {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  #

  if ($args->{file}) {

    my $pkg = "MIME::Base64";
    eval "require $pkg";

    if ($@) {
      $self->LastError("Failed to load $pkg for automagic encoding, $@");
      return undef;
    }

    open(FILE, $args->{file}) or &{
      $self->LastError("Failed to open $args->{file} for reading, $!");
      return undef;
    };

    my $buf = undef;

    while (read(FILE, $buf, 60*57)) {
      $args->{bits} .= &{$pkg."::encode_base64"}($buf);
    }

    close FILE;

    #

    if (! $args->{type}) {
      eval "require $pkg";

      if ($@) {
	$self->LastError("Failed to load $pkg for automagic type checking $@");
	return undef;
      }

      #

      my $mm = undef;

      eval { $mm = $pkg->new(); };

      if ($@) {
	$self->LastError("Failed to instantiate $pkg for automagic type checking, $@");
	return undef;
      }

      $args->{type} = $mm->checktype_filename($args->{file});

      if (! $args->{type}) {
	$self->LastError("Unable to determine file type ");
      }
    }

    #

    if (! $args->{name}) {
      require "File::Basename";
      $args->{name} = File::Basename::basename($args->{file});
    }
  }

  #

  else {
    foreach ("name","type","bin") {
      if (! $args->{$_}) {
	$self->LastError("You must define a value for the $_ property.");
	return undef;
      }
    }
  }

  #

  my $call = $self->_Client->call(
				  "metaWeblog.newMediaObject",
				  $self->_Type(string=>$self->BlogId()),
				  $self->_Type(string=>$self->Username()),
				  $self->_Type(string=>$self->Password()),
				  $self->_Type(hash=>$args),
				 );

  return ($call) ? $call->result() : undef;
}

=head2 $pkg->editPost(\%args)

=over 4

=item *

B<postid>

Int. I<required>

=item *

B<title>

String.

=item *

B<link>

=item *

B<description>

String.

=item *

B<categories>

Array reference.

=item *

B<publish>

Boolean.

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns true or false.

=cut

sub editPost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  my $postid = $args->{postid};

  if (! $postid) {
    $self->LastError("You must specify a postid");
    return 0;
  }

  delete $args->{postid};

  if (($args->{categories}) && (ref($args->{categories}) ne "ARRAY")) {
    $self->LastError("Categories must be passed as an array reference.");
    return 0;
  }

  my $publish = 0;

  if (exists $args->{publish}) {
    $publish = $args->{publish};
    delete $args->{publish};
  }

  my $call = $self->_Client->call(
				  "metaWeblog.editPost",
				  $postid,
				  $self->_Type(string=>$self->Username()),
				  $self->_Type(string=>$self->Password()),
				  $self->_Type(hash=>$args),
				  $self->_Type(boolean=>$publish),
				 );

  return ($call) ? $call->result() : undef;
}

=head2 $pkg->getPost(\%args)

Valid arguments are :

=over 4

=item *

B<postid>

Int. I<required>

=back

Releases prior to Net::Blogger 0.85 accepted a list of arguments
rather than a reference. Version 0.85+ are backwards compatible.

Returns a hash reference or undef.

=cut

sub getPost {
  my $self = shift;
  my $args = (ref($_[0]) eq "HASH") ? shift : {@_};

  my $postid = $args->{postid};

  if (! $postid) {
    $self->LastError("You must specify a postid");
    return 0;
  }

  my $call = $self->_Client->call(
				  "metaWeblog.getPost",
				  $postid,
				  $self->_Type(string=>$self->Username()),
				  $self->_Type(string=>$self->Password()),
				 );

  return ($call) ? $call->result() : undef;
}

=head2 $pkg->getCategories()

Returns an array reference or undef.

=cut

sub getCategories {
  my $self = shift;

  if ($self->{'__parent'} eq "Movabletype") {
    $self->LastError("This method is not supported by the $self->{'__parent'} engine.");
    return undef;
  }

  my $call = $self->_Client()->call(
				    "metaWeblog.getCategories",
				    $self->_Type(string=>$self->BlogId()),
				    $self->_Type(string=>$self->Username()),
				    $self->_Type(string=>$self->Password()),
				    );

  return ($call) ? $call->result() : undef;
}

=head1 VERSION

1.0

=head1 DATE

$Date: 2005/03/26 19:29:08 $

=head1 AUTHOR

Aaron Straup Cope

=head1 SEE ALSO

http://www.xmlrpc.com/metaWeblogApi

http://groups.yahoo.com/group/weblog-devel/message/200

=head1 FOOTNOTES

=over

=item [1]

http://www.xmlrpc.com/discuss/msgReader$2393

=back

=head1 LICENSE

Copyright (c) 2002-2005 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;

}
