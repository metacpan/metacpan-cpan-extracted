use lib 't/lib';
use strict;
use warnings;

use Test::More;

BEGIN {
    eval "use Test::WWW::Selenium;";
    if (my $e = $@) {
	plan skip_all => "Test::WWW::Selenium is required";
    }
}

use URI::file;
use Time::HiRes qw( sleep );
use FileTempTFH;
use TAP::Harness;
use TAP::Formatter::HTML;

my $sel_rc_port = $ENV{SELENIUM_RC_PORT} || 4446;
my $sel_speed   = $ENV{SELENIUM_SPEED};
#my $sel_rc_args = "-singleWindow -port $sel_rc_port";
#my $sel_rc      = Alien::SeleniumRC::Server->new( $sel_rc_args );
#$sel_rc->start;

my $tmp        = FileTempTFH->new;
my $output_uri = URI::file->new( $tmp->filename );

my $sel;
eval {
    $sel = Test::WWW::Selenium
      ->new( host => "localhost",
	     port => $sel_rc_port,
	     browser => "*firefox",
	     browser_url => $output_uri,
	     default_names => 1 );
};
if (my $e = $@) {
    plan skip_all => "Couldn't connect to SeleniumRC on $sel_rc_port: " .
      "try 'sudo perl t/selenium/server.pl'";
}

plan 'no_plan';

# generate some test output:
my $f     = TAP::Formatter::HTML->new({ silent => 1, output_fh => $tmp, force_inline_css => 0 });
my $h     = TAP::Harness->new({ merge => 1, formatter => $f });
my @tests = glob( 't/data/*.pl' );
$h->runtests(@tests);

my $crappy_wait_time = 0.450;

$sel->open_ok($output_uri);
$sel->wait_for_page_to_load_ok(5000);
my $loc = $sel->get_location;

$sel->set_speed( $sel_speed ) if $sel_speed;

# test summary
{
    $sel->text_is("//div[\@id='summary']/a", 'FAILED', 'summary text' );
    $sel->hi_click_ok("//div[\@id='summary']/a", 'click summary link' );
    $sel->location_is($loc, "click summary link shouldn't change location");
}

# test show/hide failed:
{
    # TODO: check for visible sections:
    $sel->is_visible_ok("//tr[\@id='t-data-01-pass-pl']", '01_pass visible');
    $sel->is_visible_ok("//tr[\@id='t-data-02-fail-pl']", '02_fail visible');

    $sel->hi_click_ok("link=show failed");
    sleep( $crappy_wait_time );
    ok( !$sel->is_visible("//tr[\@id='t-data-01-pass-pl']"), '01_pass now hidden' );
    $sel->is_visible_ok("//tr[\@id='t-data-02-fail-pl']", '02_fail still visible');

    $sel->hi_click_ok("link=show all");
    sleep( $crappy_wait_time );
    $sel->is_visible_ok("//tr[\@id='t-data-01-pass-pl']", '01_pass visible again');
    $sel->is_visible_ok("//tr[\@id='t-data-02-fail-pl']", '02_fail still visible');
}

$sel->open_ok($output_uri);
$sel->wait_for_page_to_load_ok(5000);

# test for 01_pass
{
    $sel->attribute_is("//li[\@id='t0']\@class", "tst k");
    $sel->attribute_is("//a[contains(\@href, '#t0')]/..\@class", "k p");
    $sel->attribute_is("//li[\@id='t3']\@class", "tst t");
    $sel->attribute_is("//a[contains(\@href, '#t3')]/..\@class", "t p");
    $sel->attribute_is("//li[\@id='t5']\@class", "tst s");
    $sel->attribute_is("//a[contains(\@href, '#t5')]/..\@class", "s p");
    $sel->is_element_present_ok("//tr[\@id='t-data-01-pass-pl']/td/div/ul/li[\@class='cmt']");
    $sel->is_element_present_ok("//tr[\@id='t-data-01-pass-pl']/td/div/ul/li[\@class='pln']");

    # show test detail
    ok( !$sel->is_visible("//tr[\@id='t-data-01-pass-pl']/td/div[\@class='test-detail']"),
	'01_pass detail hidden' );
    $sel->hi_click_ok("link=t/data/01_pass.pl");
    sleep( $crappy_wait_time );
    $sel->is_visible_ok
      ("//tr[\@id='t-data-01-pass-pl']/td/div[\@class='test-detail']",
       '01_pass detail now visible' );

    # hide test detail
    $sel->hi_click_ok("link=t/data/01_pass.pl");
    sleep( $crappy_wait_time );
    ok( !$sel->is_visible("//tr[\@id='t-data-01-pass-pl']/td/div[\@class='test-detail']"),
	'01_pass detail hidden again' );
}

# test 02_fail
{
    $sel->attribute_is("//li[\@id='t12']\@class", "tst n");
    $sel->attribute_is("//a[contains(\@href, '#t12')]/..\@class", "n f");
    $sel->is_element_present_ok("//tr[\@id='t-data-02-fail-pl']/td/div/ul/li[\@class='cmt']");
    $sel->is_element_present_ok("//tr[\@id='t-data-02-fail-pl']/td/div/ul/li[\@class='pln']");
    ok(!$sel->is_element_present("//tr[\@id='t-data-02-fail-pl']/td/div/ul[\@class='parse-errors']/li"),
       'no parse errors');
    ok(!$sel->is_visible("//tr[\@id='t-data-02-fail-pl']/td/div[\@class='test-detail']"),
       '02_fail detail hidden');

    # show & highlight a particular test
    $sel->hi_click_ok("//a[contains(\@href, '#t12')]");
    sleep( $crappy_wait_time );
#    $sel->attribute_is("//li[\@id='t12']\@style", "background-color: yellow;");
    $sel->is_visible_ok("//tr[\@id='t-data-02-fail-pl']/td[2]/div[\@class='test-detail']");

    # hide again
    $sel->hi_click_ok("link=t/data/02_fail.pl");
    sleep( $crappy_wait_time );
    ok(! $sel->is_visible("//tr[\@id='t-data-02-fail-pl']/td/div[\@class='test-detail']"),
      '02_fail detail hidden again');
}

