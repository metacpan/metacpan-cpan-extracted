use strict;
use warnings;

use Test::More tests => 10;

# --- Test: build() takes precedence over initialize() ---

{
    package BothDefined;
    use Simple::Accessor qw{name};

    my @calls;
    sub reset_calls { @calls = () }
    sub get_calls   { [@calls] }

    sub build {
        my ($self, %opts) = @_;
        push @calls, 'build';
        return 1;
    }

    sub initialize {
        my ($self, %opts) = @_;
        push @calls, 'initialize';
        return 1;
    }
}

BothDefined->reset_calls();
my $obj = BothDefined->new(name => 'test');
ok $obj, 'object created when both build and initialize exist';
is_deeply( BothDefined->get_calls(), ['build'],
    'only build() called when both build and initialize are defined' );

# --- Test: initialize() still works alone (backward compat) ---

{
    package InitOnly;
    use Simple::Accessor qw{val};

    my @calls;
    sub reset_calls { @calls = () }
    sub get_calls   { [@calls] }

    sub initialize {
        my ($self, %opts) = @_;
        push @calls, 'initialize';
        $self->val(99) unless defined $opts{val};
        return 1;
    }
}

InitOnly->reset_calls();
my $init_obj = InitOnly->new();
ok $init_obj, 'object created with initialize() only';
is_deeply( InitOnly->get_calls(), ['initialize'],
    'initialize() called when build does not exist' );
is $init_obj->val, 99, 'initialize() can set attributes';

# --- Test: build() alone works ---

{
    package BuildOnly;
    use Simple::Accessor qw{val};

    my @calls;
    sub reset_calls { @calls = () }
    sub get_calls   { [@calls] }

    sub build {
        my ($self, %opts) = @_;
        push @calls, 'build';
        $self->val(42) unless defined $opts{val};
        return 1;
    }
}

BuildOnly->reset_calls();
my $build_obj = BuildOnly->new();
ok $build_obj, 'object created with build() only';
is_deeply( BuildOnly->get_calls(), ['build'],
    'build() called when it is the only init method' );
is $build_obj->val, 42, 'build() can set attributes';

# --- Test: build() returning false prevents object creation ---

{
    package BuildFails;
    use Simple::Accessor qw{x};

    sub build { return 0 }
    sub initialize { die "should not be called" }
}

my $fail_obj = BuildFails->new();
ok !$fail_obj, 'build() returning false prevents object creation';

# --- Test: initialize() not called after build() fails ---

eval { BuildFails->new() };
ok !$@, 'initialize() is not called when build() returns false';
