package Sys::RotateBackup;
{
  $Sys::RotateBackup::VERSION = '0.12';
}
BEGIN {
  $Sys::RotateBackup::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: Rotate numbered backup directories

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

use Sys::FS ;
use Sys::Run;

has 'fs' => (
    'is'      => 'rw',
    'isa'     => 'Sys::FS',
    'lazy'    => 1,
    'builder' => '_init_fs',
);

has 'sys' => (
    'is'      => 'rw',
    'isa'     => 'Sys::Run',
    'lazy'    => 1,
    'builder' => '_init_sys',
);

has 'daily' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 10,
);

has 'weekly' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 4,
);

has 'monthly' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 12,
);

has 'yearly' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 10,
);

has 'vault' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

with qw(Log::Tree::RequiredLogger);

sub _init_sys {
    my $self = shift;

    my $Sys = Sys::Run::->new( { 'logger' => $self->logger(), } );

    return $Sys;
}

sub _init_fs {
    my $self = shift;

    my $FS = Sys::FS::->new(
        {
            'logger' => $self->logger(),
            'sys'    => $self->sys(),
        }
    );

    return $FS;
}

sub rotate {
    my $self = shift;
    my $time = shift || time();

    my ( $sec, $min, $hour, $dom, $mon, $year, $dow, $doy, $isdst ) = localtime($time);
    $year += 1900;
    $mon++;
    $dow++;
    $doy++;
    # dom is already correct (starting at 1, not 0 like to others ...)

    # rotate daily
    $self->_rotate( 'daily', $self->daily() );

    # rotate weekly if dow == 1 && do_weekly
    if ( $self->weekly() && $dow == 1 ) {
        $self->_rotate( 'weekly', $self->weekly() );
    }

    # rotate monthly if dom == 1 && do_monthly
    if ( $self->monthly() && $dom == 1 ) {
        $self->_rotate( 'monthly', $self->monthly() );
    }

    # rotate yearly if dom == 1 && mon == 1 && do_yearly
    if ( $self->yearly() && $doy == 1 ) {
        $self->_rotate( 'yearly', $self->yearly() );
    }

    return 1;
}

sub cleanup {
    my $self = shift;

    # cleanup old backups copies

    # clean up dailys
    $self->_cleanup( 'daily', $self->daily() );

    # clean up weeklys
    if( $self->weekly() ) {
        $self->_cleanup( 'weekly', $self->weekly() );
    } else {
        my $weekly_dir = $self->fs()->filename( $self->vault(), 'weekly' );
        $self->sys()->run_cmd( 'rm -rf ' . $weekly_dir );
    }

    # clean up monthlys
    if( $self->monthly() ) {
        $self->_cleanup( 'monthly', $self->monthly() );
    } else {
        my $monthly_dir = $self->fs()->filename( $self->vault(), 'monthly' );
        $self->sys()->run_cmd( 'rm -rf ' . $monthly_dir );
    }

    # clean up yearlys
    if( $self->yearly() ) {
        $self->_cleanup( 'yearly', $self->yearly() );
    } else {
        my $yearly_dir = $self->fs()->filename( $self->vault(), 'yearly' );
        $self->sys()->run_cmd( 'rm -rf ' . $yearly_dir );
    }

    return 1;
}

sub _cleanup {
    my $self = shift;
    my $type = shift;
    my $num  = shift || 1;

    my $basedir = $self->fs()->filename( $self->vault(), $type );

    if(!-d $basedir) {
        $self->logger()->log( message => 'Basedir '.$basedir.' not a directory. Aborting!', level => 'error', );
        return;
    }

    if(-d $basedir && opendir(my $DH, $basedir)) {
        while(my $de = readdir($DH)) {
            next if $de =~ m/^\./; # skip cur and upper dir
            next unless $de =~ m/^\d+$/; # skip non-numeric dirs
            next if $de < $num; # skip any valid rotational
            my $path = $self->fs()->filename( $basedir, $de );
            next unless -d $path; # skip any non-dirs

            if($self->sys()->run_cmd( 'rm -rf ' . $path )) {
                $self->logger()->log( message => 'Removed superflous rotational directory: '.$path, level => 'debug', );
            } else {
                $self->logger()->log( message => 'Failed to remove superflous rotational directory: '.$path, level => 'debug', );
            }
        }
        closedir($DH);
    }

    return 1;
}

