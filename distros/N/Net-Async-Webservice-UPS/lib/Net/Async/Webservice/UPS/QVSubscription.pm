package Net::Async::Webservice::UPS::QVSubscription;
$Net::Async::Webservice::UPS::QVSubscription::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::QVSubscription::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str Int Bool StrictNum);
use Types::DateTime
    DateTime => { -as => 'DateTimeT' },
    Format => { -as => 'DTFormat' };
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

my $dt = DateTimeT->plus_coercions(DTFormat['ISO8601']);

# ABSTRACT: a UPS Quantum View subscription


has begin_date => (
    is => 'ro',
    isa => $dt,
    coerce => $dt->coercion
);


has end_date => (
    is => 'ro',
    isa => $dt,
    coerce => $dt->coercion
);


has name => (
    is => 'ro',
    isa => Str,
);


has filename => (
    is => 'ro',
    isa => Str,
);


sub as_hash {
    my ($self) = @_;

    my $sr = {
        ( $self->name ? ( Name => $self->name ) : () ),
        ( $self->filename ? ( FileName => $self->filename ) : () ),
    };

    for my $f (qw(begin end)){
        my $method = "${f}_date";
        if ($self->$method) {
            my $date = $self->$method->clone->set_time_zone('UTC');
            $sr->{DateTimeRange}{"\u${f}DateTime"} =
                $date->strftime('%Y%m%d%H%M%S');
        }
    }

    return $sr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::QVSubscription - a UPS Quantum View subscription

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class can be passed to
L<Net::Async::Webservice::UPS/qv_events> to specify what events you
want to retrieve.

=head1 ATTRIBUTES

=head2 C<begin_date>

Optional L<DateTime> (with coercion from ISO 8601 strings), to only
retrieve events after this date.

=head2 C<end_date>

Optional L<DateTime> (with coercion from ISO 8601 strings), to only
retrieve events before this date.

=head2 C<name>

Optional string, the name of a subscription.

=head2 C<filename>

Optional string, the name of a Quantum View subscription file.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Simple>, will
produce the XML fragment needed in UPS C<QVEvents> requests to
represent this subscription.

=head1 AUTHORS

=over 4

=item *

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=item *

Sherzod B. Ruzmetov <sherzodr@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
