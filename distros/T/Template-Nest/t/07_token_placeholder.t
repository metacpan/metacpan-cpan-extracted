use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use lib '../lib';

use Test::More;

BEGIN { use_ok('Template::Nest') }

my $template_dir = File::Spec->catdir($Bin, 'templates');

my $nest = Template::Nest->new(
    template_dir => $template_dir,
    template_ext => '.html',
    token_delims => ['<!--%','%-->'],
    token_placeholder => "[MISSING_TOKEN]"
);

# Testing basic replacement of missing token
my $table = {
    NAME => 'table',
};

my $html = $nest->render( $table );
$html =~ s/\s//gs;

my $x_html = '<table>[MISSING_TOKEN]</table>';

is($html, $x_html, "Basic missing token replacement with default placeholder");

# Testing replacement with param_name
$nest->token_placeholder("[MISSING_TOKEN] <!--% param_name %-->");

$html = $nest->render( $table );
$html =~ s/\s//gs;

$x_html = '<table>[MISSING_TOKEN]rows</table>';


is($html, $x_html, "Missing token with param name inclusion in placeholder");

# Testing with param_name surrounded by text
$nest->token_placeholder("PUT <!--% param_name %--> HERE");

$html = $nest->render( $table );
$html =~ s/\s//gs;

$x_html = '<table>PUTrowsHERE</table>';


is($html, $x_html, "Missing token with surrounding text in placeholder");

# Testing with multiple unfilled params
$table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            #no contents
        }
    },{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            #no contents
        }
    }]
};

$nest->token_placeholder("PUT <!--% param_name %--> HERE");

$html = $nest->render( $table );
$html =~ s/\s//gs;

$x_html = '<table><tr><td>PUTcontentsHERE</td></tr><tr><td>PUTcontentsHERE</td></tr></table>';

is($html, $x_html, "Multiple missing tokens in nested structure");

done_testing();
