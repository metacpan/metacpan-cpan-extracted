use v5.14.0;
use warnings;

package OS::Package::Plugin::Solaris::SVR4;

# ABSTRACT: Solaris 10 package plugin.
our $VERSION = '0.2.7'; # VERSION

use Cwd;
use Moo;
use Env qw( $HOME );
use Time::Piece;
use Types::Standard qw( Str );
use Template;
use Path::Tiny;
use File::ShareDir qw(dist_file);
use File::Basename qw( basename dirname );
use OS::Package::Config qw($OSPKG_CONFIG);
use OS::Package::Log;
use IPC::Cmd qw( can_run run );

extends 'OS::Package';

has user => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub { $OSPKG_CONFIG->{package}{user} }
);

has group => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub { $OSPKG_CONFIG->{package}{group} }
);

has category => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub { $OSPKG_CONFIG->{package}{category} }
);

has pstamp => (
    is      => 'rw',
    isa     => Str,
    default => sub { my $t = localtime; return $t->datetime; }
);

has pkgfile => (
    is       => 'rw',
    isa      => Str,
    required => 1,
    default  => sub {
        my $self   = shift;
        my $system = OS::Package::System->new;

        my $version =
            $self->build_id
            ? sprintf( '%s-b%s', $self->application->version,
            $self->build_id )
            : $self->application->version;

        return sprintf( '%s-%s-%s-%s.pkg',
            $self->name, $version,
            $system->os, $system->type );
    }
);

sub _generate_pkginfo {
    my $self = shift;

    $LOGGER->info('generating: pkginfo');

    my $template =
        dist_file( 'OS-Package', 'plugin/Solaris/SVR4/pkginfo.tt2' );

    my $ttcfg = { INCLUDE_PATH => dirname($template) };

    my $tt = Template->new($ttcfg);

    my $pkginfo = sprintf '%s/%s/pkginfo', path( $self->fakeroot ),
        $self->prefix;

    my $version =
        $self->build_id
        ? sprintf '%s-b%s', $self->application->version, $self->build_id
        : $self->application->version;

    $tt->process(
        basename($template),
        {   pkgname     => $self->name,
            name        => $self->application->name,
            description => $self->description,
            arch        => $self->system->type,
            version     => $version,
            category    => $self->category,
            vendor      => $self->maintainer->by_line,
            pstamp      => $self->pstamp,
            basedir     => $self->prefix,
        },
        $pkginfo
    ) or $LOGGER->logdie( $tt->error );

    return 1;
}

sub _generate_prototype {
    my $self = shift;

    $LOGGER->info('generating: prototype');

    my $pkg_path = sprintf '%s/%s', path( $self->fakeroot ), $self->prefix;

    chdir path($pkg_path);

    my $command = [ can_run('pkgproto'), '.' ];

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $command );

    foreach ( @{$full_buf} ) {
        $LOGGER->debug($_);
    }

    if ( !$success ) {
        $LOGGER->error( sprintf "pkgproto failed: %s\n", $error_message );

        return 2;
    }

    my @prototype = ("i pkginfo\n");

    my @lines = split "\n", join( q{}, @{$stdout_buf} );

    foreach my $line (@lines) {
        my ( $file_type, $class, $pathname, $mode, $owner, $group ) =
            split q{ }, $line;

        next if ( $pathname =~ qr{pkginfo|prototype}xms );

        if ( defined $mode ) {
            push @prototype,
                sprintf( "%s %s %s %s %s %s\n",
                $file_type, $class, $pathname, $mode, $self->user,
                $self->group );
        }
        else {
            push @prototype,
                sprintf( "%s %s %s\n", $file_type, $class, $pathname );
        }
    }

    path( sprintf( '%s/prototype', $pkg_path ) )->spew( \@prototype );

    chdir $HOME;

    return 1;
}

sub _generate_package {
    my $self = shift;

    $LOGGER->info( sprintf 'generating package: %s', $self->name );

    my $pkg_path = sprintf '%s/%s', path( $self->fakeroot ), $self->prefix;

    chdir path($pkg_path);

    if (-d sprintf( '%s/%s', path( $OSPKG_CONFIG->dir->packages ),
            $self->name ) )
    {
        $LOGGER->debug('removing existing package spool directory');
        my $spool_dir = sprintf( '%s/%s',
            path( $OSPKG_CONFIG->dir->packages ),
            $self->name );
        path($spool_dir)->remove_tree( { safe => 0 } );
    }

    if (-f sprintf( '%s/%s',
            path( $OSPKG_CONFIG->dir->packages ),
            $self->pkgfile )
        )
    {
        $LOGGER->debug('removing existing package file from spool directory');
        my $pkg_file = sprintf( '%s/%s',
            path( $OSPKG_CONFIG->dir->packages ),
            $self->pkgfile );
        path($pkg_file)->remove;
    }

    my $command = [
        can_run('pkgmk'), '-o', '-r', cwd, '-d',
        path( $OSPKG_CONFIG->dir->packages )
    ];

    my ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $command );

    foreach ( @{$full_buf} ) {
        $LOGGER->debug($_);
    }

    if ( !$success ) {
        $LOGGER->error( sprintf "pkgproto failed: %s\n", $error_message );

        return 2;
    }

    $command = [
        can_run('pkgtrans'),                  '-s',
        path( $OSPKG_CONFIG->dir->packages ), $self->pkgfile,
        $self->name
    ];

    ( $success, $error_message, $full_buf, $stdout_buf, $stderr_buf ) =
        run( command => $command );

    foreach ( @{$full_buf} ) {
        $LOGGER->debug($_);
    }

    if ( !$success ) {
        $LOGGER->error( sprintf "pkgtrans failed: %s\n", $error_message );

        return 2;
    }

    if (-d sprintf( '%s/%s', path( $OSPKG_CONFIG->dir->packages ),
            $self->name ) )
    {
        $LOGGER->debug('removing existing package spool directory');
        my $spool_dir = sprintf( '%s/%s',
            path( $OSPKG_CONFIG->dir->packages ),
            $self->name );
        path($spool_dir)->remove_tree( { safe => 0 } );
    }

    chdir $HOME;

    $LOGGER->info(
        sprintf 'created package: %s/%s',
        path( $OSPKG_CONFIG->dir->packages ),
        $self->pkgfile
    );

    return 1;
}

sub create {
    my $self = shift;

    $LOGGER->info('generating: Solaris SVR4 package');

    $self->_generate_pkginfo;

    $self->_generate_prototype;

    $self->_generate_package;

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Plugin::Solaris::SVR4 - Solaris 10 package plugin.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 create

Create Solaris SVR4 package.

=head2 pkgfile_suffix

Returns file extension for SVR4 package.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
