use 5.10.0;
use strict;
use warnings;

use File::Temp 'tempdir';
use Test::More;
use Test::Differences;
use Path::Tiny;
use IPC::System::Simple 'capture';
use syntax 'qi';
use String::Cushion;
use Stenciller;
use Stenciller::Plugin::ToMojoliciousTest;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

my $stenciller = Stenciller->new(filepath => 't/corpus/01-test.stencil');

is $stenciller->count_stencils, 1, 'Found stencils';

my $transformed = $stenciller->transform(
                                    plugin_name => 'ToMojoliciousTest',
                                    constructor_args => {
                                        template => 't/corpus/01-test.template',
                                    },
                                );

eq_or_diff $transformed, result(), 'Mojolicious test created';

my $tempdir = path(tempdir());
$tempdir->child('01-test.t')->spew_utf8($transformed);

chmod 0755, $tempdir->child('01-test.t')->stringify;

my $output = capture($^X, $tempdir->child('01-test.t')->stringify);
eq_or_diff $output, test_result(), 'Correct result from running created test';


done_testing;

sub result {
    return cushion 0, 2, qi{
        use 5.10.0;
        use strict;
        use warnings;
        use Test::More;
        use Test::Warnings;
        use Test::Mojo::Trim;
        use Mojolicious::Lite;

        use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

        my $test = Test::Mojo::Trim->new;


        # test from line 1 in 01-test.stencil

        my $expected_01_test_1 = qq{    <a href="http://www.example.com/">Example</a>
    <form action="/01_test_1"></form>};

        get '/01_test_1' => '01_test_1';

        $test->get_ok('/01_test_1')->status_is(200)->trimmed_content_is($expected_01_test_1, 'Matched trimmed content in 01-test.stencil, line 1');

        done_testing();

        __DATA__

        @@ 01_test_1.html.ep

            %= link_to 'Example', 'http://www.example.com/'

            %= form_for '01_test_1'

    };
}

sub test_result {

    return cushion 0, 1, qi{
        ok 1 - GET /01_test_1
        ok 2 - 200 OK
        ok 3 - Matched trimmed content in 01-test.stencil, line 1
        ok 4 - no (unexpected) warnings (via done_testing)
        1..4
        };
}
