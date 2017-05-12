use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More qw/no_plan/;

use Data::Dumper;

use_ok('Postscript::HTML::Map');

my $ps2map = Postscript::HTML::Map->new({
    postscript  => "$FindBin::Bin/car-scale.ps",
    html_handler=> sub {
        my ($self, $element) = @_;

        $element->attr(href => 'javascript:alert("'.$self->comment.'");');

        return;
        },
    });

is(ref($ps2map) => 'Postscript::HTML::Map', 'Constructed a new object');
my $map = $ps2map->render();

is(ref($map) => 'HTML::Element', 'render returned a map');

my $generated = $ps2map->map->as_HTML(undef, '    ');
open(my $expected_fh, "<$FindBin::Bin/expected-scale.html");
my $expected = join '', <$expected_fh>;
close $expected_fh;

is($generated => $expected, 'HTML <map> was rendered as expected');
