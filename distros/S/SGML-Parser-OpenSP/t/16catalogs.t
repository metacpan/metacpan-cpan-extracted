# 16catalogs.t -- ...
#
# $Id: 16catalogs.t,v 1.3 2005/12/11 19:47:15 tbe Exp $

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
require_ok('SGML::Parser::OpenSP');
my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## SGML Catalogs
#########################################################

sub TestHandler11::new{bless{ok1=>0,ok2=>0,ok3=>0,ok4=>0,ok5=>0},shift}
sub TestHandler11::start_dtd
{
    my $s = shift;
    my $d = shift;
    
    return unless defined $s;
    return unless defined $d;
    
    my $e = $d->{ExternalId};
    
    return unless defined $e;
    
    $s->{ok1}++;
    
    $s->{ok2}++ if exists $e->{SystemId} and $e->{SystemId} eq
      "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd";
      
    $s->{ok3}++ if exists $e->{PublicId} and $e->{PublicId} eq
      "-//W3C//DTD XHTML 1.0 Strict//EN";
      
    # this might fail in case of conflicting catalogs :-(
    $s->{ok4}++ if exists $e->{GeneratedSystemId} and
      $e->{GeneratedSystemId} =~ /^<OSFILE>| /i;
      
    $s->{ok5}++ if exists $d->{Name} and
      $d->{Name} eq "html";
}

my $h11 = TestHandler11->new;

$p->catalogs(TEST_CATALOG);
$p->handler($h11);

lives_ok { $p->parse("<LITERAL>" . <<"__DOC__");
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
</head>
<body>
<p dir="&#xa;">...</p>
</body>
</html>
__DOC__
} 'catalogs';

ok($h11->{ok1}, 'proper dtd event');
ok($h11->{ok2}, 'proper sys id');
ok($h11->{ok3}, 'proper pub id');

ok($h11->{ok4}, 'proper osfile gen id');
ok($h11->{ok5}, 'proper root element');

# reset catalogs
$p->catalogs([]);

