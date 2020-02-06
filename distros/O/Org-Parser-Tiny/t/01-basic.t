#!perl

use 5.010001;
use strict;
use warnings;
use Test::More 0.98;

use Org::Parser::Tiny;

my $org1 = <<'_';
some text before the first headline.

* header1                                                               :tag:
contains an internal link to another part of the document [[blah]]
* header2 [#A] [20%]
- contains priority and progress cookie (percent-style)
* header3 [1/10]
- contains progress cookie (fraction-style)
** header3.1
** header3.2
** header3.3
* header4
blah blah.
* blah
_

subtest "parse() string" => sub {
    my $doc = Org::Parser::Tiny->parse($org1);

    is($doc->children->[0]->as_string,
       "* header1                                                               :tag:
contains an internal link to another part of the document [[blah]]
");
    delete $doc->children->[0]->{_str};
    is($doc->children->[0]->as_string,
       "* header1 :tag:
contains an internal link to another part of the document [[blah]]
");

};

DONE_TESTING:
done_testing;
