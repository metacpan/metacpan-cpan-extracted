# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SWISH-Filter.t'

use Test::More tests => 3;
BEGIN { use_ok('SWISH::Filter') }

diag("testing SWISH::Filter version $SWISH::Filter::VERSION");

#
#   we can't test actual filtering since it relies on many other apps
#   but we can test that our modules load and look for those other apps
#

diag("running the example script");
my $sep = $^O =~ /Win32/ ? '\\' : '/';
my $files = "t${sep}test.*";
if ($^O eq 'MSWin32') {
    $files = join(' ', glob($files));
}
ok(run("$^X example${sep}swish-filter-test --quiet --noskip_binary $files"), "example docs");
ok(
    run(
        "$^X example${sep}swish-filter-test --quiet --noskip_binary --ignore XLtoHTML --ignore pp2html $files"
       ),
    "example docs using catdoc"
  );

sub run
{
    diag(@_);
    system(@_) ? 0 : 1;
}
