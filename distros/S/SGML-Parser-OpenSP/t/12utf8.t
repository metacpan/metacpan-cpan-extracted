# 12utf8.t -- ...
#
# $Id: 12utf8.t,v 1.1 2004/09/14 08:40:31 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 17;
use Test::Exception;
use File::Spec qw();
use Encode qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## UTF-8 flags
#########################################################

sub TestHandler7::new         { bless{ok0=>0,ok1=>0,ok2=>0,ok3=>0,ok4=>0,
                                      ok5=>0,ok6=>0,ok7=>0,ok8=>0,ok9=>0,
                                      oka=>0,okb=>0,okc=>0,
                                      data=>""},shift }
sub TestHandler7::start_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    my @k = keys %{$e->{Attributes}};
    $s->{ok1}++ if Encode::is_utf8($e->{Name});
    $s->{ok2}++ if Encode::is_utf8($e->{Name}, 1);
    return unless @k;
    $s->{ok8}++ if @k == 1;
    $s->{ok9}++ if Encode::is_utf8($k[0]);
    $s->{oka}++ if Encode::is_utf8($k[0], 1);
    $s->{okb}++ if Encode::is_utf8($e->{Attributes}{$k[0]}->{Name});
    $s->{okc}++ if Encode::is_utf8($e->{Attributes}{$k[0]}->{Name}, 1);
}
sub TestHandler7::end_element
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    $s->{ok3}++ if Encode::is_utf8($e->{Name});
    $s->{ok4}++ if Encode::is_utf8($e->{Name}, 1);
    $s->{ok5}++ if Encode::is_utf8($s->{data});
    $s->{ok6}++ if Encode::is_utf8($s->{data}, 1);
    $s->{ok7}++ if $s->{data} =~ /^Bj\x{F6}rn$/;
}
sub TestHandler7::data
{
    my $s = shift;
    my $e = shift;
    return unless defined $s and defined $e;
    return unless exists $e->{Data};
    $s->{ok0}-- unless Encode::is_utf8($e->{Data});
    $s->{ok0}-- unless Encode::is_utf8($e->{Data}, 1);
    $s->{data}.=$e->{Data};
}

my $h7 = TestHandler7->new;

$p->handler($h7);

lives_ok { $p->parse("<LITERAL><no-doctype x='y'>Bj&#246;rn</no-doctype>") }
  'utf8 flags';

is($h7->{ok0}, 0, 'utf8 pcdata');
is($h7->{ok1}, 1, 'utf8 element name');
is($h7->{ok2}, 1, 'utf8 element name check');
is($h7->{ok8}, 1, 'attributes');
is($h7->{ok9}, 1, 'attribute hash key utf8');
is($h7->{oka}, 1, 'attribute hash key utf8 check');
is($h7->{okb}, 1, 'attribute name utf8');
is($h7->{okc}, 1, 'attribute name utf8 check');
is($h7->{ok3}, 1, 'end element name');
is($h7->{ok4}, 1, 'end element name');
is($h7->{ok5}, 1, 'complete data');
is($h7->{ok6}, 1, 'complete data');
is($h7->{ok7}, 1, 'correct data');

