use strict;
use warnings;
use Test::Most;
use Devel::Hide qw(Convert::Color::XTerm);
use Syntax::Highlight::WithEmacs;
use IPC::Run qw(run);
use Cwd;
require "t/start-emacs.pl";

my $emacs = $ENV{EMACS} || 'emacs';
test_start_emacs($emacs);

plan tests => 1;

my $cwd = getcwd;

my $hl = Syntax::Highlight::WithEmacs->new(
    use_client => 0,
    emacs_cmd  => $emacs,
    emacs_args => [-q => -eval => qq((add-to-list 'load-path "$cwd"))],
   );

my $sample = q{local %ENV};

throws_ok { $hl->ansify_string($sample, 'pl', color_depth => 256); } qr/Convert::Color::XTerm is required/, 'runtime module error';
