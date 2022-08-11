#!/usr/bin/env perl

use lib 't/lib';
use MooseX::Extended::Tests
  name    => 'try/catch',
  module  => 'Syntax::Keyword::Try',
  version => v5.24.0;

package My::Try {
    use MooseX::Extended includes => [qw/try/];

    sub reciprocal ( $self, $num ) {
        try {
            return 1 / $num;
        }
        catch {
            croak "Could not calculate reciprocal of $num: $@";
        }
    }
}

package My::Try::Role {
    use MooseX::Extended::Role includes => [qw/try/];

    sub reciprocal ( $self, $num ) {
        try {
            return 1 / $num;
        }
        catch {
            croak "Could not calculate reciprocal of $num: $@";
        }
    }
}

package My::Class::Consuming::The::Role {
    use MooseX::Extended;
    with 'My::Try::Role';
}

my %cases = (
    classes => 'My::Try',
    roles   => 'My::Class::Consuming::The::Role',
);

while ( my ( $name, $class ) = each %cases ) {
    subtest "try in $name" => sub {
        ok my $try = $class->new, "We should be allowed to load $name with try/catch";

        is $try->reciprocal(2), .5, 'Our try block should be able to return a value';

        throws_ok { $try->reciprocal(0); }
        qr/Could not calculate reciprocal of.*Illegal division by zero/,
          '... and our catch block should be able to trap the error';
    };
}

done_testing;
