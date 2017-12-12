use strict;
use warnings;

package Net::Amazon::Route53::Change;
$Net::Amazon::Route53::Change::VERSION = '0.173450';
use Moo;
use Types::Standard qw(InstanceOf Str);
use HTML::Entities;

=head2 SYNOPSIS

    my $change = Net::Amazon::Route53::Change->new(...);
    # use methods on $change

=cut

=head2 ATTRIBUTES

=cut

=head3 route53

A L<Net::Amazon::Route53> object, needed and used to perform requests
to Amazon's Route 53 service

=cut

has 'route53' => ( is => 'rw', isa => InstanceOf['Net::Amazon::Route53'], required => 1, weak_ref => 1 );

=head3 id

The change request's id

=head3 status

The change request's status; usually C<PENDING> or C<INSYNC>.

=head3 submittedat

The date/time the change was submitted at, in the format:
C<YYYY-MM-DDTHH:MM::SS.UUUZ>

=head3 comment

Any Comment given when the zone is created

=cut

has 'id'          => ( is => 'rw', isa => Str, required => 1, default => '' );
has 'status'      => ( is => 'rw', isa => Str, required => 1, default => '' );
has 'submittedat' => ( is => 'rw', isa => Str, required => 1, default => '' );

=head2 METHODS

=cut

=head3 refresh

Refresh the details of the change. When performed, the object's status is current.

=cut

sub refresh
{
    my $self = shift;
    die "Cannot refresh without an id\n" unless length $self->id;
    my $resp = $self->route53->request( 'get', 'https://route53.amazonaws.com/2010-10-01/' . $self->id, );
    for (qw/Id Status SubmittedAt/) {
        my $method = lc $_;
        $self->$method( decode_entities( $resp->{ChangeInfo}{$_} ) );
    }
}

no Moo;

=head1 AUTHOR

Marco FONTANI <mfontani@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Marco FONTANI.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
