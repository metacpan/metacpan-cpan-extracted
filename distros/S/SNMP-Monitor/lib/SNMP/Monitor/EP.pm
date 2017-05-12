# -*- perl -*-
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#

require 5.004;
use strict;


require SNMP::Monitor;


package SNMP::Monitor::EP;

@SNMP::Monitor::EP::ISA = qw(HTML::EP);
$SNMP::Monitor::EP::VERSION = '0.02';


sub init ($) {
    my($self) = @_;
    $self->{_ep_funcs}->{'ep-snmpmon-auth'} = { method => 'snmpmon_auth' };
    $self;
}


sub _snmpmon_auth_interface ($$$$) {
    my($self, $interface_ref, $host_ref, $user) = @_;

    my($u, $config);
    foreach $config ($interface_ref->{'users'},
		     $host_ref->{'users'},
		     $self->{'snmpmon_config'}->{'users'}) {
	if ($config) {
	    foreach $u (@$config) {
		if ($u eq $user) {
		    return $interface_ref;
		}
	    }
	    return undef;
	}
    }
    return $interface_ref;
}


sub snmpmon_auth ($$;$) {
    my($self, $attr, $func) = @_;

    if (!$self->{snmpmon_config}) {
	if (!$attr->{configuration}) {
	    die "Missing config file";
	}
	$self->{snmpmon_config} =
	    SNMP::Monitor->Configuration($attr->{configuration});
    }
    my $config = $self->{snmpmon_config};


    my $user = $self->{env}->{REMOTE_USER};
    if (!$user) {
	if (!exists($attr->{'user'})) {
	    die "Not authorized as any user";
	}
	$user = $attr->{'user'};
    }

    my $ilist = [];
    if ($attr->{interface}) {
	# Authenticate for displaying this interface
	# Host must be given!
	if ($attr->{interface} =~ /(.+)\:(.*)/) {
	    my $host = $1;
	    my $interface = $2;
	    my $host_ref = $config->{hosts}->{$host};
	    if (!$host_ref) {
		die "No such host: $host";
	    }
	    my $interface_ref;
	    foreach $interface_ref (@{$host_ref->{interfaces}}) {
		if ($interface_ref->{num} eq $interface) {
		    if ($self->_snmpmon_auth_interface($interface_ref,
						       $host_ref,
						       $user)) {
			push(@$ilist, { host => $host_ref,
					interface => $interface_ref});
			last;
		    } else {
			die "Not authorized for interface $interface at"
			    . " host $host";
		    }
		}
	    }
	    if (!@$ilist) {
		die "No such interface for host $host: $interface";
	    }
	}
    } else {
	# Authenticate for displaying any interface
	my($host_ref, $interface_ref);
	foreach $host_ref (values(%{$config->{hosts}})) {
	    foreach $interface_ref (@{$host_ref->{interfaces}}) {
		if ($self->_snmpmon_auth_interface($interface_ref,
						   $host_ref,
						   $user)) {
		    push(@$ilist, { host => $host_ref,
				    interface => $interface_ref});
		}
	    }
	}
    }

    if (!@$ilist) {
	die "Not authorized";
    }

    $self->{snmpmon_interfaces} = $ilist;

    '';
}


sub _ep_snmpmon_index {
    my $self = shift;  my $attr = shift;
    my($sec, $min, $hour, $date_d, $date_m, $date_y) = localtime(time());
    $self->{'date_d'} = $date_d;
    $self->{'date_m'} = $date_m+1;
    $self->{'date_y'} = $date_y+1900;

    $self->{'to_d'} = 1;
    $self->{'to_m'} = $date_m+1;
    $self->{'to_y'} = $date_y+1900;

    $self->{'from_d'} = 1;
    if ($date_m == 0) {
	$self->{'from_m'} = 12;
	$self->{'from_y'} = $date_y+1899;
    } else {
	$self->{'from_m'} = $date_m;
	$self->{'from_y'} = $date_y+1900;
    }
    ''
}


