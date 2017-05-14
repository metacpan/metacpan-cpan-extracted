use strict;
use warnings;
use Test::More;
use Syntax::Highlight::WithEmacs;
use IPC::Run qw(run);
use Cwd;
require "t/start-emacs.pl";

my $emacs = $ENV{EMACS} || 'emacs';
test_start_emacs($emacs);

my $emacsclient = $ENV{GNUCLIENT} || 'emacsclient';
my ($fail, $err) = test_start_client($emacsclient);

my $use_client = !$fail && $err =~ /-batch/;
diag 'using client: '.($use_client ? 'yes' : 'no');

plan tests => 8;

my $cwd = getcwd;

my $hl = Syntax::Highlight::WithEmacs->new(
    use_client => $use_client,
    emacs_cmd  => $emacs,
    client_cmd => $emacsclient,
    emacs_args => [-q => -eval => qq((add-to-list 'load-path "$cwd"))],
    ansi_opts  => +{
	italic_as => 3
       },
   );

my $fgcol2 = qr/38;2;\d{1,3};\d{1,3};\d{1,3}/;
my $bgcol2 = qr/48;2;\d{1,3};\d{1,3};\d{1,3}/;

my $sample1 = q{my $x = 42;};
my $res1 = qr/^\e\[0;(${fgcol2})mmy\e\[0m (?|\$\e\[0;(${fgcol2})m|\e\[0;(${fgcol2})m\$)x\e\[0m = 42;$/;

my $ansi1 = $hl->ansify_string($sample1, 'pl');
like($ansi1, $res1); ##### 1 #####

SKIP: {
    skip 'failed', 1 unless
	$ansi1 =~ $res1;

    isnt($1, $2, 'different colors'); ##### 2 #####
}

my %same_color1 = (color => '#c0ffee');
my %same_color2 = (color => '#ffee00');
my %custom_css = (
    '.type'	     => \%same_color1,
    '.keyword'	     => \%same_color1,
    '.variable-name' => \%same_color2,
    '.cperl-hash'    => \%same_color2
   );
my $res1_css = qr/^\e\[0;38;2;192;255;238mmy\e\[0m \$?\e\[0;38;2;255;238;0m\$?x\e\[0m = 42;$/;

my $ansi1_css = $hl->ansify_string($sample1, 'pl', css => \%custom_css);
like($ansi1_css, $res1_css, 'custom css'); ##### 3 #####

my $sample2 = q{local %ENV};
my $res2 = qr/^\e\[0;${fgcol2}mlocal\e\[0m (?|%\e\[0;${fgcol2};4m|\e\[0;1;3;${fgcol2};${bgcol2}m%)ENV$/;

my $ansi2 = $hl->ansify_string($sample2, 'pl');
like($ansi2, $res2); ##### 4 #####

sub fbterm_color {
    use Carp;
    my ($is_background, $index, $invalid) = @_;

    if (defined $invalid) { carp "fbterm doesn't support 24bit color index" }

    unless (defined $index) { "\e[0m" }
    elsif ($is_background) { "\e[2;$index}" }
    elsif (defined $is_background) { "\e[1;$index}" }
    else { "\e[0m" }
}

SKIP: {
    skip 'Convert::Color::XTerm not installed', 4 unless
	eval "use Convert::Color::XTerm; 1";

    my $ansi2b = $hl->ansify_string($sample2, 'pl', color_depth => 256, css => \%custom_css);
    like($ansi2b, qr/^\e\[0;38;5;159mlocal\e\[0m %?\e\[0;38;5;11(?:;4)?m%?ENV$/, '256 color'); ##### 5 #####

    my $ansi2c = $hl->ansify_string($sample2, 'pl', color_depth => 16, css => \%custom_css);
    like($ansi2c, qr/^\e\[0;37mlocal\e\[0m %?\e\[0;93(?:;4)?m%?ENV$/, '16 color'); ##### 6 #####

    my $ansi2d = $hl->ansify_string($sample2, 'pl', color_depth => 8, css => \%custom_css);
    like($ansi2d, qr/^\e\[0;37mlocal\e\[0m %?\e\[0;33(?:;4)?m%?ENV$/, '8 color'); ##### 7 #####

    my $ansi2_fbterm = $hl->ansify_string($sample2, 'pl',
					  color_depth => 256,
					  css => \%custom_css,
					  color_format => \&fbterm_color);
    like($ansi2_fbterm, qr/^\e\[0m\e\[1;159}local\e\[0m\e\[0m %?\e\[0(;4)?m\e\[1;11}%?ENV$/, 'fbterm'); ##### 8 #####
}
