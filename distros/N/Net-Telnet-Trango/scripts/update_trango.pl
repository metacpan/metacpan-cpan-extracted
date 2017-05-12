#!/usr/bin/perl
# $RedRiver: update_trango.pl,v 1.34 2007/02/07 23:24:39 andrew Exp $
########################################################################
# update_trango.pl *** Updates trango hosts with a new firmware
#
# 2005.11.15 #*#*# andrew fresh <andrew@mad-techies.org>
########################################################################
# Copyright (C) 2005, 2006, 2007 by Andrew Fresh
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################
use strict;
use warnings;

use YAML qw/ LoadFile /;
use Net::TFTP;
use Net::Telnet::Trango;

my $config_file = shift || 'update_trango.yaml';
my $max_tries = 3;

my $l = Mylogger->new( { log_prefix => 'UT' } );

$l->sp("Reading config file '$config_file'");
my $conf = LoadFile($config_file);

my $hosts;
if (@ARGV) {
    @{$hosts} = map { { name => $_, group => 'Trango-Client' } } @ARGV;
}
else {
    $hosts = parse_hosts( $conf->{hosts} );
}

#@{ $hosts } = grep { $_->{name} eq '10.100.7.2' } @{ $hosts };

my $global_tries = $max_tries * 2;
while ( $global_tries > 0 ) {
    $global_tries--;
    my $processed = 0;

    foreach my $host ( @{$hosts} ) {

        if ( !exists $host->{retry} ) {
            $host->{tries} = 0;
            $host->{retry} = 1;
        }

        if ( $host->{tries} >= $max_tries ) {
            $host->{retry} = 0;
        }

        if ( $host->{retry} <= 0 ) {
            next;
        }

        $host->{tries}++;
        $processed++;

        $l->sp("");
        $l->sp("Checking: $host->{name} (try $host->{tries})");
        my $needs_reboot = 0;

        ## Connect and login.
        my $t = new Net::Telnet::Trango(
            Timeout => 5,
            Errmode => 'return',
        ) or die "Couldn't make new connection: $!";
        $l->p("Connecting to $host->{name}");
        unless ( $t->open( $host->{name} ) ) {
            $l->sp("Error connecting: $!");
            next;
        }

        my $password = $host->{Telnet_Password} || $conf->{general}->{password};

        $l->p("Logging in");
        $t->login($password);
        unless ($t->logged_in) {
            $l->p('Failed!');
            $t->close;
            next;
        }

        $l->sp("Getting sudb");
        my $sudb = $t->sudb_view;
        if ($sudb) {
            foreach my $su (@{ $sudb }) {
                $l->p("Getting su info $su->{suid}");
                my $su_info = $t->su_info( $su->{suid} );
                if ($su_info->{ip}) {
                    if (grep { $_->{name} eq $su_info->{'ip'} } @{ $hosts }) {
                        $l->p("Already have $su_info->{ip}");
                        next;
                    }
                    $l->sp("Adding host $su_info->{ip}");
                    my $new_host = {
                        password => $host->{password},
                        name     => $su_info->{ip},
                        remarks  => $su_info->{remarks},
                    };
                    push @{ $hosts }, $new_host;
                } else {
                    $l->sp("Couldn't get su info for $su->{suid}");
                    $l->sp("ERR: " . $t->last_error);
                }
            }
        }

        foreach my $firmware_type ( 'Firmware', 'FPGA' ) {

            if ( !exists $conf->{$firmware_type} ) {
                $l->s("No configs for '$firmware_type'");
                next;
            }

            my $host_type = $t->host_type;
            if ( $firmware_type eq 'FPGA' ) {
                $host_type =~ s/\s.*$//;
            }

            if ( !exists $conf->{$firmware_type}->{$host_type} ) {
                $l->sp("No '$firmware_type' config for type $host_type");
                next;
            }

            if (   $firmware_type eq 'Firmware'
                && $t->firmware_version eq
                $conf->{$firmware_type}->{$host_type}->{ver} )
            {
                $l->sp("Firmware already up to date");
                next;
            }

            if ( !$t->logged_in ) {
                $l->p("Logging in");
                $t->login($password);
                unless ($t->logged_in) {
                    $l->p('Failed!');
                    $t->close;
                    last;
                }
            }

            foreach my $k ( keys %{ $conf->{general} } ) {
                $conf->{$firmware_type}->{$host_type}->{$k} ||=
                  $conf->{general}->{$k};
            }
            $conf->{$firmware_type}->{$host_type}->{firmware_type} ||=
              $firmware_type;
            $conf->{$firmware_type}->{$host_type}->{type} = $host_type;

            $l->sp("$host_type $firmware_type");
            ## Send commands
            my $rc = upload( $t, $conf->{$firmware_type}->{$host_type} );
            if ($rc) {
                $l->sp("Successfull!");
                $host->{retry}--;
                $needs_reboot = 1;
            }
            elsif ( defined $rc ) {
                $l->sp("Already up to date");
                $host->{retry}--;
            }
            else {
                $l->sp("Failed! - Bye $host->{name}");
                $l->e("Error updating $firmware_type on $host->{name}" . 
                    "(try $host->{tries})");
                $t->bye;
                # don't try any other firmware, don't want to reboot
                last;
            }

        }

        if ($needs_reboot) {
            $l->sp("Rebooting $host->{name}");
            $t->reboot;
        }
        else {
            $l->sp("Bye $host->{name}");
            $t->bye();
        }
    }

    if ( !$processed ) {
        $l->sp("");
        $l->sp("Finished.  No more hosts.");
        last;
    }
}

