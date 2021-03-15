package Sub::Meta::Parameters;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.08";

use Carp ();
use Scalar::Util ();

use Sub::Meta::Param;

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub _croak { require Carp; goto &Carp::croak }

sub param_class { 'Sub::Meta::Param' }

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;

    _croak 'parameters reqruires args' unless exists $args{args};

    my $self = bless \%args => $class;
    $self->set_args($args{args});

    $self->set_invocant(delete $args{invocant}) if exists $args{invocant};
    $self->set_nshift(delete $args{nshift}) if exists $args{nshift};
    $self->set_slurpy(delete $args{slurpy}) if exists $args{slurpy};

    return $self;
}

sub nshift()    { $_[0]{nshift} // 0 }
sub slurpy()    { $_[0]{slurpy} ? $_[0]{slurpy} : !!0 }
sub args()      { $_[0]{args} }
sub invocant()  { $_[0]{invocant} }
sub invocants() { defined $_[0]{invocant} ? [ $_[0]{invocant} ] : [] }
sub all_args()  { [ @{$_[0]->invocants}, @{$_[0]->args} ] }

sub set_slurpy {
    my ($self, $v) = @_;
    $self->{slurpy} = Scalar::Util::blessed($v) && $v->isa('Sub::Meta::Param')
                    ? $v
                    : $self->param_class->new($v);
    return $self;
}

sub set_args {
    my $self = shift;
    $self->{args} = $self->_normalize_args(@_);
    return $self;
}

sub set_nshift {
    my ($self, $v) = @_;

    unless (defined $v && ($v == 0 || $v == 1) ) {
        _croak sprintf("Can't set this nshift: %s", $v//'');
    }

    $self->{nshift} = $v;

    if ($v == 1 && !defined $self->invocant) {
        my $default_invocant = $self->param_class->new(invocant => 1);
        $self->set_invocant($default_invocant)
    }

    if ($v == 0 && defined $self->invocant) {
        delete $self->{invocant}
    }

    return $self;
}

sub set_invocant {
    my ($self, $v) = @_;

    my $invocant = Scalar::Util::blessed($v) && $v->isa('Sub::Meta::Param')
                 ? $v
                 : $self->param_class->new($v);

    $invocant->set_invocant(1);

    $self->{invocant} = $invocant;

    if ($self->nshift == 0) {
        $self->set_nshift(1);
    }

    return $self;
}

sub _normalize_args {
    my $self = shift;
    _croak 'args must be a reference' unless @_ == 1 && ref $_[0];

    my @args;
    if (ref $_[0] eq 'ARRAY') {
        @args = @{$_[0]};
    }
    elsif (ref $_[0] eq 'HASH') {
        for my $name (sort { $a cmp $b } keys %{$_[0]}) {
            my $v = $_[0]->{$name};
            my $f = ref $v && ref $v eq 'HASH';
            push @args => {
                name  => $name,
                named => 1,
                ($f ? %$v : (type => $v) ),
            }
        }
    }
    else {
        @args = ($_[0]);
    }

    return [
        map {
            Scalar::Util::blessed($_) && $_->isa('Sub::Meta::Param')
            ? $_
            : $self->param_class->new($_)
        } @args
    ]
}

sub _all_positional_required() {
    my $self = shift;
    [ @{$self->invocants}, @{$self->positional_required} ];
}


sub positional()          { [ grep { $_->positional                 } @{$_[0]->args} ] }
sub positional_required() { [ grep { $_->positional && $_->required } @{$_[0]->args} ] }
sub positional_optional() { [ grep { $_->positional && $_->optional } @{$_[0]->args} ] }

sub named()               { [ grep { $_->named                      } @{$_[0]->args} ] }
sub named_required()      { [ grep { $_->named && $_->required      } @{$_[0]->args} ] }
sub named_optional()      { [ grep { $_->named && $_->optional      } @{$_[0]->args} ] }

sub args_min() {
    my $self = shift;
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->named_required} * 2;
    $r
}

sub args_max() {
    my $self = shift;
    return 0 + 'Inf' if $self->slurpy || @{$self->named};
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->positional_optional};
    $r
}

sub is_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Parameters');

    return unless $self->slurpy ? $self->slurpy->is_same_interface($other->slurpy)
                                : !$other->slurpy;

    return unless @{$self->all_args} == @{$other->all_args};

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        return unless $self->all_args->[$i]->is_same_interface($other->all_args->[$i]);
    }

    return unless $self->nshift == $other->nshift;

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Parameters')", $v, $v);

    push @src => $self->slurpy ? $self->slurpy->is_same_interface_inlined(sprintf('%s->slurpy', $v))
                               : sprintf('!%s->slurpy', $v);

    push @src => sprintf('%d == @{%s->all_args}', scalar @{$self->all_args}, $v);

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        push @src => $self->all_args->[$i]->is_same_interface_inlined(sprintf('%s->all_args->[%d]', $v, $i))
    }

    push @src => sprintf('%d == %s->nshift', $self->nshift, $v);

    return join "\n && ", @src;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Parameters - meta information about parameters

