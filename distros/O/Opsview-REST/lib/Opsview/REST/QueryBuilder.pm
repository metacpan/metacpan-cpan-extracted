package Opsview::REST::QueryBuilder;
{
  $Opsview::REST::QueryBuilder::VERSION = '0.013';
}

use Moo::Role;
use URI;
use URI::QueryParam;

requires 'base';

has uri => (
    is      => 'ro',
    default => sub { URI->new; },
    handles => [qw/ as_string /],
);

has path => (
    is  => 'ro',
);

has args => (
    is  => 'ro',
    isa => sub { die '"args" must be a hashref' unless ref $_[0] eq 'HASH' },
);

sub BUILDARGS {
    my ($class, $path, @args) = @_;

    if (@_ == 1) {
        return {};
    } else {
        return {
            path => $path,
            args => { @args },
        };
    }
}

sub BUILD {
    my $self = shift;

    $self->uri->path($self->base . ($self->path || ''));
    $self->uri->query_form($self->args);
}

1;
__END__

=pod

=head1 NAME

Opsview::REST::QueryBuilder - Role to transform attributes into a valid method URL

=head1 SYNOPSIS

    use Moo;
    
    has base => ( default => '/downtime' );

    with 'Opsview::REST::QueryBuilder'

=head1 DESCRIPTION

This is a role to help adding functionalities to the Opsview::REST. It only
requires the consumer to have a "base", and it will generate a valid method
URL when the consumer object is instantiated.

It offers the "as_string" method, which is handled by L<URI>.

=head1 AUTHOR

=over 4

=item *

Miquel Ruiz <mruiz@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Miquel Ruiz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
