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
    defaults_namespace_char => ''
);


my $table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr_default',
        cols => {
            NAME => 'td',
            contents => 1
        }
    },{
        NAME => 'tr_default',
        cols => {
            NAME => 'td',
            contents => 2
        }
    }]
};

my $html = $nest->render( $table );

$html =~ s/\s//gs;
my $x_html = "<table><tr><td></td><td>1</td></tr><tr><td></td><td>2</td></tr></table>";

is( $html, $x_html, "defaults not set" );



$nest->defaults({ 'col1' => 'default' });

$html = $nest->render( $table );
$html =~ s/\s//gs;
$x_html = "<table><tr><td>default</td><td>1</td></tr><tr><td>default</td><td>2</td></tr></table>";

is( $html, $x_html, "non-namespaced defaults" );




$table = {
    NAME => 'table',
    rows => [{
        NAME => 'tr_default_ns',
        cols => {
            NAME => 'td',
            contents => 1
        }
    },{
        NAME => 'tr_default_ns',
        cols => {
            NAME => 'td',
            contents => 2
        }
    }]
};

$nest->defaults_namespace_char('.');


$html = $nest->render( $table );
$html =~ s/\s//gs;
$x_html = "<table><tr><td></td><td>1</td></tr><tr><td></td><td>2</td></tr></table>";

is( $html, $x_html, "namespaced, defaults not set" );


$nest->defaults({ 'default' => { col1 => 'default' } });

$html = $nest->render( $table );
$html =~ s/\s//gs;
$x_html = "<table><tr><td>default</td><td>1</td></tr><tr><td>default</td><td>2</td></tr></table>";

is( $html, $x_html, "namespaced defaults" );


$nest->defaults({
    ordinary_default => 'ORD',
    config => {
        default1 => 'CONF1',
        default2 => 'CONF2',
        default3 => 'CONF3',
        nested => {
            iexist => 'NEST1',
            metoo => 'NEST2'
        }
    }
});
    
        

my $page = {
    NAME => 'nested_default_outer',
    contents => {
        NAME => 'nested_default_contents',
        non_config_var => 'NONCONF'
    }
};


$html = $nest->render( $page );
$html =~ s/\s//gs;

$x_html = "<div>CONF2<span><h1>ORD</h1><div>CONF1</div><h4>NONCONF</h4><span>CONF2</span><h2>NEST1</h2><h3></h3></span><div>NEST1</div></div>";

is( $html, $x_html, "complex namespaced defaults" );


done_testing();
