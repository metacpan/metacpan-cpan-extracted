package Shipwright::Script::List;

use strict;
use warnings;
use Shipwright::Util;

use base qw/App::CLI::Command Shipwright::Base Shipwright::Script/;
__PACKAGE__->mk_accessors(qw/with_latest_version only_update/);

use Shipwright;
use Cwd qw/getcwd/;
use File::Temp qw/tempdir/;
use File::Spec::Functions qw/catdir/;

sub options {
    (
        'with-latest-version' => 'with_latest_version',
        'only-update'         => 'only_update',
    );
}

sub run {
    my $self = shift;
    my $name = shift;

    my $shipwright = Shipwright->new( repository => $self->repository, );

    my $versions = $shipwright->backend->version;
    my $source   = $shipwright->backend->source;
    my $refs     = $shipwright->backend->refs || {};
    my $branches;

    if ( $shipwright->backend->has_branch_support ) {
        $branches = $shipwright->backend->branches;
    }

    my $latest_version = {};

    # only_update option implies with_latest_version
    $self->with_latest_version(1) if $self->only_update;

    if ( $self->with_latest_version ) {
        my $map = $shipwright->backend->map;

        if ($name) {
            if ( $name =~ /^cpan-/ && !$source->{$name} ) {
                my %reversed = reverse %$map;
                my $module   = $reversed{$name};
                $latest_version->{$name} =
                  $self->_latest_version( name => $module );
            }
            else {
                $latest_version->{$name} =
                  $self->_latest_version( url => $source->{$name} );
            }
        }
        else {

            for my $module ( keys %$map ) {
                next if exists $latest_version->{ $map->{$module} };
                $latest_version->{ $map->{$module} } =
                  $self->_latest_version( name => $module );
            }
            for my $name ( keys %$source ) {
                next if exists $latest_version->{$name};
                for my $branch ( keys %{ $source->{$name} } ) {
                    if ( $source->{$name}{$branch} =~
                        m{^(sv[nk]|git|shipwright):} )
                    {
                        $latest_version->{$name}{$branch} =
                          $self->_latest_version(
                            url => $source->{$name}{$branch} );
                    }
                }
            }
        }
    }

    if ($name) {
        my $new_versions = {};
        $new_versions->{$name} = $versions->{$name}
          if exists $versions->{$name};
        $versions = $new_versions;
    }
    for my $name ( sort keys %$versions ) {
        my $flip = 1;

        if ( $self->only_update ) {
            $flip = 0;
            if ( $latest_version->{$name} ) {
                require version;
                my $latest = version->new( $latest_version->{$name} );
                if ( ref $versions->{$name} ) {

                  # we show this dist if at least one of the branches has update
                    for my $branch ( keys %{ $versions->{$name} } ) {
                        if ( $latest gt $versions->{$name}{$branch} ) {
                            $flip = 1;
                            last;
                        }
                    }
                }
                elsif ( $latest gt $versions->{$name} ) {
                    $flip = 1;
                }
            }
        }

        if ($flip) {
            $self->log->fatal( $name, ':' );
            my $version_info;
            if ( ref $versions->{$name} ) {

                if ( $name =~ /^cpan-/ ) {
                    $version_info = $versions->{$name}{'vendor'};
                }
                else {
                    $version_info = "\n";
                    for my $branch ( keys %{ $versions->{$name} } ) {
                        $version_info .= ' ' x 8 .
                          $branch . ': ' . $versions->{$name}{$branch}
                          || '' . "\n";
                    }
                    chomp $version_info;
                }
            }
            else {
                $version_info = $versions->{$name} || '';
            }
            $self->log->fatal( ' ' x 4 . 'version: ' . $version_info );

            my $from_info;
            if ( ref $source->{$name} ) {
                $from_info = "\n";
                for my $branch ( keys %{ $source->{$name} } ) {
                    $from_info .= ' ' x 8 . $branch .
                      ': ' . $source->{$name}{$branch} || '' . "\n";
                }
                chomp $from_info;
            }
            else {
                $from_info = $source->{$name} || 'CPAN';
            }
            $self->log->fatal( ' ' x 4 . 'from: ' . $from_info );

            $self->log->fatal( ' ' x 4 . 'references: ',
              defined $refs->{$name} ? $refs->{$name} : 'unknown' );

            if ( $self->with_latest_version ) {
                my $latest_version_info;
                if ( ref $source->{$name} ) {
                    $latest_version_info = "\n";
                    for my $branch ( keys %{ $source->{$name} } ) {
                        $latest_version_info .=
                            ' ' x 8 
                          . $branch . ': '
                          . ( $latest_version->{$name}{$branch} || 'unknown' )
                          . "\n";
                    }
                    chomp $latest_version_info;
                }
                else {
                    $latest_version_info = $latest_version->{$name} || 'unknown';
                }
                $self->log->fatal( ' ' x 4,
                    'latest_version: ' . $latest_version_info );
            }

            if ($branches && $name !~ /^cpan-/) {
                $self->log->fatal( ' ' x 4 . 'branches: ',
                    join ', ', @{ $branches->{$name} } );
            }
        }
    }

    if ( $name && keys %$versions == 0 ) {
        $self->log->fatal( "$name doesn't exist" );
    }
}

