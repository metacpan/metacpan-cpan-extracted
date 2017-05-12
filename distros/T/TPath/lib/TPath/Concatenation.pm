package TPath::Concatenation;
$TPath::Concatenation::VERSION = '1.007';
# ABSTRACT: handles the string concatenation in C<//@foo[1 ~ @bar ~ "quux"]>


use v5.10;
no if $] >= 5.018, warnings => "experimental";

use Moose;
use TPath::TypeConstraints;
use namespace::autoclean;


with 'TPath::Stringifiable';


has args => ( is => 'ro', isa => 'ArrayRef[ConcatArg]' );

has _arg_subs => (
    is      => 'ro',
    isa     => 'ArrayRef[CodeRef]',
    lazy    => 1,
    builder => '_build_arg_subs'
);

sub concatenate {
    my ( $self, $ctx ) = @_;
    my $s = '';
    $s .= $_->($ctx) for @{ $self->_arg_subs };
    return $s;
}

sub _build_arg_subs {
    my $self = shift;
    my @codes;
    for my $arg ( @{ $self->args } ) {
        my $sub;
        for ($arg) {
            when ( !blessed $_ ) {
                $sub = sub { $arg }
            }
            when ( $_->isa('TPath::Attribute') ) {
                $sub = sub { $arg->apply(shift) }
            }
            when ( $_->isa('TPath::Math') ) {
                $sub = sub { $arg->to_num(shift) }
            }
            when ( $_->isa('TPath::Expression') ) {
                $sub = sub { join '', @{ $arg->_select( shift, 1 ) } }
            }
            default { die 'unexpected concatenation argument type: ' . ref $_ }
        }
        push @codes, $sub;
    }
    return \@codes;
}

sub to_string {
    my $self      = shift;
    my $s         = '';
    my $non_first = 0;
    for my $arg ( @{ $self->args } ) {
        $s .= ' ~ ' if $non_first++;
        $s .= ref $arg ? $arg->to_string : $self->_stringify($arg);
    }
    return $s;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

TPath::Concatenation - handles the string concatenation in C<//@foo[1 ~ @bar ~ "quux"]>

=head1 VERSION

version 1.007

=head1 DESCRIPTION

For use in compiled TPath expressions. Not for external consumption.

=head1 ATTRIBUTES

=head2 args

Arguments to concatenate.

=head1 ROLES

L<TPath::Stringifiable>

=head1 AUTHOR

David F. Houghton <dfhoughton@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by David F. Houghton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
