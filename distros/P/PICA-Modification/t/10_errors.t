use strict;
use warnings;
use Test::More;

use PICA::Record;
use PICA::Modification;

my %id = (id => 'opac-de-23:ppn:311337856'); 
my $mod = PICA::Modification->new( %id, del => '012A' );
ok !$mod->error, 'ok';
is $mod->{ppn}, 311337856, 'ppn set';
is $mod->{dbkey}, 'opac-de-23', 'dbkey set';

my $pica = PICA::Record->new("003@ \$0123\n021A \$aHello");

my @malformed = (
 	[ { id => '' }, { id => 'missing record identifier', del => 'edit must not be empty' } ],
 	[ { }, { id => 'missing record identifier', del => 'edit must not be empty' } ],
	[ { id => 'ab:cd' }, { id => 'malformed record identifier', del => 'edit must not be empty' } ],
	[ {	%id, add => '144Z $a' }, { add => 'malformed fields to add' } ], 
	[ {	%id, del => '144Z $a' }, { del => 'malformed fields to remove', iln => 'missing ILN for remove'} ], 
	[ { %id, add => '144Z $afoo' }, { iln => 'missing ILN for add', del => 'fields to add must also be deleted' } ],
	[ { %id, del => '144Z' }, { iln => 'missing ILN for remove' } ],
	[ { %id, add => '209@ $fbar' }, { epn => 'missing EPN for add', del => 'fields to add must also be deleted' } ],
	[ { %id, del => '209@' }, { epn => 'missing EPN for remove' } ],
    [ { %id, del => '201A', iln => 'abc', epn => 'xyz' }, { iln => 'malformed ILN', epn => 'malformed EPN' } ],
    [ { %id, del => '003@' }, { del => 'must not modify field: 003@' } ],
    [ { iln => 20, del => '144Z', id => 'abc:ppn:123' }, { iln => 'ILN not found' }, $pica ],
    [ { iln => 20, del => '144Z', id => 'abc:ppn:123' }, { id => 'record not found' }, '' ],
    [ { iln => 20, del => '144Z', id => 'abc:ppn:456' }, { id => 'PPN does not match' }, $pica ],
);

foreach (@malformed) {
	my ($fields,$errors,$pica) = @$_;
	my $mod = PICA::Modification->new( %$fields );
    is( $mod->apply( $pica ), undef, 'application failed') if defined $pica;
    is( $mod->error, scalar (keys %$errors) );
	while (my ($f,$msg) = each %$errors) {
	   is( $mod->error($f), $msg, $msg );
    }
    is( $mod->check->error, 0, 'check resets errors' ) if defined $pica;
}

done_testing;
