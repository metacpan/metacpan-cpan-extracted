# 10errors.t -- ...
#
# $Id: 10errors.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 5;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## Error reporting
#########################################################

sub TestHandler5::new         { bless{ok=>0},shift }
sub TestHandler5::error
{
    return unless @_ == 2;
    $_[0]->{ok}++ if $_[1]->{Message} =~ /:4:13:E:/;
}

my $h5 = TestHandler5->new;
$p->handler($h5);
lives_ok { $p->parse("<LITERAL>" . <<"__DOC__");
<!DOCTYPE no-doctype [
  <!ELEMENT no-doctype - - (#PCDATA)>
  <!ATTLIST no-doctype x CDATA #REQUIRED>
]><no-doctype></no-doctype>
__DOC__
} 'does properly report erros';

is($h5->{ok}, 1, 'found right error message');

