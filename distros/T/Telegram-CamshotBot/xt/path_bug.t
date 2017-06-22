#!/usr/bin/env perl

use WWW::Telegram::BotAPI;
use Telegram::CamshotBot::Util qw(get_pm_from_mod abs_path_of_sample_mojo_conf);
use Regexp::Common qw /net/;

# print get_pm_from_mod('Dist::Zilla')."\n";
# print get_pm_from_mod('WWW::Telegram::BotAPI')."\n";
# print get_pm_from_mod('Telegram::CamshotBot')."\n";
# print abs_path_of_sample_mojo_conf('Telegram::CamshotBot')."\n";
# print 1;

my $a = 'rtsp://10.132.193.9//ch0.h264';

# my $a = '10.132.193.94';
my ($ip) = ($a =~ /($RE{net}{IPv4})/);
print $ip;

# print "Ok!\n";