sub _latest_version {
    my $self = shift;
    my %args = @_;
    if ( $args{url} ) {

        my ( $cmd, $out );

        # XXX TODO we need a better latest_version for shipwright source
        # using the source shipwright repo's whole version seems lame
        if ( $args{url} =~ s/^shipwright:// ) {
            $args{url} =~ s!/[^/]+$!!;
        }

        # has url, meaning svn, svk or git
        if ( $args{url} =~ /^svn[:+]/ ) {
            $args{url} =~ s{^svn:(?!//)}{};
            $cmd = [ $ENV{'SHIPWRIGHT_SVN'}, 'info', $args{url} ];
            $cmd = [ $ENV{'SHIPWRIGHT_SVK'}, 'info', $args{url} ];
            ($out) = run_cmd( $cmd, 1 );    # ignore failure
            if ( $out =~ /^Revision:\s*(\d+)/m ) {
                return $1;
            }
        }
        elsif ( $args{url} =~ m{^(svk:|//)} ) {
            $args{url} =~ s/^svk://;
            $cmd = [ $ENV{'SHIPWRIGHT_SVK'}, 'info', $args{url} ];
            ($out) = run_cmd( $cmd, 1 );    # ignore failure
            if ( $out =~ /^Revision:\s*(\d+)/m ) {
                return $1;
            }
        }
        elsif ( $args{url} =~ /^git:/ ) {
            $args{url} =~ s{^git:(?!//)}{};

         # TODO XXX is there a better way that we can get latest version of git?
         # current way is not too heavy: it needs clone and log

            my $cwd = getcwd();
            my $dir = tempdir(
                'shipwright_list_git_XXXXXX',
                CLEANUP => 1,
                TMPDIR  => 1
            );
            my $path = catdir( $dir, 'git' );
            run_cmd(
                [ $ENV{SHIPWRIGHT_GIT}, 'clone', $args{url}, $path, ] );
            chdir $path;
            ($out) = run_cmd( [ $ENV{SHIPWRIGHT_GIT}, 'log' ] );
            chdir $cwd;

            if ( $out =~ /^commit\s+(\w+)/m ) {
                return $1;
            }
        }

    }
    elsif ( $args{name} ) {

        # cpan
        require CPAN;
        require CPAN::DistnameInfo;

        select_fh('cpan');

        my $module = CPAN::Shell->expand( 'Module', $args{name} );

        select_fh('stdout');

        my $info    = CPAN::DistnameInfo->new( $module->cpan_file );
        my $version = $info->version;
        $version =~ s/^v//;    # we don't want the leading 'v'
        return $version;
    }
    return;
}

1;

__END__

=head1 NAME

Shipwright::Script::List - List dists of a project

=head1 SYNOPSIS

 list NAME

=head1 OPTIONS

   --with-latest-version           : show the latest version if possible
   --only-update                   : only show the dists that can be updated

=head1 GLOBAL OPTIONS

 -r [--repository] REPOSITORY   : specify the repository uri of our shipyard
 -l [--log-level] LOGLEVEL      : specify the log level
                                  (info, debug, warn, error, or fatal)
 --log-file FILENAME            : specify the log file

=head1 AUTHORS

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Shipwright is Copyright 2007-2015 Best Practical Solutions, LLC.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

