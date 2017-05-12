my $serial_asn1;
my $i;
package Foo;
sub length {1};
package main;
bless $serial_asn1 => 'Foo';

for ($i=0; $i<$serial_asn1->length; $i++) {
}

