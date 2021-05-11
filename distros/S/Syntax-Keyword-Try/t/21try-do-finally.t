#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;
BEGIN {
   # Before 5.24 this code won't even compile
   plan skip_all => "try do { } finally { } is not supported before perl 5.24" if $] < 5.024;
}

use constant HAVE_WARN_EXPERIMENTAL => $] >= 5.018;

no if HAVE_WARN_EXPERIMENTAL, warnings => 'experimental';
use Syntax::Keyword::Try qw( try try_value );

no warnings 'deprecated';

# try do { } finally { }
{
   my $x;
   my $result = try do { $x .= 1; "result" }
      finally { $x .= 2 }, $x .= 3;

   is( $result, "result", 'try do { } finally yields result' );
   is( $x, "123", 'try do {} finally has finally side-effect' );
}

# try do { } catch { } finally { }
{
   my $x;
   my $result = try do { $x .= 4; die "oops" }
      catch ($e) { $x .= 5; "failure" }
      finally { $x .= 6 };
   is( $result, "failure", 'try do {} catch finally catches exception' );
   is( $x, "456", 'try do {} catch finally has finally side-effect' );
}

done_testing;