# test 03_plan_fail
{
    $sel->attribute_is("//li[\@id='t18']\@class", "tst k unp");
    $sel->attribute_is("//a[contains(\@href, '#t18')]/..\@class", "k f");
    $sel->is_element_present_ok("//tr[\@id='t-data-03-plan-fail-pl']/td/div/ul/li[\@class='cmt']");
    $sel->is_element_present_ok("//tr[\@id='t-data-03-plan-fail-pl']/td/div/ul/li[\@class='pln']");
    $sel->is_element_present_ok("//tr[\@id='t-data-03-plan-fail-pl']/td/div/ul[\@class='parse-errors']/li");
    $sel->hi_click_ok("link=t/data/03_plan_fail.pl");
    sleep( $crappy_wait_time );
    $sel->is_visible_ok("//tr[\@id='t-data-03-plan-fail-pl']/td[2]/div[\@class='test-detail']");
}

# test 04_die_fail
{
    $sel->is_element_present_ok("//tr[\@id='t-data-04-die-fail-pl']/td/div/ul/li[\@class='cmt']");
    $sel->is_element_present_ok("//tr[\@id='t-data-04-die-fail-pl']/td/div/ul/li[\@class='pln']");
    $sel->is_element_present_ok("//tr[\@id='t-data-04-die-fail-pl']/td/div/ul/li[\@class='unk']");
    $sel->hi_click_ok("link=t/data/04_die_fail.pl");
    sleep( $crappy_wait_time );
}

# test 05_compile_fail
{
    $sel->is_element_present_ok("//tr[\@id='t-data-05-compile-fail-pl']/td/div/ul/li[\@class='cmt']");
    ok(! $sel->is_element_present("//tr[\@id='t-data-05-compile-fail-pl']/td/div/ul/li[\@class='pln']"),
       'no test plan' );
    $sel->is_element_present_ok("//tr[\@id='t-data-05-compile-fail-pl']/td/div/ul[\@class='parse-errors']/li");

    # show & highlight a particular test
    ok(! $sel->is_visible("//tr[\@id='t-data-05-compile-fail-pl']/td[2]/div[\@class='test-detail']"),
       '05_compile_fail detail hidden' );
    $sel->highlight_ok("//a[contains(\@title, 'No tests run!')]");
    $sel->hi_click_ok("//a[contains(\@title, 'No tests run!')]");
    sleep( $crappy_wait_time );
    $sel->location_is($loc);
    $sel->is_visible_ok("//tr[\@id='t-data-05-compile-fail-pl']/td[2]/div[\@class='test-detail']");

    # hide again
    $sel->hi_click_ok("link=t/data/05_compile_fail.pl");
    sleep( $crappy_wait_time );
    ok(! $sel->is_visible("//tr[\@id='t-data-05-compile-fail-pl']/td[2]/div[\@class='test-detail']"),
       '05_compile_fail detail hidden again' );
}

# test 06_skip_all
{
    $sel->is_element_present_ok("//tr[\@id='t-data-06-skip-all-pl']/td/div/ul/li[\@class='pln']");

    # show & highlight a particular test
    ok(! $sel->is_visible("//tr[\@id='t-data-06-skip-all-pl']/td[2]/div[\@class='test-detail']"),
       '06_skip_all detail hidden' );
    $sel->hi_click_ok("//tr[\@id='t-data-06-skip-all-pl']/td[\@class='results']//a");
    sleep( $crappy_wait_time );
    $sel->location_is($loc);
    $sel->is_visible_ok("//tr[\@id='t-data-06-skip-all-pl']/td[2]/div[\@class='test-detail']");

    # hide again
    $sel->hi_click_ok("link=t/data/06_skip_all.pl");
    sleep( $crappy_wait_time );
    ok(! $sel->is_visible("//tr[\@id='t-data-06-skip-all-pl']/td[2]/div[\@class='test-detail']"),
       '06_skip_all detail hidden again' );
}

# test 07_todo_pass
{
    $sel->attribute_is("//li[\@id='t25']\@class", "tst u");
    ok(! $sel->is_visible("//tr[\@id='t-data-07-todo-pass-pl']/td[2]/div[\@class='test-detail']"),
       '07_todo_pass detail hidden' );
    $sel->hi_click_ok("//a[contains(\@href, '#t25')]");
    sleep( $crappy_wait_time );
    $sel->is_visible_ok("//tr[\@id='t-data-07-todo-pass-pl']/td[2]/div[\@class='test-detail']");
}

# test 08_html_in_output
{
    $sel->hi_click_ok("//a[contains(\@href, '#t31')]");
    local $TODO = 'selenium returns this back to us w/HTML entities decoded';
    $sel->text_like("//li[\@id='t31']", qr/&lt;html&gt;/, 'embedded html' );
}

# test 09_skip_error
{
    $sel->hi_click_ok("link=t/data/09_skip_error.pl");
}

# test 11_lots_of_tests
{
    $sel->hi_click_ok("//a[contains(\@href, '#t519')]");
}


# Laziness
sub Test::WWW::Selenium::hi_click_ok {
    my ($self, $id, $msg) = @_;
    $self->highlight_ok($id, $msg);
    $self->click_ok($id, $msg);
}

