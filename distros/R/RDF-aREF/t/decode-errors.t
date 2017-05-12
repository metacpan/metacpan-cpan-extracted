use strict;
use warnings;
use Test::More;
use RDF::aREF::Decoder;
use Scalar::Util qw(reftype);

sub check_errors(@) {
    my $errors = pop;
    my %options = @_;
    my $msg = delete $options{msg};
    my $decoder = RDF::aREF::Decoder->new( complain => 2, %options );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    while (@$errors) {
        my $aref   = shift @$errors;
        eval { $decoder->decode( $aref ) };
        if (@$errors and reftype $errors->[0] eq reftype qr//) {
            my $expect = shift @$errors;
            like($@, $expect, ($msg // $expect));
        } else {
            ok $@, $msg // '';
        }
    }
}

check_errors [

    { _ns => [] },
        => qr{^namespace map must be map or string},

# invalid subjects
    { [] => { a => 'foaf:Person' } }
        => qr{^invalid subject: ARRAY\(},
    { '<x:subject>' => { a => 'foaf:Person' } } 
        => qr{^invalid subject},

# invalid predicates        
    { 'x:subject' => { \"" => "" } }
        => qr{^invalid predicate IRI SCALAR\(},

# TODO: check different forms of same IRI
# invalid objects
    { 'x:subject' => { a => \"" } }
        => qr{^object must not be reference to SCALAR},
    { 'x:subject' => { a => [ \"" ] } }
        => qr{^object must not be reference to SCALAR},

    { _ns => { 1 => 'http://example.org/' }, 
      'x:subject' => { a => 'foaf:Person' } }
        => qr{^invalid prefix: 1},
    { _ns => { x => 'foo' }, 
      'x:subject' => { a => 'foaf:Person' } }
        => qr{^invalid namespace: foo}
];

check_errors strict => 1, msg => 'strict makes undef error',
    [ { '<x:subj>' => { a => undef } } => qr{.} ];

check_errors strict => 1, null => '', msg => 'strict makes null value error',
    [ { '' => { a => 'foaf_Person' } } ];
    
check_errors strict => 1, msg => 'empty string not null by default',
    [ { '' => { a => 'foaf_Person' } } ];

done_testing;
