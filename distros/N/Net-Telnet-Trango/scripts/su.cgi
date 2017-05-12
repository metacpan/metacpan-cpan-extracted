#!/usr/bin/perl
# $RedRiver: su.cgi,v 1.6 2008/09/04 21:05:21 andrew Exp $
########################################################################
# su.cgi *** a CGI for Trango SU utilities.
#
# 2007.02.07 #*#*# andrew fresh <andrew@mad-techies.org>
########################################################################
# Copyright (C) 2007 by Andrew Fresh
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################
use strict;
use warnings;

my $host_file = 'su.yaml';

my $default_timeout = 5;
my $default_mac     = '0001DE';
my $default_suid    = 'all';
my $default_cir     = 256;
my $default_mir     = 9999;
my $Start_SUID      = 3;

use CGI qw/:standard/;
use YAML qw/ LoadFile Dump /;
use Net::Telnet::Trango;

print header;

my $aps = get_aps($host_file);

my ( $header, $body );
my $head;
my $show_form = 0;

if ( param() ) {
    my $AP = param('AP');

    unless ( exists $aps->{$AP} ) {
        print h3("AP '$AP' does not exist!");
        print end_html;
        exit;
    }

    my $sumac = param('sumac') || '';
    $sumac =~ s/[^0-9A-Fa-f]//g;
    $sumac = uc($sumac);

    my $suid      = param('suid');
    my $test_type = param('test_type');

    if ( length $sumac == 12 ) {
        ( $header, $body ) = add_su( $aps->{$AP}, $sumac, $suid );
    }
    elsif ( length $suid ) {
        if ( $test_type && $test_type eq 'linktest' ) {
            ( $header, $body ) = linktest( $aps->{$AP}, $suid );
        }
        else {
            ( $header, $body ) = testrflink( $aps->{$AP}, $suid );
            $head = '<meta http-equiv=refresh content=5>';
        }
    }
    else {
        $header    = "Invalid SUID '$suid' and MAC '$sumac'";
        $show_form = 1;
    }

}
else {
    $show_form = 1;
}

if ($header) {

# We don't really want to do this here because we don't want to refresh if we're adding an SU
    if ($head) {
        print start_html( -title => $header, -head => ["$head"] );
    }
    else {
        print start_html($header);
    }
    if ( not defined param('bare') ) {
        print h1($header);
    }

    if ($body) {
        print $body;
    }
}
else {
    print start_html('Trango SU Utilities'), h1('Trango SU Utilities');
}

show_form( $aps, $default_mac ) if $show_form;

print end_html;

sub get_aps {
    my $file = shift;

    my $conf = LoadFile($file);

    my %aps;

    my @hosts;
    foreach my $ap ( keys %{$conf} ) {
        next if $ap eq 'default';
        my $h = $conf->{$ap};

        if ( $h->{name}
            =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.)(\d{1,3})-(\d{1,3})/ )
        {
            for ( $2 .. $3 ) {
                my %cur_host;
                foreach my $k ( keys %{$h} ) {
                    $cur_host{$k} = $h->{$k};
                }
                $cur_host{name} = $1 . $_;
                if ( !grep { $cur_host{name} eq $h->{name} } values %aps ) {
                    my $ap_name = $ap . $_;
                    $aps{$ap_name} = \%cur_host;
                }
            }
        }
        else {
            $aps{$ap} = $conf->{$ap};
            push @hosts, $h;
        }
    }

    if ( ref $conf->{default} eq 'HASH' ) {
        foreach my $ap ( keys %aps ) {
            foreach my $k ( keys %{ $conf->{default} } ) {
                $aps{$ap}{$k} ||= $conf->{default}->{$k};
            }
        }
    }

    return \%aps;

    return {
        'rrlhcwap0000' => {
            group           => 'Trango',
            version         => 1,
            name            => '192.168.1.1',
            port            => 161,
            Read_Community  => 'private',
            Write_Community => 'private',
        }
    };

}

