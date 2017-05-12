use strict;
use inc::Module::Install;

name('MooseX-WithCache');
all_from('lib/MooseX/WithCache.pm');

requires('Moose', '0.59');
requires('MooseX::Role::Parameterized');
requires('Cache::Memcached');
requires('Cache::FileCache');
requires('Data::Dumper');
requires('Digest::MD5');

test_requires 'IO::Socket::INET';
test_requires 'Test::More';
test_requires 'Test::Exception';

eval { require MooseX::WithCache };
if (! $@ && defined $MooseX::WithCache::VERSION && $MooseX::WithCache::VERSION <= 0.00005) {
    my $y_n = prompt("You have MooseX::WithCache <= 0.00005. This version breaks compatibility with the version ucrrently installed. Are you sure you want to continue with the installation?", "n");
    if ($y_n !~ /^y(?:es)?$/i) {
        exit 1;
    }
}

tests( 't/*.t t/*/*.t' );
WriteAll;
