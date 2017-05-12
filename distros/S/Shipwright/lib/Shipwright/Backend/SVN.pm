package Shipwright::Backend::SVN;

use warnings;
use strict;
use File::Spec::Functions qw/catfile/;
use Shipwright::Util;
use File::Copy::Recursive qw/rcopy/;

our %REQUIRE_OPTIONS = ( import => [qw/source/] );

use base qw/Shipwright::Backend::Base/;

=head1 NAME

Shipwright::Backend::SVN - SVN repository backend

=head1 SYNOPSIS

    svnadmin create /home/me/shipwright/my_proj
    shipwright create -r svn:file:///home/me/shipwright/my_proj

=head1 DESCRIPTION

This module implements a SVN based backend
for Shipwright L<repository|Shipwright::Manual::Glossary/repository>.

=head1 ENVIRONMENT VARIABLES

=over 4

=item SHIPWRIGHT_SVN - path of F<svn> command, default value is F<svn>.
F<svnadmin> command is expected to be in the same directory as F<svn>.

=back

=head1 METHODS

=over 4

=item build

=cut



sub build {
    my $self = shift;
    $self->strip_repository
        if $self->repository =~ m{^svn:[a-z]+(?:\+[a-z]+)?://};
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
    $self->_initialize_local_dir();

}

=item import

=cut

sub import {
    my $self = shift;
    return unless ref $self; # get rid of class->import
    return $self->SUPER::import( @_, delete => 1 );
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
        @cmd =
          [ $ENV{'SHIPWRIGHT_SVN'}, 'checkout', $self->repository . $args{path}, $args{target} ];
    }
    elsif ( $type eq 'export' ) {
        @cmd =
          [ $ENV{'SHIPWRIGHT_SVN'}, 'export', $self->repository . $args{path}, $args{target} ];
    }
    elsif ( $type eq 'import' ) {
        if ( $args{_initialize} ) {
            @cmd = [
                $ENV{'SHIPWRIGHT_SVN'}, 'import', $args{source},
                $self->repository . ( $args{path} || '' ),
                '-m', $args{comment},
            ];
        }
        elsif ( $args{_extra_tests} ) {
            @cmd = [
                $ENV{'SHIPWRIGHT_SVN'},         'import',
                $args{source}, $self->repository . '/t/extra',
                '-m',          $args{comment},
            ];
        }
        else {
            if ( my $script_dir = $args{build_script} ) {
                @cmd = [
                    $ENV{'SHIPWRIGHT_SVN'},       'import',
                    $script_dir, $self->repository . "/scripts/$args{name}/",
                    '-m',        $args{comment},
                ];
            }
            else {
                if ( $self->has_branch_support ) {
                    @cmd = [
                        $ENV{'SHIPWRIGHT_SVN'},
                        'import',
                        $args{source},
                        $self->repository . "/sources/$args{name}/$args{as}",
                        '-m',
                        $args{comment},
                    ];
                }
                else {
                    @cmd = [
                        $ENV{'SHIPWRIGHT_SVN'},
                        'import',
                        $args{source},
                        $self->repository . "/dists/$args{name}",
                        '-m',
                        $args{comment},
                    ];

                }
            }
        }
    }
    elsif ( $type eq 'list' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'list', $self->repository . $args{path} ];
    }
    elsif ( $type eq 'commit' ) {
        @cmd =
          [ $ENV{'SHIPWRIGHT_SVN'}, 'commit', '-m', $args{comment}, $args{path} ];
    }
    elsif ( $type eq 'delete' ) {
        @cmd = [
            $ENV{'SHIPWRIGHT_SVN'}, 'delete',
            '-m',                   'delete ' . $args{path},
            $self->repository . $args{path},
        ];
    }
    elsif ( $type eq 'move' ) {
        @cmd = [
            $ENV{'SHIPWRIGHT_SVN'},
            'move',
            '-m',
            "move $args{path} to $args{new_path}",
            $self->repository . $args{path},
            $self->repository . $args{new_path}
        ];
    }
    elsif ( $type eq 'info' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'info', $self->repository . $args{path} ];
    }
    elsif ( $type eq 'cat' ) {
        @cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'cat', $self->repository . $args{path} ];
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

    my $file = $self->local_dir . $path;

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
            [ $ENV{'SHIPWRIGHT_SVN'}, 'cat', $self->repository . $path ] );
        return load_yaml($out);
    }
}

=item info

a wrapper around svn's info command.

=cut

sub info {
    my $self = shift;
    my ( $info, $err ) = $self->SUPER::info(@_);

    if (wantarray) {
        return $info, $err;
    }
    else {
        if ($err) {
            $err =~ s/\s+$//;
            $self->log->warn($err);
            return;
        }
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

        my ( $info, $err ) = $self->info;

        my $repo = $self->repository;

        # $err like
        # file:///tmp/svn/foo:  (Not a valid URL)
        # usually means foo doesn't exist, which is valid for create
        if ($info) {
            return 1 if $args{force} || $info =~ /Revision: 0/;
            $self->log->fatal("$repo has commits already");
            return;
        }
        return 1 if $err && $err =~ m{^\Q$repo\E:}m;
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

    $self->_sync_local_dir( $path );
    my $file = $self->local_dir . $path;
    rcopy( $latest, $file ) or confess_or_die "can't copy $latest to $file: $!";
    $self->commit(
        path => $file,
        comment => "updated $path",
    );
}

sub _update_dir {
    my $self   = shift;
    my $path   = shift;
    my $latest = shift;

    $self->delete( path => $path );
    $self->import( path => $path, source => $latest, _initialize => 1 );
}

sub _initialize_local_dir {
    my $self = shift;
    # the 0 is very important, or it may results in recursion
    my $target = $self->local_dir( 0 ); 
    remove_tree( $target ) if -e $target;

    run_cmd(
        [ $ENV{'SHIPWRIGHT_SVN'}, 'checkout', $self->repository, $target ] );
    return $target;
}

sub _sync_local_dir {
    my $self = shift;
    my $path = shift || '';
    run_cmd(
        [ $ENV{'SHIPWRIGHT_SVN'}, 'update', $self->local_dir . $path ], 1 );
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
