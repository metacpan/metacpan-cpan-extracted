use strict;
use warnings;
use inc::Module::Install;

name     'Podcast-ESLPodcast-Splitter';
author   'Yohei Yamaguchi <joker13meister@gmail.com>';
all_from 'lib/Podcast/ESLPodcast/Splitter.pm';

requires 'LWP::UserAgent';
requires 'XML::FeedPP';
requires 'MP3::Splitter';
requires 'Time::Piece';
requires 'List::MoreUtils';
requires 'Data::Dumper';

test_requires 'Test::More';
test_requires 'Test::Perl::Critic';

auto_install;
WriteAll;
