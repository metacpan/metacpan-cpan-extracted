#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Syntax::Keyword::Try;
use Syntax::Keyword::Try::Deparse;

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
   sub { try { ABC() } catch { DEF() } },
   "try {\n    ABC();\n}\ncatch {\n    DEF();\n}",
   'try/catch';

is_deparsed
   sub { try { ABC() } catch($e) { DEF() } },
   "try {\n    ABC();\n}\ncatch {\n    my \$e = \$@;\n    DEF();\n}",
   'try/catch(VAR)';

is_deparsed
   sub { try { ABC() } finally { XYZ() } },
   "try {\n    ABC();\n}\nfinally {\n    XYZ();\n}",
   'try/finally';

is_deparsed
   sub { try { ABC() } catch { DEF() } finally { XYZ() } },
   "try {\n    ABC();\n}\ncatch {\n    DEF();\n}\nfinally {\n    XYZ();\n}",
   'try/catch/finally';

done_testing;
