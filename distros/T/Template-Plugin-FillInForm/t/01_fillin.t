use strict;
use CGI;
use Test::More tests => 6;
use Template;

my $query = CGI->new({ foo => 'bar', bar => 'baz' });
my $tt = Template->new;

local $/ = '';
while (<DATA>) {
    my($test, $expect) = /^--test--\n(.*?)\n--expect--\n(.*?)\n$/s;
    my @expect = split /\n/, $expect;
    $tt->process(\$test, { query => $query }, \my $out);
    like $out, qr/$_/ for @expect;
}

__END__
--test--
[% USE FillInForm -%]
[% FILTER fillinform fobject => query -%]
<form action="foo" method="POST"><input name="foo" type="text"></form>
[%- END %]
--expect--
name="foo"
type="text"
value="bar"

--test--
[% USE FillInForm -%]
[% FILTER fillinform fdat => { foo => 'foo&' } -%]
<form action="foo" method="POST"><input name="foo" type="text"></form>
[%- END %]
--expect--
name="foo"
type="text"
value="foo&amp;"
