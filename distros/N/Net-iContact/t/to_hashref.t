#!perl -T
use strict;

use Test::More tests => 3;
use Net::iContact;

my $root = Net::iContact::_parse(do {local $/;<DATA>});

my %a = %{Net::iContact::_to_hashref($root->{response}->{contact})};
ok($a{fname} eq "Test");
ok(!exists($a{pos}));
ok(!exists($a{attr}));
__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<response status="success" xmlns:xlink="http://www.w3.org/1999/xlink">
  <contact id="695535">
    <fname>Test</fname>
    <lname>Contact</lname>
    <email>test@example.com</email>
    <prefix />
    <suffix />
    <business />
    <address1 />
    <address2 />
    <city />
    <state />
    <zip />
    <phone />
    <fax />
    <custom_fields xlink:href="contact/695535/custom_fields" />
    <subscriptions xlink:href="contact/695535/subscriptions" />
  </contact>
</response>
