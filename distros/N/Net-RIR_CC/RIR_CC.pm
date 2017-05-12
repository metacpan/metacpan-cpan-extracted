package Net::RIR_CC;

use Mouse;
use File::ShareDir qw(dist_file);
use HTML::TableExtract;
use Net::RIR_CC::RIR;
use Carp;

use vars qw($VERSION);

$VERSION = '0.06';

has 'datafile'  => ( is => 'ro', isa => 'Str', default => sub {
  my $datafile = dist_file( 'Net-RIR_CC', 'list-of-country-codes-and-rirs-ordered-by-country-code.html' );
  -f $datafile or die "Missing datafile '$datafile'\n";
  return $datafile;
} );
has 'table'     => ( is => 'ro', lazy_build => 1 );
has 'cc_map'    => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
has 'a3_map'    => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );

sub _build_table {
  my $self = shift;

  my $te = HTML::TableExtract->new( headers => [ 'A 2', 'A 3', 'Region' ] );
  $te->parse_file( $self->datafile );

  die sprintf "Found %d tables in datafile, when expecting 1\n", scalar $te->tables
    if $te->tables != 1;

  return $te->first_table_found;
}

sub _map_table_with_key {
  my ($self, $key) = @_;

  my $map = {};
  for my $row ($self->table->rows) {
    my $value = $row->[$#$row];
    next if ! defined $value;
    $value =~ s/\sNCC$//;

    $map->{ $row->[$key] } = $value;
  }

  return $map;
}

sub _build_cc_map {
  my $self = shift;

  my $data = $self->_map_table_with_key(0);

  # Add missing codes not covered by the NRO page
  $data->{RS} = 'RIPE';             # Serbia
  $data->{ME} = 'RIPE';             # Montenegro
  $data->{JE} = 'RIPE';             # Jersey
  $data->{GG} = 'RIPE';             # Guernsey
  $data->{IM} = 'RIPE';             # Isle of Man
  $data->{MF} = 'ARIN';             # Saint Martin
  $data->{SS} = 'AFRINIC';          # South Sudan
  $data->{BQ} = 'LACNIC';           # Bonaire, Sint Eustatius and Saba
  $data->{UK} = 'RIPE';             # GB is official ISO-3166-2 code

  # Region codes
  $data->{EU} = 'RIPE';             # Europe
  $data->{AP} = 'APNIC';            # Asia-Pacific

  return $data;
}

sub _build_a3_map {
  my $self = shift;

  my $data = $self->_map_table_with_key(1);

  # Add missing codes not covered by the NRO page
  $data->{SRB} = 'RIPE';            # Serbia
  $data->{MNE} = 'RIPE';            # Montenegro
  $data->{JEY} = 'RIPE';            # Jersey
  $data->{GGY} = 'RIPE';            # Guernsey
  $data->{IMN} = 'RIPE';            # Isle of Man
  $data->{MAF} = 'ARIN';            # Saint Martin
  $data->{SSD} = 'AFRINIC';         # South Sudan
  $data->{BES} = 'LACNIC';          # Bonaire, Sint Eustatius and Saba

  return $data;
}

sub get_rir {
  my ($self, $code) = @_;

  croak "Invalid code '$code' (not alpha2 or alpha3)" if length $code != 2 and length $code != 3;

  my $name = length $code == 2 ? $self->cc_map->{$code} : $self->a3_map->{$code}
    or croak "Invalid code '$code'";

  return Net::RIR_CC::RIR->new( name => $name );
}

=head1 NAME

Net::RIR_CC - perl module for mapping country codes to RIRs

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use Net::RIR_CC;

    # Constructor
    $rc = Net::RIR_CC->new;

    # Or with an explicit (updated) data file
    $rc = Net::RIR_CC->new(datafile => '/tmp/list-of-country-codes-and-rirs-ordered-by-country-code');

    # Lookup an ISO-3166 alpha2 or alpha3 code, returning a Net::RIR_CC::RIR object
    $rir = $rc->get_rir('AU');
    $rir = $rc->get_rir('NZL');
    print $rir->name;


=head1 DESCRIPTION

Net::RIR_CC is a perl module for mapping ISO-3166 country codes to RIRs
(Regional Internet Registries), using the mappings from
L<http://www.nro.net/about-the-nro/list-of-country-codes-and-rirs-ordered-by-country-code>,
plus a few extras missing from that page.

A snapshot of this page is included with the distribution, but you can
download and load an updated version if you'd prefer. 

=head1 AUTHOR

Gavin Carr, C<< <gavin at openfusion.com.au> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-rir_cc at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-RIR_CC>.

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Gavin Carr.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;

