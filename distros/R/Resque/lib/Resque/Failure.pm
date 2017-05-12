package Resque::Failure;
# ABSTRACT: Role to be consumed by any failure class.
$Resque::Failure::VERSION = '0.31';
use Moose::Role;
with 'Resque::Encoder';

use overload '""' => \&stringify;
use DateTime;
use Moose::Util::TypeConstraints;

requires 'save';

has 'worker' => (
    is       => 'ro',
    isa      => 'Resque::Worker',
    required => 1
);

has 'job' => (
    is      => 'ro',
    handles  => {
        resque  => 'resque',
        requeue => 'enqueue',
        payload => 'payload',
        queue   => 'queue',
    },
    required => 1
);

has created => (
    is      => 'rw',
    default => sub { DateTime->now }
);

has failed_at => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->created->strftime("%Y/%m/%d %H:%M:%S %Z");
    },
    predicate => 'has_failed_at'
);

has exception => (
    is      => 'rw',
    lazy    => 1,
    default => sub { 'Resque::Failure' }
);

coerce 'Str'
    => from 'Object'
    => via {"$_"};

has error     => ( is => 'rw', isa => 'Str', required => 1, coerce => 1 );
# ruby 'resque-web' expect backtrace is array.
has backtrace => ( is => 'rw', isa => 'ArrayRef[Str]' );

around error => sub {
    my $orig = shift;
    my $self = shift;

    return $self->$orig() unless @_;

    my ( $value, @stack ) = split "\n", shift;
    $self->backtrace( \@stack );
    return $self->$orig($value);
};

sub BUILD {
    my $self = shift;
    if ( (my $error = $self->error) =~ /\n/ ) {
        $self->error($error);
    }
}

sub stringify { $_[0]->error }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Resque::Failure - Role to be consumed by any failure class.

=head1 VERSION

version 0.31

=head1 METHODS

=head2 BUILD

=head2 stringify

=head1 AUTHOR

Diego Kuperman <diego@freekeylabs.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Diego Kuperman.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
