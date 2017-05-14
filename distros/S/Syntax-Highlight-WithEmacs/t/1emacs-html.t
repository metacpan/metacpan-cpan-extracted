use strict;
use warnings;
use Test::More;
use Syntax::Highlight::WithEmacs;
use IPC::Run qw(run);
use Cwd;
require "t/start-emacs.pl";
require "t/basic-html.pl";

my $emacs = $ENV{EMACS} || 'emacs';
my $out = test_start_emacs($emacs);

plan tests => 4;

diag $out =~ /(\w+\s?emacs\s+\d+(?:\.\d+)*)/i ? $1 : "unkown Emacs version";

my $cwd = getcwd;

my $hl = Syntax::Highlight::WithEmacs->new(
    use_client => 0,
    emacs_cmd => $emacs,
    emacs_args => [-q => -eval => qq((add-to-list 'load-path "$cwd"))]
   );
basic_html_tests($hl);
