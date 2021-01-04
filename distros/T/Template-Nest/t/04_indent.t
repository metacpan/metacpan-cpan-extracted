use strict;
use warnings;
use FindBin qw($Bin);
use File::Spec;
use lib '../lib';

use Test::More;
BEGIN { use_ok('Template::Nest') };

my $template_dir = File::Spec->catdir($Bin,'templates');

my $nest = Template::Nest->new(
    template_dir => $template_dir,
    template_ext => '.html',
    name_label => 'NAME',
    token_delims => ['<!--%','%-->'],
    defaults_namespace_char => '',
    fixed_indent => 0
);

my $nest_sq = Template::Nest->new(
    template_dir => $template_dir,
    template_ext => '.html',
    name_label => 'NAME',
    token_delims => ['[%','%]'],
    defaults_namespace_char => '',
    fixed_indent => 0
);


my $table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            contents => '1'
        }
    },{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            contents => '2'
        }
    }]
};

my $table_sq = {
    NAME => 'table_sq',
    rows => [{
        NAME => 'tr_sq',
        cols => {
            NAME => 'td_sq',
            contents => '1'
        }
    },{
        NAME => 'tr_sq',
        cols => {
            NAME => 'td_sq',
            contents => '2'
        }
    }]
};


my $x_html = "<table>
    <tr>
    <td>
    1
</td>
</tr><tr>
    <td>
    2
</td>
</tr>
</table>";

my $html = $nest->render( $table );
my $html_sq = $nest_sq->render( $table_sq );

is( $html, $x_html, "fixed_indent = 0" );
is( $html_sq, $x_html, "fixed_indent = 0, square token delims" );

$nest->fixed_indent(1);
$nest_sq->fixed_indent(1);

$x_html = "<table>
    <tr>
        <td>
            1
        </td>
    </tr><tr>
        <td>
            2
        </td>
    </tr>
</table>";

$html = $nest->render( $table );
$html_sq = $nest_sq->render( $table_sq );

is( $html, $x_html, "fixed_indent = 1" );
is( $html_sq, $x_html, "fixed_indent = 1, square token delims");

done_testing();
