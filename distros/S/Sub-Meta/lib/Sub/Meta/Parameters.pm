package Sub::Meta::Parameters;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.13";

use Carp ();
use Scalar::Util ();

use Sub::Meta::Param;

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub _croak { require Carp; goto &Carp::croak }

sub param_class { return 'Sub::Meta::Param' }

sub new {
    my ($class, @args) = @_;
    my %args = @args == 1 ? %{$args[0]} : @args;

    _croak 'parameters reqruires args' unless exists $args{args};

    my $self = bless \%args => $class;
    $self->set_args($args{args});

    $self->set_invocant(delete $args{invocant}) if exists $args{invocant};
    $self->set_nshift(delete $args{nshift}) if exists $args{nshift};
    $self->set_slurpy(delete $args{slurpy}) if $args{slurpy};

    return $self;
}

sub nshift()    { my $self = shift; return $self->{nshift} // 0 }
sub slurpy()    { my $self = shift; return $self->{slurpy} }
sub args()      { my $self = shift; return $self->{args} }
sub invocant()  { my $self = shift; return $self->{invocant} }
sub invocants() { my $self = shift; return defined $self->{invocant} ? [ $self->{invocant} ] : [] }
sub all_args()  { my $self = shift; return [ @{$self->invocants}, @{$self->args} ] }

sub has_invocant() { my $self = shift; return defined $self->{invocant} }
sub has_slurpy()   { my $self = shift; return defined $self->{slurpy} }

sub set_slurpy {
    my ($self, $v) = @_;
    $self->{slurpy} = Scalar::Util::blessed($v) && $v->isa('Sub::Meta::Param')
                    ? $v
                    : $self->param_class->new($v);
    return $self;
}

sub set_args {
    my ($self, @args) = @_;
    $self->{args} = $self->_normalize_args(@args);
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
    my ($self, @args) = @_;
    my $args = $args[0];
    _croak 'args must be a single reference' unless @args == 1 && ref $args;

    my @normalized_args;
    if (ref $args eq 'ARRAY') {
        @normalized_args = @{$args};
    }
    elsif (ref $args eq 'HASH') {
        for my $name (sort { $a cmp $b } keys %{$args}) {
            my $v = $args->{$name};
            my $f = ref $v && ref $v eq 'HASH';
            push @normalized_args => {
                name  => $name,
                named => 1,
                ($f ? %$v : (type => $v) ),
            }
        }
    }
    else {
        @normalized_args = ($args);
    }

    return [
        map {
            Scalar::Util::blessed($_) && $_->isa('Sub::Meta::Param')
            ? $_
            : $self->param_class->new($_)
        } @normalized_args
    ]
}

sub _all_positional_required() {
    my $self = shift;
    return [ @{$self->invocants}, @{$self->positional_required} ];
}


sub positional()          { my $self = shift; return [ grep { $_->positional                 } @{$self->args} ] }
sub positional_required() { my $self = shift; return [ grep { $_->positional && $_->required } @{$self->args} ] }
sub positional_optional() { my $self = shift; return [ grep { $_->positional && $_->optional } @{$self->args} ] }

sub named()               { my $self = shift; return [ grep { $_->named                      } @{$self->args} ] }
sub named_required()      { my $self = shift; return [ grep { $_->named && $_->required      } @{$self->args} ] }
sub named_optional()      { my $self = shift; return [ grep { $_->named && $_->optional      } @{$self->args} ] }

sub args_min() {
    my $self = shift;
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->named_required} * 2;
    return $r
}

sub args_max() {
    my $self = shift;
    return 0 + 'Inf' if $self->slurpy || @{$self->named}; ## no critic (ProhibitMismatchedOperators)
    my $r = 0;
    $r += @{$self->_all_positional_required};
    $r += @{$self->positional_optional};
    return $r
}

sub is_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Parameters');

    if ($self->has_slurpy) {
        return unless $self->slurpy->is_same_interface($other->slurpy)
    }
    else {
        return if $other->has_slurpy;
    }

    return unless $self->nshift == $other->nshift;

    return unless @{$self->all_args} == @{$other->all_args};

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        return unless $self->all_args->[$i]->is_same_interface($other->all_args->[$i]);
    }

    return !!1;
}

