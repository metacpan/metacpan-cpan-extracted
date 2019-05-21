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
    token_delims => ['<%','%>'],
    defaults_namespace_char => '',
    escape_char => '\\',
    die_on_bad_params => 1
);

# escape_char = \

my $x_html = '<div><%imescaped%></div><div></div><div>\</div>';
my $html = $nest->render({ NAME => 'escapes'});
$html =~ s/\s*//g;
is ($html,$x_html,'escape_char=\ template escape_char=\ No params');

$x_html = '<div><%imescaped%></div><div>2</div><div>\3</div>';
$html = $nest->render({ 
    NAME => 'escapes',
    imnotescaped => '2',
    neitherami => '3'
});
$html =~ s/\s*//g;

is( $html, $x_html, 'escape_char=\ template escape_char=\ Good params');

eval {
    $nest->render({
        NAME =>  'escapes',
        imescaped => '1',
        imnotescaped => '2',
        neitherami => '3'
    });
};

like( $@, qr/imescaped.*?does not exist/, 'escape char=\ template escape char=\ Bad params' );

$x_html = "<div>E1</div><div>2</div><div>EE3</div>";
$html = $nest->render({
    NAME => 'escapes_e',
    imescaped => '1',
    imnotescaped => '2',
    neitherami => '3'
});
$html =~ s/\s*//g;
is( $html, $x_html, 'escape_char=\ template escape_char=E with params');




# escape_char=E

$nest->escape_char( 'E' );

$x_html = '<div><%imescaped%></div><div></div><div>E</div>';
$html = $nest->render({ NAME => 'escapes_e'});
$html =~ s/\s*//g;
is ($html,$x_html,'escape_char=E template escape_char=E No params');

$x_html = '<div><%imescaped%></div><div>2</div><div>E3</div>';
$html = $nest->render({ 
    NAME => 'escapes_e',
    imnotescaped => '2',
    neitherami => '3'
});
$html =~ s/\s*//g;

is( $html, $x_html, 'escape_char=E template escape_char=E Good params');

eval {
    $nest->render({
        NAME =>  'escapes_e',
        imescaped => '1',
        imnotescaped => '2',
        neitherami => '3'
    });
};

like( $@, qr/imescaped.*?does not exist/, 'escape char=E template escape char=E Bad params' );

$x_html = "<div>\\1</div><div>2</div><div>\\\\3</div>";
$html = $nest->render({
    NAME => 'escapes',
    imescaped => '1',
    imnotescaped => '2',
    neitherami => '3'
});
$html =~ s/\s*//g;

is( $html, $x_html, 'escape_char=E template escape_char=\ with params');

done_testing();
