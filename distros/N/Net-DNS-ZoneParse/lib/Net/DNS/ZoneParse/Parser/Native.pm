package Net::DNS::ZoneParse::Parser::Native;

use 5.008000;
use strict;
use warnings;
use vars qw($VERSION);

use Net::DNS;

require Net::DNS::ZoneParse::Parser::Native::DNSext
	unless Net::DNS::RR->can("new_from_filestring");
$VERSION = 0.103;

=pod

=head1 NAME

Net::DNS::ZoneParse::Parser::Native - Net::DNS::ZoneParse's native parser.

=head1 DESCRIPTION

the Native parser can be used without any external dependencies - except
of Net::DNS. It supports the directives $TTL, $ORIGIN, $INCLUDE and
$GENERATE.
It can handle all RRs supported by Net::DNS, as it uses their parsing routines.

=cut

###############
# Global Data #
###############

# This RE matches only, if there where the same number of opening as of closing
# brackets
my $_matchparentheses;
$_matchparentheses = qr/(?>[^()]+|\((??{$_matchparentheses})\))*/;

# This RE matches any possible TTL - with bind extensions
my $_dns_ttlre = qr/^(\d+[\dwdhms]*)$/;

# This contains the functions for the different directives defined in RFC1035
# and the BIND-extension $TTL and $GENERATE
my %_dns_directives = (
	ORIGIN => \&Net::DNS::ZoneParse::_dns_test_set_origin,
	TTL => sub {
		return unless($_[0] =~ $_dns_ttlre);
		$_[1]->{ttl} = $1;
	},
	INCLUDE => sub {
		my ($line, $param, $self, $rr) = @_;
		my $filename = dns_next_item($line);
		return unless($filename);
		my $fh = $param->{fh};
		$param->{fh} = undef;
		open($param->{fh}, "<", $filename) or return;

		my $origin = $param->{origin};
		my $neworigin = dns_next_item($line);
		$param->{origin} = $neworigin if $neworigin;

		parse($self, $param, $rr);

		close($param->{fh});
		$param->{fh} = $fh;
		$param->{origin} = $origin;
	},
	GENERATE => sub {
		my ($line, $param, $self, $rr) = @_;
		my ($first, $last) = split(/-/,dns_next_item($line),2);
		return unless( defined $first);
		$last = $first unless( defined $last);
		for($first .. $last) {
			my $aline = $line;
			$aline =~ s/\$/$_/g;
			my $ele = _dns_parse_line($self, $aline, $param, $rr);
			push(@{$rr}, $ele) if($ele);
		}
	},
);

# A Lookup-table for all valid DNS Classes.
my %_dns_classes = ( IN => 1, CS => 1, CH => 1, HS => 1 );

#####################
# private functions #
#####################

# read a full line and strips all comments
sub _dns_read_line {
	my ($file);
	($_, $file) = @_;
	s/(?<!\\);.*//;
	while(not m/^$_matchparentheses$/) {
		my $tail = <$file>;
		last unless $tail;
		chomp;
		$tail =~ s/(?<!\\);.*//;
		$_ .= $tail;
	}
	return $_;
}

# Find the correct domain-name for the next item; aware of directives
sub _dns_find_name {
	my $name = dns_next_item(@_);
	return $name if(substr($name,0,1) eq '$');
	return Net::DNS::RR->dns_fqdn($name, $_[2]->{origin});
}

# parse one (chomped) line of the file
sub _dns_parse_line {
	my ($self, $line, $param, $ret, $lnr, $name) = @_;
	$name = _dns_find_name($line, $name?$name.".":$name , $param);
	if(substr($name, 0, 1) eq '$') {
		my $directive = substr($name,1);
		unless ($_dns_directives{$directive}) {
			warn("Unknown directive '$directive'\n");
			return undef;
		}
		&{$_dns_directives{$directive}}($line, $param, $self, $ret);
		return undef;
	}
	$_[5] = $name;
	return undef if($line =~ m/^\s*$/);
	my %prep = (
		name => $name,
		ttl => $param->{ttl},
		class => '',
		rdlength => 0,
		rdata => '',
		Line => $lnr,
	);
	while( not exists $prep{type}) {
		my $type = dns_next_item($line);
		last unless $type;
		if($_dns_classes{uc($type)}) {
			$prep{class} = uc($type);
			next;
		}
		if($type =~ $_dns_ttlre) {
			$prep{ttl} = $1;
			next;
		}
		$prep{type} = uc($type);
	};
	return undef unless($prep{type});
	$line =~ s/\s*$//;
	my $subclass = Net::DNS::RR->_get_subclass($prep{type});
	my $ele = \%prep;
	$ele = $subclass->new_from_filestring($ele, $line, $param);
	return $ele;
}

=pod

=head2 EXPORT

=head3 parse

	$rr = Net::DNS::ZoneParse::Parser::Native->parse($param)

This is the real parsing-routine, used by Net::DNS::ZoneParse.

=cut

sub parse {
	my ($self, $param, $ret) = @_;
	my $name = $param->{name}.".";
	$ret = [] unless $ret;
	my $fh = $param->{fh};
	while(<$fh>) {
		my $line = $.;
		chomp;
		$_ = _dns_read_line($_, $fh);
		my $ele = _dns_parse_line(
			$param->{self}, $_, $param, $ret, $line, $name);
		next unless $ele;
		if($ele->can("check")) { next unless $ele->check(); }
		push(@{$ret}, $ele);
	}
	return $ret;
}

=pod

=head3 dns_next_item

	$item = dns_next_item($line[, $default])

This will return the next item on the given line. If default is given and
the line is empty or starts with blanks, $default is returned.

$line will be modified to start with the following - not returned - item.

This functions is inteded to be used by the extension of Net::DNS::RR::xx
parsing functionality.

=cut

sub dns_next_item {
	local($_);
	my $name;
	($_, $name) = @_;
	if(s/^"(.*?)\s*(?<!\\)"//) {
		$name = $1;
	} elsif(s/^(\S+)\s*//) {
		$name = $1;
	} else {
		s/^\s*//;
	}
	$_[0] = $_;
	return $name;
}


=pod

=head1 SEE ALSO

Net::DNS::ZoneParse

=head1 AUTHOR

Benjamin Tietz E<lt>benjamin@micronet24.deE<gt>

=head1 COPYRIGHT

Copyright (C) 2010 by Benjamin Tietz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;

