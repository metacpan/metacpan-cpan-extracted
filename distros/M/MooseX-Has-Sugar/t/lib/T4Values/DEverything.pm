package  T4Values::DEverything;

# $Id:$
use strict;
use warnings;
use MooseX::Has::Sugar;
use namespace::clean -except => 'meta';

sub generated {
  {
    isa => 'Str',
    ro, required, lazy, lazy_build, coerce, weak_ref, auto_deref
  };
}

sub generated_bare {
  {
    isa => 'Str',
    bare, required, lazy, lazy_build, coerce, weak_ref, auto_deref
  };
}

sub generated_rw {
  {
    isa => 'Str',
    rw, required, lazy, lazy_build, coerce, weak_ref, auto_deref
  };
}

sub manual {
  {
    isa        => 'Str',
    is         => 'ro',
    required   => 1,
    lazy       => 1,
    lazy_build => 1,
    coerce     => 1,
    weak_ref   => 1,
    auto_deref => 1,
  };
}

sub manual_rw {
  {
    isa        => 'Str',
    is         => 'rw',
    required   => 1,
    lazy       => 1,
    lazy_build => 1,
    coerce     => 1,
    weak_ref   => 1,
    auto_deref => 1,
  };
}

sub manual_bare {
  {
    isa        => 'Str',
    is         => 'bare',
    required   => 1,
    lazy       => 1,
    lazy_build => 1,
    coerce     => 1,
    weak_ref   => 1,
    auto_deref => 1,
  };
}

1;

