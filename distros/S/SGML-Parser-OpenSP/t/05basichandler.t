# 05basichandler.t -- ...
#
# $Id: 05basichandler.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 14;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## Simple Event Handler
#########################################################

sub TestHandler1::new { bless{ok1=>0,ok2=>0,ok3=>0,ok4=>0,ok5=>0,
                              ok6=>0,ok7=>0,ok8=>0,ok9=>0,oka=>0},shift }
sub TestHandler1::start_element {
    my $s = shift;
    my $e = shift;
    
    return unless defined $s;
    return unless defined $e;
    
    $s->{ok1}++ if UNIVERSAL::isa($s, 'TestHandler1');

    # Name
    $s->{ok2}++ if exists $e->{Name};
    $s->{ok3}++ if $e->{Name} =~ /no-doctype/i;
    
    # Attributes
    $s->{ok4}++ if exists $e->{Attributes};
    $s->{ok5}++ if UNIVERSAL::isa($e->{Attributes}, "HASH");
    $s->{ok6}++ if scalar(keys(%{$_[1]->{Attributes}})) == 0;
    
    # Included
    $s->{ok7}++ if exists $e->{Included};
    $s->{ok8}++ if $e->{Included} == 0;
    
    # ContentType
    $s->{ok9}++ if exists $e->{ContentType};
}

my $h1 = TestHandler1->new;

isa_ok($h1, 'TestHandler1');

$p->handler($h1);

lives_ok { $p->parse(NO_DOCTYPE) }
  'basic parser test';

ok($h1->{ok1}, 'self to handler');
ok($h1->{ok2}, 'has name');
ok($h1->{ok3}, 'proper name');
ok($h1->{ok4}, 'has attrs');
ok($h1->{ok5}, 'attrs hash ref');
ok($h1->{ok6}, 'proper attrs');
ok($h1->{ok7}, 'has included');
ok($h1->{ok8}, 'included == 0');
ok($h1->{ok9}, 'has content type');

