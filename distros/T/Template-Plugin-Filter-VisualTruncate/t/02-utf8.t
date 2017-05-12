use Test::Base;
use Template;

plan tests => 23;

use_ok('Template::Plugin::Filter::VisualTruncate');
use_ok('Template::Plugin::Filter::VisualTruncate::UTF8');

my $tt = Template->new({
    PLUGINS => {
        VisualTruncate => 'Template::Plugin::Filter::VisualTruncate'
    }
});

ok($tt);
ok(UNIVERSAL::isa($tt, 'Template'));
ok($tt->process(\'[% USE VisualTruncate %]'));

sub default_sanitize {
    my $input = $_[0];
    my $output;
    $tt->process(\$input, undef, \$output);

    if (utf8::is_utf8($output)) {
        $output = 'INVALID';
    }

    return $output;
}

spec_file('t/test_base_spec.txt');

filters('default_sanitize');
run_is 'input' => 'expected';

{
    use utf8;
    my $text = "これは十文字ですよ。";
    ok( utf8::is_utf8($text) );
    my $truncated = Template::Plugin::Filter::VisualTruncate::UTF8->trim($text, 10);
    ok( utf8::is_utf8($truncated), 'utf8 flag');
    is( $truncated, "これは十文");
}

{
    use bytes;
    my $text = "これは十文字ですよ。";
    ok( !utf8::is_utf8($text) );
    my $truncated = Template::Plugin::Filter::VisualTruncate::UTF8->trim($text, 10);
    ok( !utf8::is_utf8($truncated), 'utf8 flag');
    is( $truncated, "これは十文");
}
