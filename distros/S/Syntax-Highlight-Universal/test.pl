# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test::More tests => 8;
BEGIN { use_ok('Syntax::Highlight::Universal') };

my $highlighter = Syntax::Highlight::Universal->new();
ok($highlighter, 'new Syntax::Highlight::Universal;');

eval_ok('$highlighter->addConfig("hrc/proto.hrc")', 'addConfig("hrc/proto.hrc");');

eval_ok('$highlighter->highlight("perl", "print qq[Hello, World!\\\\n];")', 'basic perl highlighting');

eval_ok('$highlighter->highlight("c", "int main(void) {\nreturn 0\n}")', 'basic c highlighting');

eval_ok('$highlighter->highlight("c", ["int main(void) {", "return 0", "}"])', 'c highlighting with a lines array');

eval_ok('$highlighter->highlight("perl", "print qq[Hello, World!\\n];", {})', 'perl highlighting with callbacks');

eval_ok('$highlighter->precompile("precompiled.hrcc")', 'precompile configuration (creates file precompiled.hrcc)');

sub eval_ok
{
  my($code, $name) = @_;
  eval($code);
  print STDERR "\n" . $@ if $@;
  $@ ? fail($name) : pass($name);
}