=head1 SYNOPSIS

    use Sub::Meta::Parameters;

    my $p1 = Sub::Meta::Parameters->new(
        args => ['Str']
    );
    $p1->invocant;            # => undef;
    $p1->invocants;           # => [];
    $p1->positional;          # => [Sub::Meta::Param->new('Str')]
    $p1->positional_required; # => [Sub::Meta::Param->new('Str')]
    $p1->positional_optional; # => []
    $p1->named;               # => []
    $p1->named_required;      # => []
    $p1->named_optional;      # => []
    $p1->nshift;              # => 0
    $p1->slurpy;              # => 0
    $p1->args_min;            # => 1
    $p1->args_max;            # => 1


    my $x = Sub::Meta::Param->new({ type => 'Int', name => '$x', named => 1 });
    my $y = Sub::Meta::Param->new({ type => 'Int', name => '$y', named => 1 });

    my $p2 = Sub::Meta::Parameters->new(
        nshift => 1,
        args => [
            'ClassName', $x, $y
        ]
    );

    $p2->invocant;            # => Sub::Meta::Param->new('ClassName');
    $p2->invocants;           # => [Sub::Meta::Param->new('ClassName')];
    $p2->positional;          # => []
    $p2->positional_required; # => []
    $p2->positional_optional; # => []
    $p2->named;               # => [$x, $y]
    $p2->named_required;      # => [$x, $y]
    $p2->named_optional;      # => []
    $p2->nshift;              # => 1
    $p2->slurpy;              # => 0
    $p2->args_min;            # => 5
    $p2->args_max;            # => 0+'Inf'

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta::Parameters>.

    my $p = Sub::Meta::Parameters->new(
        args   => ['Str'], # required. arguments
        nshift => 0,       # optional. number of shift arguments
        slurpy => 0,       # optional. whether get all rest arguments
    );

=head2 ACCESSORS

=head3 args

Subroutine arguments arrayref.

=head3 set_args(ArrayRef), set_args(HashRef), set_args(Ref)

Setter for subroutine arguments.
An element can be an argument of C<Sub::Meta::Param>.

    use Types::Standard -types;

    my $p = Sub::Meta::Parameters->new(args => []);
    $p->set_args([Int,Int]);
    $p->set_args([{ type => Int, name => 'num' }]);

    # named case:
    $p->set_args({ a => Str, b => Str });
    $p->set_args({
        a => { isa => Str, default => 123 },
        b => { isa => Str, optional => 1 }
    });

    # single ref:
    $p->set_args(Str); # => $p->set_args([Str])

=head3 all_args

Subroutine invocants and arguments arrayref.

=head3 nshift

Number of shift arguments.

=head3 set_nshift($nshift)

Setter for nshift.
For example, it is assumed that 1 is specified in the case of methods, and 0 is specified in the case of normal functions.

=head3 slurpy

Subroutine all rest arguments.

=head3 set_slurpy($param_args)

Setter for slurpy:

    my $p = Sub::Meta::Parameters->new(args => [{ isa => 'Int', name => '$a'}]);
    $p->set_slurpy({ name => '@numbers', isa => 'Int' }); # => (Int $a, Int @numbers)

=head3 positional

Returns an arrayref of parameter objects for the positional arguments.

=head3 positional_required

Returns an arrayref of parameter objects for the required positional arguments.

=head3 positional_optional

Returns an arrayref of parameter objects for the optional positional arguments.

=head3 named

Returns an arrayref of parameter objects for the named arguments.

=head3 named_required

Returns an arrayref of parameter objects for the required named arguments.

=head3 named_optional

Returns an arrayref of parameter objects for the optional named arguments.

=head3 invocant

First element of invocants.

=head3 invocants

Returns an arrayref of parameter objects for the variables into which initial arguments are shifted automatically. This will usually return () for normal functions and ('$self') for methods.

=head3 set_invocant

Setter for invocant:

    my $invocant = Sub::Meta::Param->new(name => '$self');
    my $p = Sub::Meta::Parameters->new(args => []);
    $p->set_invocant($invocant);

    $p->invocant; # => Sub::Meta::Param->new(name => '$self', invocant => 1);
    $p->nshift; # => 1

=head3 args_min

Returns the minimum number of required arguments.

This is computed as follows:
  Invocants and required positional parameters count 1 each.
  Optional parameters don't count.
  Required named parameters count 2 each (key + value).
  Slurpy parameters don't count either because they accept empty lists.

=head3 args_max

Returns the maximum number of arguments.

This is computed as follows:
  If there are any named or slurpy parameters, the result is Inf.
  Otherwise the result is the number of all invocants and positional parameters.

=head3 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Parameters> object is same or not.
Specifically, check whether C<args>, C<nshift> and C<slurpy> are equal.

=head2 OTHERS

=head3 is_same_interface_inlined($other_meta_inlined)

Returns inlined C<is_same_interface> string.

=head3 param_class

Returns class name of param. default: Sub::Meta::Param
Please override for customization.

=head1 SEE ALSO

L<Function::Parameters::Info>.

The methods in this module are almost copied from the C<Function::Parameters::Info> methods.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