sub is_relaxed_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Parameters');

    if ($self->has_slurpy) {
        return unless $self->slurpy->is_same_interface($other->slurpy)
    }

    return unless $self->nshift == $other->nshift;

    return unless @{$self->all_args} <= @{$other->all_args};

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        return unless $self->all_args->[$i]->is_relaxed_same_interface($other->all_args->[$i]);
    }

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Parameters')", $v, $v);

    push @src => $self->has_slurpy ? $self->slurpy->is_same_interface_inlined(sprintf('%s->slurpy', $v))
                                   : sprintf('!%s->has_slurpy', $v);

    push @src => sprintf('%d == %s->nshift', $self->nshift, $v);

    push @src => sprintf('%d == @{%s->all_args}', scalar @{$self->all_args}, $v);

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        push @src => $self->all_args->[$i]->is_same_interface_inlined(sprintf('%s->all_args->[%d]', $v, $i))
    }

    return join "\n && ", @src;
}

sub is_relaxed_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Parameters')", $v, $v);

    push @src => $self->slurpy->is_relaxed_same_interface_inlined(sprintf('%s->slurpy', $v)) if $self->has_slurpy; 

    push @src => sprintf('%d == %s->nshift', $self->nshift, $v);

    push @src => sprintf('%d <= @{%s->all_args}', scalar @{$self->all_args}, $v);

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        push @src => $self->all_args->[$i]->is_relaxed_same_interface_inlined(sprintf('%s->all_args->[%d]', $v, $i))
    }

    return join "\n && ", @src;
}


sub error_message {
    my ($self, $other) = @_;

    return sprintf('must be Sub::Meta::Parameters. got: %s', $other // '')
        unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Parameters');

    if ($self->has_slurpy) {
        return sprintf('invalid slurpy. got: %s, expected: %s', $other->has_slurpy ? $other->slurpy->display : '', $self->slurpy->display)
            unless $self->slurpy->is_same_interface($other->slurpy)
    }
    else {
        return 'should not have slurpy' if $other->has_slurpy;
    }

    return sprintf('nshift is not equal. got: %d, expected: %d', $other->nshift, $self->nshift)
        unless $self->nshift == $other->nshift;

    return sprintf('invalid args length. got: %d, expected: %d', scalar @{$other->all_args}, scalar @{$self->all_args})
        unless @{$self->all_args} == @{$other->all_args};

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        my $s = $self->all_args->[$i];
        my $o = $other->all_args->[$i];
        return sprintf('args[%d] is invalid. got: %s, expected: %s', $i, $o->display, $s->display)
            unless $s->is_same_interface($o);
    }

    return '';
}

