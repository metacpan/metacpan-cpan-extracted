#!perl -T
use strict;

use Test::More tests => 1;
use Net::iContact;

my $root = Net::iContact::_parse(do {local $/;<DATA>});

### test _to_arrayref
my @a = @{ Net::iContact::_to_arrayref($root->{response}->{contact})};
## Can't depend on the order in the array, because the XML is parsed
## into a hash first.
ok(grep(695535, @a) && grep(775201, @a));
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<response status="success" xmlns:xlink="http://www.w3.org/1999/xlink">
  <contact id="695535" xlink:href="/contact/695535" />
  <contact id="775201" xlink:href="/contact/775201" />
</response>
