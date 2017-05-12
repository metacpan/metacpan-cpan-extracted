package Shipwright::Backend::SVK;

use warnings;
use strict;
use File::Spec::Functions qw/catfile/;
use Shipwright::Util;
use File::Copy::Recursive qw/rcopy/;
use File::Path qw/remove_tree/;

our %REQUIRE_OPTIONS = ( import => [qw/source/] );

use base qw/Shipwright::Backend::Base/;

=head1 NAME

Shipwright::Backend::SVK - SVK repository backend

=head1 SYNOPSIS

    shipwright create -r svk:/depot/shipwright/my_proj

=head1 DESCRIPTION

This module implements an L<SVK> based backend
for Shipwright L<repository|Shipwright::Manual::Glossary/repository>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item SHIPWRIGHT_SVK - path of F<svk> command, default value is F<svk>.

=back

L<Shipwright::Manual::ENV/SHIPWRIGHT_SVN> can be used as well.

=head1 METHODS

=over 4

=item build

=cut

sub build {
    my $self = shift;
    $self->strip_repository;
    $self->SUPER::build(@_);
}

=item initialize

initialize a project.

=cut

sub initialize {
    my $self = shift;
    my $dir  = $self->SUPER::initialize(@_);

    $self->delete;    # clean repository in case it exists
    $self->import(
        source      => $dir,
        _initialize => 1,
        comment     => 'created project',
    );
    $self->_initialize_local_dir;
}

sub _svnroot {
    my $self = shift;
    return $self->{svnroot} if $self->{svnroot};
    my $depotmap = run_cmd( [ $ENV{'SHIPWRIGHT_SVK'} => depotmap => '--list' ] );
    $depotmap =~ s{\A.*?^(?=/)}{}sm;
    while ($depotmap =~ /^(\S*)\s+(.*?)$/gm) {
        my ($depot, $svnroot) = ($1, $2);
        if ($self->repository =~ /^$depot(.*)/) {
            return $self->{svnroot} = "file://$svnroot/$1";
        }
    }
    confess_or_die "Can't find determine underlying SVN repository for ". $self->repository;
}

# a cmd generating factory
sub _cmd {
    my $self = shift;
    my $type = shift;
    my %args = @_;
    $args{path}    ||= '';
    $args{comment} ||= '';

    for ( @{ $REQUIRE_OPTIONS{$type} } ) {
        confess_or_die "$type need option $_" unless $args{$_};
    }

    my @cmd;

    if ( $type eq 'checkout' ) {
        if ( $args{detach} ) {
            @cmd = [ $ENV{'SHIPWRIGHT_SVK'}, 'checkout', '-d', $args{target} ];
        }
        else {
            @cmd = [
                $ENV{'SHIPWRIGHT_SVK'},                           'checkout',
                $self->repository . $args{path}, $args{target}
            ];
        }
    }
    elsif ( $type eq 'export' ) {
        @cmd = (
            [
                $ENV{'SHIPWRIGHT_SVN'},                           'export',
                $self->_svnroot . $args{path}, $args{target}
            ],
        );
    }
    elsif ( $type eq 'list' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'list', $self->_svnroot . $args{path} ];
    }
    elsif ( $type eq 'import' ) {
        if ( $args{_initialize} ) {
            @cmd = [
                $ENV{'SHIPWRIGHT_SVK'}, 'import', $args{source},
                $self->repository . ( $args{path} || '' ),
                '-m', $args{comment},
            ];
        }
        elsif ( $args{_extra_tests} ) {
            @cmd = [
                $ENV{'SHIPWRIGHT_SVK'},         'import',
                $args{source}, $self->repository . '/t/extra',
                '-m',          $args{comment},
            ];
        }
        else {
            my ( $path, $source );
            if ( $args{build_script} ) {
                $path   = "/scripts/$args{name}";
                $source = $args{build_script};
            }
            else {
                $path =
                  $self->has_branch_support
                  ? "/sources/$args{name}/$args{as}"
                  : "/dists/$args{name}";
                $source = $args{source};
            }

            if ( $self->info( path => $path ) ) {
                @cmd = (
                    sub {
                        $self->_sync_local_dir( $path );
                        remove_tree( $self->local_dir . $path );
                        rcopy( $source, $self->local_dir . $path, );
                    },
                    [
                        $ENV{'SHIPWRIGHT_SVK'}, 'commit',
                        '--import',             $self->local_dir . $path,
                        '-m',                   $args{comment}
                    ],
                );
            }
            else {
                @cmd = [
                    $ENV{'SHIPWRIGHT_SVK'},   'import',
                    $source, $self->repository . $path,
                    '-m',    $args{comment},
                ];
            }
        }

    }
    elsif ( $type eq 'commit' ) {
        @cmd = [
            $ENV{'SHIPWRIGHT_SVK'},
            'commit',
            (
                $args{import}
                ? '--import'
                : ()
            ),
            '-m',
            $args{comment},
            $args{path}
        ];
    }
    elsif ( $type eq 'delete' ) {
        @cmd = [
            $ENV{'SHIPWRIGHT_SVK'}, 'delete',
            '-m',                   'delete repository',
            $self->repository . $args{path},
        ];
    }
    elsif ( $type eq 'move' ) {
        @cmd = [
            $ENV{'SHIPWRIGHT_SVK'},
            'move',
            '-m',
            "move $args{path} to $args{new_path}",
            $self->repository . $args{path},
            $self->repository . $args{new_path}
        ];
    }
    elsif ( $type eq 'info' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVK'}, 'info', $self->repository . $args{path} ];
    }
    elsif ( $type eq 'cat' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'cat', $self->_svnroot . $args{path} ];
    }
    else {
        confess_or_die "invalid command: $type";
    }

    return @cmd;
}

