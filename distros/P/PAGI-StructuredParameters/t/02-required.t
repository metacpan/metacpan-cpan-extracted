use strict;
use warnings;
use Test2::V0;
use PAGI::StructuredParameters;

# 'required' is the strict counterpart of 'permitted': the trailing coderef is
# mandatory, success returns the clean hashref, and any missing required key
# triggers the callback whose return value is thrown (Nano's dispatch sends it).

subtest 'success returns the clean hashref' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { title => 'Buy milk', extra => 'drop me' },
    );
    my $on_missing = sub { die 'should not be called' };
    is $sp->required('title', $on_missing),
        { title => 'Buy milk' },
        'all required present -> clean hashref, callback not invoked';
};

subtest 'missing required key throws the callback return value' => sub {
    my $ctx = { i_am => 'the context' };
    my $sp  = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { title => 'Buy milk' },
        context  => $ctx,
    );

    my @callback_args;
    my $on_missing = sub {
        my ($context, $missing) = @_;
        @callback_args = ($context, $missing);
        return { error => 'missing', fields => $missing };
    };

    my $thrown = dies { $sp->required('title', 'due_date', $on_missing) };

    is $callback_args[0], $ctx, 'callback receives the engine context as first arg';
    is $callback_args[1], ['due_date'], 'callback receives an arrayref of missing keys';
    is $thrown, { error => 'missing', fields => ['due_date'] },
        'the callback return value is thrown';
};

subtest 'all missing keys are collected, not just the first' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => {},
    );
    my $seen;
    my $on_missing = sub { my ($context, $missing) = @_; $seen = $missing; die "boom\n" };
    eval { $sp->required('a', 'b', 'c', $on_missing) };
    is $seen, ['a', 'b', 'c'], 'every missing required key is reported';
};

subtest 'an entirely-absent required array key is reported missing' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { title => 'Buy milk' },    # no 'tags' at all
    );
    my $seen;
    my $on_missing = sub { my ($context, $missing) = @_; $seen = $missing; die "boom\n" };
    eval { $sp->required('title', +{ tags => [] }, $on_missing) };
    is $seen, ['tags'],
        'a required array rule whose key is wholly absent fires the callback';
};

subtest 'omitting the on-missing callback is a setup error' => sub {
    my $sp = PAGI::StructuredParameters->new(
        src      => 'body',
        src_data => { title => 'x' },
    );
    my $err = dies { $sp->required('title') };
    like $err, qr/required needs an on-missing callback/,
        'a missing trailing coderef is a loud setup error';
};

done_testing;
