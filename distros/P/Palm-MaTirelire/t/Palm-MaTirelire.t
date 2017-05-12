# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Palm-MaTirelire.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 12;
BEGIN
{
    use_ok('Palm::MaTirelire');

    use_ok('Palm::MaTirelire::DBItem');
    use_ok('Palm::MaTirelire::DBItemId');

    use_ok('Palm::MaTirelire::AccountsV1');
    use_ok('Palm::MaTirelire::AccountsV2');
    use_ok('Palm::MaTirelire::Currencies');
    use_ok('Palm::MaTirelire::Descriptions');
    use_ok('Palm::MaTirelire::ExternalCurrencies');
    use_ok('Palm::MaTirelire::Modes');
    use_ok('Palm::MaTirelire::SavedPreferences');
    use_ok('Palm::MaTirelire::Types');

    use_ok('Palm::MaTirelire::CGICLI');
};

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
