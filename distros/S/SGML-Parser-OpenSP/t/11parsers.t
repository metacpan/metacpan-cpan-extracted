# 11parsers.t -- ...
#
# $Id: 11parsers.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 85;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## Lots of parsers
#########################################################

my @parser;

for (1..20)
{
    my $p = SGML::Parser::OpenSP->new;

    isa_ok($p, 'SGML::Parser::OpenSP');

    ok(exists $p->{__o},
      'pointer to C++ object');

    isnt($p->{__o}, 0,
      'C++ object pointer not null-pointer');
    
    $p->handler(bless{},'TestHandler6');

    lives_ok { $p->parse("<LITERAL><no-doctype></no-doctype>") }
      'reading from a <literal>';
    
    push @parser, $p;
}

is(scalar(@parser), 20, 'all parsers loaded');

lives_ok { undef @parser } 'parser destructors';

