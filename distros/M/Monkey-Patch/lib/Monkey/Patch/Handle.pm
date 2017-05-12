package Monkey::Patch::Handle;
BEGIN {
  $Monkey::Patch::Handle::VERSION = '0.03';
}
use Scalar::Util qw(weaken);
use Sub::Delete;

use strict;
use warnings;

my %handles;

# What we're doing here, essentially, is keeping a stack of subroutine
# refs for each name (Foo::bar::baz type name).  We're doing this so that
# the coderef that lives at that name is always the top of the stack, so
# the wrappers get uninstalled in a funky order all hell doesn't break
# loose.  The most recently installed undestroyed wrapper will always get
# called, and it will unwind gracefully until we get down to the original
# sub (if there was one).

sub new {
    my ($class, %args) = @_;
    bless \%args, $class;
}

sub name {
    my $self = shift;
    $self->{name} ||= "$self->{package}::$self->{subname}";
}

sub stack {
    my $self = shift;
    $self->{stack} ||= $handles{ $self->name } ||= [];
}

sub call_previous {
    my $self    = shift;
    my $stack   = $self->stack;
    my $wrapper = $self->wrapper;
    for my $i (1..$#$stack) {
        if ($stack->[$i] == $wrapper) {
            goto &{ $stack->[$i-1] };
        }
    }
    $self->call_default(@_);
}

sub call_default {}

sub should_call_code { 1 }

sub wrapper {
    my $self = shift;
    unless ($self->{wrapper}) {
        weaken($self);
        $self->{wrapper} = sub {
            if ($self->should_call_code($_[0])) {
                unshift @_, sub { $self->call_previous(@_) };
                goto $self->{code};
            }
            else {
                return $self->call_previous(@_);
            }
        };
    }
    return $self->{wrapper};
}

sub install {
    my $self = shift;
    my $name  = $self->name;
    my $stack = $self->stack;

    no strict 'refs';

    unless (@$stack) {
        if (*$name{CODE}) {
            push @$stack, \&$name;
        }
    }

    my $code = $self->wrapper;

    no warnings 'redefine';
    *$name = $code;
    push(@$stack, $code);

    return $self;
}

sub DESTROY {
    my $self    = shift;
    my $stack   = $self->stack;
    my $wrapper = $self->wrapper;
    for my $i (0..$#$stack) {
        if($stack->[$i] == $wrapper) {
            splice @$stack, $i, 1;
            no strict 'refs';
            my $name = $self->name;
            if(my $top = $stack->[-1]) {
                no warnings 'redefine';
                *$name = $top;
            }
            else {
                delete_sub $name;
            }
            last;
        }
    }
}

1;

=pod

=begin Pod::Coverage

.*

=end Pod::Coverage
