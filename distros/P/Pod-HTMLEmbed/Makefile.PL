use inc::Module::Install;
name 'Pod-HTMLEmbed';
all_from 'lib/Pod/HTMLEmbed.pm';

requires 'Any::Moose' => '0.10';
requires 'Carp::Clan';
requires 'Pod::Simple::Search';
requires 'Pod::Simple::XHTML';
requires 'HTML::TreeBuilder';
requires 'URI::Escape';
requires 'HTML::Entities';
requires 'List::Util';

test_requires 'Test::More' => '0.88';
author_tests('xt');

auto_include;
auto_set_repository;

if (author_context) {
    # gfx++
    # repeat testing
    # see also ExtUtils::MM_Any::test_via_harness()
    my $test_moose = q{$(FULLPERLRUN) -MExtUtils::Command::MM -e}
                    .q{ "do 't/force-moose.pl'; }
                    .q{test_harness($(TEST_VERBOSE), '$(INST_LIB)', '$(INST_ARCHLIB)')"}
                    .q{ $(TEST_FILES)} . "\n";

    postamble qq{test_dynamic :: moose\n\n}
            . qq{moose ::\n}
            . qq{\t} . $test_moose;
}

WriteAll;
