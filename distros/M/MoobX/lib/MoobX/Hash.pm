package MoobX::Hash;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: MoobX wrapper for hash variables
$MoobX::Hash::VERSION = '0.1.2';

use Moose;

use experimental 'postderef';

has value => (
    traits => [ 'Hash' ],
    is => 'rw',
    default => sub { +{} },
    handles => {
        FETCH => 'get',
        STORE => 'set',
        CLEAR => 'clear',
        DELETE => 'delete',
        EXISTS => 'exists',
    },
);

sub BUILD_ARGS {
    my( $class, @args ) = @_;

    unshift @args, 'value' if @args == 1;

    return { @args }
}

sub TIEHASH { 
    (shift)->new( value => +{ @_ } ) 
}

sub FIRSTKEY { my $self = shift; my $a = scalar keys $self->value->%*; each $self->value->%* }
sub NEXTKEY  { my $self = shift; each $self->value->%* }



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MoobX::Hash - MoobX wrapper for hash variables

=head1 VERSION

version 0.1.2

=head1 DESCRIPTION

Class implementing a C<tie>ing interface for hash variables.

Used internally by L<MoobX>.

=head1 AUTHOR

Yanick Champoux <yanick@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
