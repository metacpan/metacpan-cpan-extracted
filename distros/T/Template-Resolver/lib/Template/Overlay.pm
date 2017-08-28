use strict;
use warnings;

package Template::Overlay;
$Template::Overlay::VERSION = '1.14';
# ABSTRACT: A powerful, and simple, library for resolving placeholders in templated files
# PODNAME: Template::Resolver

use Carp;
use File::Copy qw(copy);
use File::Find;
use File::Path qw(make_path);
use File::Spec;
use File::stat;
use Fcntl;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    return bless( {}, shift )->_init(@_);
}

sub _init {
    my ( $self, $base, $resolver, %options ) = @_;

    $self->{base}     = File::Spec->rel2abs($base);
    $self->{resolver} = $resolver;
    $self->{key}      = $options{key};

    $logger->debug( 'new overlay [', $self->{base}, ']' );

    return $self;
}

sub _overlay_files {
    my ( $self, $overlays ) = @_;

    my %overlay_files = ();
    foreach my $overlay ( ref($overlays) eq 'ARRAY' ? @$overlays : ($overlays) ) {
        $overlay = File::Spec->rel2abs($overlay);
        my $base_path_length = length($overlay);
        find(
            sub {
                if ( -f $File::Find::name && $_ !~ /~$/ && $_ !~ /^\..+\.swp$/ ) {
                    my $relative = _relative_path( $File::Find::name, $base_path_length );
                    $overlay_files{$relative} = $File::Find::name;
                }
            },
            $overlay
        );
    }

    return %overlay_files;
}

sub overlay {
    my ( $self, $overlays, %options ) = @_;

    my %overlay_files = $self->_overlay_files($overlays);
    my $destination   = $self->{base};
    if ( $options{to} && $options{to} ne $self->{base} ) {
        $destination = File::Spec->rel2abs( $options{to} );
        my $base_path_length = length( File::Spec->rel2abs( $self->{base} ) );
        find(
            sub {
                my $relative = _relative_path( $File::Find::name, $base_path_length );
                if ( -d $File::Find::name ) {
                    make_path( File::Spec->catdir( $destination, $relative ) );
                }
                if ( -f $File::Find::name ) {
                    my $template = delete( $overlay_files{$relative} );
                    my $file = File::Spec->catfile( $destination, $relative );
                    if ($template) {
                        $self->_resolve( $template, $file, $options{resolver} );
                    }
                    else {
                        copy( $_, $file );
                    }
                }
            },
            $self->{base}
        );
    }
    foreach my $relative ( keys(%overlay_files) ) {
        my $file = File::Spec->catfile( $destination, $relative );
        make_path( ( File::Spec->splitpath($file) )[1] );
        $self->_resolve( $overlay_files{$relative}, $file, $options{resolver} );
    }
}

sub _relative_path {
    my ( $path, $base_path_length ) = @_;
    return
        length($path) == $base_path_length
        ? ''
        : substr( $File::Find::name, $base_path_length + 1 );
}

sub _resolve {
    my ( $self, $template, $file, $resolver ) = @_;

    return if ( $resolver && &$resolver( $template, $file ) );

    if ( -f $file ) {
        $logger->debugf(
            '[%s] already exists, deleting to ensure creation with proper permissions', $file );
        unlink($file);
    }

    my $mode = stat($template)->mode() & 07777;    ## no critic
    $logger->infof( 'processing [%s] -> [%04o] [%s]', $template, $mode, $file );
    sysopen( my $handle, $file, O_CREAT | O_TRUNC | O_WRONLY, $mode )
        || croak("open $file failed: $!");
    eval {
        print( $handle $self->{resolver}->resolve(
                filename => $template,
                ( $self->{key} ? ( key => $self->{key} ) : () )
            )
        );
    };
    my $error = $@;
    close($handle);
    croak($error) if ($error);
}

1;

__END__

=pod

=head1 NAME

Template::Resolver - A powerful, and simple, library for resolving placeholders in templated files

=head1 VERSION

version 1.14

=head1 SYNOPSIS

  use Template::Overlay;
  use Template::Resolver;

  my $overlay_me = Template::Overlay->new(
      '/path/to/base/folder',
      Template->Resolver->new($entity),
      key => 'REPLACEME');
  $overlay_me->overlay(
      ['/path/to/template/base','/path/to/another/template/base'],
      to => '/path/to/processed');

=head1 DESCRIPTION

This provides the ability ot overlay a set of files with a set of resolved templates.
It uses L<Template::Resolver> to resolve each file.

=head1 CONSTRUCTORS

=head2 new($base, $resolver, [%options])

Creates a new overlay processor for the files in C<$base> using C<$resolver> to process
the template files. The available options are:

=over 4

=item key

The template key used by C<Template::Resolver-E<lt>resolve>.

=back

=head1 METHODS

=head2 overlay($overlays, [%options])

Overlays the C<$base> directory (specified in the constructor) with the resolved 
templates from the directories in C<$overlays>.  C<$overlays> can be either a path,
or an array reference containing paths.  If multiple C<$overlays> contain the same 
template, the last one in the array will take precedence.  The available options are:

=over 4

=item resolver

A callback, that if specified, will be called for each template file found.  It will
be called with two arguments: the first is the path to the template file, the second
is the path to the destination file.  If the callback returns a I<falsey> value, 
then it is assumed that the supplied callbac decided not to process this file and 
processing will proceed as normal.  Otherwise, it is assumed that the callback 
handled processing of the file, so the default processing will be skipped.

=item to

If specified, the files in C<$base> will not be not be modified.  Rather, they will
be copied to the path specified by C<$to> and the overlays will be processed on top
of that directory.

=back

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Template::Resolver|Template::Resolver>

=item *

L<Template::Resolver|Template::Resolver>

=item *

L<Template::Transformer|Template::Transformer>

=item *

L<https://github.com/lucastheisen/template-resolver|https://github.com/lucastheisen/template-resolver>

=back

=cut