sub upload {
    my $t    = shift;
    my $conf = shift;

    my $file = $conf->{firmware_path} . '/' . $conf->{file_name};

    my $fw_type = $conf->{firmware_type};

    my $ver = $t->ver;

    if (
        !(
            $ver->{ $fw_type . ' Version' } && $ver->{ $fw_type . ' Checksum' }
        )
      )
    {
        $l->sp("Error getting current version numbers");
        return;
    }

    if (   $ver->{ $fw_type . ' Version' } eq $conf->{'ver'}
        && $ver->{ $fw_type . ' Checksum' } eq $conf->{'cksum'} )
    {
        return 0;
    }

    $l->sp("Updating $fw_type");
    $l->sp("Config information:");
    $l->sp("  Hardware Type: $conf->{'type'}");
    $l->sp("  File Name:     $conf->{'file_name'}");
    $l->sp("  File Size:     $conf->{'file_size'}");
    $l->sp("  File Checksum: $conf->{'file_cksum'}");
    $l->sp("  Conf Version:  $conf->{'ver'}");
    $l->sp("  Cur  Version:  $ver->{$fw_type . ' Version'}");
    $l->sp("  Conf Checksum: $conf->{'cksum'}");
    $l->sp("  Cur  Checksum: $ver->{$fw_type . ' Checksum'}");

    my $try = 0;
    while (1) {
        if ( $try >= $max_tries ) {
            $l->sp("Couldn't update in $max_tries tries!");
            return;
        }
        $try++;

        $l->p("Enabling TFTPd");
        unless ( $t->enable_tftpd ) {
            $l->sp("Couldn't enable tftpd");
            next;
        }

        $l->p("Uploading file ($conf->{file_name})");

        # use tftp to push the file up
        my $tftp = Net::TFTP->new( $t->Host, Mode => 'octet' );

        unless ( $tftp->put( $file, $file ) ) {
            $l->sp( "Error uploading: " . $tftp->error );
            next;
        }

        $l->p("Checking upload ($conf->{'file_cksum'})");
        my $results = $t->tftpd;

        # check the 'File Length' against ???
        if (
            !(
                   $results->{'File Checksum'}
                && $results->{'File Length'}
                && $results->{'File Name'}
            )
          )
        {
            $l->sp("Unable to get results of upload");
            next;
        }
        if ( $results->{'File Checksum'} ne $conf->{'file_cksum'} ) {
            $l->sp( "File checksum ("
                  . $results->{'File Checksum'}
                  . ") does not match config file ("
                  . $conf->{'file_cksum'}
                  . ")!" );
            next;
        }
        $l->p("File checksum matches . . . ");

        if ( $results->{'File Length'} !~ /^$conf->{'file_size'} bytes/ ) {
            $l->sp( "File length ("
                  . $results->{'File Length'}
                  . ") does not match config file ("
                  . $conf->{'file_size'}
                  . " bytes)!" );
            next;
        }
        $l->p("File length matches . . . ");

        if ( uc( $results->{'File Name'} ) ne uc($file) ) {
            $l->sp( "File name ("
                  . $results->{'File Name'}
                  . ") does not match config file ("
                  . $file
                  . ")!" );
            next;
        }
        $l->p("File name matches . . . ");

        my $image_type = 'mainimage';
        if ( $fw_type eq 'FPGA' ) {
            $image_type = 'fpgaimage';
        }
        $l->p("Updating $image_type (new checksum '$conf->{'cksum'}')");
        unless (
            $results = $t->updateflash(
                args => $image_type . ' '
                  . $ver->{ $fw_type . ' Checksum' } . ' '
                  . $conf->{'cksum'},
                Timeout => 90,
            )
          )
        {
            $l->sp("Couldn't update flash: $!");
            next;
        }

        unless ( defined $results->{'Checksum'}
            && $results->{'Checksum'} eq $conf->{'cksum'} )
        {
            $l->sp( "Saved checksum "
                  . $results->{'Checksum'}
                  . " does not match config file "
                  . $conf->{'cksum'}
                  . "!" );
            next;
        }

        $l->p("$fw_type saved checksum matches . . . ");

        return 1;
    }
}

