# 15parseinput.t -- ...
#
# $Id: 15parseinput.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## non-scalar to parse
#########################################################

sub TestHandler10::new{bless{},shift}

my $h10 = TestHandler10->new;
$p->handler($h10);

dies_ok { $p->parse({}) }
  'non-scalar to parse';

dies_ok { $p->parse([]) }
  'non-scalar to parse';

ok(open(F, '<', NO_DOCTYPE), 'can open no-doctype.xml');

dies_ok { $p->parse(\*F) }
  'file handle to parse';

ok(close(F), 'can close no-doctype.xml');

