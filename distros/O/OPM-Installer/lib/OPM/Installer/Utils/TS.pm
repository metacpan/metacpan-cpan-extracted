package OPM::Installer::Utils::TS;

# ABSTRACT: class that provides helper functionality regarding the addon installation

use strict;
use warnings;

our $VERSION = '1.0.1'; # VERSION

use Carp;
use Moo;
use Types::Standard qw(ArrayRef Str);

use OPM::Installer::Utils::File;

has path         => ( is => 'ro' );
has os_env       => ( is => 'ro',  lazy => 1, default => \&_os_env );
has framework_version => ( is => 'rwp', lazy => 1, default => \&_find_version);
has inc          => ( is => 'rwp', lazy => 1, default => \&_build_inc );
has manager      => ( is => 'rwp', lazy => 1, default => \&_build_manager );
has db           => ( is => 'rwp', lazy => 1, default => \&_get_db );

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

    return $info{version} if !$param{version};

    my $is_installed = $self->_check_version(
        installed => $info{version},
        requested => $param{version},
    );

    return $is_installed if $is_installed;
    return;
}

sub _check_version {
    my ($self, %param) = @_;

    my @i_parts = split /\./, $param{installed} || 0;
    my @r_parts = split /\./, $param{requested} || 10000000;

    my $installed = sprintf "%03d%03d%03d", map{ $i_parts[$_] && $i_parts[$_] =~ m{\A[0-9]+\z} ? $i_parts[$_] : 0 }( 0 .. 2);
    my $requested = sprintf "%03d%03d%03d", map{ $r_parts[$_] && $r_parts[$_] =~ m{\A[0-9]+\z} ? $r_parts[$_] : 0 }( 0 .. 2);

    return $installed if $installed >= $requested;
    return;
}

sub _get_db {
    my ($self) = @_;

    push @INC, @{ $self->inc };

    my $object;
    eval {
        require Kernel::System::ObjectManager;
        $Kernel::OM = Kernel::System::ObjectManager->new;

        $object = $Kernel::OM->Get('Kernel::System::DB');
    } or die $@;

    $object;
}
 
sub _build_manager {
    my ($self) = @_;

    push @INC, @{ $self->inc };

    my $manager;
    eval {
        require Kernel::System::ObjectManager;
        $Kernel::OM = Kernel::System::ObjectManager->new;

        $manager = $Kernel::OM->Get('Kernel::System::Package');
    } or die $@;

    $manager;
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
        my $utils = OPM::Installer::Utils::Config->new;
        my $cfg   = $utils->rc_config;

        $args{path} = $cfg->{path} if defined $cfg->{path};
    }

    return \%args;
}

sub _os_env {
    if ( $ENV{OPMINSTALLERTEST} ) {
        return 'OPM::Installer::Utils::Test';
    }
    else {
        return 'OPM::Installer::Utils::Linux';
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OPM::Installer::Utils::TS - class that provides helper functionality regarding the addon installation

=head1 VERSION

version 1.0.1

=begin Pod::Coverage




=end Pod::Coverage

=over 4

=item * BUILDARGS

=back

=head1 ATTRIBUTES

=over 4

=item * path

=item * os_env

=item * framework_version

=item * inc

=item * manager

=item * db

=back

=head1 METHODS

=head2 is_installed

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
