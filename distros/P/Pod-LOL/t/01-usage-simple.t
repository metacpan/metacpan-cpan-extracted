#!perl
use v5.26;    # Indented heredoc.
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

BEGIN {
    use_ok( 'Pod::LOL' ) || print "Bail out!\n";
}

diag( "Testing Pod::LOL $Pod::LOL::VERSION, Perl $], $^X" );

my @cases = (
    {
        name          => "Empty",
        expected_root => [],
        pod           => <<~POD,
      POD
    },
    {
        name          => "Head1-Para",
        expected_root => [
            [ "head1", "NAME" ],
            [
                "Para",
                "Example - Just an example"
            ],

        ],
        pod => <<~POD,
      =head1 NAME
      
      Example - Just an example
      
      =cut
      POD
    },
    {
        name          => "Head1-Para (no cut)",
        expected_root => [
            [ "head1", "NAME" ],
            [
                "Para",
                "Example - Just an example"
            ],

        ],
        pod => <<~POD,
      =head1 NAME
      
      Example - Just an example
      POD
    },
    {
        name          => "Head2",
        expected_root => [ [ "head2", "Function1" ], ],
        pod           => <<~POD,

      =head2 Function1
      
      =cut

      POD
    },
    {
        name          => "Head2-Para",
        expected_root => [ [ "head2", "Function1" ], [ "Para", "Summary" ], ],
        pod           => <<~POD,

      =head2 Function1
      
      Summary
      
      =cut

      POD
    },
    {
        name          => "Head2-Para-Verbatim",
        expected_root => [
            [ "head2",    "Function1" ],
            [ "Para",     "Summary" ],
            [ "Verbatim", " Desc" ],
        ],
        pod => <<~POD,

      =head2 Function1
      
      Summary
      
       Desc
      
      =cut

      POD
    },
);

my ( $fh, $file ) = tempfile( SUFFIX => ".pm" );

for my $case ( @cases ) {

    # Empty the tempfile.
    truncate $fh, 0;
    $fh->seek( 0, 0 );

    # Add some pod.
    print $fh $case->{pod};

    # Make at the beginning of the file.
    $fh->seek( 0, 0 );

    # Parse and compare
    is_deeply(
        Pod::LOL->new_root( $file ),
        $case->{expected_root},
        $case->{name},
    );
}

done_testing();

