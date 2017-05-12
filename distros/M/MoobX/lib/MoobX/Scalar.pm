package MoobX::Scalar;
our $AUTHORITY = 'cpan:YANICK'; 
# ABSTRACT: MoobX wrapper for scalar variables
$MoobX::Scalar::VERSION = '0.1.0';

use Moose;

has value => (
    is     => 'rw',
    writer => 'STORE',
);

sub FETCH { $_[0]->value }

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIESCALAR { $_[0]->new( value => $_[1]) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Scalar - MoobX wrapper for scalar variables

=head1 VERSION

version 0.1.0

=head1 DESCRIPTION

Class implementing a C<tie>ing interface for scalar variables.

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
