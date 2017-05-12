use strict;
use warnings;

use Test::More tests => 7;
use Shipwright::Test;
use Shipwright::Backend;

Shipwright::Test->init;

my %backend = (
    'svk:/test/foo'              => 'SVK',
    '//test/foo'                 => 'SVK',
    'svn:file:///test/foo'       => 'SVN',
    'svn://example.com/test/foo' => 'SVN',
);

for ( sort keys %backend ) {
    my $backend = Shipwright::Backend->new( repository => $_ );
    isa_ok( $backend, 'Shipwright::Backend::' . $backend{$_}, $_ );
}

my %invalid_backend = (
    'foo' => 'invalid repository',
    ''    => 'invalid repository',
);

for ( keys %invalid_backend ) {
    eval { my $backend = Shipwright::Backend->new( repository => $_ ) };
    like( $@, qr/$invalid_backend{$_}/, $invalid_backend{$_} );
}

eval { my $backend = Shipwright::Backend->new };
like( $@, qr/need repository arg/, 'new need repository arg' );

