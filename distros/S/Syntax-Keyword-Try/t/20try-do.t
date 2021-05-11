#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use constant HAVE_WARN_EXPERIMENTAL => $] >= 5.018;

no if HAVE_WARN_EXPERIMENTAL, warnings => 'experimental';
use Syntax::Keyword::Try qw( try try_value );

no warnings 'deprecated';

# try do { } yields result
{
   is( try do { "result" } catch ($e) {},
       "result",
       'try do { } yields result' );
}

# try do { } failure returns catch
{
   is( try do { die "oops\n" } catch ($e) { "failure" },
       "failure",
       'try do { } yields catch result on failure' );
}

# stack discipline
{
   my @v = ( 1, [ 2, try do { 3 } catch ($e) {}, 4 ], 5 );
   is_deeply( \@v, [ 1, [ 2 .. 4 ], 5 ],
      'try do { } preserves stack discipline' ) or
         diag "Got ", explain \@v;
}

# list context
{
   my @v = try do { 1, 2, 3 } catch ($e) {};
   is_deeply( \@v, [ 1 .. 3 ],
      'try do can yield lists' );
}

# $@ localising
SKIP: {
   # RT124366
   skip "perls before 5.24 fail to lexicalise \$@ properly (RT124366)", 1 unless $] >= 5.024;

   eval { die "oopsie" };

   my $ret = try do { die "another failure" } catch ($e) {};
   like( $@, qr/^oopsie at /, '$@ after try do/catch' );
}

# Non-try do { ... } unaffected
{
   is( do { 1 + 2 }, 3,
      'Plain do { ... } unaffected' );
}

# try do syntax produces experimental and deprecated warnings
SKIP: {
   use if HAVE_WARN_EXPERIMENTAL, warnings => 'experimental';
   skip "No 'experimental' warnings category", 1 unless HAVE_WARN_EXPERIMENTAL;

   use warnings 'deprecated';

   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   eval "try do { 1 } catch (\$e) { 2 }" or die $@;

   like( $warnings, qr/^'try do' syntax is experimental/,
      'try do syntax produces experimental warnings' );
   like( $warnings, qr/^'try do' syntax is deprecated /m,
      'try do syntax produces deprecated warnings' );

   # warning can be disabled
   use Syntax::Keyword::Try qw( :experimental(try_value) );
   no warnings 'deprecated';

   $warnings = "";

   eval "try do { 3 } catch (\$e) { 4 }" or die $@;
   is( $warnings, "", 'no warnings when :experimental(try_value) is enabled' );
}

done_testing;
