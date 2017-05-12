use strict;
use warnings;
use Test::More tests => 15;
use Try::Tiny;

{
    package Class;
    use Moose;
    use MooseX::Types::Moose ':all';
    use MooseX::Attribute::TypeConstraint::CustomizeFatal;

    my %attributes = (
        a => "warning",
        b => "default",
        c => "default_no_warning",
        d => "error",
    );

    while (my ($attribute, $on_typeconstraint_failure) = each %attributes) {
        has $attribute => (
            is                        => 'ro',
            isa                       => Int,
            default                   => int rand 2 == 0 ? 12345 : sub { 12345 },

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

    1;
}

{
    package ImmutableClass;
    our @ISA = ('Class');
    __PACKAGE__->meta->make_immutable;
}

{
    package RwClass;
    use Moose;
    use MooseX::Types::Moose ':all';
    use MooseX::Attribute::TypeConstraint::CustomizeFatal;

    my %attributes = (
        a => "warning",
        b => "default",
        c => "default_no_warning",
        d => "error",
    );

    while (my ($attribute, $on_typeconstraint_failure) = each %attributes) {
        has $attribute => (
            is                        => 'rw',
            isa                       => Int,
            default                   => 12345,

            traits                    => ['TypeConstraint::CustomizeFatal'],
            on_typeconstraint_failure => $on_typeconstraint_failure,
        );
    }

}

my @tests = (
    # "error"
    sub {
        my ($class) = @_;
        try {
            $class->new( d => "foo" );
        } catch {
            like($_, qr/does not pass the type constraint/, "We got an error");
        };
    },
    # "warning"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( a => "foo" );
        }
        like($warning, qr/does not pass the type constraint/, "We got a warning");
        is_deeply(
            {%$obj},
            {
                'a' => 'foo',
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got an incorrect value with a warning"
        );
    },
    # "default"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( b => "foo" );
        }
        like($warning, qr/does not pass the type constraint/, "We got a default");
        is_deeply(
            {%$obj},
            {
                'a' => 12345,
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got a default value with default"
        );
    },
    # "default_no_warning"
    sub {
        my ($class) = @_;
        my ($warning, $obj);
        {
            local $SIG{__WARN__} = sub { $warning .= "@_" };
            $obj = $class->new( c => "foo" );
        }
        ok((not defined $warning), "We didn't get a warning with default_no_warning");
        is_deeply(
            {%$obj},
            {
                'a' => 12345,
                'b' => 12345,
                'c' => 12345,
                'd' => 12345
            },
            "We got a default value with default"
        );
    },
);

# Testing just a plain mutable class
$_->('Class') for @tests;

# Testing a mutable class
for my $test (@tests) {
    try {
        $test->('ImmutableClass');
    } catch {
      TODO: {
        local $TODO = "Our _coerce_and_verify isn't called when you __PACKAGE__->meta->make_immutable";
        my ($why) = $_ =~ /\A(.*)/; # Just the first line, not a huge stacktrace
        fail $why;
      }
    };
}

# This doesn't work on accessors
for my $accessor ("a".."d") {
    try {
        RwClass->new;
        RwClass->$accessor("foo");
    } catch {
        like($_, qr/does not pass the type constraint/, "We got an error on accessor as expected");
    };
}
