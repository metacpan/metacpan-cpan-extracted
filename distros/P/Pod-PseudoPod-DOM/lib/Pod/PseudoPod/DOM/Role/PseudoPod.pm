package Pod::PseudoPod::DOM::Role::PseudoPod;
# ABSTRACT: a P::PP::D formatter to produce PseudoPod

use strict;
use warnings;

use Moose::Role;

requires 'type';

sub emit
{
    my $self = shift;
    my $type = $self->type;

    my $emit = 'emit_' . $type;
    $self->$emit();
}

sub emit_document { return shift->emit_kids }

sub emit_kids { join '', map { $_->emit } @{ shift->children } }

sub emit_header
{
    my $self = shift;

    return '=head1 ' . $self->text->emit . "\n\n";
}

sub emit_text
{
    my $self = shift;
    return $self->content || '';
}

sub emit_literal
{
    my $self = shift;
    return "=begin literal\n\n" . $self->emit_kids . "=end literal\n\n";
}

sub emit_paragraph
{
    my $self     = shift;
    my $content  = $self->emit_kids;
    return '' unless defined $content;
    return $content . "\n\n";
}

sub emit_anchor
{
    my $self = shift;
    return 'Z<' . $self->content->emit . '>';
}

sub emit_italics
{
    my $self = shift;
    return 'I<' . $self->content->emit . '>';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::PseudoPod::DOM::Role::PseudoPod - a P::PP::D formatter to produce PseudoPod

=head1 VERSION

version 1.20210620.2040

=head1 AUTHOR

chromatic <chromatic@wgz.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
