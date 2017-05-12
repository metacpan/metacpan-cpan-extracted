use Mojo::Base -strict;

BEGIN {
    $ENV{'MOJO_NO_IPV6'} = 1;
    $ENV{'MOJO_REACTOR'} = 'Mojo::Reactor::Poll';
}

use Test::More;
use Mojolicious::Lite;
use Test::Mojo::Trim;

plugin 'BootstrapHelpers', {
    icons => {
        class => 'glyphicon',
        formatter => 'glyphicon-%s',
    },
};

ok 1;

my $test = Test::Mojo::Trim->new;



# test from line 1 in formgroup-1.stencil

my $expected_formgroup_1_1 = qq{    <div class="form-group">
        <label class="control-label" for="test_text">Text test 1</label>
        <input class="form-control" id="test_text" name="test_text" type="text" />
    </div>};

get '/formgroup_1_1' => 'formgroup_1_1';

$test->get_ok('/formgroup_1_1')->status_is(200)->trimmed_content_is($expected_formgroup_1_1, 'Matched trimmed content in formgroup-1.stencil, line 1');

# test from line 16 in formgroup-1.stencil

my $expected_formgroup_1_16 = qq{    <div class="form-group">
        <label class="control-label" for="test_text">Text test 2</label>
        <input class="form-control" id="test_text" name="test_text" size="30" type="text" />
    </div>};

get '/formgroup_1_16' => 'formgroup_1_16';

$test->get_ok('/formgroup_1_16')->status_is(200)->trimmed_content_is($expected_formgroup_1_16, 'Matched trimmed content in formgroup-1.stencil, line 16');

# test from line 28 in formgroup-1.stencil

my $expected_formgroup_1_28 = qq{    <div class="form-group">
        <label class="control-label" for="test-text">Text test 4</label>
        <input class="form-control input-lg" id="test-text" name="test_text" type="text" />
    </div>};

get '/formgroup_1_28' => 'formgroup_1_28';

$test->get_ok('/formgroup_1_28')->status_is(200)->trimmed_content_is($expected_formgroup_1_28, 'Matched trimmed content in formgroup-1.stencil, line 28');

# test from line 46 in formgroup-1.stencil

my $expected_formgroup_1_46 = qq{    <div class="form-group">
        <label class="control-label" for="test_text">Text test 5</label>
        <input class="form-control" id="test_text" name="test_text" type="text" value="200" />
    </div>};

get '/formgroup_1_46' => 'formgroup_1_46';

$test->get_ok('/formgroup_1_46')->status_is(200)->trimmed_content_is($expected_formgroup_1_46, 'Matched trimmed content in formgroup-1.stencil, line 46');

# test from line 61 in formgroup-1.stencil

my $expected_formgroup_1_61 = qq{    <form class="form-horizontal">
        <div class="form-group form-group-lg">
            <label class="control-label col-sm-2" for="test_text">Text test 6</label>
            <div class="col-sm-10">
                <input class="form-control" id="test_text" name="test_text" type="text">
            </div>
        </div>
    </form>};

get '/formgroup_1_61' => 'formgroup_1_61';

$test->get_ok('/formgroup_1_61')->status_is(200)->trimmed_content_is($expected_formgroup_1_61, 'Matched trimmed content in formgroup-1.stencil, line 61');

# test from line 83 in formgroup-1.stencil

my $expected_formgroup_1_83 = qq{    <div class="form-group">
        <label class="control-label" for="test_text"> Text test 7 </label>
        <input class="form-control input-xs" id="test_text" name="test_text" type="text" />
    </div>};

get '/formgroup_1_83' => 'formgroup_1_83';

$test->get_ok('/formgroup_1_83')->status_is(200)->trimmed_content_is($expected_formgroup_1_83, 'Matched trimmed content in formgroup-1.stencil, line 83');

# test from line 98 in formgroup-1.stencil

my $expected_formgroup_1_98 = qq{    <div class="form-group">
        <label class="control-label col-md-2 col-sm-4" for="test_text">Text test 8</label>
        <div class="col-md-10 col-sm-8">
            <input class="form-control" id="test_text" name="test_text" type="text" />
        </div>
    </div>};

get '/formgroup_1_98' => 'formgroup_1_98';

$test->get_ok('/formgroup_1_98')->status_is(200)->trimmed_content_is($expected_formgroup_1_98, 'Matched trimmed content in formgroup-1.stencil, line 98');

# test from line 117 in formgroup-1.stencil

my $expected_formgroup_1_117 = qq{    <div class="form-group">
        <input class="form-control" id="test-text-9" name="test_text_9" type="text" />
    </div>};

get '/formgroup_1_117' => 'formgroup_1_117';

$test->get_ok('/formgroup_1_117')->status_is(200)->trimmed_content_is($expected_formgroup_1_117, 'Matched trimmed content in formgroup-1.stencil, line 117');

# test from line 128 in formgroup-1.stencil

my $expected_formgroup_1_128 = qq{    <div class="form-group">
        <label class="control-label" for="atextarea">Text test 9</label>
        <textarea class="form-control" id="atextarea" name="atextarea">default text</textarea>
    </div>};

get '/formgroup_1_128' => 'formgroup_1_128';

$test->get_ok('/formgroup_1_128')->status_is(200)->trimmed_content_is($expected_formgroup_1_128, 'Matched trimmed content in formgroup-1.stencil, line 128');

done_testing();

__DATA__

@@ formgroup_1_1.html.ep

    %= formgroup 'Text test 1', text_field => ['test_text']

@@ formgroup_1_16.html.ep

    %= formgroup 'Text test 2', text_field => ['test_text', size => 30]

@@ formgroup_1_28.html.ep

    %= formgroup 'Text test 4', text_field => ['test-text', large]

@@ formgroup_1_46.html.ep

    %= formgroup 'Text test 5', text_field => ['test_text', '200' ]

@@ formgroup_1_61.html.ep

    <form class="form-horizontal">

        %= formgroup 'Text test 6', text_field => ['test_text'], large, cols => { small => [2, 10] }

    </form>

@@ formgroup_1_83.html.ep

    %= formgroup text_field => ['test_text', xsmall] => begin

        Text test 7

    %  end

@@ formgroup_1_98.html.ep

    %= formgroup 'Text test 8', text_field => ['test_text'], cols => { medium => [2, 10], small => [4, 8] }

@@ formgroup_1_117.html.ep

    %= formgroup text_field => ['test-text-9']

@@ formgroup_1_128.html.ep

    %= formgroup 'Text test 9', text_area => ['atextarea', 'default text']

