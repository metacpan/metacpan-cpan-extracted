use strict;
use Test::More;
use MojoX::CustomTemplateFileParser;

my $parser = MojoX::CustomTemplateFileParser->new(path => 'corpus/test-1.mojo', output => ['Test']);

my $expected = q{
# Code here




#** test from test-1.mojo, line 4

my $expected_test_1_1 = qq{
    <a href="http://www.metacpan.org/">MetaCPAN</a>
};

get '/test_1_1' => 'test_1_1';

$test->get_ok('/test_1_1')->status_is(200)->trimmed_content_is($expected_test_1_1, 'Matched trimmed content in test-1.mojo, line 4');


#** test from test-1.mojo, line 15, loop: first

my $expected_test_1_2_first_first = qq{
    <input name="username" placeholder="first" type="text" />
};

get '/test_1_2_first' => 'test_1_2_first';

$test->get_ok('/test_1_2_first')->status_is(200)->trimmed_content_is($expected_test_1_2_first_first, 'Matched trimmed content in test-1.mojo, line 15, loop: first');


#** test from test-1.mojo, line 15, loop: name

my $expected_test_1_2_name_name = qq{
    <input name="username" placeholder="name" type="text" />
};

get '/test_1_2_name' => 'test_1_2_name';

$test->get_ok('/test_1_2_name')->status_is(200)->trimmed_content_is($expected_test_1_2_name_name, 'Matched trimmed content in test-1.mojo, line 15, loop: name');

done_testing();

__DATA__

@@ test_1_1.html.ep


    %= link_to 'MetaCPAN', 'http://www.metacpan.org/'


@@ test_1_2_first.html.ep


    %= text_field username => placeholder => 'first'


@@ test_1_2_name.html.ep


    %= text_field username => placeholder => 'name'

};

is $parser->to_test, $expected, 'Creates correct tests';


done_testing;
