use strict;
use warnings;
use Test::More;    # Requires 0.94 as noted in Build.PL
use File::Temp qw[tempfile];
use Template::Liquid;
use Template::LiquidX::Tag::Include;
note 'chdir to ./t '
    . (chdir './t/' ? 'okay' : 'failed ' . $!)
    if !-d '_includes';

if (!-d '_includes') {
    diag 'Failed to find include directory';
    done_testing();
    exit 0;
}
#
like( Template::Liquid->parse(
           <<'INPUT')->render(), qr"Testing!\r?\n\n", 'Include static filename');
{%include 'testing.inc'%}
INPUT
like( Template::Liquid->parse(
        <<'INPUT')->render(include => 'testing.inc'), qr"Testing!\r?\n\n", 'Include dynamic filename');
{%include include%}
INPUT
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Undefined filenames cause error');
{%include missing%}
INPUT

EXPECTED
is( Template::Liquid->parse(
        <<'INPUT')->render(), <<'EXPECTED', 'Non existing filenames cause error');
{%include 'missing' %}
INPUT

EXPECTED

# I'm finished
done_testing();
