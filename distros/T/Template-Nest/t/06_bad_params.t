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
    die_on_bad_params => 1
);


my $table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr',
        cols => {
            NAME => 'tr',
            bad_param => 'stuff'
        }
    },{
        NAME => 'tr',
        cols => {
            NAME => 'td',
            #no contents
        }
    }]
};


eval{ $nest->render( $table ) };

like( $@, qr/bad_param.*?does not exist/, "error on bad params" );

$nest->die_on_bad_params(0);

my $x_html = "<table><tr><tr></tr></tr><tr><td></td></tr></table>";
my $html = $nest->render( $table );
$html =~ s/\s*//g;

is( $html, $x_html, "ignores bad param with die_on_bad_params = 0" );

done_testing();
