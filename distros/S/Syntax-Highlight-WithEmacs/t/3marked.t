use strict;
use warnings;
use Test::More;
use Syntax::Highlight::WithEmacs;
use IPC::Run qw(run);
use Cwd;
require "t/start-emacs.pl";

my $emacs = $ENV{EMACS} || 'emacs';
test_start_emacs($emacs);

plan tests => 3;

my $cwd = getcwd;

my $hl = Syntax::Highlight::WithEmacs->new(
    use_client => 0,
    emacs_cmd => $emacs,
    emacs_args => [-q => -eval => qq((add-to-list 'load-path "$cwd"))]
   );

my $sample = q{local %ENV};
my $res = $hl->marked_string($sample, 'pl');

is(@$res, 3, 'tokenize');

my $path = $res->[0][0];
like($path, qr/^(?|keyword|type)$/, 'type of local');

my $want = $path eq 'keyword'
    ? [
	[ 'keyword',    'local' ],
	[ '',           ' '     ],
	[ 'cperl-hash', '%ENV'  ] ]
    : [
	[ 'type',                    'local' ],
	[ '',                        ' %'    ],
	[ 'underline variable-name', 'ENV'   ] ]
    ;

is_deeply($res, $want, 'struct');
