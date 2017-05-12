package Shipwright::Backend::FS;

use warnings;
use strict;
use File::Spec::Functions qw/catfile splitdir catdir rel2abs/;
use Shipwright::Util;
use File::Copy::Recursive qw/rcopy rmove/;
use File::Path qw/remove_tree make_path/;

our %REQUIRE_OPTIONS = ( import => [qw/source/] );

use base qw/Shipwright::Backend::Base/;

=head1 NAME

Shipwright::Backend::FS - File System backend

=head1 SYNOPSIS

    shipwright create -r fs:/home/me/shipwright/my_project

=head1 DESCRIPTION

This module implements file system based backend with version control
for Shipwright L<repository|Shipwright::Manual::Glossary/repository>.

=head1 METHODS

=cut

=over 4

=item build

=cut

sub build {
    my $self = shift;
    $self->strip_repository;

    my $repo = $self->repository;
    $repo =~ s/^~/user_home/e;
    my $abs_path = rel2abs($repo);
    $repo = $abs_path if $abs_path;
    $self->repository($repo);

    $self->SUPER::build(@_);
}

=item initialize

Initialize a project.

=cut

sub initialize {
    my $self = shift;

    my $dir = $self->SUPER::initialize(@_);

    $self->delete;    # clean repository in case it exists

    rcopy( $dir, $self->repository )
      or confess_or_die "can't copy $dir to " . $self->repository . ": $!";
}

# a cmd generating factory
sub _cmd {
    my $self = shift;
    my $type = shift;
    my %args = @_;
    $args{path} ||= '';

    for ( @{ $REQUIRE_OPTIONS{$type} } ) {
        confess_or_die "$type need option $_" unless $args{$_};
    }

    my @cmd;

    if ( $type eq 'checkout' || $type eq 'export' ) {
        @cmd = sub {
            rcopy( $self->repository . $args{path}, $args{target} );
        };
    }
    elsif ( $type eq 'import' ) {
        if ( $args{_extra_tests} ) {
            @cmd = sub {
                rcopy( $args{source},
                    catdir( $self->repository, 't', 'extra' ) );
            };
        }
        else {
            if ( my $script_dir = $args{build_script} ) {
                push @cmd, sub {
                    rcopy( catdir($script_dir),
                        catdir( $self->repository, 'scripts', $args{name} ) );
                };
            }
            else {
                if ( $self->has_branch_support ) {
                    my @dirs = splitdir( $args{as} );
                    unless (
                        -e catdir(
                            $self->repository, 'sources',
                            $args{name},       @dirs[ 0 .. $#dirs - 1 ]
                        )
                      )
                    {
                        push @cmd, sub {
                            make_path(
                                catdir(
                                    $self->repository,
                                    'sources',
                                    $args{name},
                                    @dirs[ 0 .. $#dirs - 1 ]
                                )
                            );
                        };
                    }

                    push @cmd, sub {
                        rcopy(
                            catdir( $args{source} ),
                            catdir(
                                $self->repository, 'sources',
                                $args{name},       $args{as}
                            )
                        );
                    };
                }
                else {
                    push @cmd, sub {
                        rcopy( catdir( $args{source} ),
                            catdir( $self->repository, 'dists', $args{name} ) );
                    };
                }
            }
        }
    }
    elsif ( $type eq 'delete' ) {
        @cmd = sub { remove_tree( $self->repository . $args{path} ) };
    }
    elsif ( $type eq 'move' ) {
        @cmd = sub {
            rmove(
                $self->repository . $args{path},
                $self->repository . $args{new_path}
            );
        };
    }
    elsif ( $type eq 'info' ) {
        @cmd = sub { -e $self->repository . $args{path} };
    }
    elsif ( $type eq 'list' ) {
        @cmd = sub {
            my $path = $self->repository . $args{path};
            return 'No such file or directory' unless -e $path;

            if ( -d $path ) {
                my $dh;
                opendir $dh, $path or confess_or_die $!;
                my $dirs = join "\t", grep { /^[^.]/ } readdir $dh;
                return $dirs;
            }
            else {
                return $path;
            }
        };
    }
    elsif ( $type eq 'cat' ) {
        @cmd = sub {
            my $path = $self->repository . $args{path};
            return ( 'No such file or directory' ) unless -e $path;
            return ( '', 'Is a directory' ) unless -f $path;
            local $/;
            open my $fh, '<', $path or confess_or_die $!;
            my $c = <$fh>;
            return $c;
        };
    }
    else {
        confess_or_die "invalid command: $type";
    }

    return @cmd;
}

=item _yml


=cut

sub _yml {
    my $self = shift;
    my $path = shift;
    my $yml  = shift;

    my $file = catfile( $self->repository, $path );
    if ($yml) {

        dump_yaml_file( $file, $yml );
    }
    else {
        load_yaml_file($file);
    }
}

=item info


=cut

sub info {
    my $self = shift;
    my %args = @_;
    my $path = $args{path} || '';

    my ( $info, $err ) = $self->SUPER::info( path => $path );

    if (wantarray) {
        return $info, $err;
    }
    else {
        return $info;
    }
}

=item check_repository

Check if the given repository is valid.

=cut

sub check_repository {
    my $self = shift;
    my %args = @_;
    if ( $args{action} eq 'create' ) {
        my $repo = $self->repository;
        if ( $args{force} || !-e $repo ) {
            return 1;
        }
        $self->log->fatal("$repo exists already");
        return;
    }
    else {
        return $self->SUPER::check_repository(@_);
    }
}

sub _update_file {
    my $self   = shift;
    my $path   = shift;
    my $latest = shift;

    my $file = catfile( $self->repository, $path );
    unlink $file;
    rcopy( $latest, $file ) or confess_or_die "can't copy $latest to $file: $!";
}

sub _update_dir {
    my $self   = shift;
    my $path   = shift;
    my $latest = shift;

    my $dir = catfile( $self->repository, $path );
    rcopy( $latest, $dir ) or confess_or_die "can't copy $latest to $dir: $!";
}

=item import

=cut

sub import {
    my $self = shift;
    return unless ref $self;    # get rid of class->import
    return $self->SUPER::import( @_, delete => 1 );
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