sub _yml {
    my $self = shift;
    my $path = shift;
    my $yml  = shift;

    my $file = catfile( $self->local_dir . $path );

    if ($yml) {
        if ( $path =~ /scripts/ ) {
            $self->_sync_local_dir('/scripts');
        }
        else {
            $self->_sync_local_dir($path);
        }
        dump_yaml_file( $file, $yml );
        $self->commit( path => $file, comment => "updated $path" );
    }
    else {
        my ($out) = run_cmd(
            [ $ENV{'SHIPWRIGHT_SVN'}, 'cat', $self->_svnroot . $path ] );
        return load_yaml($out);
    }
}

=item info

a wrapper around svk's info command.

=cut

sub info {
    my $self = shift;
    my ( $info, $err ) = $self->SUPER::info(@_);

    if (wantarray) {
        return $info, $err;
    }
    else {
        return if $info =~ /not exist|not a checkout path/;
        return $info;
    }
}

=item check_repository

check if the given repository is valid.

=cut

sub check_repository {
    my $self = shift;
    my %args = @_;

    if ( $args{action} eq 'create' ) {

        my $repo = $self->repository;
        my ( $info, $err ) = $self->info;
        if ($err) {
            $err =~ s{\s+$}{ };
            $self->log->fatal( $err, "maybe root of $repo does not exist?" );
            return;
        }

        return 1
          if $args{force} || $info =~ /not exist/ || $info =~ /Revision: 0/;

        $self->log->fatal("$repo has commits already");
        return;
    }
    else {
        return $self->SUPER::check_repository(@_);
    }
    return;
}

sub _update_file {
    my $self   = shift;
    my $path   = shift;
    my $latest = shift;

    my $file = $self->local_dir . $path;
    $self->_sync_local_dir( $path );

    rcopy( $latest, $file ) or confess_or_die "can't copy $latest to $file: $!";
    $self->commit(
        path    => $file,
        comment => "updated $path",
    );
}

sub _update_dir {
    my $self   = shift;
    my $path   = shift;
    my $latest = shift;

    $self->_sync_local_dir( $path );
    my $dir = $self->local_dir . $path;
    remove_tree( $dir );
    rcopy( $latest, $dir ) or confess_or_die "can't copy $latest to $dir: $!";
    $self->commit(
        path    => $dir,
        comment => "updated $path",
        import  => 1,
    );
}

sub _initialize_local_dir {
    my $self = shift;
    # the 0 is very important, or it may results in recursion
    my $target = $self->local_dir( 0 ); 
    remove_tree( $target ) if -e $target;

    run_cmd(
        [ $ENV{'SHIPWRIGHT_SVK'}, 'checkout', $self->repository, $target ] );
    return $target;
}

sub _sync_local_dir {
    my $self = shift;
    my $path = shift || '';

    run_cmd(
        [ $ENV{'SHIPWRIGHT_SVK'}, 'update', $self->local_dir . $path ] );
}

=back

=cut

1;

__END__

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
