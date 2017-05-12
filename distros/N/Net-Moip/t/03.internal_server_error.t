use strict;
use warnings;
use Test::More;

package HTTPTestAgent;

sub new { bless {}, shift }

sub post { shift }

sub is_success { 0 }

sub content {
    return q{<ns1:XMLFault xmlns:ns1="http://cxf.apache.org/bindings/xformat"><ns1:faultstring xmlns:ns1="http://cxf.apache.org/bindings/xformat">javax.xml.stream.XMLStreamException: ParseError at [row,col]:[1,1]
    Message: Content is not allowed in prolog.</ns1:faultstring></ns1:XMLFault>}
}

package main;

use Net::Moip;

my $moip = Net::Moip->new(
    token => 123,
    key   => 321,
    ua    => HTTPTestAgent->new,
);

my $res = $moip->pagamento_unico({
    razao => 'Compra na loja X',
    valor => 50,
});

is ref $res->{response}, 'HTTPTestAgent', 'got the test agent';

is scalar keys %$res, 1, 'only got one key on internal server error';

done_testing;
