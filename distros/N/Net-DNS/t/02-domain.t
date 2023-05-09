#!/usr/bin/perl
# $Id: 02-domain.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 46;
use TestToolkit;


use_ok('Net::DNS::Domain');


for my $domain ( Net::DNS::Domain->new('example.com') ) {
	ok( $domain->isa('Net::DNS::Domain'), 'object returned by new() constructor' );

	my $same = Net::DNS::Domain->new( $domain->name );
	is( $same, $domain, "same name returns cached object" );

	my %cache;
	my ( $i, $j );
	for ( ; ; ) {
		$j = ( $i++ >> 1 ) + 1;
		my $fill = "name-$i";
		my $test = "name-$j";
		$cache{$fill} = Net::DNS::Domain->new($fill);
		last unless $cache{$test} == Net::DNS::Domain->new($test);
	}
	my $size = $i - $j;
	ok( $size, "name cache at least $size deep" );
}


for my $domain ( Net::DNS::Domain->new('name') ) {
	$domain->name;			## untestable optimisation: avoid returning name in void context
	is( $domain->name,   'name',  '$domain->name() without trailing dot' );
	is( $domain->fqdn,   'name.', '$domain->fqdn() with trailing dot' );
	is( $domain->string, 'name.', '$domain->string() with trailing dot' );
}


for my $root ( Net::DNS::Domain->new('.') ) {
	is( $root->name,   '.', '$root->name() represented by single dot' );
	is( $root->fqdn,   '.', '$root->fqdn() represented by single dot' );
	is( $root->xname,  '.', '$root->xname() represented by single dot' );
	is( $root->string, '.', '$root->string() represented by single dot' );
}


for my $domain ( Net::DNS::Domain->new('example.com') ) {
	my $labels = @{[$domain->label]};
	is( $labels, 2, 'domain labels separated by dots' );
}


use constant ESC => '\\';

{
	my $case   = ESC . '.';
	my $domain = Net::DNS::Domain->new("example${case}com");
	my $labels = @{[$domain->label]};
	is( $labels, 1, "$case devoid of special meaning" );
}


{
	my $case   = ESC . ESC;
	my $domain = Net::DNS::Domain->new("example${case}.com");
	my $labels = @{[$domain->label]};
	is( $labels, 2, "$case devoid of special meaning" );
}


{
	my $case   = ESC . ESC . ESC . '.';
	my $domain = Net::DNS::Domain->new("example${case}com");
	my $labels = @{[$domain->label]};
	is( $labels, 1, "$case devoid of special meaning" );
}


{
	my $case   = '\092';
	my $domain = Net::DNS::Domain->new("example${case}.com");
	my $labels = @{[$domain->label]};
	is( $labels, 2, "$case devoid of special meaning" );
}


{
	my $name   = 'simple-name';
	my $simple = Net::DNS::Domain->new($name);
	is( $simple->name, $name, "$name absolute by default" );

	my $create = origin Net::DNS::Domain(undef);
	my $domain = &$create( sub { Net::DNS::Domain->new($name); } );
	is( $domain->name, $name, "$name absolute if origin undefined" );
}


{
	my $name   = 'simple-name';
	my $create = origin Net::DNS::Domain('.');
	my $domain = &$create( sub { Net::DNS::Domain->new($name); } );
	is( $domain->name, $name, "$name absolute if origin '.'" );
	my @label = $domain->label;
	is( scalar(@label), 1, "$name has single label" );
}


{
	my $name   = 'simple-name';
	my $suffix = 'example.com';
	my $create = origin Net::DNS::Domain($suffix);
	my $domain = &$create( sub { Net::DNS::Domain->new($name); } );
	my $expect = Net::DNS::Domain->new("$name.$suffix");
	is( $domain->name, $expect->name, "origin appended to $name" );

	my $root = Net::DNS::Domain->new('@');
	is( $root->name, '.', 'bare @ represents root by default' );

	my $origin = &$create( sub { Net::DNS::Domain->new('@'); } );
	is( $origin->name, $suffix, 'bare @ represents defined origin' );
}


{
	my $ldh	   = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-0123456789';
	my $domain = Net::DNS::Domain->new($ldh);
	is( $domain->name, $ldh, '63 octet LDH character label' );
}


{
	my $name   = 'example.com';
	my $domain = Net::DNS::Domain->new("$name...");
	is( $domain->name, $name, 'ignore gratuitous trailing dots' );
}


foreach my $case (
	'\000\001\002\003\004\005\006\007\008\009\010\011\012\013\014\015',
	'\016\017\018\019\020\021\022\023\024\025\026\027\028\029\030\031'
	) {
	my $domain = Net::DNS::Domain->new($case);
	is( $domain->name, $case, "C0 controls:\t$case" );
}


foreach my $case (
	'\032!\034#$%&\'\(\)*+,-\./',				#  32 .. 47
	'0123456789:\;<=>?',					#  48 ..
	'@ABCDEFGHIJKLMNO',					#  64 ..
	'PQRSTUVWXYZ[\092]^_',					#  80 ..
	'`abcdefghijklmno',					#  96 ..
	'pqrstuvwxyz{|}~\127'					# 112 ..
	) {
	my $domain = Net::DNS::Domain->new($case);
	is( $domain->name, $case, "G0 graphics:\t$case" );
}


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
	my $domain = Net::DNS::Domain->new($case);
	is( $domain->name, $case, "8-bit codes:\t$case" );
}


exception( 'empty argument list', sub { Net::DNS::Domain->new() } );
exception( 'argument undefined',  sub { Net::DNS::Domain->new(undef) } );

exception( 'empty intial label',   sub { Net::DNS::Domain->new('..example.com') } );
exception( 'empty interior label', sub { Net::DNS::Domain->new('..example.com') } );

my $long = 'LO-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-O-NG!';
exception( 'long domain label', sub { Net::DNS::Domain->new($long) } );

exit;

