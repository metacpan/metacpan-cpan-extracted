package PIX::Accesslist::Line;

use strict;
use warnings;

our $VERSION = '1.10';

=pod

=head1 NAME

PIX::Accesslist::Line - ACL line object for each line of an PIX::Accesslist.

=head1 SYNOPSIS

PIX::Accesslist::Line is used by PIX::Accesslist to hold a single line of an ACL.
Each line can be searched against a set of IP & port criteria to find a match.
Users will not usually have to create objects from this directly.

See B<PIX::Accesslist> for more information regarding PIX Accesslists.

 $line = new PIX::Accesslist::Line(
	$action, $proto, $source, 
	$source_ort, $dest, $dest_port, $idx,
	$parent_acl_obj
 );

=head1 METHODS

=over

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = { };
	my ($action, $protocol, $source, $sport, $dest, $dport, $idx, $parent) = @_;

	$self->{class} = $class;
	$self->{action} = lc $action;
	$self->{proto} = $protocol;
	$self->{source} = $source;
	$self->{sport} = $sport;
	$self->{dest} = $dest;
	$self->{dport} = $dport;
	$self->{idx} = $idx || 0;
	$self->{parent} = $parent;	# parent PIX::Accesslist object

	bless($self, $class);
	$self->_init;

	return $self;
}

sub _init { }

=item B<elements( )>

=over

Returns the total access-list elements (ACE) for the ACL line.
B<Note:> It's not wise to call this over and over again. Store the result
in a variable and use that variable if you need to use this result in multiple
places.

=back

=cut
sub elements {
	my $self = shift;
	my $total = 0;
	foreach my $proto ($self->{proto}->list) {
		$total++ unless $self->{source}->list;
		foreach my $src ($self->{source}->list) {
			$total++ unless $self->{dest}->list;
			foreach my $dest ($self->{dest}->list) {
				my @dport_list = $self->{dport} ? $self->{dport}->list : ();
				$total += scalar @dport_list ? @dport_list : 1;
			}
		}
	}
#	print "LINE " . $self->num . " has $total elements\n";
	return $total;
}

=item B<match(%args)>

=over

Returns a true value if the criteria given matches the logic of the ACL line. 
'Loose' matching is performed. For example, If you supply a single IP or port
a match may return TRUE on a line even though the final logic of the line might
overwise be FALSE according to the OS on the firewall. If you want to be sure 
you get accurate matching you must provide all criteria shown below.

=over

* source : Source IP

* sport  : Source Port

* dest   : Destination IP

* dport  : Destionation Port

* proto  : Protocol

=back

B<Note:> source port {sport} is not usually used. You will usually only want to
use {dport}.

=back

=cut
sub match {
	my $self = shift;
	my $arg = ref $_[0] ? $_[0] : { @_ };
	my $ok = 0;
	$arg->{proto} ||= 'ip';		# default to IP
	
	# shortcut, alias {port} to {dport} if specified
	$arg->{dport} ||= $arg->{port} if exists $arg->{port};
	
	# does the protocol match?
	if ($arg->{proto} eq 'ip') {
		$ok = 1;
	} else {
		$ok = scalar grep { lc $_ eq 'ip' or lc $_ eq $arg->{proto} } $self->{proto}->list;
	}
	#print "PROTO =$ok\n";
	return 0 unless $ok;

	# check for ICMP TYPES if the protcol is ICMP and we are an icmp-type group
	#if ($self->{dport}->type eq 'icmp-type' and grep { $_ eq 'icmp' } $self->{proto}->list) {
	#	warn "ICMP TEST\n";
	#}


	# does the source IP match?
	$ok = $self->{source}->matchip($arg->{source}) if $arg->{source} and $self->{source};
	#print "SOURCE=$ok\n";
	return 0 unless $ok;

	# does the source port match?
	$ok = $self->{sport}->matchport($arg->{sport}) if $arg->{sport} and $self->{sport};
	#print "SPORT =$ok\n";
	return 0 unless $ok;

	# does the destination IP match?
	$ok = $self->{dest}->matchip($arg->{dest}) if $arg->{dest} and $self->{dest};
	#print "DEST  =$ok\n";
	return 0 unless $ok;

	# does the destination port match?
	$ok = $self->{dport}->matchport($arg->{dport}) if $arg->{dport} and $self->{dport};
	#print "DPORT =".($ok||'')."\n";
	return 0 unless $ok;
	
	return 1;
}

=item B<print([$any])>

=over

Pretty prints the ACL line. Tries to make it easy to read. If object-group's are
used the names are printed instead of IP's if more than a single IP is present
for a line.

$any is an optional string that will be used for any IP that represents 'ANY',
defaults to: 0.0.0.0/0. It's useful to change this to 'ANY' to make the output
easier to read.

  1)  permit (tcp)   192.168.0.0/24 -> 0.0.0.0/0 [Web_Services_tcp: 80,443]

=back