sub _ep_snmpmon_graph {
    my $self = shift;  my $attr = shift;
    my($ifc,$dif,@if_list,$if_id);
    my $cgi = $self->{'cgi'};
    $self->{'snmpmon_if_displayed'} = [];
    foreach $ifc ($cgi->param()) {
 	if ($ifc =~ /^if_\d+$/) {
 	    $if_id = $cgi->param($ifc);
 	    if ($if_id) {
 		push(@if_list, $if_id);
 		foreach $dif (@{$self->{'snmpmon_interfaces'}}) {
 		    if ($dif->{'host'}->{'name'} . ":"
			. $dif->{'interface'}->{'num'}
 			eq $if_id) {
 			$dif->{'selected'} = "CHECKED";
			push(@{$self->{'snmpmon_if_displayed'}}, $dif);
 			last;
 		    }
 		}
 	    }
 	}
    }
    $self->{'snmpmon_display'} = scalar(@{$self->{'snmpmon_if_displayed'}});

    my($sec, $min, $hour, $date_d, $date_m, $date_y) = localtime(time());
    $self->{'date_d'} = $date_d;
    $self->{'date_m'} = $date_m+1;
    $self->{'date_y'} = $date_y+1900;

    my $crit = $self->{'crit'} = [];
    my $crit_selected = $cgi->param('critical');
    push(@$crit, { 'value' => "", 'text' => "Off",
		   'selected' => $crit_selected ? "" : " SELECTED" });
    my $val;
    foreach $val (100,75,50,25,10,5,2,1,0.5) {
	push(@$crit, { 'value' => $val, 'text' => "$val %",
		       'selected' => ($crit_selected == $val)
			   ? " SELECTED" : "" });
    }

    $self->{'avg_checked'} = $cgi->param('average') ? " CHECKED" : "";

    '';
}


