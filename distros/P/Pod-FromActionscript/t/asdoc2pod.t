#!/usr/bin/perl

use warnings;
use strict;
use File::Temp qw(tempfile);

BEGIN
{
   use Test::More tests => 23;
   use_ok("Pod::FromActionscript", "asdoc2pod");
}

my $out;
my $trivial_input = "/**\n\@author Foo\n*/\nclass Foo{}\n";
my $trivial_output = "=head1 AUTHOR\n\nFoo\n\n";
my $trivial_code = "/*\n\n=head1 AUTHOR\n\nFoo\n\n=cut\n*/\nclass Foo{}\n";

## Failure cases
eval { asdoc2pod(out => \$out); };
like($@, qr/no input/i, "no input");

eval { asdoc2pod(infile => "nosuchfile"); };
like($@, qr/failed to read/i, "no such input file");

eval { asdoc2pod(in => $trivial_input); };
like($@, qr/no output/i, "no output");

eval { asdoc2pod(in => $trivial_input, out => ""); };
like($@, qr/not a ref/i, "output not a reference");

eval { asdoc2pod(in => $trivial_input, outfile => "nosuchdir/out"); };
like($@, qr/failed to write/i, "no such output file");

{
   local $SIG{__WARN__} = sub {};

   asdoc2pod(in => "/**\nfoo\n*/ ", out => \$out);
   is($out, "", "out of place comment");

   $SIG{__WARN__} = sub {die @_};

   eval { asdoc2pod(in => "/**\nfoo\n*/ ", out => \$out); };
   like($@, qr/unhandled/i, "out of place comment");

   eval { asdoc2pod(in => "/**\n\@foo\n*/\nclass Foo{}\n", out => \$out); };
   like($@, qr/unhandled.*foo/i, "unknown directive");
}


## Simple successes
asdoc2pod(in => "", out => \$out);
is($out, "", "empty input");

asdoc2pod(in => "foo", out => \$out);
is($out, "", "no comments");

asdoc2pod(in => "foo /*\n bar\n */", out => \$out);
is($out, "", "plain comments");

asdoc2pod(in => "foo", out => \$out, code => 1);
is($out, "foo", "no comments, code");

asdoc2pod(in => "foo /*\n bar\n */", out => \$out, code => 1);
is($out, "foo /*\n bar\n */", "plain comments, code");

asdoc2pod(in => $trivial_input, out => \$out);
is($out, $trivial_output, "basic content");

asdoc2pod(in => $trivial_input, out => \$out, code => 1);
is($out, $trivial_code, "basic content, code");

eval { asdoc2pod(in => "foo"); };
ok(!$@, "omitting out allowed with empty output");

{
   my ($ofh, $ofname) = tempfile(UNLINK => 1);
   asdoc2pod(in => $trivial_input, outfile => $ofh);
   close($ofh) || die;
   $out = read_file($ofname);
   is($out, $trivial_output, "output filehandle");

   ($ofh, $ofname) = tempfile(UNLINK => 1);
   print $ofh "";
   close($ofh) || die;

   asdoc2pod(in => $trivial_input, outfile => $ofname);
   $out = read_file($ofname);
   is($out, $trivial_output, "output file");
}

asdoc2pod(in => "/** foo **/ ", out => \$out);
is($out, "", "non-JavaDoc comment");



## Complex data
my $infile = 't/example/foo.in';
my $expectfile = 't/example/foo.expect';
my $in = read_file($infile);
my $expect = read_file($expectfile);

asdoc2pod(in => $in, out => \$out);
is($out, $expect, "full example, string");

asdoc2pod(infile => $infile, out => \$out);
is($out, $expect, "full example, filename");

{
   open(my $infh, '<', $infile) || die;
   asdoc2pod(infile => $infh, out => \$out);
   close($infh) || die;
   is($out, $expect, "full example, filehandle");
}

sub read_file
{
   my $infile = shift;

   my $in;
   local *F;
   local $/ = undef;
   open(F, '<', $infile) || die;
   $in = <F>;
   close F || die;
   return $in;
}
