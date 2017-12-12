package OTRS::OPM::Installer::Utils::OTRS;
$OTRS::OPM::Installer::Utils::OTRS::VERSION = '0.03';
# ABSTRACT: class that provides helper functionality regarding the OTRS installation

use strict;
use warnings;

use Carp;
use Moo;
use Module::Path qw/module_path/;
use Types::Standard qw(ArrayRef Str);

use OTRS::OPM::Installer::Types qw(OTRSVersion);
use OTRS::OPM::Installer::Utils::File;

has path         => ( is => 'ro' );
has obj_env      => ( is => 'ro',  lazy => 1, default => \&_obj_env );
has os_env       => ( is => 'ro',  lazy => 1, default => \&_os_env );
has otrs_version => ( is => 'rwp', lazy => 1, default => \&_find_version);#isa => OTRSVersion );
has inc          => ( is => 'rwp', lazy => 1, default => \&_build_inc );#isa => ArrayRef[Str] );
has manager      => ( is => 'rwp', lazy => 1, default => \&_build_manager );#isa => Object );
has db           => ( is => 'rwp', lazy => 1, default => \&_get_db ); #sub { my $class = $self->obj_env; my $string = $class . '::_get_db'; $self->$string(); } );#isa => Object );

sub is_installed {
    my ($self, %param) = @_;

    my $sql = 'SELECT name, version FROM package_repository WHERE name = ?';

    return if !$self->db;

    $self->db->Prepare(
        SQL  => $sql,
        Bind => [ \$param{package} ],
    );

    my %info;
    while ( my @row = $self->db->FetchrowArray() ) {
        %info = (
            name    => $row[0],
            version => $row[1],
        );
    }

    return if !%info;

    my $is_installed = $self->_check_version(
        installed => $info{version},
        requested => $param{version},
    );

    return 1 if $is_installed;
    return;
}

sub _check_version {
    my ($self, %param) = @_;

    my @i_parts = split /\./, $param{installed} || 0;
    my @r_parts = split /\./, $param{requested} || 10000000;

    my $installed = sprintf "%03d%03d%03d", map{ $i_parts[$_] && $i_parts[$_] =~ m{\A[0-9]+\z} ? $i_parts[$_] : 0 }( 0 .. 2);
    my $requested = sprintf "%03d%03d%03d", map{ $r_parts[$_] && $r_parts[$_] =~ m{\A[0-9]+\z} ? $r_parts[$_] : 0 }( 0 .. 2);

    return $installed >= $requested;
}

sub _get_db {
    my ($self) = @_;

    my $class = $self->obj_env;
    my $path  = module_path $class;
    require $path;

    my $string = $class . '::_get_db';

    $self->$string();
}
 
sub _build_manager {
    my ($self) = @_;

    my $class = $self->obj_env;
    my $path  = module_path $class;
    require $path;

    my $string = $class . '::_build_manager';

    $self->$string();
}
 
sub _find_version {
    my ($self) = @_;

    my $file    = $self->path . '/RELEASE';
    my $content = do { local ( @ARGV, $/ ) = $file; <> };

    my ($version) = $content =~ m{VERSION \s+ = \s+ ([0-9.]+)}xms;
    return $version;
}

sub _build_inc {
    my ($self) = @_;

    return [ map{ $self->path . "/" . $_ }( '', 'Kernel/cpan-lib' ) ];
}

sub BUILDARGS {
    my $class = shift;

    if ( @_ % 2 != 0 ) {
        croak 'Check the parameters for ' . __PACKAGE__ . '. You have to pass a hash.';
    }

    my %args = @_;
    if ( !exists $args{path} ) {
        my $utils = OTRS::OPM::Installer::Utils::Config->new;
        my $cfg   = $utils->rc_config;

        $args{path} = $cfg->{otrs_path} if defined $cfg->{otrs_path};
    }

    return \%args;
}

sub _obj_env {
    my ($self) = @_;

    my ($major) = $self->otrs_version =~ m{\A(\d+)\.};
    if ( $major <= 3 ) {
        return 'OTRS::OPM::Installer::Utils::OTRS::OTRS3';
    }
    else {
        return 'OTRS::OPM::Installer::Utils::OTRS::OTRS4';
    }
}

sub _os_env {
    if ( $ENV{OTRSOPMINSTALLERTEST} ) {
        return 'OTRS::OPM::Installer::Utils::OTRS::Test';
    }
    else {
        return 'OTRS::OPM::Installer::Utils::OTRS::Linux';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OTRS::OPM::Installer::Utils::OTRS - class that provides helper functionality regarding the OTRS installation

=head1 VERSION

version 0.03

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
