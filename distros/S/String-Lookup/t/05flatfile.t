
BEGIN {				# Magic Perl CORE pragma
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = '../lib';
    }
}

use Test::More tests => 2 * ( 5 + 6 + 5 + 6 );
use strict;
use warnings;

# modules that we need
use String::Lookup;
use Encode qw( is_utf8 _utf8_on );

# initializations
my $foo= 'foo';
my $bar= 'bar';
_utf8_on($bar);
my $foobar= join ",", $foo, $bar;

# flush test logic
my $ok_list;
my $tag=      'test_tag';
my $filename= "$tag.lookup";
my @storage;

foreach (
    [ '.', undef, "from environment" ], 
    [ undef, '.', "from parameter" ], 
) {
    my ( $env, $param, $type )= @{$_};
    @storage= ( storage => 'FlatFile', tag => $tag );

    # set up
    $ENV{STRING_LOOKUP_FLATFILE_DIR}= $env;
    push @storage, ( dir => $param ) if $param;

    # set up the hash for flush at destruction
    do {
        tie my %hash, 'String::Lookup',
          @storage;
        ok( -e $filename, 'does the flat file exist' );
        is( $hash{ \$foo }, 1, "first lookup/flush" );
        is( $hash{ \$bar }, 2, "second lookup/flush" );
        is( -s $filename, 0, 'file right length before destruction' );
    };
    is( -s $filename, 20, 'file right length after destruction' );
    check_read("flush at destruction $type");

    # set up the hash for autoflush every id
    do {
        tie my %hash, 'String::Lookup',
          autoflush => 1,   # every new ID should flush
          @storage;
        ok( -e $filename, 'does the flat file exist' );
        is( $hash{ \$foo }, 1, "first lookup/flush" );
        is( -s $filename, 10, 'file right length after first lookup/flush' );
        is( $hash{ \$bar }, 2, "second lookup/flush" );
        is( -s $filename, 20, 'file right length after second lookup/flush' );
    };
    check_read("autoflush every id $type");
}

#-------------------------------------------------------------------------------
# read from flat file
sub check_read {
    my ($message)= @_;
    tie my %hash, 'String::Lookup', @storage;
    is( $hash{ \$foo }, 1, "$message: first lookup/flush" );
    ok( !is_utf8( $hash{1} ), "$message: first lookup was not utf8on" );
    is( $hash{ \$bar }, 2, "$message: second lookup/flush" );
    ok( is_utf8( $hash{2} ), "$message: second lookup was utf8on" );
    is( join( ",", keys %hash ), $foobar, "$message: are keys in right order" );
    ok( unlink($filename), "$message: remove flat file" );
}
#-------------------------------------------------------------------------------
