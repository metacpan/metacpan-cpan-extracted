# 09locations.t -- ...
#
# $Id: 09locations.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

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
## Locations for implied document type declarations
#########################################################

# OpenSP 1.5.1 generates random numbers for the locations

sub TestHandler4::new { bless{p=>$_[1],ok1=>0,ok2=>0,ok3=>0,ok4=>0},shift }
sub TestHandler4::start_dtd
{
    my $s = shift;
    return unless defined $s;
    my $l = $s->{p}->get_location;
    return unless defined $l;
    
    $s->{ok1}++ if $l->{ColumnNumber} == 3;
    $s->{ok2}++ if $l->{LineNumber} == 2;
    $s->{ok3}++ if $l->{EntityOffset} == 7;
}
sub TestHandler4::end_dtd
{
    my $s = shift;
    return unless defined $s;
    my $l = $s->{p}->get_location;
    return unless defined $l;
    
    $s->{ok4}++ if $l->{ColumnNumber} == 3;
    $s->{ok4}++ if $l->{LineNumber} == 2;
    $s->{ok4}++ if $l->{EntityOffset} == 7;
}

my $h4 = TestHandler4->new($p);

$p->handler($h4);

lives_ok { $p->parse("<LITERAL>\n  \n  <no-doctype></no-doctype>") }
  'implied dtd locations';

is($h4->{ok1}, 1, "implied col");
is($h4->{ok2}, 1, "implied line");
is($h4->{ok3}, 1, "implied offset");
is($h4->{ok4}, 3, "implied end_dtd");