sub show_form {
    my $aps = shift;

    my %cache    = ();
    my @ap_names = sort {
        my @a = $a =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
        my @b = $b =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;

        if (@a) {
            $cache{$a} ||= pack( 'C4' => @a );
        }
        else {
            $cache{$a} ||= lc($a);
        }
        if (@b) {
            $cache{$b} ||= pack( 'C4' => @b );
        }
        else {
            $cache{$b} ||= lc($b);
        }

        $cache{$a} cmp $cache{$b};
    } keys %{$aps};

    print p(
        start_form( -method => 'GET' ),
        'AP:    ',
        popup_menu( -name => 'AP', -values => \@ap_names ),
        br,
        'SUMAC: ',
        textfield( -name => 'sumac', -default => $default_mac ),
        br,
        'SUID:  ',
        textfield( -name => 'suid', -default => $default_suid ),
        br,
        'Test Type: ',
        radio_group(
            -name    => 'test_type',
            -values  => [ 'su testrflink', 'linktest' ],
            -default => 'su testrflink',
        ),
        br, submit, end_form
    );

    print p(
        'Fill in the SUMAC if you wish to add an SU ',
        'or fill in the SUID to run an RF link test.  ',
        'If you enter both a valid SUMAC and a numeric SUID, ',
        'the SU will be added with that SUID.  ',
        'If the SUID is already in the AP, it will be deleted ',
        'before the new SU is added.  '
    );

    return 1;
}

sub login {
    my $host     = shift;
    my $password = shift;

    my $t = new Net::Telnet::Trango( Timeout => $default_timeout );

    #$t->input_log('/tmp/telnet_log');
    #$t->dump_log('/tmp/telnet_log');

    unless ( $t->open( Host => $host ) ) {
        print h3("Error connecting!");
        $t->close;
        return undef;
    }

    unless ( $t->login($password) ) {
        print h3("Couldn't log in: $!");
        $t->exit;
        $t->close;
        return undef;
    }

    return $t;
}

sub add_su {
    my ( $ap, $sumac, $suid ) = @_;

    my $t = login( $ap->{'name'}, $ap->{'Telnet_Password'} );

    my $cur_sus = $t->sudb_view;

    my $new_suid = $suid;
    $new_suid =~ s/\D//gxms;

    if ( !$new_suid ) {
        $new_suid = next_suid($cur_sus);
    }

    my $old_su = '';
    foreach my $su ( @{$cur_sus} ) {
        if ( $new_suid == $su->{'suid'} ) {
            $old_su = $su;
        }

        if ( $sumac eq $su->{'mac'} ) {
            $t->exit;
            $t->close;
            return "MAC '$sumac' already in AP '$ap->{'name'}' "
                . "with SUID '$su->{'suid'}'";
        }
    }

    my $cir = $default_cir;
    my $mir = $default_mir;

    if ($old_su) {
        $cir = $old_su->{'cir'} if $old_su->{'cir'};
        $mir = $old_su->{'mir'} if $old_su->{'mir'};

        if ( !$t->sudb_delete($new_suid) ) {
            $t->exit;
            $t->close;
            return "Error removing SU!";
        }
    }

    if ( !$t->sudb_add( $new_suid, 'reg', $cir, $mir, $sumac ) ) {
        $t->exit;
        $t->close;
        return "Error adding SU!";
    }

    my $new_sus = $t->sudb_view;
    my $added   = 0;
    foreach my $su ( @{$new_sus} ) {
        if ( $su->{'suid'} == $new_suid ) {
            $added = 1;
            last;
        }
    }

    unless ($added) {
        $t->exit;
        $t->close;
        return "Couldn't add su id: $new_suid";
    }

    unless ( $t->save_sudb ) {
        $t->exit;
        $t->close;
        return "Couldn't save sudb";
    }

    $t->exit;
    $t->close;

    my $msg = '';

    if ($old_su) {
        $msg
            .= "Removed old SU with ID '$new_suid' "
            . "and MAC '"
            . $old_su->{'mac'} . "' "
            . "from '$ap->{'name'}'.  ";
    }

    $msg
        .= "Added new SU with ID '$new_suid' "
        . "and MAC '$sumac' "
        . "to '$ap->{'name'}'.  "
        . '<a href="'
        . url(-relative => 1)
        . '?' . 'AP='
        . $ap->{'name'} . '&' . 'suid='
        . $new_suid
        . '">Test SU RFLink</a>';

    return $msg;
}

