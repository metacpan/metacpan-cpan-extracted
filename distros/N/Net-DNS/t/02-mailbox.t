# $Id: 02-mailbox.t 1406 2015-10-05 08:25:49Z willem $	-*-perl-*-

use strict;
use Test::More tests => 43;


BEGIN {
	use_ok('Net::DNS::Mailbox');
}


{
	my $name    = 'mbox@example.com';
	my $mailbox = new Net::DNS::Mailbox($name);
	ok( $mailbox->isa('Net::DNS::Mailbox'), 'object returned by new() constructor' );
}


{
	my $mailbox = eval { new Net::DNS::Mailbox(); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "empty argument list\t[$exception]" );
}


{
	my $mailbox = eval { new Net::DNS::Mailbox(undef); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "argument undefined\t[$exception]" );
}


{
	my %testcase = (
		'.'				    => '<>',
		'<>'				    => '<>',
		'a'				    => 'a',
		'a.b'				    => 'a@b',
		'a.b.c'				    => 'a@b.c',
		'a.b.c.d'			    => 'a@b.c.d',
		'a@b'				    => 'a@b',
		'a@b.c'				    => 'a@b.c',
		'a@b.c.d'			    => 'a@b.c.d',
		'a\.b.c.d'			    => 'a.b@c.d',
		'a\.b@c.d'			    => 'a.b@c.d',
		'empty <>'			    => '<>',
		'fore <a.b@c.d> aft'		    => 'a.b@c.d',
		'nested <<address>>'		    => 'address',
		'obscure <<left><<<deep>>><right>>' => 'right',
		);

	foreach my $test ( sort keys %testcase ) {
		my $expect  = $testcase{$test};
		my $mailbox = new Net::DNS::Mailbox($test);
		my $data    = $mailbox->encode;
		my $decoded = decode Net::DNS::Mailbox( \$data );
		is( $decoded->address, $expect, "encode/decode mailbox	$test" );
	}
}


{
	my %testcase = (
		'"(a.b)"@c.d' => '"(a.b)"@c.d',
		'"[a.b]"@c.d' => '"[a.b]"@c.d',
		'"a,b"@c.d'   => '"a,b"@c.d',
		'"a:b"@c.d'   => '"a:b"@c.d',
		'"a;b"@c.d'   => '"a;b"@c.d',
		'"a@b"@c.d'   => '"a@b"@c.d',
		);

	foreach my $test ( sort keys %testcase ) {
		my $expect  = $testcase{$test};
		my $mailbox = new Net::DNS::Mailbox($test);
		my $data    = $mailbox->encode;
		my $decoded = decode Net::DNS::Mailbox( \$data );
		is( $decoded->address, $expect, "encode/decode mailbox	$test" );
	}
}


{
	my $mailbox   = new Net::DNS::Mailbox( uc 'MBOX.EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $mailbox->encode( 1, $hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = decode Net::DNS::Mailbox( \$data );
	my $downcased = new Net::DNS::Mailbox( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox'), 'object returned by Net::DNS::Mailbox->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox'), 'object returned by Net::DNS::Mailbox->decode()' );
	is( length $compress, length $data, 'Net::DNS::Mailbox encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::Mailbox encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox canonical form is uncompressed' );
	isnt( $canonical, $downcased, 'Net::DNS::Mailbox canonical form preserves case' );
}


{
	my $mailbox   = new Net::DNS::Mailbox1035( uc 'MBOX.EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $mailbox->encode( 1, $hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = decode Net::DNS::Mailbox1035( \$data );
	my $downcased = new Net::DNS::Mailbox1035( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox1035'), 'object returned by Net::DNS::Mailbox1035->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox1035'), 'object returned by Net::DNS::Mailbox1035->decode()' );
	isnt( length $compress, length $data, 'Net::DNS::Mailbox1035 encoding is compressible' );
	isnt( $data,		$downcased,   'Net::DNS::Mailbox1035 encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox1035 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::Mailbox1035 canonical form is lower case' );
}


{
	my $mailbox   = new Net::DNS::Mailbox2535( uc 'MBOX.EXAMPLE.COM' );
	my $hash      = {};
	my $data      = $mailbox->encode( 1, $hash );
	my $compress  = $mailbox->encode( length $data, $hash );
	my $canonical = $mailbox->encode( length $data );
	my $decoded   = decode Net::DNS::Mailbox2535( \$data );
	my $downcased = new Net::DNS::Mailbox2535( lc $mailbox->name )->encode( 0, {} );
	ok( $mailbox->isa('Net::DNS::Mailbox2535'), 'object returned by Net::DNS::Mailbox2535->new()' );
	ok( $decoded->isa('Net::DNS::Mailbox2535'), 'object returned by Net::DNS::Mailbox2535->decode()' );
	is( length $compress, length $data, 'Net::DNS::Mailbox2535 encoding is uncompressed' );
	isnt( $data, $downcased, 'Net::DNS::Mailbox2535 encoding preserves case' );
	is( length $canonical, length $data, 'Net::DNS::Mailbox2535 canonical form is uncompressed' );
	is( $canonical,	       $downcased,   'Net::DNS::Mailbox2535 canonical form is lower case' );
}


exit;

