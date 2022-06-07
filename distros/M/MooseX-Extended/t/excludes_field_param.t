#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests;

eval <<"END";
package My::Class1 {
    use MooseX::Extended excludes => [qw/param/], types => ['Str'];

    field foo => ( isa => Str );
    param foo => ( isa => Str );
}
END

my $error = $@;
like $error, qr/syntax error .* near "param foo"/,
  'We should be able to exclude param()';

eval <<"END";
package My::Class1 {
    use MooseX::Extended excludes => [qw/field/], types => ['Str'];

    param foo => ( isa => Str );
    field foo => ( isa => Str );
}
END

$error = $@;
like $error, qr/syntax error .* near "field foo"/,
  'We should be able to exclude field()';

done_testing;
