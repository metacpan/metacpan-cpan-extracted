#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::App226;
    use Resource::Silo -class;
    use Carp;

    # Basic coerce: plain string -> uppercase wrapper object (arrayref here)
    resource loud =>
        init    => sub { 'hello' },
        coerce  => sub { my ($self, $val) = @_; uc $val };

    # coerce runs before check
    resource checked =>
        init    => sub { '  trimmed  ' },
        coerce  => sub { my ($self, $val) = @_; $val =~ s/^\s+|\s+$//g; $val },
        check   => sub {
            my ($self, $val) = @_;
            croak "checked: value must not contain spaces" if $val =~ /\s/;
        };

    # coerce returning undef => error
    resource undef_coerce =>
        init    => sub { 'something' },
        coerce  => sub { return undef };  ## no critic

    # coerce returning empty string => error
    resource empty_coerce =>
        init    => sub { 'something' },
        coerce  => sub { return '' };
}

subtest 'coerce transforms the return value' => sub {
    my $app = My::App226->new;
    is $app->loud, 'HELLO', 'coerce applied';
};

subtest 'coerce runs before check' => sub {
    my $app = My::App226->new;
    lives_and { is $app->checked, 'trimmed', 'coerced and checked' };
};

subtest 'coerce returning undef is an error' => sub {
    my $app = My::App226->new;
    throws_ok { $app->undef_coerce } qr/empty value/, 'undef from coerce croaks';
};

subtest 'coerce returning empty string is an error' => sub {
    my $app = My::App226->new;
    throws_ok { $app->empty_coerce } qr/empty value/, 'empty string from coerce croaks';
};

subtest 'coerce must be a coderef' => sub {
    throws_ok {
        package My::App226bad;
        use Resource::Silo -class;
        resource bad => init => sub { 1 }, coerce => 'not a sub';
    } qr/coerce.*function/, 'non-coderef coerce rejected';
};

done_testing;
