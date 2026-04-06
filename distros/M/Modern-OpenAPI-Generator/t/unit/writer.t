use v5.26;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use Modern::OpenAPI::Generator::Writer;

my $root = tempdir( CLEANUP => 1 );

sub read_file {
    my ($rel) = @_;
    open my $fh, '<:encoding(UTF-8)', File::Spec->catfile( $root, $rel )
      or die $!;
    return do { local $/; <$fh> };
}

{
    my $w = Modern::OpenAPI::Generator::Writer->new(
        root  => $root,
        force => 0,
        merge => 0,
    );
    $w->write( 'a.txt', "first\n" );
    is( read_file('a.txt'), "first\n", 'write creates file' );
}

{
    my $w = Modern::OpenAPI::Generator::Writer->new(
        root  => $root,
        force => 0,
        merge => 1,
    );
    $w->write( 'a.txt', "second\n" );
    is( read_file('a.txt'), "first\n", 'merge skips existing without force' );
}

{
    my $w = Modern::OpenAPI::Generator::Writer->new(
        root  => $root,
        force => 1,
        merge => 1,
    );
    $w->write( 'a.txt', "third\n" );
    is( read_file('a.txt'), "third\n", 'force overwrites with merge' );
}

{
    my $w = Modern::OpenAPI::Generator::Writer->new(
        root  => $root,
        force => 0,
        merge => 0,
    );
    $w->write( 'b.txt', "x\n" );
    my $err = '';
    eval {
        $w->write( 'b.txt', "y\n" );
        1;
    } or $err = $@ || 'unknown';
    like( $err, qr/Refusing to overwrite/, 'no force without merge croaks' );
}

{
    my $err = '';
    eval {
        Modern::OpenAPI::Generator::Writer->new( root => $root )->write( '', 'x' );
        1;
    } or $err = $@ || '';
    like( $err, qr/empty rel/, 'empty rel croaks' );
}

done_testing;
