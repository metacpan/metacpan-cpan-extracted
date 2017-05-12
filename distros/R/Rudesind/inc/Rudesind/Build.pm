package Rudesind::Build;

use strict;

use base 'Module::Build';

use File::Basename ();
use File::Copy ();
use File::Spec;

sub get_html_dir
{
    my $self = shift;

    my $default;
    foreach my $d ( qw( /var/www
                        /usr/local/apache/htdocs
                        /usr/local/htdocs
                        /opt/apache/htdocs
                      )
                  )
    {
        if ( -d $d )
        {
            $default = "$d/Rudesind";
            last;
        }
    }

    my $dir =
        $self->prompt( 'Where do you want the Mason components '
                       . 'for Rudesind installed?', $default );

    $self->notes( Rudesind_root => $dir );
}

sub get_config_dir
{
    my $self = shift;

    my $config = eval { require Rudesind::Config; Rudesind::Config->new };

    if ($config)
    {
        print "\n";
        print 'You seem to have an existing Rudesind config file '
              . $config->config_file . ".\n";
        print "No boilerplate configuration file will be installed.\n";

        return;
    }

    print "\n";
    my $dir =
        $self->prompt( 'Where do you want the boilerplate Rudesind '.
                       ' configuration file installed?',
                       '/etc/Rudesind',
                     );

    $self->notes( Rudesind_config_dir => $dir );
}

sub ACTION_install
{
    my $self = shift;

    $self->SUPER::ACTION_install(@_);
    $self->dispatch('install_htdocs');
    $self->dispatch('make_image_dirs');
    $self->dispatch('write_config_file');
#    $self->dispatch('print_apache_config');
}

sub ACTION_install_htdocs
{
    my $self = shift;

    # Don't use "use", or we'll short-circuit attempts to figure out
    # this distro's prereqs.
    require File::Find::Rule;
    my $rule = File::Find::Rule->new;

    my @files =
        $rule->or( $rule->new
                   ->directory
                   ->name('.svn')
                   ->prune
                   ->discard,

                   $rule->new
                   ->directory
                   ->name('images')
                   ->prune
                   ->discard,

                   $rule->new
                   ->directory
                   ->name('image-cache')
                   ->prune
                   ->discard,

                   $rule->new
                   ->name(qr/~$/)
                   ->prune
                   ->discard,

                   $rule->new,
                 )->file->in('htdocs');


    foreach my $file (@files)
    {
        my $dir = File::Basename::dirname($file);
        $dir =~ s:.*htdocs::;

        my $to =
            File::Spec->catfile( $self->notes('Rudesind_root'),
                                 $dir,
                                 File::Basename::basename($file) );

        $self->copy_if_modified( from => $file,
                                 to   => $to,
                                 flatten => 1,
                               );
    }
}

sub ACTION_make_image_dirs
{
    my $self = shift;

    foreach my $d ( qw( images image-cache ) )
    {
        my $dir = File::Spec->catdir( $self->notes('Rudesind_root'), $d );

        unless ( -d $dir )
        {
            print "Creating $dir directory.\n";

            mkdir $dir, 0755
                or die "Cannot make dir $dir: $!";
        }
    }
}

sub ACTION_write_config_file
{
    my $self = shift;

    my $dir = $self->notes('Rudesind_config_dir');

    return unless defined $dir;

    File::Path::mkpath( $dir, 0, 0755 );

    my $file = File::Spec->catfile( $dir, 'Rudesind.conf' );

    print "Writing boilerplate config file at $file.  You may want to edit this.\n";

    open my $fh, ">$file"
        or die "Cannot write to $file: $!";
    print $fh $self->_config_boilerplate
        or die "Cannot write to $file: $!";
    close $fh;
}

sub _config_boilerplate
{
    my $self = shift;

    my $root = $self->notes('Rudesind_root');

    return <<"EOF";
#
# The root_dir parameter is the directory under which Rudesind's Mason
# components are stored, as well as the images to be displayed, and
# cached images created by Rudesind.  The image directories will need
# to be accessible via your web server.  It is required.
#
# You should not change this unless you have manually moved the files
# located under this directory.
#
root_dir = $root

#
# data_dir is used by Mason.  It is required.
#
data_dir = /var/Rudesind-mason

#
# All other parameters below are optional
#

#
# The uri_root is the root of the web URI by which Rudesind will be
# accessed.  This does not need to have any correspondence to the
# root_dir, but it can.
#
# Defaults to /Rudesind
#
#uri_root = /Rudesind

#
# The image_uri_root is the root of the web URI by which your images
# will be served.  The default should work under most configurations.
#
# Defaults to an empty string
#
#image_uri_root =

#
# The raw_image_subdir is the directory under the root_dir in which
# you will store your images.  So if your root_dir is
# /var/www/gallery, and your raw_image_subdir is images, Rudesind will
# look for images on the filesystem at /var/www/gallery/images
#
# Defaults to images
#
#raw_image_subdir = images

#
# The view parameter allows you to specify what set of Mason
# components to be used by Rudesind when generating pages.
#
# Rudesind will look for a directory under <root_dir>/<view>.
#
# If this is set to anything other than "default", it will fall back
# to using "default" for any components which are not defined in the
# other view directory, so you can selectively replace components.
#
# Defaults to default
#
# view = default

#
# The charset parameter is used to determine the character set in the
# header for pages Rudesind generates.
#
# Defaults to UTF-8
#
# charset = UTF-8

#
# The tmp_dir is used for saving session files.
#
# Defaults to File::Spec->tmpdir
#
# tmp_dir =

#
# The admin_password is used to protect the admin functions.  If it is
# not set, the only way to login as an admin will be through HTTP
# basic auth.  See the "ADMIN AUTHORIZATION" section of the Rudesind
# docs (perldoc Rudesind) for details.
#
# Defaults to undef
#
# admin_password =

#
# The gallery_columns parameter controls how many columns of
# thumbnails are shown when browsing a gallery.
#
# Defaults to 3
#
# gallery_columns = 3

#
# The thumbnail_max_height parameter sets the maximum height, in
# pixels, of thumbnail images.
#
# Defaults to 200
#
# thumbnail_max_height = 200

#
# The thumbnail_max_width parameter sets the maximum width, in
# pixels, of thumbnail images.
#
# Defaults to 200
#
# thumbnail_max_width = 200

#
# The image_page_max_height parameter sets the maximum height, in
# pixels, of image page images.
#
# Defaults to 400
#
# image_page_max_height = 400

#
# The image_page_max_width parameter sets the maximum width, in
# pixels, of image page images.
#
# Defaults to 500
#
# image_page_max_width = 500

#
# The error_mode parameter is passed to Mason.  Set this to output to
# make debugging Rudesind easier.
#
# Defaults to fatal
#
# error_mode = fatal
EOF
}


1;

__END__

=pod

=head1 NAME

Rudesind::Build - Custom build methods for Rudesind

=head1 SYNOPSIS



=head1 DESCRIPTION



=cut
