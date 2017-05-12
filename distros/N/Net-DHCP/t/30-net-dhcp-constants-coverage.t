#!/usr/bin/perl

use Test::More tests => 207;

BEGIN { use_ok('Net::DHCP::Constants'); }

use Net::DHCP::Constants
  qw(%DHO_CODES %DHCP_MESSAGE %NWIP_CODES %CCC_CODES %GEOCONF_CODES %RELAYAGENT_CODES);

use strict;
use warnings;

# load in the iana definitions
my %iana;
eval {
    our $VAR1;
    for my $file (qw(  ./.iana.pl ../t/.iana.pl t/.iana.pl  )) {
        require $file if -f $file;
    }
    die "couldnt load iana file"
      unless ref $VAR1;
    %iana = %$VAR1;
};

SKIP: {
    skip( q|Couldn't load iana details, skipping coverage|, 206 ) if $@;

    # check that all iana codes are included

    # DHO CODES - bootp-dhcp-parameters-1
    {
        my @val = values %DHO_CODES;

        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-1'}
          ->{record};    # this is mildy nasty

        for my $k (
            sort { int $codes->{$a}->{value} <=> int $codes->{$b}->{value} }
            grep { $_ !~ m/unassigned|private use/i }
            keys %$codes
          )
        {

            my $name = $k;
            $name =~ s/\n+//;
            my $value = int $codes->{$k}->{value};
            ok(
                ( grep { $value == $_ } @val ),
                "\%DHO_CODES has $value aka $name"
            );

        }

    }

## MESSAGE TYPES - bootp-dhcp-parameters-2
    {
        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-1'}->{registry}
          ->{'bootp-dhcp-parameters-2'}->{record};    # this is mildy nasty
        for my $k (
            sort { int $codes->{$a}->{value} <=> int $codes->{$b}->{value} }
            keys %$codes
          )
        {
            ok( $DHCP_MESSAGE{$k}, "\%DHCP_MESSAGE has $k" );
            ok(
                $DHCP_MESSAGE{$k} == int $codes->{$k}->{value},
                "...and $k is " . $codes->{$k}->{value}
            );
        }
    }

## NWIP CODES - bootp-dhcp-parameters-3
    {

        my @val = values %NWIP_CODES;

        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-1'}->{registry}
          ->{'bootp-dhcp-parameters-3'}->{record};    # this is mildy nasty

        for my $k (
            sort { int $codes->{$a}->{value} <=> int $codes->{$b}->{value} }
            grep { $_ !~ m/unassigned|private use/i }
            keys %$codes
          )
        {

            my $name = $k;
            $name =~ s/\n+//;
            my $value = int $codes->{$k}->{value};
            ok(
                ( grep { $value == $_ } @val ),
                "\%NWIP_CODES has $value aka $name"
            );

            #die unless (grep {$value == $_} @val);

        }
    }

## CCC CODES - bootp-dhcp-parameters-4
    {

        my @val = values %CCC_CODES;

        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-1'}->{registry}
          ->{'bootp-dhcp-parameters-4'}->{record};    # this is mildy nasty

        for my $k (
            sort { int $a->{value} <=> int $b->{value} }
            grep { $_->{description} !~ m/unassigned|private use/i } @$codes
          )
        {

            my $name = $k->{description};
            $name =~ s/\n+//;
            my $value = $k->{value};
            ok(
                ( grep { $value == $_ } @val ),
                "\%CCC_CODES has $value aka $name"
            );

            #die unless (grep {$value == $_} @val);

        }
    }

## GEOCONF CODES - bootp-dhcp-parameters-5
    {

        my @val = values %CCC_CODES;

        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-1'}->{registry}
          ->{'bootp-dhcp-parameters-5'}->{record};    # this is mildy nasty

        for my $k (
            sort { int $a->{value} <=> int $b->{value} }
            grep { $_->{description} !~ m/unassigned|private use/i } @$codes
          )
        {

            my $name = $k->{description};
            $name =~ s/\n+//;
            my $value = $k->{value};
            ok(
                ( grep { $value == $_ } @val ),
                "\%GEOCONF_CODES has $value aka $name"
            );

            #die unless (grep {$value == $_} @val);

        }
    }
## GEOCONF CODES - bootp-dhcp-parameters-6

    # im not quite sure what to do with geoconf

## CCC PacketCable mask bits. also not sure - bootp-dhcp-parameters-7

## DHCP RELAY SUB OPTIONS CODES - bootp-dhcp-parameters-8
    {

        my @val = values %RELAYAGENT_CODES;

        my $codes =
          $iana{registry}->{'bootp-dhcp-parameters-8'}
          ->{record};    # this is mildy nasty

        for my $k (
            sort { int $a->{value} <=> int $b->{value} }
            grep { $_->{description} !~ m/unassigned|private use|reserved/i }
            @$codes
          )
        {

            my $name = $k->{description};
            $name =~ s/\n+//;
            my $value = $k->{value};
            ok( ( grep { $value == $_ } @val ),
                "\%RELAYAGENT_CODES has $value aka $name" );

            #die unless (grep {$value == $_} @val);

        }
    }

## DHCP RELAY SUB OPTIONS CODES - suboptions are defined in - bootp-dhcp-parameters-9
## DHCP RELAY SUB OPTIONS CODES - suboptions are defined in - bootp-dhcp-parameters-10
    # neither of which i have any idea what to do with yet

}

1;
