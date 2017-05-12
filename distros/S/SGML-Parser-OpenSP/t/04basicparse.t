# 04basicparse.t -- ...
#
# $Id: 04basicparse.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 6;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## Accessors
#########################################################

$p->handler(7);

is($p->handler, 7, 'accessor');

#########################################################
## More Exceptions
#########################################################

dies_ok { $p->parse(NO_DOCTYPE) }
  'must die when handler not an object';

$p->handler(bless{}, 'NullHandler');

lives_ok { $p->parse(NO_DOCTYPE) }
  'must not die when handler cannot handle a method';

