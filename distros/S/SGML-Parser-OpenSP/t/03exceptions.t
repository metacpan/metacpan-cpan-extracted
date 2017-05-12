# 03exceptions.t -- ...
#
# $Id: 03exceptions.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

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
## Exceptions
#########################################################

dies_ok { $p->get_location }
  'must die when calling get_location while not parsing';

dies_ok { $p->parse }
  'must die when no file name specified for parse';

dies_ok { $p->parse(NO_DOCTYPE) }
  'must die when no handler specified';

