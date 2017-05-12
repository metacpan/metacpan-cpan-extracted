use strict;
use warnings;
use Test::More;
use RDF::aREF;

sub decode_ok(@) {
    my $aref  = shift;
    my $count = shift;
    my $triples = 0;
    RDF::aREF::Decoder
        ->new( callback => sub { $triples++ }, @_ )
        ->decode($aref);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is $triples, $count;
}

# ignore undef
decode_ok { _id => undef, a => 'ex:ample' }, 0; 
decode_ok { _id => 'an:id', a => 'ex:ample' }, 1;
decode_ok { _id => 'an:id', a => undef }, 0;
decode_ok { _id => 'an:id', a => [undef,'ex:ample'] }, 1;

# ignore undef and '0'
decode_ok { _id => '0', a => 'ex:ample' }, 0, null => 0;
decode_ok { _id => 'an:id', a => 'ex:ample' }, 1, null => 0;
decode_ok { _id => 'an:id', a => '0' }, 0, null => 0;
decode_ok { _id => 'an:id', a => ['0','ex:ample'] }, 1, null => 0;
decode_ok { _id => 'an:id', a => [undef,'ex:ample'] }, 1, null => undef;
decode_ok { 'an:id' => { a => 'ex:ample' }, '0' => { a => 'ex:ample' } }, 1, null => 0;

# ignore as subject
decode_ok { '' => { a => 'ex:ample' } }, 0, null => '';

done_testing;
