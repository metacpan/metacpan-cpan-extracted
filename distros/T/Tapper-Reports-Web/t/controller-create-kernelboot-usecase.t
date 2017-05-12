use strict;
use warnings;
use Test::More;
use Test::WWW::Mechanize::Catalyst;
use Data::Dumper;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;


BEGIN { use_ok 'Catalyst::Test', 'Tapper::Reports::Web' }
BEGIN { use_ok 'Tapper::Reports::Web::Controller::Tapper' }

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Tapper::Reports::Web');

$mech->{catalyst_debug} = 1;

$mech->get_ok('/tapper/start');
#$mech->page_links_ok('/tapper/start', 'All links on start page deliver HTTP/ok');

$mech->follow_link_ok({text => 'Create a new testrun'}, "Click on 'Create new testrun'");

$mech->get_ok('/tapper/testruns/create','Create form exists');

$mech->forms(0);
is(scalar($mech->find_all_inputs(name => 'use_case')), 1, 'First form on create_testrun is selection of use cases');


my $kernel_build;
# actually there is hardly a way for this test to fail because the
# controller only included the existing files in the first place
foreach my $form_element ( @{($mech->find_all_inputs(name => 'use_case'))[0]->{menu}} ) {
        ok(-e $form_element->{value}, 'Use case file '.$form_element->{value}.' exists');
        $kernel_build = $form_element->{value} if $form_element->{value} =~ /kernel_?reboot/;
}


$mech->submit_form(button => 'submit');
$mech->content_contains('This field is required', 'No form without use case accepted');

die "No kernelbuild use case found" unless $kernel_build;

$mech->submit_form(fields => {use_case => $kernel_build} , button => 'submit');
$mech->content_contains('Use case details', 'Form to fill out use case details loaded');
# if the content test fails, we need to know what page actually was shown
diag($mech->content) unless $mech->content() =~ /Use case details/;

$mech->forms(0);
$mech->submit_form(button => 'submit' );
$mech->content_like(qr|Testrun \d+.+</a>\s* created on host <strong>\w+</strong>\s* with precondition IDs|s, 'Testrun created');

done_testing();
