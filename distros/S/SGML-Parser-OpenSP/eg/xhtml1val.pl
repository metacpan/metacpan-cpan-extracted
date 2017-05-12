#!/usr/bin/perl -w
#######################################################################
# A simple XHTML 1.0 Strict Validation script with encoding detection
#
# By Bjoern Hoehrmann bjoern@hoehrmann.de http://bjoern.hoehrmann.de
#######################################################################

BEGIN {
  $ENV{SP_CHARSET_FIXED} = 1;      
  $ENV{SP_ENCODING}      = "UTF-8";
  $ENV{SP_BCTF}          = "UTF-8";
}

sub ErrorHandler::new {bless {p=>$_[1]}, shift}
sub ErrorHandler::error
{
  push @{$_[0]->{errors}}, $_[0]->{p}->split_message($_[1])
}

use strict;
use warnings;
use SGML::Parser::OpenSP qw();
use HTML::Encoding qw();
use HTML::Doctype qw();
use LWP::UserAgent qw();
use I18N::Charset qw();
use Encode qw();

use constant TEST_CATALOG =>
  File::Spec->catfile(File::Spec->updir, 'samples', 'test.soc');

our @SP_OPTS = qw/
  non-sgml-char-ref
  valid
  no-duplicate
  xml
/;

my $u = LWP::UserAgent->new;
my $p = SGML::Parser::OpenSP->new;
my $e = ErrorHandler->new($p);

my $r = $u->get("http://www.w3.org/");

my $name1 = HTML::Encoding::encoding_from_http_message($r);
my $name2 = I18N::Charset::enco_charset_name($name1);
my $text = Encode::decode($name2 => $r->content);

# Validation
$p->handler($e);
$p->catalogs(TEST_CATALOG);
$p->warnings(@SP_OPTS);
$p->parse_string($text);

foreach my $error (@{$e->{errors}})
{
    my $prim = $error->{primary_message};
    printf "[%4d %4d %s]: %s\n",
      $prim->{LineNumber},
      $prim->{ColumnNumber},
      $prim->{Severity},
      $prim->{Text}
}

if (not @{$e->{errors}}) {
  printf "No errors found!\n";
}
