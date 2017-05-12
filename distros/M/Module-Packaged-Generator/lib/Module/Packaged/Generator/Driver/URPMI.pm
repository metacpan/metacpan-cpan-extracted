#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Module::Packaged::Generator::Driver::URPMI;
BEGIN {
  $Module::Packaged::Generator::Driver::URPMI::VERSION = '1.111930';
}
# ABSTRACT: urpmi-based driver to fetch available modules

use Moose;
use MooseX::Has::Sugar;

use Module::Packaged::Generator::Module;

extends 'Module::Packaged::Generator::Driver';
with    'Module::Packaged::Generator::Role::Logging';
with    'Module::Packaged::Generator::Role::UrlFetching';



# -- private attributes

has _medias => (
    ro, lazy_build,
    isa     => 'HashRef[Str]',
    traits  => ['Hash'],
    handles => {
        medias        => 'keys',
        get_media_url => 'get',
    },
);


# -- public methods

sub list {
    my $self = shift;
    my @synthesises = $self->_get_synthesis;

    $self->log_step( "fetching list of available perl modules" );
    require URPM;
    my $urpm = URPM->new;
    $self->log( "parsing synthesis files" );
    $urpm->parse_synthesis($_) for @synthesises;

    $self->log( "extracting perl modules information" );
    my @modules;
    my %seen;
    $urpm->traverse( sub {
        my $pkg  = shift;
        my @provides = $pkg->provides;
        my $pkgname = $pkg->name;
        foreach my $p ( @provides ) {
            next unless $p =~ /^perl\(([^)]+)\)(\[== (.*)\])?$/;
            my ($name, $version) = ($1, $3);
            next if $seen{ $name }++;
            push @modules, Module::Packaged::Generator::Module->new( {
                name    => $name,
                version => $version,
                pkgname => $pkgname,
            } );
        }
    } );
    return @modules;
}


# -- private methods

#
# my @files = $urpmi->_get_synthesis;
#
# download the synthesis files from a mirror and store them locally,
# return the path to the local files. this allows to use latest &
# greatest data instead of (stalled?) local data.
#
sub _get_synthesis {
    my $self = shift;

    $self->log_step( "downloading synthesis information" );
    my @files;
    (my $driver = ref($self)) =~ s/.*:://;
    foreach my $media ( $self->medias ) {
        my $url  = $self->get_media_url($media);
        my $base = "synthesis.hdlist.$driver.$media.cz";
        push @files, $self->fetch_url( $url, $base );
    }

    return @files;
}

1;


=pod

=head1 NAME

Module::Packaged::Generator::Driver::URPMI - urpmi-based driver to fetch available modules

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This module is the L<Module::Packaged::Generator::Driver> driver
for urpmi-based distributions (such as Mageia and Mandriva).

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

