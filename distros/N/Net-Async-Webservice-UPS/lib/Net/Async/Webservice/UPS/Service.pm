package Net::Async::Webservice::UPS::Service;
$Net::Async::Webservice::UPS::Service::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::Service::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

# ABSTRACT: shipment service from UPS


has code => (
    is => 'ro',
    isa => ServiceCode,
);


has label => (
    is => 'ro',
    isa => ServiceLabel,
);


has total_charges => (
    is => 'ro',
    isa => Measure,
    required => 0,
);


has rates => (
    is => 'ro',
    isa => RateList,
    required => 0,
);


has rated_packages => (
    is => 'ro',
    isa => PackageList,
    required => 0,
);


has guaranteed_days => (
    is => 'ro',
    isa => Str,
    required => 0,
);

my %code_for_label = (
    NEXT_DAY_AIR            => '01',
    '2ND_DAY_AIR'           => '02',
    GROUND                  => '03',
    WORLDWIDE_EXPRESS       => '07',
    WORLDWIDE_EXPEDITED     => '08',
    STANDARD                => '11',
    '3_DAY_SELECT'          => '12',
    '3DAY_SELECT'           => '12',
    NEXT_DAY_AIR_SAVER      => '13',
    NEXT_DAY_AIR_EARLY_AM   => '14',
    WORLDWIDE_EXPRESS_PLUS  => '54',
    '2ND_DAY_AIR_AM'        => '59',
    SAVER                   => '65',
    TODAY_EXPRESS_SAVER     => '86',
    TODAY_EXPRESS           => '85',
    TODAY_DEDICATED_COURIER => '83',
    TODAY_STANDARD          => '82',
);
my %label_for_code = reverse %code_for_label;


sub label_for_code {
    my ($code) = @_;
    return $label_for_code{$code};
}

around BUILDARGS => sub {
    my ($orig,$class,@etc) = @_;
    my $args = $class->$orig(@etc);
    if ($args->{code} and not $args->{label}) {
        $args->{label} = $label_for_code{$args->{code}};
        if (!defined $args->{label}) {
            require Carp;
            Carp::croak "Bad service code $args->{code}";
        }
    }
    elsif ($args->{label} and not $args->{code}) {
        $args->{code} = $code_for_label{$args->{label}};
        if (!defined $args->{code}) {
            require Carp;
            Carp::croak "Bad service label $args->{label}";
        }
    }
    return $args;
};


sub name {
    my $self = shift;

    my $name = $self->label();
    $name =~ s/_/ /g;
    return $name;
}


sub cache_id { return $_[0]->code }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::Service - shipment service from UPS

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class describe a particular shipping service. They
can be used as parameter to
L<Net::Async::Webservice::UPS/request_rate>, and are also used inside
L<Net::Async::Webservice::UPS::Response::Rate>, as returned by that
same method.

=head1 ATTRIBUTES

=head2 C<code>

UPS service code, see
L<Net::Async::Webservice::UPS::Types/ServiceCode>. If you construct an
object passing only L</label>, the code corresponding to that label
will be used.

=head2 C<label>

UPS service label, see
L<Net::Async::Webservice::UPS::Types/ServiceLabel>. If you construct
an object passing only L</code>, the label corresponding to that code
will be used.

=head2 C<total_charges>

If thes service has been returned by C<request_rate>, this is the
total charges for the shipment, equal to the sum of C<total_charges>
of all the rates in L</rates>.

=head2 C<rates>

If thes service has been returned by C<request_rate>, this is a
arrayref of L<Net::Async::Webservice::UPS::Rate> for each package.

=head2 C<rated_packages>

If thes service has been returned by C<request_rate>, this is a
arrayref of L<Net::Async::Webservice::UPS::Package> holding the rated
packages.

=head2 C<guaranteed_days>

If thes service has been returned by C<request_rate>, this is number
of guaranteed days in transit.

=head1 METHODS

=head2 C<name>

Returns the L</label>, with underscores replaced by spaces.

=head2 C<cache_id>

Returns a string identifying this service.

=head1 FUNCTIONS

=head2 C<label_for_code>

  my $label = Net::Async::Webservice::UPS::Service::label_for_code($code);

I<Not a method>. Returns the UPS service label string for the given
service code.

=for Pod::Coverage BUILDARGS

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
