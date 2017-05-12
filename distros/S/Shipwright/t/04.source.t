use strict;
use warnings;

use Test::More;
use Shipwright::Test;
use Shipwright::Source;
use File::Spec::Functions qw/catfile/;

Shipwright::Test->init;

my %source = (
    'http://example.com/hello.tar.gz'           => 'HTTP',
    'ftp://example.com/hello.tar.gz'            => 'FTP',
    'svn:file:///home/sunnavy/svn/hello'        => 'SVN',
    'svk://local/hello'                         => 'SVK',
    'cpan:Acme::Hello'                          => 'CPAN',
    'cpan:S/SU/SUNNAVY/IP-QQWry-v0.0.15.tar.gz' => 'CPAN',
    'file:' . catfile( 't', 'hello', 'Acme-Hello-0.03.tar.gz' ) => 'Compressed',
    'dir:' . catfile( 't', 'hello' ) => 'Directory',
    'git:file:///home/sunnavy/git/hello'        => 'Git',
);

for ( keys %source ) {
    my $source = Shipwright::Source->new( source => $_ );
    isa_ok( $source, 'Shipwright::Source::Base', $_ );
    isa_ok( $source, 'Shipwright::Source::' . $source{$_}, $_ );
    if (/tar\.gz/) {
        ok( $source->is_compressed, "$_ is compressed" );
    }
    else {
        ok( !$source->is_compressed, "$_ is not compressed" );
    }
}

my @invalid_sources = ( '' );

for (@invalid_sources) {
    eval { my $source = Shipwright::Source->new( source => $_ ) };
    like( $@, qr/invalid source/, "$_ is invalid source" );
}

eval { my $source = Shipwright::Source->new };
like( $@, qr/need source arg/, 'new need source arg' );

done_testing;
