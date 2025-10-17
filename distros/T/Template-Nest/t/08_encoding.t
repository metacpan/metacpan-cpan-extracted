use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Spec;
use lib '../lib';

use open qw(:std :utf8);
binmode(STDOUT, ':utf8');

use Test::More;
BEGIN { use_ok('Template::Nest') };

my $template_dir = File::Spec->catdir($Bin,'templates');

my $nest = Template::Nest->new(
    template_dir => $template_dir,
    template_ext => '.html',
    name_label => 'NAME',
    token_delims => ['<%','%>'],
    file_encoding => 'UTF-8',
);

my $template = {
    NAME => 'utf8-template',
    emoji => '🚀',
};

my $html = $nest->render( $template );
$html =~ s/\s+$//;
my $x_html = "Hello World! 🎉  🚀";

is( $html, $x_html, "unicode emoji not preserved after render" );

done_testing();
