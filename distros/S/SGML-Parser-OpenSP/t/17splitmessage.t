# 17splitmessage.t -- ...
#
# $Id: 17splitmessage.t,v 1.2 2004/10/01 23:21:19 hoehrmann Exp $

use strict;
use warnings;
use Test::More tests => 18;
use Test::Exception;
use File::Spec qw();

use constant NO_DOCTYPE   => File::Spec->catfile('samples', 'no-doctype.xml');
use constant TEST_CATALOG => File::Spec->catfile('samples', 'test.soc');

BEGIN { use_ok('SGML::Parser::OpenSP') };
BEGIN { use_ok('SGML::Parser::OpenSP::Tools') };

require_ok('SGML::Parser::OpenSP');
require_ok('SGML::Parser::OpenSP::Tools');

my $p = SGML::Parser::OpenSP->new;
isa_ok($p, 'SGML::Parser::OpenSP');

#########################################################
## newlines in enum attribute
#########################################################

sub TestHandler12::new{bless{p=>$_[1],ok1=>0,ok2=>0,ok3=>0,ok4=>0,
                             ok5=>0,ok6=>0,ok7=>0,ok8=>0},shift}
sub TestHandler12::error
{
    my $s = shift;
    my $e = shift;
    my $p = $s->{p};
    
    return unless defined $s and
                  defined $e and
                  defined $p;
                  
    my $l = $p->get_location;
    
    return unless defined $l;
    $s->{ok1}++;
    my $m;
    
    eval
    {
        $m = $p->split_message($e);
    };
    
    return if $@;
    $s->{ok2}++;
    
    if ($m->{primary_message}{Number} == 122)
    {
        $s->{ok3}++ if $m->{primary_message}{ColumnNumber} == 8;
        $s->{ok4}++ if $m->{primary_message}{LineNumber} == 8;
        $s->{ok5}++ if $m->{primary_message}{Text} =~
          /.+\n.+/;
    }
    elsif ($m->{primary_message}{Number} == 131)
    {
        $s->{ok6}++ if $m->{primary_message}{ColumnNumber} == 13;
        $s->{ok7}++ if $m->{primary_message}{LineNumber} == 8;
        $s->{ok8}++ if $m->{primary_message}{Text} =~
        /.+\n.+/;
    }
}

my $h12 = TestHandler12->new($p);
$p->handler($h12);
$p->catalogs(TEST_CATALOG);
$p->show_error_numbers(1);

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
} 'newlines in enum attr values';

cmp_ok($h12->{ok1}, '>=', 2, 'two errors');
cmp_ok($h12->{ok2}, '>=', 2, 'two errors split');

ok($h12->{ok3}, 'correct col 122');
ok($h12->{ok4}, 'correct lin 122');
ok($h12->{ok5}, 'correct text 122');
ok($h12->{ok6}, 'correct col 131');
ok($h12->{ok7}, 'correct lin 131');
ok($h12->{ok8}, 'correct text 131');

$p->catalogs([]);
$p->show_error_numbers(0);

my @tests = (

### 1 ###

{
input => [
  q(<OSFD>0:116:49:1075801588.108:E: there is no attribute "XMLNS:UTILITY"),
  q(<OSFD>0),
  0,
  1,
  0,
],

output => {
  primary_message => {
    Number => '108',
    ColumnNumber => '49',
    Module => '1075801588',
    Severity => 'E',
    LineNumber => '116',
    Text => 'there is no attribute "XMLNS:UTILITY"'
  }
}
},

### 2 ###

{
input => [
  q(c:\\temp\\file:116:49:1075801588.108:E: there is no attribute "XMLNS:UTILITY"),
  q(c:\\temp\\file),
  0,
  1,
  0,
],

output => {
  primary_message => {
    Number => '108',
    ColumnNumber => '49',
    Module => '1075801588',
    Severity => 'E',
    LineNumber => '116',
    Text => 'there is no attribute "XMLNS:UTILITY"'
  }
}

},

### 3 ###

{
input => [
  q(c:\\temp\\file:116:49:E: there is no attribute "XMLNS:UTILITY"),
  q(c:\\temp\\file),
  0,
  0,
  0,
],

output => {
  primary_message => {
    ColumnNumber => '49',
    Severity => 'E',
    LineNumber => '116',
    Text => 'there is no attribute "XMLNS:UTILITY"'
  }
}

},

### 4 ###

{
input => [
  q(<OSFD>0:320:175:1075801588.338:W: cannot generate system identifier for general entity "AP"),
  q(<OSFD>0),
  0,
  1,
  0,
],

output => {
  primary_message => {
    Number => '338',
    ColumnNumber => '175',
    Module => '1075801588',
    Severity => 'W',
    LineNumber => '320',
    Text => 'cannot generate system identifier for general entity "AP"'
  }
}

},

);

foreach (@tests)
{
    my $inpu = $_->{input};
    my $outp = $_->{output};
    my $resu = SGML::Parser::OpenSP::Tools::split_message(@$inpu);
    is_deeply($resu, $outp);
}
