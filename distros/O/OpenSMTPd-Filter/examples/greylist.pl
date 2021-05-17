#!/usr/bin/perl
use v5.16;
use warnings;

use OpenSMTPd::Filter;

use OpenBSD::Pledge;
use DB_File;

my $debug = 0;

my $passtime = 60 * 25;
my $greyexp  = 60 * 60 * 4;
my $whiteexp = 60 * 60 * 864;

tie my %greylist, 'DB_File', '/var/db/greylist.db'
    or die "Unable to tie /var/db/greylist.db: $!";

# To see modules pledge(2) blocks loading
unshift @INC, sub { warn "Attempted to load $_[1]"; return };

pledge(qw<>) || die $!;

OpenSMTPd::Filter->new(
    debug => $debug,
    on    => { filter => { 'smtp-in' => { 'rcpt-to' => \&greylist } } }
)->ready;

sub greylist {
    my ( $phase, $s ) = @_;

    my $src  = $s->{state}->{src};
    my $from = $s->{state}->{message}->{'mail-from'};
    my $to   = $s->{events}->[-1]->{address};
    my $now  = $s->{events}->[-1]->{timestamp};

    $src =~ s/:\d+$//;    # remove port

    my $key = fc join $;, $src, $from, $to;
    my $new = 'block';

    if ( my $status = $greylist{$key} ) {
        my ( $current, $when ) = split /\|/, $status;

        if ( $current eq 'block' ) {
            if ( $when <= $now - $greyexp ) {
                warn "Old entry expired $src from $from to $to\n" if $debug;
            }
            elsif ( $when <= $now - $passtime ) {
                warn "Allowing $src from $from to $to\n" if $debug;
                $new = 'allow';
            }

            else {
                warn "Fast retry on $src from $from to $to\n" if $debug;
                $new = '';
            }
        }

        elsif ( $current eq 'allow' and $when >= $now - $whiteexp ) {
            warn "Updating allow entry $src from $from to $to\n" if $debug;
            $new = 'allow';
        }
        else {
            warn "Expired allow entry $src from $from to $to\n" if $debug;
        }
    }
    else {
        warn "New entry $src from $from to $to\n" if $debug;
    }

    # In theory we could store the key and new status in the state
    # and then only write the new value in a 'tx-reset'
    # handler iff we actually accepted the message.
    $greylist{$key} = "$new|$now" if $new;

    return 'proceed' if $new eq 'allow';
    return reject => '451 Temporary failure, please try again later.';
}

