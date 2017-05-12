#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 21;

BEGIN { use_ok 'Resource::Dispose' };


{
    package My::Class;

    our $Dispose_Called;

    sub new {
        return bless {} => $_[0];
    };

    sub store {
        my ($self, $what) = @_;
        $self->{stash} = $what;
    };

    sub DISPOSE {
        $Dispose_Called = 1;
    };
}


{
    $My::Class::Dispose_Called = '';
    eval q{
        my $obj = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, '';
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource my $obj = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource my($obj) = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource my ($obj) = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource my ($obj, $obj2);
        $obj = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource my ($obj2, $obj);
        $obj = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        our $objg;
        resource $objg = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        resource our $objo = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

{
    $My::Class::Dispose_Called = '';
    eval q{
        our $objl;
        resource local $objl = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}

SKIP: {
    skip 'state introduced in Perl 5.10', 2 unless $] >= 5.010;
    $My::Class::Dispose_Called = '';
    eval q{
        use feature 'state';
        resource state $objs = My::Class->new;
    };
    is $@, '';
    is $My::Class::Dispose_Called, 1;
}
