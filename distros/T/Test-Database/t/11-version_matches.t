use strict;
use warnings;
use Test::More;
use Test::Database::Driver;
use version;

# test version_matches() on a dummy driver

my @requests;

my @ok = (
    {},
    { version     => '1.2.3' },
    { min_version => '1.2.2' },
    { min_version => '1.2.3' },
    { max_version => '1.3.0' },
    { version     => '1.2.3', min_version => '1.2.0' },
    { version     => '1.2.3', max_version => '1.4.3' },
    { min_version => '1.2.0', max_version => '2.0' },
    { version     => '1.2.3', min_version => '1.2.0', max_version => '2.0' },
    { regex_version => qr/^1\.2/ },
);

my @ok_beta
    = map { my %r = %$_; $r{version} = '1.2.3-beta' if $r{version}; \%r } @ok;
push @ok_beta, { regex_version => qr/beta/ };

my @not_ok = (
    { min_version   => '1.3.0' },
    { max_version   => '1.002' },
    { max_version   => '1.2.3' },
    { version       => '1.2.3-beta' },
    { version       => '1.3.4' },
    { min_version   => '1.3.0', max_version => '2.1' },
    { min_version   => '0.1.3', max_version => '1.002' },
    { regex_version => qr/^1\.2\.[1245]$/ },
    { regex_version => qr/^1\.2$/ },
);

my @not_ok_beta = map {
    my %r = %$_;
    $r{version} = '1.2.3' if $r{version} && $r{version} eq '1.2.3-beta';
    \%r
} @not_ok;

# define our dummy class
package Test::Database::Driver::Dummy;
our @ISA = qw( Test::Database::Driver );
sub _version { $_[0]{xxx} || '1.2.3' }

package main;
my $driver = bless {}, 'Test::Database::Driver::Dummy';
my $driver_beta = bless { xxx => '1.2.3-beta' },
    'Test::Database::Driver::Dummy';

plan tests => @ok + @not_ok + @ok_beta + @not_ok_beta;

for my $request (@ok) {
    ok( $driver->version_matches($request),
        to_string($request) . ' matches driver'
    );
}

for my $request (@not_ok) {
    ok( !$driver->version_matches($request),
        to_string($request) . ' does not match driver' );
}

for my $request (@ok_beta) {
    ok( $driver_beta->version_matches($request),
        to_string($request) . ' matches beta driver'
    );
}

for my $request (@not_ok_beta) {
    ok( !$driver_beta->version_matches($request),
        to_string($request) . ' does not match beta driver'
    );
}

sub to_string {
    my ($request) = @_;
    return
          '{ '
        . join( ', ', map {"$_ => $request->{$_}"} sort keys %$request )
        . ' }';
}

