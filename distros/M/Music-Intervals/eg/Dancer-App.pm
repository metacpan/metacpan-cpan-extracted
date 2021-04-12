package App;

# ABSTRACT: Exposes the relationships between musical notes

use Dancer2;

set serializer => 'JSON';

use Music::Intervals;

our $VERSION = '0.02';

=head1 DESCRIPTION

* This is the module for the Dancer2 framework.

This API exposes the mathematical relationships between musical notes as JSON.

Example:

  > plackup bin/app.psgi # <- In one terminal. Then in another:
  > curl "http://localhost:5000/api/natural_intervals?notes=C+D+E&size=2"

=head1 ROUTES

=head2 /api/:resultset

The endpoint for results.

Possible resultsets:

  eq_tempered_frequencies
  eq_tempered_intervals
  eq_tempered_cents
  natural_frequencies
  natural_intervals
  natural_cents
  natural_prime_factors
  chord_names
  integer_notation

=cut

get '/api/:resultset' => sub {
    my $m = _instantiate(
        query_parameters->get('notes'),
        query_parameters->get('size'),
    );

    my $method = route_parameters->get('resultset');

    my $json = {};
    $json = $m->$method if keys %{ $m->$method };

    return $json;
};

sub _instantiate {
    my ($notes, $size) = @_;

    $notes ||= 'C E G';
    $notes = [ split /[\s,]+/, $notes ];

    $size ||= 3;

    my $m = Music::Intervals->new(
      notes    => $notes,
      size     => $size,
      chords   => 1,
      justin   => 1,
      equalt   => 1,
      freqs    => 1,
      interval => 1,
      cents    => 1,
      prime    => 1,
      integer  => 1,
    );
     
    $m->process;

    return $m;
};

true;

__END__

=head1 SEE ALSO

L<Dancer2>

L<Music::Intervals>

=cut
