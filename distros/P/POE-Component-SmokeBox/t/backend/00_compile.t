use strict;
use warnings;
use Test::More tests => 5;
use_ok('POE::Component::SmokeBox::Backend::Base');
use_ok('POE::Component::SmokeBox::Backend::CPAN::YACSmoke');
use_ok('POE::Component::SmokeBox::Backend::CPAN::Reporter');
use_ok('POE::Component::SmokeBox::Backend::CPANPLUS::YACSmoke');
use_ok('POE::Component::SmokeBox::Backend');
