package MooX::ConfigFromFile::Role;

use strict;
use warnings;

our $VERSION = '0.007';

use FindBin qw/$Script/;

use Config::Any;
use File::Find::Rule;

use Moo::Role;

with "MooX::File::ConfigDir";

around BUILDARGS => sub {
    my $next   = shift;
    my $class  = shift;
    my $params = $class->$next(@_);
    $class->_initialize_from_config($params);
    return $params;
};

sub _initialize_from_config
{
    my ( $class, $params ) = @_;
    defined $params->{loaded_config} or $params->{loaded_config} = $class->_build_loaded_config($params);

    # This copies stuff from loaded_config into the object's parameters
    foreach my $cfg_key ( keys %{ $params->{loaded_config} } )
    {
        exists $params->{$cfg_key} and next;
        $params->{$cfg_key} = $params->{loaded_config}->{$cfg_key};
    }

    return $params;
}

has 'config_prefix' => ( is => 'lazy' );

sub _build_config_prefix { $Script; }

has 'config_prefixes' => ( is => 'lazy' );

sub _build_config_prefixes
{
    my ( $class, $params ) = @_;
    defined $params->{config_prefix} or $params->{config_prefix} = $class->_build_config_prefix($params);
    [ $params->{config_prefix} ];
}

has 'config_prefix_map_separator' => ( is => 'lazy' );

sub _build_config_prefix_map_separator { "-" }

has 'config_prefix_map' => ( is => 'lazy' );

sub _build_config_prefix_map
{
    my ( $class, $params ) = @_;

    defined $params->{config_prefix_map_separator}
      or $params->{config_prefix_map_separator} = $class->_build_config_prefix_map_separator($params);
    defined $params->{config_prefixes} or $params->{config_prefixes} = $class->_build_config_prefixes($params);

    my ( $sep, $i, @prefix_map ) = ( $params->{config_prefix_map_separator} );
    for ( $i = 0; $i < scalar @{ $params->{config_prefixes} }; ++$i )
    {
        push @prefix_map, join( $sep, @{ $params->{config_prefixes} }[ 0 .. $i ] );
    }

    \@prefix_map;
}

has 'config_extensions' => ( is => 'lazy' );

sub _build_config_extensions { [ Config::Any->extensions() ] }

has 'config_files_pattern' => ( is => 'lazy' );

sub _build_config_files_pattern
{
    my ( $class, $params ) = @_;

    defined $params->{config_prefix_map} or $params->{config_prefix_map} = $class->_build_config_prefix_map($params);
    defined $params->{config_extensions} or $params->{config_extensions} = $class->_build_config_extensions($params);
    # my @cfg_pattern = map { $params->{config_prefix} . "." . $_ } @{ $params->{config_extensions} };
    my @cfg_pattern = map {
        my $ext = $_;
        map { $_ . "." . $ext } @{ $params->{config_prefix_map} }
    } @{ $params->{config_extensions} };

    \@cfg_pattern;
}

has 'config_files' => ( is => 'lazy' );

sub _build_config_files
{
    my ( $class, $params ) = @_;

    defined $params->{config_files_pattern} or $params->{config_files_pattern} = $class->_build_config_files_pattern($params);
    defined $params->{config_dirs}          or $params->{config_dirs}          = $class->_build_config_dirs($params);
    ref $params->{config_dirs} eq "ARRAY"   or $params->{config_dirs}          = ["."];

    my @cfg_files =
      File::Find::Rule->file()->name( @{ $params->{config_files_pattern} } )->maxdepth(1)->in( @{ $params->{config_dirs} } );

    return \@cfg_files;
}

has raw_loaded_config => (
    is      => 'lazy',
    clearer => 1
);

sub _build_raw_loaded_config
{
    my ( $class, $params ) = @_;

    defined $params->{config_files} or $params->{config_files} = $class->_build_config_files($params);
    return [] if !@{ $params->{config_files} };

    [
        sort { my @a = %{$a}; my @b = %{$b}; $a[0] cmp $b[0]; } @{ Config::Any->load_files(
                {
                    files   => $params->{config_files},
                    use_ext => 1
                }
            )
        }
    ];
}

has 'loaded_config' => (
    is      => 'lazy',
    clearer => 1
);

sub _build_loaded_config
{
    my ( $class, $params ) = @_;

    defined $params->{raw_loaded_config} or $params->{raw_loaded_config} = $class->_build_raw_loaded_config($params);

    my $config_merged = {};
    for my $c ( map { values %$_ } @{ $params->{raw_loaded_config} } )
    {
        %$config_merged = ( %$config_merged, %$c );
    }

    $config_merged;
}

=head1 NAME

MooX::ConfigFromFile::Role - Moo eXtension for initializing objects from config file

=head1 DESCRIPTION

This role adds a initializing sub around L<BUILDARGS|Moose::Manual::Construction/BUILDARGS>
and puts all what could read from config files into the hash which will be
used to construct the final object.

While it does that, it internally calls it's own _build_* methods (I<_build_config_prefix>,
I<_build_config_files> and I<_build_loaded_config>) unless the appropriate attributes are
already in C<$params>.

=head1 ATTRIBUTES

This role uses following attributes which might be suitable customized by
overloading the appropriate builder or pass defaults in construction arguments.

Be sure to read L<MooX::File::ConfigDir/ATTRIBUTES>, especially
L<MooX::File::ConfigDir/config_identifier> to understand how the L</config_dirs>
are build.

When you miss a directory - see L<File::ConfigDir/plug_dir_source> and
L<File::ConfigDir::Plack>.

=head2 config_prefix

This attribute is a string and defaults to L<FindBin>'s C<$Script>. It's
interpreted as the basename of the config file name to use.

=head2 config_prefixes

This attribute is an array of strings and defaults to C<<[ config_prefix ]>>.

=head2 config_prefix_map_separator

This attribute is a string and contains the character which is used building
I<config_prefix_map> from I<config_prefixes>.

=head2 config_prefix_map

This attribute is an array of strings containing all config-prefixes joint
together C<($0, $0.$1, $0.$1.$2, ...)> using I<config_prefix_map_separator>.

=head2 config_files_pattern

This attribute contains a cross-product of I<config_prefix_map> and
I<config_extensions>. Both are concatenated using the shell wildcard '*'.

=head2 config_dirs

This attribute is consumed from L<MooX::File::ConfigDir|MooX::File::ConfigDir/config_dirs>.
It might not be smart to override - but possible. Use with caution.

=head2 config_extensions

This attribute defaults to list of extensions from L<Config::Any|Config::Any/extensions>.

=head2 config_files

This attribute contains the list of existing files in I<config_dirs> matching
I<config_prefix> . I<config_extensions>.  Search is operated by L<File::Find::Rule>.

=head2 raw_loaded_config

This attribute contains the config as loaded from file system in an array of
C<< filename => \%content >>.  The result from L<Config::Any> is sorted by
filename (C<< '-' < '.' >>).

=head2 loaded_config

This attribute contains the config loaded and transformed while constructing
the instance. Construction is done from I<raw_loaded_config>, ignoring the
filename part.

For classes set up using

  use MooX::ConfigFromFile config_singleton = 1;

this attribute is cached from the very first construction and fed by overwritten
I<builder>. The content of this attribute is passed to lower I<BUILDARGS>.

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

Toby Inkster suggested to rely on BUILDARGS instead of intercepting object
creation with nasty hacks. He also taught me a bit more how Moo(se) works.

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
