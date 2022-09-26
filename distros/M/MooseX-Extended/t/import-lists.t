#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name    => 'method',
  version => v5.24.0,
  requires => { 'Function::Parameters' => '2.001003', 'Syntax::Keyword::Try' => '0.027' };

package My::Import::List {
    use MooseX::Extended types => 'is_PositiveOrZeroInt',
      includes                 => {
        method => [qw/method fun/],
        try    => undef,
      };

    method fac($n) { return _fac($n) }

    fun _fac($n) {
        is_PositiveOrZeroInt($n) or die "Don't do that!";
        return 1 if $n < 2;
        return $n * _fac $n - 1;
    }

    method reciprocal($n) {
        try {
            return 1 / $n;
        }
        catch ($error) {
            croak "My error: $error";
        }
    }
}

subtest 'custom import lists' => sub {
    my $thing = My::Import::List->new;
    is $thing->fac(4), 24, 'Our "method" can call a "fun"ction';

    throws_ok { $thing->fac(3.14) } qr/Don't do that!/,
      '... and our type constraint works inside of the fun';

    is $thing->reciprocal(.5), 2, 'We are in the try';
    throws_ok { $thing->reciprocal(0) } qr/My error/,
      '... and now we are in the catch';
};

done_testing;
