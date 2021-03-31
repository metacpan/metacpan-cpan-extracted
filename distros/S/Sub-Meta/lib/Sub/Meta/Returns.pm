package Sub::Meta::Returns;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.10";

use Scalar::Util ();

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub new {
    my ($class, @args) = @_;
    my $v = $args[0];
    my %args = @args == 1 ? ref $v && ref $v eq 'HASH' ? %{$v}
                       : ( scalar => $v, list => $v, void => $v )
             : @args;

    return bless \%args => $class;
}

sub scalar() :method { my $self = shift; return $self->{scalar} } ## no critic (ProhibitBuiltinHomonyms)
sub list()           { my $self = shift; return $self->{list} }
sub void()           { my $self = shift; return $self->{void} }

sub set_scalar    { my ($self, $v) = @_; $self->{scalar} = $v; return $self }
sub set_list      { my ($self, $v) = @_; $self->{list}   = $v; return $self }
sub set_void      { my ($self, $v) = @_; $self->{void}   = $v; return $self }

sub coerce()   { my $self = shift; return !!$self->{coerce} }
sub set_coerce { my ($self, $v) = @_; $self->{coerce} = defined $v ? $v : 1; return $self }

sub is_same_interface {
    my ($self, $other) = @_;

    return unless Scalar::Util::blessed($other) && $other->isa('Sub::Meta::Returns');

    return unless defined $self->scalar ? _eq($self->scalar, $other->scalar)
                                        : !defined $other->scalar;

    return unless defined $self->list ? _eq($self->list, $other->list)
                                      : !defined $other->list;

    return unless defined $self->void ? _eq($self->void, $other->void)
                                      : !defined $other->void;

    return !!1;
}

sub is_same_interface_inlined {
    my ($self, $v) = @_;

    my @src;

    push @src => sprintf("Scalar::Util::blessed(%s) && %s->isa('Sub::Meta::Returns')", $v, $v);

    push @src => defined $self->scalar ? _eq_inlined($self->scalar, sprintf('%s->scalar', $v))
                                       : sprintf('!defined %s->scalar', $v);

    push @src => defined $self->list ? _eq_inlined($self->list, sprintf('%s->list', $v))
                                     : sprintf('!defined %s->list', $v);

    push @src => defined $self->void ? _eq_inlined($self->void, sprintf('%s->void', $v))
                                     : sprintf('!defined %s->void', $v);

    return join "\n && ", @src;
}

sub _eq {
    my ($type, $other) = @_;

    if (ref $type && ref $type eq "ARRAY") {
        return unless ref $other eq "ARRAY";
        return unless @$type == @$other;
        for (my $i = 0; $i < @$type; $i++) {
            return unless $type->[$i] eq $other->[$i];
        }
    }
    else {
        return unless $type eq $other;
    }
    return 1;
}

sub _eq_inlined {
    my ($type, $v) = @_;

    my @src;
    if (ref $type && ref $type eq "ARRAY") {
        push @src => sprintf('ref %s eq "ARRAY"', $v);
        push @src => sprintf('%d == @{%s}', scalar @$type, $v);
        for (my $i = 0; $i < @$type; $i++) {
            push @src => sprintf('"%s" eq %s->[%d]', $type->[$i], $v, $i);
        }
    }
    else {
        push @src => sprintf('"%s" eq %s', $type, $v);
    }

    return join "\n && ", @src;
}

sub display {
    my $self = shift;

    if (_eq($self->scalar, $self->list) && _eq($self->list, $self->void)) {
        return $self->scalar . '';
    }
    else {
        my @r = map { $self->$_ ? "$_ => @{[$self->$_]}" : () } qw(scalar list void);
        return "(@{[join ', ', @r]})";
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sub::Meta::Returns - meta information about return values

=head1 SYNOPSIS

    use Sub::Meta::Returns;

    my $r = Sub::Meta::Returns->new(
        scalar  => 'Int',      # optional
        list    => 'ArrayRef', # optional
        void    => 'Void',     # optional
        coerce  => 1,          # optional
    );

    $r->scalar; # 'Int'
    $r->list;   # 'ArrayRef'
    $r->void;   # 'Void'
    $r->coerce; # 1

=head1 METHODS

=head2 new

Constructor of C<Sub::Meta::Returns>.

=head2 ACCESSORS

=head3 scalar

A type for value when called in scalar context.

=head3 set_scalar($scalar)

Setter for C<scalar>.

=head3 list

A type for value when called in list context.

=head3 set_list($list)

Setter for C<list>.

=head3 void

A type for value when called in void context.

=head3 set_void($void)

Setter for C<void>.

=head3 coerce

A boolean whether with coercions.

=head3 set_coerce($bool)

Setter for C<coerce>.

=head2 METHODS

=head3 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Returns> object is same or not.
Specifically, check whether C<scalar>, C<list> and C<void> are equal.

=head3 is_same_interface_inlined($other_meta_inlined)

Returns inlined C<is_same_interface> string.

=head3 display

Returns the display of Sub::Meta::Returns:

    use Sub::Meta::Returns;
    use Types::Standard qw(Tuple Str);
    my $meta = Sub::Meta::Returns->new(Tuple[Str,Str]);
    $meta->display; # 'Tuple[Str,Str]'

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

