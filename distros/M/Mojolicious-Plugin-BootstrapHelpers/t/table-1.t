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



# test from line 1 in table-1.stencil

my $expected_table_1_1 = qq{    <table class="table">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>};

get '/table_1_1' => 'table_1_1';

$test->get_ok('/table_1_1')->status_is(200)->trimmed_content_is($expected_table_1_1, 'Matched trimmed content in table-1.stencil, line 1');

# test from line 45 in table-1.stencil

my $expected_table_1_45 = qq{    <table class="table table-condensed table-hover table-striped">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>};

get '/table_1_45' => 'table_1_45';

$test->get_ok('/table_1_45')->status_is(200)->trimmed_content_is($expected_table_1_45, 'Matched trimmed content in table-1.stencil, line 45');

# test from line 89 in table-1.stencil

my $expected_table_1_89 = qq{    <div class="panel panel-success">
        <div class="panel-heading">
            <h3 class="panel-title">Heading Table 4</h3>
        </div>
        <table class="table table-condensed" id="the-table">
            <thead>
                <tr>
                    <th>th 1</th>
                    <th>th 2</th>
            </thead>
            <tbody>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
            </tbody>
        </table>
    </div>};

get '/table_1_89' => 'table_1_89';

$test->get_ok('/table_1_89')->status_is(200)->trimmed_content_is($expected_table_1_89, 'Matched trimmed content in table-1.stencil, line 89');

# test from line 140 in table-1.stencil

my $expected_table_1_140 = qq{    <table class="table">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>};

get '/table_1_140' => 'table_1_140';

$test->get_ok('/table_1_140')->status_is(200)->trimmed_content_is($expected_table_1_140, 'Matched trimmed content in table-1.stencil, line 140');

# test from line 181 in table-1.stencil

my $expected_table_1_181 = qq{    <table class="table table-condensed table-hover table-striped">
        <thead>
            <tr>
                <th>th 1</th>
                <th>th 2</th>
        </thead>
        <tbody>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
            <tr>
                <td>Cell 1</td>
                <td>Cell 2</td>
            </tr>
        </tbody>
    </table>};

get '/table_1_181' => 'table_1_181';

$test->get_ok('/table_1_181')->status_is(200)->trimmed_content_is($expected_table_1_181, 'Matched trimmed content in table-1.stencil, line 181');

# test from line 221 in table-1.stencil

my $expected_table_1_221 = qq{    <div class="panel panel-default">
        <div class="panel-heading">
            <h3 class="panel-title">Heading Table 3</h3>
        </div>
        <table class="table table-condensed table-hover table-striped">
            <thead>
                <tr>
                    <th>th 1</th>
                    <th>th 2</th>
            </thead>
            <tbody>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
                <tr>
                    <td>Cell 1</td>
                    <td>Cell 2</td>
                </tr>
            </tbody>
        </table>
    </div>};

get '/table_1_221' => 'table_1_221';

$test->get_ok('/table_1_221')->status_is(200)->trimmed_content_is($expected_table_1_221, 'Matched trimmed content in table-1.stencil, line 221');

done_testing();

__DATA__

@@ table_1_1.html.ep

    <%= table begin %>

        <thead>

            <tr>

                <th>th 1</th>

                <th>th 2</th>

        </thead>

        <tbody>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

        </tbody>

    <% end %>

@@ table_1_45.html.ep

    %= table hover, striped, condensed, begin

        <thead>

            <tr>

                <th>th 1</th>

                <th>th 2</th>

        </thead>

        <tbody>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

        </tbody>

    %  end

@@ table_1_89.html.ep

    %= table 'Heading Table 4', panel => { success }, condensed, id => 'the-table', begin

            <thead>

                <tr>

                    <th>th 1</th>

                    <th>th 2</th>

            </thead>

            <tbody>

                <tr>

                    <td>Cell 1</td>

                    <td>Cell 2</td>

                </tr>

                <tr>

                    <td>Cell 1</td>

                    <td>Cell 2</td>

                </tr>

            </tbody>

    %  end

@@ table_1_140.html.ep

    <%= table begin %>

        <thead>

            <tr>

                <th>th 1</th>

                <th>th 2</th>

        </thead>

        <tbody>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

        </tbody>

    <% end %>

@@ table_1_181.html.ep

    %= table hover, striped, condensed, begin

        <thead>

            <tr>

                <th>th 1</th>

                <th>th 2</th>

        </thead>

        <tbody>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

        </tbody>

    %  end

@@ table_1_221.html.ep

    %= table 'Heading Table 3', hover, striped, condensed, begin

        <thead>

            <tr>

                <th>th 1</th>

                <th>th 2</th>

        </thead>

        <tbody>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

            <tr>

                <td>Cell 1</td>

                <td>Cell 2</td>

            </tr>

        </tbody>

    %  end

