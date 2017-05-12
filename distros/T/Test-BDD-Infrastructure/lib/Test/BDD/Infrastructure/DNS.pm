package Test::BDD::Infrastructure::DNS;

use strict;
use warnings;

our $VERSION = '1.005'; # VERSION
# ABSTRACT: cucumber step definitions for DNS based checks
 
use Test::More;
use Test::BDD::Cucumber::StepFile qw( Given When Then );

sub S { Test::BDD::Cucumber::StepFile::S }

use Test::BDD::Infrastructure::Utils qw(
	convert_unit convert_cmp_operator $CMP_OPERATOR_RE convert_interval
	lookup_config );


use Net::DNS::Resolver;

Given qr/the DNS resolver of the system is used/, sub {
	S->{'dns'} = Net::DNS::Resolver->new;
};

Given qr/the DNS resolver as configured in (\S+) is used/, sub {
	S->{'dns'} = Net::DNS::Resolver->new(
		config_file => $1,
	);
};

Given qr/the DNS resolver nameserver(?:s are| is) (.*)$/, sub {
	S->{'dns'}->nameservers(split(/\s*,\s*/, $1));
};

Given qr/the DNS resolver searchlist is (.*)$/, sub {
	S->{'dns'}->searchlist(split(/\s*,\s*/, $1));
};

Given qr/the DNS resolver recursion flag is (enabled|disabled)$/, sub {
	S->{'dns'}->recurse( $1 eq 'disabled' ? 0 : 1 );
};

Given qr/the DNS resolver (dnssec|adflag|cdflag) flag is (enabled|disabled)$/, sub {
	S->{'dns'}->$1( $2 eq 'enabled' ? 1 : 0 );
};

When qr/a DNS query for (\S+)(?: of type (\S+))? is sent$/, sub {
	my $name = $1;
	my @types;
	if( defined $2 ) {
		@types = split(/\s*,\s*/, $2);
	}
	diag('current DNS resolver state is: '.S->{'dns'}->string);
	my $packet = S->{'dns'}->send( $name, @types );
	ok( defined $packet, 'must recieve an answer to DNS query');
	isa_ok( $packet, 'Net::DNS::Packet');
	if( defined $packet ) {
		diag('recieved DNS packet: '.$packet->string);
		S->{'dns-packet'} = $packet;
	}
};

Then qr/the DNS answer must contain $CMP_OPERATOR_RE (\d+) records?$/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	cmp_ok( scalar(S->{'dns-packet'}->answer), $op, $count, "the DNS answer must contain $op $count records");
};

Then qr/the DNS header (qr|aa|tc|rd|ra|z|ad|cd) flag must be (not set|set)$/, sub {
	my $flag = $1;
	my $value = $2 eq 'set' ? 1 : 0;
	cmp_ok( S->{'dns-packet'}->header->$flag, '==', $value, "the dns header flag $flag must be $value");
};

Then qr/the DNS (answer|pre|prerequisite|authority|update|additional) (?:section )?must contain a RR (\S+)(?: of type (\S+))?/, sub {
	my $section = $1;
	my $name = $2;
	my $type = $3;
	my $rr;
	if( defined $type ) {
		($rr) = grep { $_->name eq $name && $_->type eq 'type' } S->{'dns-packet'}->$section;
	} else {
		($rr) = grep { $_->name eq $name } S->{'dns-packet'}->$section;
	}
	ok( defined $rr, 'packet section must contain a matching RR');
	isa_ok( $rr, 'Net::DNS::RR');
	S->{'dns-rr'} = $rr;
};

Then qr/the DNS record must be of (type|class) (\S+)$/, sub {
	my $field = $1;
	my $value = $2;
	cmp_ok( S->{'dns-rr'}->$field, 'eq', $value, "DNS record must be of $field $value");
};

Then qr/the DNS record TTL must be $CMP_OPERATOR_RE (\d+)$/, sub {
	my $op = convert_cmp_operator( $1 );
	my $count = $2;
	cmp_ok(S->{'dns-rr'}->ttl, $op, $count, "ttl must be $op $count");
};

Then qr/the DNS record (address|cname|preference|exchange|nsdname|ptrdname|txtdata) must be (.*)$/, sub {
	my $field = $1;
	my $value = $2;
	cmp_ok(S->{'dns-rr'}->$field, 'eq', $value, "DNS records $field must be $value");
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::BDD::Infrastructure::DNS - cucumber step definitions for DNS based checks

=head1 VERSION

version 1.005

=head1 Synopsis

  Given the DNS resolver of the system is used
  When a DNS query for www.example.com is sent
  Then the DNS answer must contain at least 1 record

=head1 Step definitions

Configure the DNS resolver with Given steps:

  Given the DNS resolver of the system is used
  Given the DNS resolver as configured in <path to resolv.conf> is used
  Given the DNS resolver nameserver(s) (are|is) <comma separated list>
  Given the DNS resolver searchlist is <comma separated list>
  Given the DNS resolver recursion flag is (enabled|disabled)
  Given the DNS resolver (dnssec|adflag|cdflag) flag is (enabled|disabled)

Execute a DNS query:

  When a DNS query for <hostname> is sent
  When a DNS query for <hostname> of type <type> is sent

Check the result:

  Then the DNS answer must contain <compare> <count> record(s)
  Then the DNS header (qr|aa|tc|rd|ra|z|ad|cd) flag must be (not set|set)
  Then the DNS (answer|pre|prerequisite|authority|update|additional) (section )?must contain a RR <hostname>
  Then the DNS (answer|pre|prerequisite|authority|update|additional) (section )?must contain a RR <hostname> of type <type>
  Then the DNS record must be of (type|class) <value>
  Then the DNS record TTL must be <compare> <count>
  Then the DNS record (address|cname|preference|exchange|nsdname|ptrdname|txtdata) must be <value>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Markus Benning.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
