package Syntax::Feature::In;
use strict;
use warnings;
use match::simple qw(match);
use Sub::Infix;
use Exporter qw(import);
our @EXPORT = qw(in);

our $VERSION = '0.0003'; # VERSION

sub install {
    my ($class, %args) = @_;
    no strict 'refs';
    *{$args{into} . '::in'} = infix { match @_ };
}

# ABSTRACT: provides an "in" operator as a replacement for smartmatch


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Syntax::Feature::In - provides an "in" operator as a replacement for smartmatch

=head1 VERSION

version 0.0003

=head1 SYNOPSIS

    use syntax 'in';

    my $found = 42 |in| [ 1 .. 100 ];

=head1 DESCRIPTION

This modules imports the C<in> operator.
It can be used as in infix operator:

    $foo |in| $bar

Or in a more traditional way:

    in->($foo, $bar)

It does a simplified version of smartmatch as described in L<match::simple>.

=head1 SEE ALSO

=over

=item *

L<match::simple>

=item *

L<Scalar::In>

=back

=head1 AUTHOR

Naveed Massjouni <naveed@vt.edu>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naveed Massjouni.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