=cut
sub print {
	my $self = shift;
	my $any = shift || '0.0.0.0/0';
	my $output = '';

	$output .= sprintf("%3d) ", $self->num);
	$output .= sprintf("%6s %-10s", $self->{action}, "(" . $self->proto_str . ")");

	# display the source
	$output .= $self->source_str($any);
	#if ($self->{proto}->first !~ /^(ip|icmp)$/) {
	if ($self->{proto}->first ne 'ip') {
		if ($self->{sport} and $self->sourceport_str) {
			my $name = $self->{sport}->name;
			my @enum = $self->{sport}->enumerate;
			my @list = $self->{sport}->list;
			$output .= sprintf(" [%s]", $name =~ /^unnamed/ && @enum == 1  
				? @enum
				: @enum <= 4
					? $name . ": " .join(',',@enum) 
					: $name . " (" . @list . " ranges; " . @enum . " ports)"
			);
		} else {
			# since source ports are not usually used in most ACL's
			# (from my experience) lets not show anything if ANY
			# is allowed.
			$output .= "";
		}
	}

	$output .= " -> ";

	# display the destination
	$output .= $self->dest_str($any);
	#if ($self->{proto}->first !~ /^(ip|icmp)$/) {
	if ($self->{proto}->first ne 'ip') {
		if ($self->{dport} and $self->destport_str) {
			my $name = $self->{dport}->name;
			my @enum = $self->{dport}->enumerate;
			my @list = $self->{dport}->list;
			$output .= sprintf(" [%s]", $name =~ /^unnamed/ && @enum == 1  
				? @enum
				: @enum <= 4
					? $name . ": " .join(',',@enum) 
					: $name . " (" . @list . " ranges; " . @enum . " ports)"
			);
		} else {
			$output .= " [any]";
		}
	}

	return $output;
}

=item B<num( )>

=over

Returns the line number for the ACL line

=back

=cut
sub num { $_[0]->{idx} }

=item B<action(), permit(), deny()>

=over 

Returns the action string 'permit' or 'deny' of the ACL line, 
or true if the ACL line is a permit or deny, respectively.

=back

=cut
sub permit { $_[0]->{action} eq 'permit' }
sub deny   { $_[0]->{action} eq 'deny' }
sub action { $_[0]->{action} }

sub proto_str { return wantarray ? $_[0]->{proto}->list : join(',',$_[0]->{proto}->list) }
sub source_str {
	my $self = shift;
	my $any = shift || '0.0.0.0/0';
	my $str;
	if ($self->{source}->name =~ /^unnamed/ && $self->{source}->list == 1) {
		$str = $self->{source}->first;
	} else {
		$str = $self->{source}->name;
	}
	return $str eq '0.0.0.0/0' ? $any : $str;
}
sub dest_str {
	my $self = shift;
	my $any = shift || '0.0.0.0/0';
	my $str;
	if ($self->{dest}->name =~ /^unnamed/ && $self->{dest}->list == 1) {
		$str = $self->{dest}->first;
	} else {
		$str = $self->{dest}->name;
	}
	return $str eq '0.0.0.0/0' ? $any : $str;
}
sub sourceport_str {
	my $self = shift;
	return '' unless $self->{proto}->first ne 'ip' && $self->{sport};
	if ($self->{sport}->name =~ /^unnamed/ && $self->{sport}->enumerate == 1) {
		return $self->{sport}->enumerate;
	} else {
		return $self->{sport}->name;
	}
}
sub destport_str {
	my $self = shift;
	return '' unless $self->{proto}->first ne 'ip' && $self->{dport};
	if ($self->{dport}->name =~ /^unnamed/ && $self->{dport}->enumerate == 1) {
		return $self->{dport}->enumerate;
	} else {
		return $self->{dport}->name;
	}
}
sub destportdetail_str {
	my $self = shift;
	return '' if $self->{dport}->name =~ /^unnamed/ && $self->{dport}->enumerate == 1;
	if ($self->{dport}->enumerate <= 4) {
		return join(',', $self->{dport}->enumerate);
	} else {
		return $self->{dport}->list . " ranges; " . $self->{dport}->enumerate . " ports)";
	}
	return '';
}
#	if ($self->{dport}->name =~ /^unnamed/ && $self->{dport}->enumerate == 1) {
#		$output .= join(',',$self->{dport}->enumerate);
#	} elsif ($self->{dport}->enumerate <= 4) {
#		$output .= $self->{dport}->name . ": " .join(',',$self->{dport}->enumerate);
#	} else {
#		$output .= $self->{dport}->name . " (" . $self->{dport}->list . " ranges; " . $self->{dport}->enumerate . " ports)";
#	}

1; 

=pod

=head1 AUTHOR

Jason Morriss <lifo 101 at - gmail dot com>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-pix-walker at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PIX-Walker>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

    perldoc PIX::Walker

    perldoc PIX::Accesslist
    perldoc PIX::Accesslist::Line

    perldoc PIX::Object
    perldoc PIX::Object::network
    perldoc PIX::Object::service
    perldoc PIX::Object::protocol
    perldoc PIX::Object::icmp_type

=head1 COPYRIGHT & LICENSE

Copyright 2006-2008 Jason Morriss, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
