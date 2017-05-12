use inc::Module::Install;

name           'Task-Business-AU';
all_from       'lib/Task/Business/AU.pm';
build_requires 'Test::More'                => '0.42';
build_requires 'File::Spec'                => '0.80';

# Business Numbers
requires       'Business::AU::ABN'         => '1.05';
requires       'Business::AU::ACN'         => '0.28';
requires       'Business::AU::TFN'         => '0.1';

# Date and Time
requires       'Date::Holidays::AU'        => '0.04';

# SMS Sending
requires       'SMS::Send'                 => '0.03';
requires       'SMS::Send::AU::MyVodafone' => '0.02';

WriteAll;
