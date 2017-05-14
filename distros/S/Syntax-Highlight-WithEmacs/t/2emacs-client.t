use strict;
use warnings;
use Test::More;
use Syntax::Highlight::WithEmacs;
use IPC::Run qw(run);
use Cwd;
require "t/start-emacs.pl";
require "t/basic-html.pl";

my $emacs = $ENV{EMACS} || 'emacs';
test_start_emacs($emacs);

my $emacsclient = $ENV{GNUCLIENT} || 'emacsclient';
my ($fail, $err) = test_start_client($emacsclient);
plan skip_all => "Emacsclient did not respond, cannot test" if $fail;


plan tests => 5;

SKIP: {
    skip 'unsupported emacsclient', 4 unless
	like($err, qr/-batch/, 'not lucid');

    my $cwd = getcwd;

    my $hl = Syntax::Highlight::WithEmacs->new(
	use_client => 1,
	emacs_cmd => $emacs,
	client_cmd => $emacsclient,
	emacs_args => [-q => -eval => qq((add-to-list 'load-path "$cwd"))]
       );
    basic_html_tests($hl);
}
