# 08comments.t -- ...
#
# $Id: 08comments.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

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
## Comments at user option
#########################################################

sub TestHandler3::new         { bless{ok=>0},shift }
sub TestHandler3::comment_decl{ $_[0]->{ok}++ }

my $h3 = TestHandler3->new(1);

isa_ok($h3, 'TestHandler3');

$p->handler($h3);

$p->output_comment_decls(1);

is($p->output_comment_decls, 1, 'comments turned on');

lives_ok { $p->parse("<LITERAL><no-doctype><!--...--></no-doctype>") }
  'comment reported at user option';
  
isnt($h3->{ok}, 0, 'comments ok');

$p->output_comment_decls(0);

is($p->output_comment_decls, 0, 'comments turned off');

