# $Id: 02-domain.t 1611 2018-01-02 09:41:24Z willem $	-*-perl-*-

use strict;
use Test::More tests => 53;


use_ok('Net::DNS::Domain');


{
	my $name   = 'example.com';
	my $domain = new Net::DNS::Domain($name);
	ok( $domain->isa('Net::DNS::Domain'), 'object returned by new() constructor' );

	my $same = new Net::DNS::Domain($name);
	is( $same, $domain, "same name returns cached object" );

	my %cache;
	my ( $i, $j );
	for ( ; ; ) {
		$j = ( $i++ >> 1 ) + 1;
		my $fill = "name-$i";
		my $test = "name-$j";
		$cache{$fill} = new Net::DNS::Domain($fill);
		last unless $cache{$test} == new Net::DNS::Domain($test);
	}
	my $size = $i - $j;
	ok( $size, "name cache at least $size deep" );
}


{
	my $domain = eval { new Net::DNS::Domain(); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "empty argument list\t[$exception]" );
}


{
	my $domain = eval { new Net::DNS::Domain(undef); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "argument undefined\t[$exception]" );
}


{
	my $domain = new Net::DNS::Domain('name');
	is( $domain->name,   'name',  '$domain->name() without trailing dot' );
	is( $domain->fqdn,   'name.', '$domain->fqdn() with trailing dot' );
	is( $domain->string, 'name.', '$domain->string() with trailing dot' );
}


{
	my $root = new Net::DNS::Domain('.');
	is( $root->name,   '.', '$root->name() represented by single dot' );
	is( $root->fqdn,   '.', '$root->fqdn() represented by single dot' );
	is( $root->xname,  '.', '$root->xname() represented by single dot' );
	is( $root->string, '.', '$root->string() represented by single dot' );
}


{
	my $domain = new Net::DNS::Domain('example.com');
	my $labels = @{[$domain->label]};
	is( $labels, 2, 'domain labels separated by dots' );
}


use constant ESC => '\\';

{
	my $case   = ESC . '.';
	my $domain = new Net::DNS::Domain("example${case}com");
	my $labels = @{[$domain->label]};
	is( $labels, 1, "$case devoid of special meaning" );
}


{
	my $case   = ESC . ESC;
	my $domain = new Net::DNS::Domain("example${case}.com");
	my $labels = @{[$domain->label]};
	is( $labels, 2, "$case devoid of special meaning" );
}


{
	my $case   = ESC . ESC . ESC . '.';
	my $domain = new Net::DNS::Domain("example${case}com");
	my $labels = @{[$domain->label]};
	is( $labels, 1, "$case devoid of special meaning" );
}


{
	my $case   = '\092';
	my $domain = new Net::DNS::Domain("example${case}.com");
	my $labels = @{[$domain->label]};
	is( $labels, 2, "$case devoid of special meaning" );
}


{
	my $name   = 'simple-name';
	my $simple = new Net::DNS::Domain($name);
	is( $simple->name, $name, "$name absolute by default" );

	my $create = origin Net::DNS::Domain(undef);
	my $domain = &$create( sub { new Net::DNS::Domain($name); } );
	is( $domain->name, $name, "$name absolute if origin undefined" );
}


{
	my $name   = 'simple-name';
	my $create = origin Net::DNS::Domain('.');
	my $domain = &$create( sub { new Net::DNS::Domain($name); } );
	is( $domain->name, $name, "$name absolute if origin '.'" );
	my @label = $domain->label;
	is( scalar(@label), 1, "$name has single label" );
}


{
	my $name   = 'simple-name';
	my $suffix = 'example.com';
	my $create = origin Net::DNS::Domain($suffix);
	my $domain = &$create( sub { new Net::DNS::Domain($name); } );
	my $expect = new Net::DNS::Domain("$name.$suffix");
	is( $domain->name, $expect->name, "origin appended to $name" );

	my $root = new Net::DNS::Domain('@');
	is( $root->name, '.', 'bare @ represents root by default' );

	my $origin = &$create( sub { new Net::DNS::Domain('@'); } );
	is( $origin->name, $suffix, 'bare @ represents defined origin' );
}


{
	foreach my $char (qw($ ' " ; @)) {
		my $name   = $char . 'example.com.';
		my $domain = new Net::DNS::Domain($name);
		is( $domain->string, ESC . $name, "escape leading $char in string" );
	}
}


{
	foreach my $part (qw(_rvp._tcp *)) {
		my $name   = "$part.example.com.";
		my $domain = new Net::DNS::Domain($name);
		is( $domain->string, $name, "permit leading $part" );
	}
}


{
	my $ldh	   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789';
	my $domain = new Net::DNS::Domain($ldh);
	is( $domain->name, $ldh, '63 octet LDH character label' );
}


{
	my $name      = 'LO-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-NG!';
	my $domain    = eval { new Net::DNS::Domain("$name") };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "long domain label\t[$exception]" );
}


{
	my $domain = eval { new Net::DNS::Domain('.example.com') };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "empty initial label\t[$exception]" );
}


{
	my $domain = eval { new Net::DNS::Domain("example..com"); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "empty interior label\t[$exception]" );
}


{
	my $name   = 'example.com';
	my $domain = new Net::DNS::Domain("$name...");
	is( $domain->name, $name, 'ignore gratuitous trailing dots' );
}


{
	foreach my $case (
		'\000\001\002\003\004\005\006\007\008\009\010\011\012\013\014\015',
		'\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031'
		) {
		my $domain = new Net::DNS::Domain($case);
		is( $domain->name, $case, "C0 controls:\t$case" );
	}
}


{
	foreach my $case (
		'\032!"#$%&\'()*+,-\./',			#  32 .. 47
		'0123456789:;<=>?',				#  48 ..
		'@ABCDEFGHIJKLMNO',				#  64 ..
		'PQRSTUVWXYZ[\\\\]^_',				#  80 ..
		'`abcdefghijklmno',				#  96 ..
		'pqrstuvwxyz{|}~\127'				# 112 ..
		) {
		my $domain = new Net::DNS::Domain($case);
		is( $domain->name, $case, "G0 graphics:\t$case" );
	}
}


{
	foreach my $case (
		'\128\129\130\131\132\133\134\135\136\137\138\139\140\141\142\143',
		'\144\145\146\147\148\149\150\151\152\153\154\155\156\157\158\159',
		'\160\161\162\163\164\165\166\167\168\169\170\171\172\173\174\175',
		'\176\177\178\179\180\181\182\183\184\185\186\187\188\189\190\191',
		'\192\193\194\195\196\197\198\199\200\201\202\203\204\205\206\207',
		'\208\209\210\211\212\213\214\215\216\217\218\219\220\221\222\223',
		'\224\225\226\227\228\229\230\231\232\233\234\235\236\237\238\239',
		'\240\241\242\243\244\245\246\247\248\249\250\251\252\253\254\255'
		) {
		my $domain = new Net::DNS::Domain($case);
		is( $domain->name, $case, "8-bit codes:\t$case" );
	}
}


exit;

