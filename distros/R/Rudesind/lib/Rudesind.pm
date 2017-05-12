package Rudesind;

use strict;

use Apache::Request;

use File::Slurp ();
use File::Spec;
use Image::Magick ();
use Path::Class ();

use Rudesind::Config;
use Rudesind::Gallery;
use Rudesind::Image;
use Rudesind::UI;


$Rudesind::VERSION = 0.04;


1;

__END__

=pod

=head1 NAME

Rudesind - A Mason-based image gallery

=head1 SYNOPSIS

  PerlModule Rudesind::Handler

  <Location /Rudesind>
    SetHandler perl-script
    PerlHandler Rudesind::Handler
  </Location>

  <Location /images>
    SetHandler default-handler
  </Location>

  <Location /image-cache>
    SetHandler default-handler
  </Location>

=head1 DESCRIPTION

Rudesind is a Mason-based image gallery program.  It provides image
and gallery captioning, and on-the-fly thumbnails and image
manipulation.  Generated images are cached and subsequently served
without using Mason, in order to improve the speed of the application.

=head1 CONFIGURATION

Rudesind is configured in two files.  First in its own
F<Rudesind.conf> config file.  When Rudesind is installed, it will
write a boilerplate config to a location of your choosing.  The
boilerplate config file contains a detailed description of all of the
possible configuration parameters.

Of these, the most important are the "root_dir", "uri_root",
"raw_image_subdir" and "image_uri_root" parameters.

For the following examples, we will assume that we have a document
root of F</var/www>, and the following Rudesind configuration:

=over 4

=item root_dir

F</var/www/gallery>

=item uri_root

F</Rudesind>

=item raw_image_subdir

F<images>

=item image_uri_root

F<gallery>

=back

=head2 Making Images Available

To make an image available in the gallery, we can place them under the
directory defined by concatenating our "root_dir" and "raw_image_subdir",
F</var/www/gallery/images>.  You can create a hierarchy of
galleries under this directory as you see fit.  Images are
displayed sorted ASCII-betically by filename.

=head2 Setting the Configuration File Location

By default, Rudesind will look for the configuration file in the
following locations:

=over 4

=item * $ENV{RUDESIND_CONFIG}

=item * $ENV{HOME}/.Rudesind.conf

=item * /etc/Rudesind.conf

=item * /etc/Rudesind/Rudesind.conf

=item * /opt/Rudesind/Rudesind.conf

=back

You can have multiple configuratoins with a single server by using
C<PerlSetEnv RUDESIND_CONFIG> in different Apache configuration
blocks.

=head2 Apache/mod_perl Configuration

The C<Rudesind::Handler> module will server Mason components based on
a virtual URL, defined by your "uri_root" parameter.

If your "uri_root" is "/Rudesind", then your Apache configuration
should look like this:

  <Location /Rudesind>
    SetHandler perl-script
    PerlHandler Rudesind::Handler
  </Location>

You also need to set up a handler for the "image_uri_root" URI.
Images go into the directory defined by the "raw_image_subdir"
parameter.  So if this is set to F<images>, they will go into
F</var/www/gallery/images>.  The image cache files are stored under
the root directory in an F<image-cache> directory.  So they will be in
F</var/www/gallery/image-cache>.

We want to serve all of these images with the default handler.

  # This location corresponds to our "image_uri_root"
  <Location /gallery>
    SetHandler default-handler
  </Location>

=head2 Two Apache Configuration

Rudesind also works well when using two Apache servers, with a
frontend non-mod_perl server proxying some requests to a backend
mod_perl server.  Our front-end configuration would just look like
this:

  RewriteRule ^(/Rudesind.*)  http://localhost:12345$1  [P,L]

Since our images are located under the server's document root, the
will be served by the front end server without any additional
configuration needed.

Then our back end configuration just needs this piece:

  <Location /Rudesind>
    SetHandler perl-script
    PerlHandler Rudesind::Handler
  </Location>

=head1 ADMIN AUTHORIZATION

Rudesind allows you to login as an admin in order to edit gallery and
image captions.  There are two ways this can be done.  The simplest is
to set an "admin_password" parameter in the Rudesind configuration
file.  You will then be prompted for this password when you click on
the "admin" link.

You may prefer to use HTTP basic authentication instead.  In that
case, you should configure Apache to protect the F</admin> directory
under your "uri_root" (F</Rudesind/admin> in our example) URI with
basic authentication.  If you access the admin area after
authenticating yourself via HTTP basic auth, then you will be given
admin access.

=cut