sub testrflink {
    my $ap   = shift;
    my $suid = shift;

    my $t = login( $ap->{'name'}, $ap->{'Telnet_Password'} );

    my $timeout = $default_timeout;
    if ( $suid eq 'all' ) {
        my $sudb  = $t->sudb_view();
        my $count = scalar @{$sudb};
        $timeout = $count * $default_timeout;
    }
    my $result = $t->su_testrflink( args => $suid, Timeout => $timeout );

    unless ($result) {
        $t->exit;
        $t->close;
        return "Error testing SU rflink!";
    }

    my @keys = ( 'suid', 'AP Tx', 'AP Rx', 'SU Rx' );

    my @table;
    foreach my $su ( @{$result} ) {
        next unless ref $su eq 'HASH';
        next unless exists $su->{'suid'};
        $su->{'suid'} =~ s/\D//g;
        next unless $su->{'suid'};

        push @table, td( [ @{$su}{@keys} ] );
    }

    $t->exit;
    $t->close;
    return $ap->{'name'} . ': su testrflink ' . $suid,
        table(
        { -border => 1, -cellspacing => 0, -cellpadding => 1 },
        Tr( { -align => 'CENTER', -valign => 'TOP' },
            [ th( \@keys ), @table ]
        )
        );

}

sub linktest {
    my $ap   = shift;
    my $suid = shift;

    if ( !$suid =~ /^\d+$/ ) {
        return "Invalid SUID [$suid]";
    }

    my $t = login( $ap->{'name'}, $ap->{'Telnet_Password'} );

    my $result = $t->linktest($suid);

    $t->exit;
    $t->close;

    unless ($result) {
        return "Error testing SU rflink!";
    }

    my @keys = (
        {   caption => 'Overview',
            fields  => [
                'AP to SU Error Rate',
                'SU to AP Error Rate',
                'Avg of Throughput',
            ],
        },
        {   caption => 'Details',
            fields  => [
                'AP Total nTx',
                'AP Total nRx',
                'AP Total nRxErr',

                'SU Total nTx',
                'SU Total nRx',
                'SU Total nRxErr',
            ],
        },
    );

    my @detail_keys = (
        'AP Tx', 'AP Rx',    'AP RxErr', 'SU Tx',
        'SU Rx', 'SU RxErr', 'time',     'rate',
    );

    my $html;
    foreach my $keys (@keys) {
        my @table;
        foreach my $k ( @{ $keys->{fields} } ) {
            if ( $result->{$k} ) {
                push @table, td( [ b($k), $result->{$k} ] );
            }
            else {
                push @table, td( [] );
            }
        }
        $html .= table(
            { -border => 1, -cellspacing => 0, -cellpadding => 1, },
            caption( $keys->{caption} ),
            Tr( { -align => 'CENTER', -valign => 'TOP' }, \@table ),
        );
    }

    my @detail_table;
    foreach my $test ( @{ $result->{tests} } ) {
        push @detail_table, td( [ @{$test}{@detail_keys} ] );
    }
    $html .= table(
        { -border => 1, -cellspacing => 0, -cellpadding => 1 },
        caption('Test Details'),
        Tr( { -align => 'CENTER', -valign => 'TOP' },
            [ th( \@detail_keys ), @detail_table, ],
        ),
    );

    return $ap->{'name'} . ': linktest ' . $suid, $html;
}

sub next_suid {
    my $sudb = shift;

    my $next_id = $Start_SUID;

    my %ids = map { $_->{'suid'} => 1 } @{$sudb};

    my $next_key = sprintf( '%04d', $next_id );
    while ( exists $ids{$next_key} ) {
        $next_id++;
        $next_key = sprintf( '%04d', $next_id );
    }

    return $next_id;
}
