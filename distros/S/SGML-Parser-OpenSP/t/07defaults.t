# 07defaults.t -- ...
#
# $Id: 07defaults.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

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
## Comments not default
#########################################################

sub TestHandler2::new         { bless{ok1=>0},shift }
sub TestHandler2::comment     { $_->{ok1}-- }

my $h2 = TestHandler2->new;
isa_ok($h2, 'TestHandler2');

$p->handler($h2);

lives_ok { $p->parse("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comments not reported by default';

is($h2->{ok1}, 0, 'comments not default');

