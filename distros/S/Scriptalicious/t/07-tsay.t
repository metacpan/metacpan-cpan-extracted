#  -*- perl -*-

use strict;
use warnings;

use Test::More tests => 2;

use Scriptalicious;

$ENV{PERL5LIB} = join ":", "lib", split ":", ($ENV{PERL5LIB} || "");

SKIP: {
    eval 'use Template';
    if ( $@ ) {
	skip "Template not installed", 1;
    }

    my $output = capture($^X, "t/tsay.pl");
    is($output, "Hello, Bernie
tsay.pl: Yo momma's so fat your family portrait has stretchmarks.", "Template say");
}

$ENV{PERL5LIB} = join ":", "t/missing", split ":", ($ENV{PERL5LIB} || "");
delete $ENV{PERL5OPT};

my $output = capture($^X, "t/tsay.pl");
my $expected = <<'EOM';
tsay.pl: warning: failed to include YAML; not able to load config
tsay.pl: warning: install Template Toolkit for prettier messages
tsay.pl: ----- Template `hello' -----
Hello, [% name %]
[% INCLUDE yomomma -%]
tsay.pl: ------ Template variables ------
$x = {
       'name' => 'Bernie'
     };
tsay.pl: -------- end of message --------
EOM
chomp($expected);

is($output, $expected, "no Template say");
