#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use constant HAVE_WARN_EXPERIMENTAL => $] >= 5.018;

no if HAVE_WARN_EXPERIMENTAL, warnings => 'experimental';
use Syntax::Keyword::Try qw( try try_value );

# try do { } yields result
{
   is( try do { "result" } catch {},
       "result",
       'try do { } yields result' );
}

# try do { } failure returns catch
{
   is( try do { die "oops\n" } catch { "failure" },
       "failure",
       'try do { } yields catch result on failure' );
}

# stack discipline
{
   my @v = ( 1, [ 2, try do { 3 } catch {}, 4 ], 5 );
   is_deeply( \@v, [ 1, [ 2 .. 4 ], 5 ],
      'try do { } preserves stack discipline' ) or
         diag "Got ", explain \@v;
}

# list context
{
   local $TODO = "list context";

   no warnings 'void';
   my @v = try do { 1, 2, 3 } catch {};
   is_deeply( \@v, [ 1 .. 3 ],
      'try do can yield lists' );
}

# $@ localising
SKIP: {
   # RT124366
   skip "perls before 5.24 fail to lexicalise \$@ properly (RT124366)", 1 unless $] >= 5.024;

   eval { die "oopsie" };

   my $ret = try do { die "another failure" } catch {};
   like( $@, qr/^oopsie at /, '$@ after try do/catch' );
}

# Non-try do { ... } unaffected
{
   is( do { 1 + 2 }, 3,
      'Plain do { ... } unaffected' );
}

# try do syntax produces experimental warnings
SKIP: {
   use if HAVE_WARN_EXPERIMENTAL, warnings => 'experimental';
   skip "No 'experimental' warnings category", 1 unless HAVE_WARN_EXPERIMENTAL;

   my $warnings = "";
   local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

   eval "try do { 1 } catch { 2 }" or die $@;

   like( $warnings, qr/^'try do' syntax is experimental/,
      'try do syntax produces experimental warnings' );
}

done_testing;
