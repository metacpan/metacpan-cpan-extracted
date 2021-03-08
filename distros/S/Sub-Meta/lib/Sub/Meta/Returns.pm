package Sub::Meta::Returns;
use 5.010;
use strict;
use warnings;

our $VERSION = "0.07";

use Scalar::Util ();

use overload
    fallback => 1,
    eq => \&is_same_interface
    ;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? ref $_[0] && ref $_[0] eq 'HASH' ? %{$_[0]}
                       : ( scalar => $_[0], list => $_[0], void => $_[0] )
             : @_;

    bless \%args => $class;
}

sub scalar() :method { $_[0]{scalar} }
sub list()           { $_[0]{list} }
sub void()           { $_[0]{void} }

sub set_scalar($)    { $_[0]{scalar} = $_[1]; $_[0] }
sub set_list($)      { $_[0]{list}   = $_[1]; $_[0] }
sub set_void($)      { $_[0]{void}   = $_[1]; $_[0] }

sub coerce()      { !!$_[0]{coerce} }
sub set_coerce($) { $_[0]{coerce} = defined $_[1] ? $_[1] : 1; $_[0] }

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

=head2 OTHERS

=head3 is_same_interface($other_meta)

A boolean value indicating whether C<Sub::Meta::Returns> object is same or not.
Specifically, check whether C<scalar>, C<list> and C<void> are equal.

=head3 is_same_interface_inlined($other_meta_inlined)

Returns inlined C<is_same_interface> string.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly@cpan.orgE<gt>

=cut

