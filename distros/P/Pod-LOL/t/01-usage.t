#!perl
use v5.30;
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );
use feature qw( say );
use Mojo::Util qw( dumper );

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
   truncate $fh, 0;

   $fh->seek( 0, 0 );
   print $fh $case->{pod};
   $fh->seek( 0, 0 );

   my $parser = Pod::LOL->new;
   is_deeply(
      $parser->parse_file( $file )->root,
      $case->{expected_root},
      $case->{name},
   );
}

done_testing();

