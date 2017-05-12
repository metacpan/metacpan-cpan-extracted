package Net::RIR_CC::RIR;

use Mouse;
use Carp;

my $rir_data = {
  AFRINIC   => {
    code => 'AF',
    region => 'Africa and Indian Ocean',
    whois_server => 'whois.afrinic.net',
  },
  APNIC     => {
    code => 'AP',
    region => 'Asia-Pacific',
    whois_server => 'whois.apnic.net',
  },
  ARIN      => {
    code => 'AR',
    region => 'North America',
    whois_server => 'whois.arin.net',
  },
  LACNIC    => {
    code => 'LA',
    region => 'Latin America',
    whois_server => 'whois.lacnic.net',
  },
  RIPE      => {
    code => 'RI',
    region => 'Europe',
    whois_server => 'whois.ripe.net',
  },
};

has 'name'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'code'          => ( is => 'ro', isa => 'Str', required => 1 );
has 'region'        => ( is => 'ro', isa => 'Str', required => 1 );
has 'whois_server'  => ( is => 'ro', isa => 'Str', required => 1 );

around BUILDARGS => sub {
  my ($orig, $class, %arg) = @_;

  my $data = $rir_data->{ $arg{name} }
    or croak "Invalid RIR '$arg{name}'";

  $arg{$_} ||= $data->{$_} foreach keys %$data;

  return $class->$orig(%arg);
};

sub dump {
  my $self = shift;
  sprintf "%s\t%s\t%s", $self->name, $self->code, $self->region;
}

=head1 NAME

Net::RIR_CC::RIR - RIR class

=head1 SYNOPSIS

    # Typically returned by a Net::RIR_CC get_rir() call
    $rir = $rc->get_rir('AU');

    # Methods
    print $rir->name;               # e.g. APNIC
    print $rir->code;               # e.g. AP
    print $rir->region;             # e.g. Asia-Pacific
    print $rir->whois_server;       # e.g. whois.apnic.net

    print $rir->dump;

=head1 DESCRIPTION

Net::RIR_CC::RR is a class modelling an RIR (Regional Internet Registry),
one of:

    Name        Code    Region
    -------------------------------------------
    AFRINIC     AF      Africa and Indian Ocean
    APNIC       AP      Asia-Pacific
    ARIN        AR      North America
    LACNIC      LA      Latin America
    RIPE        RI      Europe

=head1 SEE ALSO

L<Net::RIR_CC>

=head1 AUTHOR

Gavin Carr, C<< <gavin at openfusion.com.au> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gavin Carr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