sub _FromUnixTime {
    my($sec, $min, $hour, $mday, $mon, $year) = localtime(shift);
    sprintf('%04d-%02d-%02d %02d:%02d:%02d',
	    $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

sub _ep_snmpmon_ifgif {
    my $self = shift;  my $attr = shift;
    my $if = $self->{'snmpmon_interfaces'}->[0];
    my $debug = $self->{'debug'};
    my $cgi = $self->{'cgi'};
    my($to_y) = $cgi->param('to_y');
    my $to;
    my($sec,$min,$hour,$mday,$mon,$year);
    require Time::Local;
    my $now = time();
    if ($to_y) {
	my($to_m) = $cgi->param('to_m');
	my($to_d) = $cgi->param('to_d');
	if ($to_y < 98) {
	    $to_y += 2000;
	} elsif ($to_y < 100) {
	    $to_y += 1900;
	}
        $to = Time::Local::timelocal(0, 0, 12, $to_d, $to_m-1,
                                       $to_y-1900);
    } else {
        ($sec,$min,$hour,$mday,$mon,$year) = localtime($now);
        $to = Time::Local::timelocal(0, 0, 12, $mday, $mon, $year); 
    }
    $to += 1 * 24 * 3600;
    ($sec,$min,$hour,$mday,$mon,$year) = localtime($to);
    my $to_range = sprintf("%04d-%02d-%02d,%02d:%02d:%02d",
			$year+1900, $mon+1, $mday, 0, 0, 0);
    $to = Time::Local::timelocal(0, 0, 0, $mday, $mon, $year);

    my $from = $to - ($cgi->param('days') || 1) * 24 * 3600;
    ($sec,$min,$hour,$mday,$mon,$year) = localtime($from);
    my $from_range = sprintf("%04d-%02d-%02d,%02d:%02d:%02d",
			     $year+1900, $mon+1, $mday, 0, 0, 0);
    $from = Time::Local::timelocal(0, 0, 0, $mday, $mon, $year);

    my $to_now = ($to < $now) ? $to : $now;
    if ($cgi->param('average')  &&  $from < $to_now) {
	require SNMP::Monitor::Event::IfLoad;
	my $type = $if->{'interface'}->{'type'};
	my $full_duplex;
	if ($type =~ /^(\d+)$/) {
	    my $ref = $SNMP::Monitor::Event::IfLoad::ITYPES->[$type];
	    if (defined($ref)) {
		$full_duplex = $ref->[1];
	    }
	} else {
	    my $ref;
	    foreach $ref (@$SNMP::Monitor::Event::IfLoad::ITYPES) {
		if ($ref  &&  $ref->[0] eq $type) {
		    $full_duplex = $ref->[1];
		    last;
		}
	    }
	}
	if (defined($full_duplex)) {
	    my $dbh = $self->{'dbh'};
	    my $query = sprintf('SELECT SUM(INOCTETS), SUM(OUTOCTETS)'
				. ' FROM SNMPMON_IFLOAD WHERE INTERVAL_END'
				. ' >= %s AND INTERVAL_END < %s AND'
				. ' INTERFACE = %s AND HOST = %s',
				$dbh->quote(_FromUnixTime($from)),
				$dbh->quote(_FromUnixTime($to_now)),
				$if->{'interface'}->{'num'},
				$dbh->quote($if->{'host'}->{'name'}));
	    if ($debug) {
		$self->print("Avg query: $query\n");
	    }
	    my $sth = $dbh->prepare($query);
	    $sth->execute();
	    my($sumIn, $sumOut) = $sth->fetchrow_array();
	    if ($sumIn) {
		my $delta;
		if ($full_duplex) {
		    $delta = ($sumIn > $sumOut) ? $sumIn : $sumOut;
		} else {
		    $delta = $sumIn + $sumOut;
		}
		$self->{'average'} = ($delta * 8 * 100.0) /
		    (($to_now - $from) * $if->{'interface'}->{'speed'});
	    }
	}
    }

    my $scale = $cgi->param('scale') || 100;
    if($scale < 0) {
	my $dbh = $self->{'dbh'};
	my $query = sprintf('SELECT MAX(UTILIZATION) FROM SNMPMON_IFLOAD'
			    . ' WHERE INTERVAL_END > %s  AND INTERVAL_END < %s'
			    . ' AND HOST = %s AND INTERFACE = %s ORDER BY'
			    . ' INTERVAL_END',
			    $dbh->quote(_FromUnixTime($from)),
			    $dbh->quote(_FromUnixTime($to_now)),
			    $dbh->quote($if->{'host'}->{'name'}),
			    $if->{'interface'}->{'num'});
	my $sth = $dbh->prepare($query);
	$sth->execute();
	$scale = $sth->fetchrow_array() || 100;
    }

    my $dbh = $self->{'dbh'};
    my $query = sprintf('SELECT UTILIZATION, INTERVAL_END FROM SNMPMON_IFLOAD'
			. ' WHERE INTERVAL_END > %s  AND INTERVAL_END < %s'
			. ' AND HOST = %s AND INTERFACE = %s ORDER BY'
			. ' INTERVAL_END',
			$dbh->quote(_FromUnixTime($from)),
			$dbh->quote(_FromUnixTime($to_now)),
			$dbh->quote($if->{'host'}->{'name'}),
			$if->{'interface'}->{'num'});
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $command = $self->{'snmpmon_config'}->{'path_gnuplot'} . " | " .
        $self->{'snmpmon_config'}->{'path_ppmtogif'} . " 2>/dev/null";
    my $fh;
    if ($debug) {
        $self->print("Creating pipe to the following command:\n$command\n");
    } else {
        $fh = Symbol::gensym();
        if (!open($fh, "| $command")) {
            die "Cannot open pipe to command $command: $!";
        }
	$| = 1;
        $self->print("content-type: image/gif\n\n");
    }
    my $critical = $cgi->param('critical') ?
        (", crit(x) = " . $cgi->param('critical') 
	 . ", crit(x)") : '';
    my $avg = $self->{'average'} ?
        (", avg(x) = " . $self->{'average'} . ", avg(x)") : '';
    my $title = $cgi->param('title')
        || $if->{'interface'}->{'short_message'}
        || $if->{'interface'}->{'description'};

    my $output = <<"GNUPLOT";
set size noratio 1.5,0.4
set title '$title'
set terminal pbm color
set timefmt '%Y-%m-%d,%H:%M:%S'
set xdata time
set xrange [ "$from_range" : "$to_range" ]
set yrange [ 0 : $scale ]
set ylabel 'Auslastung [%]
set format x \"%H:%M\\n%d.%m\"
plot '-' using 1:2 title '$title' with lines $critical$avg
GNUPLOT
    if ($debug) {
        $self->print($output);
    } else {
        print $fh $output;
    }

    my($ref, $time, $utilization);
    while ($ref = $sth->fetchrow_arrayref) {
        ($utilization, $time) = @$ref;
        $time =~ s/ /,/;
        if ($debug) {
            $self->print("$time $utilization\n");
        } else {
            print $fh "$time $utilization\n";
        }
    }
    if (!$debug) {
        close($fh);
    }
    $self->Stop();
}


sub _ep_snmpmon_stats {
    my $self = shift;  my $attr = shift;
    my($sec, $min, $hour, $date_d, $date_m, $date_y)
        = localtime($self->{'now'} = time());
    $self->{'date_d'} = $date_d;
    $self->{'date_m'} = $date_m+1;
    $self->{'date_y'} = $date_y+1900;

    my $cgi = $self->{'cgi'};
    $self->{'to_d'} = $cgi->param('to_d');
    $self->{'to_m'} = $cgi->param('to_m');
    $self->{'to_y'} = $cgi->param('to_y');
    $self->{'from_d'} = $cgi->param('from_d');
    $self->{'from_m'} = $cgi->param('from_m');
    $self->{'from_y'} = $cgi->param('from_y');

    my($ifc,$dif,@if_list,$if_id);
    $self->{'snmpmon_if_displayed'} = [];
    foreach $ifc ($cgi->param()) {
 	if ($ifc =~ /^if_\d+$/) {
 	    $if_id = $cgi->param($ifc);
 	    if ($if_id) {
 		push(@if_list, $if_id);
 		foreach $dif (@{$self->{snmpmon_interfaces}}) {
 		    if ($dif->{'host'}->{'name'} . ":"
			. $dif->{'interface'}->{'num'}	eq  $if_id) {
 			$dif->{'selected'} = "CHECKED";
			push(@{$self->{'snmpmon_if_displayed'}}, $dif);
 			last;
 		    }
 		}
 	    }
 	}
    }
    $self->{'snmpmon_display'} = @{$self->{'snmpmon_if_displayed'}};

    ''
}


sub _ep_snmpmon_stats2 {
    my $self = shift;  my $attr = shift;
    my $dbh = $self->{'dbh'};
    require Time::Local;
    my $from = Time::Local::timelocal(0, 0, 0, $self->{'from_d'},
	                              $self->{'from_m'}-1,
                                      $self->{'from_y'}-1900);
    my $to = Time::Local::timelocal(0, 0, 0, $self->{'to_d'},
	  	                    $self->{'to_m'}-1,
                                    $self->{'to_y'}-1900);
    my $to_now = ($to < $self->{'now'}) ? $to : $self->{'now'};
    my $secs = $self->{'secs'} = ($to_now - $from) > 0 ? ($to_now - $from) : 0;
    while ($self->{'secs'} =~ s/(\d{1,3})(\d{3})(\s.*)?$/$1 $2$3/) { }

    my $query = "SELECT SUM(INOCTETS), SUM(OUTOCTETS),  AVG(OPERSTATUS=1)"
	. " FROM SNMPMON_IFLOAD WHERE INTERVAL_END >= "
	. $dbh->quote(_FromUnixTime($from))
	. " AND INTERVAL_END < " . $dbh->quote(_FromUnixTime($to))
	. " AND INTERFACE = %s AND HOST = %s";

    my $if;
    foreach $if (@{$self->{'snmpmon_if_displayed'}}) {
       my $q = sprintf($query, $if->{'interface'}->{'num'},
                       $dbh->quote($if->{'host'}->{'name'}));
       $self->print("Executing query: $q\n");
       my $sth = $dbh->prepare($q);
       $sth->execute();
       my $ref = $sth->fetchrow_arrayref();

       my $inOctets = $ref ? $ref->[0] : 0;
       my $outOctets = $ref ? $ref->[1] : 0;
       my $sumOctets = $inOctets + $outOctets;
       my $avgOctets = $secs ?
           sprintf("%.0f", ((8*($inOctets+$outOctets))/$secs)) : 0;

       while ($inOctets =~ s/(\d{1,3})(\d{3})(\s.*)?$/$1 $2$3/) { }
       $if->{'in_octets'} = $inOctets;

       while ($outOctets =~ s/(\d{1,3})(\d{3})(\s.*)?$/$1 $2$3/) { }
       $if->{'out_octets'} = $outOctets;

       while ($sumOctets =~ s/(\d{1,3})(\d{3})(\s.*)?$/$1 $2$3/) { }
       $if->{'sum_octets'} = $sumOctets;

       while ($avgOctets =~ s/(\d{1,3})(\d{3})(\s.*)?$/$1 $2$3/) { }
       $if->{'avg_octets'} = $avgOctets;

       $if->{'up_percent'} = $ref ? sprintf("%.2f", ($ref->[2]*100)) : '';
    }
    ''
}


1;
