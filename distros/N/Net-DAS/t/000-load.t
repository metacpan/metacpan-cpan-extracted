#!/usr/bin/perl -w

use Test::More tests => 16;

BEGIN {
    use_ok('Module::Load');
    use_ok('IO::Socket');
    use_ok('IO::Socket::INET');
    use_ok('Time::HiRes');
    use_ok('Net::DAS');
    use_ok('Net::DAS::EU');
    use_ok('Net::DAS::BE');
    use_ok('Net::DAS::NO');
    use_ok('Net::DAS::LT');
    use_ok('Net::DAS::UK');
    use_ok('Net::DAS::SI');
    use_ok('Net::DAS::IT');
    use_ok('Net::DAS::GENT');
    use_ok('Net::DAS::SE');
    use_ok('Net::DAS::NU');
    use_ok('Net::DAS::RO');
}

exit 0;
