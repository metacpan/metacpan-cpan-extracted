# 14illegalparse.t -- ...
#
# $Id: 14illegalparse.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

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
## parse from handler
#########################################################

sub TestHandler9::new{bless{p=>$_[1],ok1=>0},shift}
sub TestHandler9::start_element
{
    my $s = shift;
    
    eval
    {
        $s->{p}->parse(NO_DOCTYPE)
    };
        
    $s->{ok1}-- unless $@;
}

my $h9 = TestHandler9->new($p);

$p->handler($h9);

lives_ok { $p->parse(NO_DOCTYPE) }
  'parse must not be called from handler';

is($h9->{ok1}, 0, 'parse from handler croaks');

