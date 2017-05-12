#===============================================================================
# vim: ts=8 et sw=4 sts=4
#
#         FILE:  69-to-experimental.t
#===============================================================================

use lib 't';
use strict;
use warnings;
use ExtUtils::testlib;
use Storable::AMF qw(thaw0 thaw3 freeze0 freeze3);
use Storable::AMF::Mapper;
eval 'use Test::More tests => 8;';

sub serialize0{
	my $mapper = Storable::AMF::Mapper->new(to_amf=>1);
	my @values = Storable::AMF0::freeze($_[0], $mapper);
	if (@values != 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
sub serialize3{
	my $mapper = Storable::AMF::Mapper->new(to_amf=>1);
	my @values = Storable::AMF3::freeze($_[0], $mapper);
	if (@values != 1) {
		print STDERR "many returned values\n";
	}
	return $values[0];
}
{{
package Test::ToAMF;

sub new{
	bless {foo => 'bar'};
}

sub TO_AMF {
    return { %{ $_[0] }, a => 1 };
}
}}
sub MyDump{
	join "", map { ord >31 ? $_ : "\\x". unpack "H*", $_ }  split "", $_[0];
}
my $obj = Test::ToAMF->new();
my $bank_0 = serialize0($obj);
my $newobj_0 = thaw0($bank_0);
my $bank_3 = serialize3($obj);
my $newobj_3 = thaw3($bank_3);

ok(defined($bank_0), 'froze ok' );
ok(defined($bank_3), 'froze ok' );
ok(defined($newobj_0), 'thawed ok' );
ok(defined($newobj_3), 'thawed ok' );

my $expected = { foo => 'bar', a => 1 };
is_deeply( $newobj_0, $expected, 'thawed TO_AMF version');
is_deeply( $newobj_3, $expected, 'thawed TO_AMF version');
is(ref ($newobj_0), 'HASH', 'TO_AMF version is unblessed' );
is(ref ($newobj_3), 'HASH', 'TO_AMF version is unblessed' );




