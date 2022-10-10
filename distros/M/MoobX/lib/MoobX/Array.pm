package MoobX::Array;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: MoobX wrapper for array variables
$MoobX::Array::VERSION = '0.1.2';

use Moose;

has value => (
    traits => [ 'Array' ],
    is => 'rw',
    default => sub { [] },
    handles => {
        FETCHSIZE => 'count',
        CLEAR     => 'clear',
        STORE     => 'set',
        FETCH     => 'get',
        PUSH      => 'push',
    },
);

sub EXTEND { }

sub STORESIZE { }

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIEARRAY { 
    (shift)->new( value => [ @_ ] ) 
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Array - MoobX wrapper for array variables

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

Class implementing a C<tie>ing interface for array variables.

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
