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


my %templates = (
    'table' => [ "rows" ],
    'tr' => [ 'cols' ],
    'td' => [ 'contents' ],
    'tr_default' => [ 'col1', 'cols' ],
    'nested_default_outer' => [
          'config.default2',
          'config.nested.iexist',
          'contents'
    ],
    'nested_default_contents' => [
          'config.default1',
          'config.default2',
          'config.nested.idontexist',
          'config.nested.iexist',
          'non_config_var',
          'ordinary_default'
    ]
);


for my $template (keys %templates){

    my $params = $nest->params( $template );

    is_deeply($params, $templates{$template}, "params in $template");

}


done_testing();



