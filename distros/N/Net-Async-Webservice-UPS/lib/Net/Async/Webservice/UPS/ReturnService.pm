package Net::Async::Webservice::UPS::ReturnService;
$Net::Async::Webservice::UPS::ReturnService::VERSION = '1.1.4';
{
  $Net::Async::Webservice::UPS::ReturnService::DIST = 'Net-Async-Webservice-UPS';
}
use Moo;
use 5.010;
use Types::Standard qw(Str);
use Net::Async::Webservice::UPS::Types ':types';
use namespace::autoclean;

# ABSTRACT: shipment return service from UPS


has code => (
    is => 'ro',
    isa => ReturnServiceCode,
);


has label => (
    is => 'ro',
    isa => ReturnServiceLabel,
);

my %code_for_label = (
    PNM => '2',
    RS1 => '3',
    RS3 => '5',
    ERL => '8',
    PRL => '9',
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
            Carp::croak "Bad return service code $args->{code}";
        }
    }
    elsif ($args->{label} and not $args->{code}) {
        $args->{code} = $code_for_label{$args->{label}};
        if (!defined $args->{code}) {
            require Carp;
            Carp::croak "Bad return service label $args->{label}";
        }
    }
    return $args;
};


sub cache_id { return $_[0]->code }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::UPS::ReturnService - shipment return service from UPS

=head1 VERSION

version 1.1.4

=head1 DESCRIPTION

Instances of this class describe a particular shipping return service.

=head1 ATTRIBUTES

=head2 C<code>

UPS service code, see
L<Net::Async::Webservice::UPS::Types/ReturnServiceCode>. If you
construct an object passing only L</label>, the code corresponding to
that label will be used.

=head2 C<label>

UPS service label, see
L<Net::Async::Webservice::UPS::Types/ReturnServiceLabel>. If you
construct an object passing only L</code>, the label corresponding to
that code will be used.

=head1 METHODS

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
