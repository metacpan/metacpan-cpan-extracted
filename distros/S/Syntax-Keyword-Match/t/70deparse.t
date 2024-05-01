#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use Syntax::Keyword::Match;
use Syntax::Keyword::Match::Deparse;

use B::Deparse;
my $deparser = B::Deparse->new();

sub is_deparsed
{
   my ( $sub, $exp, $name ) = @_;

   my $got = $deparser->coderef2text( $sub );

   # Deparsed output is '{ ... }'-wrapped
   $got = ( $got =~ m/^{\n(.*)\n}$/s )[0];
   $got =~ s/^    //mg;

   # Deparsed output will have a lot of pragmata and so on
   1 while $got =~ s/^\s*(?:use|no) \w+.*\n//;
   $got =~ s/^BEGIN \{\n.*?\n\}\n//s;

   # Trim a trailing linefeed
   chomp $got;

   is( $got, $exp, $name );
}

is_deparsed
   sub { match(1 : ==) { case(1) { YES() } case(2) { NO() } } },
   "match (1 : ==) {\n" .
   "    case (1) {YES();}\n" .
   "    case (2) {NO();}\n" .
   "};",
   'match/case on ==';

is_deparsed
   sub { match('a' : eq) { case('a') { YES() } case('b') { NO() } } },
   "match ('a' : eq) {\n" .
   "    case ('a') {YES();}\n" .
   "    case ('b') {NO();}\n" .
   "};",
   'match/case on eq';

is_deparsed
   sub { match('a' : =~) { case(m/a/) { YES() } case(m/b/) { NO() } } },
   "match ('a' : =~) {\n" .
   "    case (m/a/u) {YES();}\n" .
   "    case (m/b/u) {NO();}\n" .
   "};",
   'match/case on =~';

is_deparsed
   eval q(sub { match('OBJ' : isa) { case(AClass) { YES() } case(BClass) { NO() } } }),
   "match ('OBJ' : isa) {\n" .
   "    case ('AClass') {YES();}\n" .
   "    case ('BClass') {NO();}\n" .
   "};",
   'match/case on isa' if $^V ge v5.32.0;

is_deparsed
   sub { match(1 : ==) { case(1) { YES() } case(2) { NO() } default { ALSO_NO() } } },
   "match (1 : ==) {\n" .
   "    case (1) {YES();}\n" .
   "    case (2) {NO();}\n" .
   "    default {ALSO_NO();}\n" .
   "};",
   'match/case with default';

is_deparsed
   sub { match(1 : ==) { case(1), case(2) { YES() } case(3) { NO() } } },
   "match (1 : ==) {\n" .
   "    case (1), case (2) {YES();}\n" .
   "    case (3) {NO();}\n" .
   "};",
   'match/case with multiple case conditions';

is_deparsed
   sub { match(1 : ==) { case if (rand > 0.5) { MAYBE() } case(2) { NO() } } },
   "match (1 : ==) {\n" .
   "    case if (rand > 0.5) {MAYBE();}\n" .
   "    case (2) {NO();}\n" .
   "};",
   'match/case with case if';

done_testing;
