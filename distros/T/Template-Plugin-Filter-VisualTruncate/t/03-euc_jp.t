use Test::Base;
use Template;
use Encode;

plan tests => 16;

use_ok('Template::Plugin::Filter::VisualTruncate');

my $tt = Template->new({
    PLUGINS => {
        VisualTruncate => 'Template::Plugin::Filter::VisualTruncate'
    }
});

ok($tt);
ok(UNIVERSAL::isa($tt, 'Template'));
ok($tt->process(\'[% USE VisualTruncate \'euc-jp\' %]'));

sub default_sanitize {
    my $input = $_[0];
    my $output;

    Encode::from_to($input, 'utf8', 'euc-jp', 1);

    $tt->process(\$input, undef, \$output);
    return $output;
}

spec_file('t/test_base_spec.txt');

filters('default_sanitize');
run_is 'input' => 'expected';
