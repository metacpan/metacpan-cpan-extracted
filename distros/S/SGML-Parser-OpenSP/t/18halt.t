# 18halt.t -- ...
#
# $Id: 18halt.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 10;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## normal halt
#########################################################

sub TestHandler13::new{bless{p=>$_[1],ok1=>0,ok2=>0},shift}
sub TestHandler13::start_element
{
    my $s = shift;
    my $e = shift;
    my $o = $s->{p};

    return unless defined $s;
    return unless defined $e;
    return unless defined $o;
    
    $s->{ok1}++;
    $o->halt;
}
sub TestHandler13::end_element
{
    my $s = shift;
    $s->{ok2}--;
}

my $h13 = TestHandler13->new($p);
$p->handler($h13);

lives_ok { $p->parse(NO_DOCTYPE); }
  'normal halt';

ok($h13->{ok1}, 'halt handler called');
is($h13->{ok2}, 0, 'halt stops events');

#########################################################
## halt via die in handler
#########################################################

sub TestHandler14::new{bless{ok1=>0,ok2=>0},shift}
sub TestHandler14::start_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    $s->{ok1}++;
    
    die "SUCKS!"
}
sub TestHandler14::end_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    $s->{ok2}--;
}

my $h14 = TestHandler14->new;

$p->handler($h14);

throws_ok { $p->parse(NO_DOCTYPE) } qr/SUCKS!/,
  'die in handler propagates';

ok($h14->{ok1});
is($h14->{ok2}, 0, 'die in handler halts');

$p->handler(bless{},'NullHandler');

lives_ok { $p->parse(NO_DOCTYPE) }
  'object still usable after die in handler';
