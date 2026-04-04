#!perl

use strict;
use warnings;

use Test::More;

use_ok('Razor2::Errorhandler');

# --- Basic construction ---

{
    my $eh = Razor2::Errorhandler->new;
    isa_ok( $eh, 'Razor2::Errorhandler' );
}

# --- error() and errstr() ---

{
    my $eh = Razor2::Errorhandler->new;

    # error() returns undef
    my $result = $eh->error("something went wrong");
    ok( !defined $result, "error() returns undef" );

    # errstr() returns the error message with trailing newline
    is( $eh->errstr(), "something went wrong\n", "errstr() returns error message" );
}

{
    my $eh = Razor2::Errorhandler->new;

    # Multiple errors: last one wins
    $eh->error("first error");
    $eh->error("second error");
    is( $eh->errstr(), "second error\n", "subsequent error() overwrites previous" );
}

# --- errprefix ---

{
    my $eh = Razor2::Errorhandler->new;
    $eh->error("connection failed");
    $eh->errprefix("Client");

    is( $eh->errstr(), "Client: connection failed\n", "errprefix prepends to error message" );
}

# --- errstrrst ---

{
    my $eh = Razor2::Errorhandler->new;
    $eh->error("some error");
    $eh->errstrrst();

    is( $eh->errstr(), "", "errstrrst clears the error string" );
}

# --- Inheritance pattern ---

{
    package TestDerived;
    use parent -norequire, 'Razor2::Errorhandler';

    sub new { bless {}, shift }

    sub do_something {
        my $self = shift;
        return $self->error("derived class error");
    }

    package main;

    my $obj = TestDerived->new;
    my $result = $obj->do_something();
    ok( !defined $result, "derived class error() returns undef" );
    is( $obj->errstr(), "derived class error\n",
        "derived class can use inherited error handling" );
}

# --- Construction error (class-level errstr) ---

{
    package TestConstructionError;
    use parent -norequire, 'Razor2::Errorhandler';

    sub new {
        my $class = shift;
        my $self  = bless {}, $class;
        $self->error("construction failed", 1);
        return;
    }

    package main;

    my $obj = TestConstructionError->new;
    ok( !defined $obj, "construction error returns undef from constructor" );

    # The class-level errstr should be set
    no strict 'refs';
    my $class_err = ${"TestConstructionError::errstr"};
    use strict 'refs';
    like( $class_err, qr/construction failed/, "construction error sets class-level errstr" );
}

done_testing;