sub _rotate {
    my $self = shift;
    my $type = shift;
    my $num  = shift;

    my $basedir = $self->fs()->filename( $self->vault(), $type );

    if ( $num > 500 ) {
        $num = 500;
    }
    elsif ( $num < 1 ) {
        $num = 10;
    }

    # Create basedir for this type
    if ( !-d $basedir ) {
        $self->fs()->makedir($basedir);
    }

    # Remove the oldest directory
    if ( -d $basedir . q{/} . $num ) {
        $self->sys()->run_cmd( 'rm -rf ' . $basedir . q{/} . $num );
    }

    # Rotate the others
    ## no critic (ProhibitCStyleForLoops)
    for ( my $i = $num ; $i > 0 ; $i-- ) {
        my $olddir = $basedir . q{/} . ( $i - 1 );
        my $newdir = $basedir . q{/} . $i;
        if ( -d $olddir && -w $basedir ) {
            $self->logger()->log( message => 'Moving from '.$olddir.' to '.$newdir, level => 'debug', );
            my $cmd = q{mv -f "} . $olddir . q{" "} . $newdir . q{"};
            $self->logger()->log( message => 'CMD: ' . $cmd, level => 'debug', );
            $self->sys()->run_cmd($cmd);
        }
        elsif ( -w $basedir ) {
            my $cmd = q{mkdir -p -m0700 "} . $newdir . q{"};
            $self->logger()->log( message => 'CMD: ' . $cmd, level => 'debug', );
            $self->sys()->run_cmd($cmd);
            if ( $i > 1 ) {    # do not create the 0 dir, or mv'ing inprogress will move to wrong destination
                $cmd = q{mkdir -p -m0700 "}.$olddir.q{"};
                $self->logger()->log( message => 'CMD: ' . $cmd, level => 'debug', );
                $self->sys()->run_cmd($cmd);
            }
        }
    }
    ## use critic

    # Create the current dir
    if ( $type eq 'daily' ) {

        # Move inprogress
        my $olddir = $basedir . '/inprogress';
        my $newdir = $basedir . '/0';
        if ( -d $olddir && -w $basedir ) {
            $self->logger()->log( message => 'Moving from '.$olddir.' to '.$newdir, level => 'debug', );
            my $cmd = q{mv -f "} . $olddir . q{" "} . $newdir . q{"};
            $self->logger()->log( message => 'CMD: ' . $cmd, level => 'debug', );
            $self->sys()->run_cmd($cmd);
        }
        else {
            $self->logger()->log( message => q{Can't move from }.$olddir.' to '.$newdir.'. '.$olddir.' not found or '.$basedir.' is not writeable.', level => 'debug', );
        }
    }
    else {
        my $daily  = $self->fs()->filename( $self->vault(), 'daily', '0' );
        my $newdir = $basedir . '/0';
        my $cmd    = q{};
        if ( -x '/usr/bin/rsync' ) {
            $cmd = '/usr/bin/rsync -a --whole-file --link-dest=' . $daily . q{/ } . $daily . q{/ } . $newdir . q{/};
        }
        else {
            $cmd = '/bin/cp -al ' . $daily . q{/ } . $newdir . q{/};
        }
        $self->logger()->log( message => "CMD: $cmd", level => 'debug', );
        $self->sys()->run_cmd($cmd);
    }
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sys::RotateBackup - Rotate numbered backup directories

=head1 METHODS

=head2 rotate

Rotate all valid types in vault.

=head2 cleanup

Remove all unnecessary directores.

=cut

=head1 NAME

Sys::RotateBackup - rotate numiercal directories

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