sub relaxed_error_message {
    my ($self, $other) = @_;

    return sprintf('must be Sub::Meta::Parameters. got: %s', $other // '')
        unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Parameters');

    if ($self->has_slurpy) {
        return sprintf('invalid slurpy. got: %s, expected: %s', $other->has_slurpy ? $other->slurpy->display : '', $self->slurpy->display)
            unless $self->slurpy->is_same_interface($other->slurpy)
    }

    return sprintf('nshift is not equal. got: %d, expected: %d', $other->nshift, $self->nshift)
        unless $self->nshift == $other->nshift;

    return sprintf('invalid args length. got: %d, expected: %d', scalar @{$other->all_args}, scalar @{$self->all_args})
        unless @{$self->all_args} <= @{$other->all_args};

    for (my $i = 0; $i < @{$self->all_args}; $i++) {
        my $s = $self->all_args->[$i];
        my $o = $other->all_args->[$i];
        return sprintf('args[%d] is invalid. got: %s, expected: %s', $i, $o->display, $s->display)
            unless $s->is_relaxed_same_interface($o);
    }

    return '';
}
sub display {
    my $self = shift;

    my $s = '';
    $s .= $self->invocant->display . ': '
        if $self->invocant && $self->invocant->display;

    $s .= join ', ', map { $_->display } @{$self->args};
    $s .= ', ' if $s && $self->slurpy;
    $s .= $self->slurpy->display if $self->slurpy;
    return $s;
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

    method args() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Subroutine arguments arrayref.

=head3 set_args

    method set_args(ArrayRef[InstanceOf[Sub::Meta::Param]]) => $self
    method set_args(ArrayRef[$sub_meta_param_args]) => $self
    method set_args(Dict[Str, $sub_meta_param_args]) => $self
    method set_args(Ref $type) => $self

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

    method all_args() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Subroutine invocants and arguments arrayref.

=head3 nshift

    method nshift() => Enum[0,1]

Number of shift arguments.

=head3 set_nshift($nshift)

    method nshift(Enum[0,1] $nshift) => $self

Setter for nshift.
For example, it is assumed that 1 is specified in the case of methods, and 0 is specified in the case of normal functions.

=head3 slurpy

    method slurpy() => Maybe[InstanceOf[Sub::Meta::Param]]

Subroutine all rest arguments.

=head3 has_slurpy

    method has_slurpy() => Bool

Whether Sub::Meta::Parameters has slurpy or not.

=head3 set_slurpy($param_args)

    method set_slurpy(InstanceOf[Sub::Meta::Param]) => $self> or
    method set_slurpy($sub_meta_param_args)> or

Setter for slurpy:

    my $p = Sub::Meta::Parameters->new(args => [{ isa => 'Int', name => '$a'}]);
    $p->set_slurpy({ name => '@numbers', isa => 'Int' }); # => (Int $a, Int @numbers)

=head3 positional

    method positional() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the positional arguments.

=head3 positional_required

    method positional_required() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the required positional arguments.

=head3 positional_optional

    method positional_optional() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the optional positional arguments.

=head3 named

    method named() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the named arguments.

=head3 named_required

    method named_required() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the required named arguments.

=head3 named_optional

    method named_optional() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the optional named arguments.

=head3 invocant

    method invocant() => Maybe[InstanceOf[Sub::Meta::Param]]

First element of invocants.

=head3 invocants

    method invocants() => ArrayRef[InstanceOf[Sub::Meta::Param]]

Returns an arrayref of parameter objects for the variables into which initial arguments are shifted automatically. This will usually return () for normal functions and ('$self') for methods.

=head3 has_invocant 

    method has_invocant() => Bool

Whether Sub::Meta::Parameters has invocant or not.

=head3 set_invocant($param_args)

    method set_invocant(InstanceOf[Sub::Meta::Param]) => $self
    method set_invocant($sub_meta_param_args) => $self

Setter for invocant:

    my $invocant = Sub::Meta::Param->new(name => '$self');
    my $p = Sub::Meta::Parameters->new(args => []);
    $p->set_invocant($invocant);

    $p->invocant; # => Sub::Meta::Param->new(name => '$self', invocant => 1);
    $p->nshift; # => 1

=head3 args_min

    method args_min() => NonNegativeInt

Returns the minimum number of required arguments.

This is computed as follows:
  Invocants and required positional parameters count 1 each.
  Optional parameters don't count.
  Required named parameters count 2 each (key + value).
  Slurpy parameters don't count either because they accept empty lists.

=head3 args_max

    method args_max() => NonNegativeInt

Returns the maximum number of arguments.

This is computed as follows:
  If there are any named or slurpy parameters, the result is Inf.
  Otherwise the result is the number of all invocants and positional parameters.

=head2 METHODS

=head3 is_same_interface($other_meta)

    method is_same_interface(InstanceOf[Sub::Meta::Parameters] $other_meta) => Bool

A boolean value indicating whether C<Sub::Meta::Parameters> object is same or not.
Specifically, check whether C<args>, C<nshift> and C<slurpy> are equal.

=head3 is_relaxed_same_interface($other_meta)

    method is_relaxed_same_interface(InstanceOf[Sub::Meta::Parameters] $other_meta) => Bool

A boolean value indicating whether C<Sub::Meta::Parameters> object is same or not.
Specifically, check whether C<args>, C<nshift> and C<slurpy> are satisfy
the condition of C<$self> side:

    my $meta = Sub::Meta::Parameters->new(args => []);
    my $other = Sub::Meta::Parameters->new(args => ["Str"]);
    $meta->is_same_interface($other); # NG
    $meta->is_relaxed_same_interface($other); # OK. The reason is that $meta does not specify the elements of args.

=head3 is_same_interface_inlined($other_meta_inlined)

    method is_same_interface_inlined(InstanceOf[Sub::Meta::Parameters] $other_meta) => Str

Returns inlined C<is_same_interface> string.

=head3 is_relaxed_same_interface_inlined($other_meta_inlined)

    method is_relaxed_same_interface_inlined(InstanceOf[Sub::Meta::Parameters] $other_meta) => Str

Returns inlined C<is_relaxed_same_interface> string.

=head3 error_message($other_meta)

    method error_message(InstanceOf[Sub::Meta::Parameters] $other_meta) => Str

Return the error message when the interface is not same. If same, then return empty string.

=head3 relaxed_error_message($other_meta)

    method relaxed_error_message(InstanceOf[Sub::Meta::Parameters] $other_meta) => Str

Return the error message when the interface does not satisfy the C<$self> meta. If match, then return empty string.

=head3 display

    method display() => Str

Returns the display of Sub::Meta::Parameters:

    use Sub::Meta::Parameters;
    use Types::Standard qw(Num);
    my $meta = Sub::Meta::Parameters->new(
        args => [
            { name => '$lat', type => Num, named => 1 },
            { name => '$lng', type => Num, named => 1 },
        ],
    );
    $meta->display; # 'Num :$lat, Num :$lng'

=head2 OTHERS

=head3 param_class

    method param_class() => Str

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