sub parse_hosts {
    my $src = shift;

    my @hosts;
    foreach my $h ( @{$src} ) {
        if ( $h->{name} =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.)(\d{1,3})-(\d{1,3})/ )
        {
            for ( $2 .. $3 ) {
                my %cur_host;
                foreach my $k ( keys %{$h} ) {
                    $cur_host{$k} = $h->{$k};
                }
                $cur_host{name} = $1 . $_;
                if ( !grep { $cur_host{name} eq $h->{name} } @hosts ) {
                    push @hosts, \%cur_host;
                }
            }
        }
        else {
            push @hosts, $h;
        }
    }

    return \@hosts;
}

package Mylogger;

use Fcntl ':flock';    # import LOCK_* constants

#use YAML;
use constant LOG_PRINT => 128;
use constant LOG_SAVE  => 64;
use constant LOG_ERR   => 1;

DESTROY {
    my $self = shift;
    if ( $self->{'MYLOG'} ) {
        $self->p("Closing log ($self->{'log_path'}/$self->{'log_file'})");
        close $self->{'MYLOG'};
    }
}

sub new {
    my $package = shift;
    my $self = shift || {};

    $self->{'base_path'}  ||= '.';
    $self->{'log_path'}   ||= $self->{'base_path'};
    $self->{'log_prefix'} ||= 'LOG';
    $self->{'log_file'} ||=
      GetLogName( $self->{'log_prefix'}, $self->{'log_path'} );
    bless $self, $package;
}

sub s {
    my $self = shift;
    my $m    = shift;
    return $self->mylog( $m, LOG_SAVE );
}

sub p {
    my $self = shift;
    my $m    = shift;
    return $self->mylog( $m, LOG_PRINT );
}

sub sp {
    my $self = shift;
    my $m    = shift;
    return $self->mylog( $m, LOG_SAVE | LOG_PRINT );
}

sub e {
    my $self = shift;
    my $m    = shift;
    return $self->mylog( $m, LOG_ERR );
}

sub mylog {
    my $self = shift;

    my $thing = shift;
    chomp $thing;

    my $which = shift;

    my $MYLOG;
    if ( $which & LOG_PRINT ) {
        print $thing, "\n";
    }

    if ( $which & LOG_SAVE ) {
        if ( $self->{'MYLOG'} ) {
            $MYLOG = $self->{'MYLOG'};
        }
        else {
            unless ($MYLOG) {
                open( $MYLOG, '>>',
                    $self->{'log_path'} . '/' . $self->{'log_file'} )
                  or die "Couldn't open logfile!\n";
                my $ofh = select $MYLOG;
                $| = 1;
                select $ofh;
                $self->{'MYLOG'} = $MYLOG;

                $self->p(
                    "Opened log ($self->{'log_path'}/$self->{'log_file'})");
            }
        }
        flock( $MYLOG, LOCK_EX );
        print $MYLOG ( scalar gmtime ), "\t", $thing, "\n"
          or die "Couldn't print to MYLOG: $!";
        flock( $MYLOG, LOCK_UN );
    }

    if ( $which & LOG_ERR ) {
        # XXX Could tie in here to handle some sort of notifications.
        print STDERR $thing, "\n";
    }
}

sub GetLogName {
    my $prefix = shift || die "Invalid prefix passed for log";

    my $logdate = GetLogDate();
    my $logver  = 0;
    my $logname;

    do {
        $logname = $prefix . $logdate . sprintf( "%02d", $logver ) . '.log';
        $logver++;
    } until ( not -e $logname );

    return $logname;
}

sub GetLogDate {
    my ( $sec, $min, $hour, $mday, $mon, $year,,, ) = localtime();

    $mon++;
    $year += 1900;

    if ( $min  < 10 ) { $min  = "0$min"  }
    if ( $sec  < 10 ) { $sec  = "0$sec"  }
    if ( $hour < 10 ) { $hour = "0$hour" }
    if ( $mday < 10 ) { $mday = "0$mday" }
    if ( $mon  < 10 ) { $mon  = "0$mon"  }

    my $time = $year . $mon . $mday;

    return $time;
}
