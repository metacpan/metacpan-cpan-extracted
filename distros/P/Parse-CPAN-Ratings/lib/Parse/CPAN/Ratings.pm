package Parse::CPAN::Ratings;
use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Path::Class;
use Parse::CPAN::Ratings::Rating;
use Parse::CSV;
our $VERSION = '0.33';

has 'filename' =>
    ( is => 'ro', isa => 'Path::Class::File', required => 1, coerce => 1 );

has 'db' => (
    is         => 'ro',
    isa        => 'HashRef[Parse::CPAN::Ratings::Rating]',
    lazy_build => 1,
);

no Moose;

__PACKAGE__->meta->make_immutable;

sub _build_db {
    my $self     = shift;
    my $filename = $self->filename;
    my %db;

    my $parser = Parse::CSV->new(
        file   => $filename->stringify,
        fields => 'auto',
    );
    while ( my $rating = $parser->fetch ) {
        $db{ $rating->{distribution} } = Parse::CPAN::Ratings::Rating->new(
            distribution => $rating->{distribution},
            rating       => $rating->{rating},
            review_count => $rating->{review_count},
        );
    }
    if ( $parser->errstr ) {
        confess( "Error parsing CSV: " . $parser->errstr );
    }
    return \%db;
}

sub rating {
    my ( $self, $distribution ) = @_;
    return $self->db->{$distribution};
}

sub ratings {
    my $self = shift;
    return values %{ $self->db };
}

__END__

=head1 NAME

Parse::CPAN::Ratings - Parse CPAN ratings

=head1 SYNOPSIS

  my $ratings
      = Parse::CPAN::Ratings->new( filename => 't/all_ratings_100.csv' );

  my $rating = $ratings->rating('Archive-Zip');
  print $rating->distribution . "\n"; # Archive-Zip
  print $rating->rating . "\n";       # 3.8
  print $rating->review_count . "\n"; # 6

  my @all_ratings = $ratings->ratings;

=head1 DESCRIPTION

CPAN ratings is a web site where programmers can rate CPAN modules:

  http://cpanratings.perl.org/
  
It provides a file containing the average ratings at:

  http://cpanratings.perl.org/csv/all_ratings.csv

This module provides a simple interface to that file.

=head1 METHODS

=head2 rating

Returns a L<Parse::CPAN::Ratings::Rating> object representing
the distribution:

  my $rating = $ratings->rating('Archive-Zip');
  print $rating->distribution . "\n"; # Archive-Zip
  print $rating->rating . "\n";       # 3.8
  print $rating->review_count . "\n"; # 6

=head2 ratings

Returns a list of all L<Parse::CPAN::Ratings::Rating> objects.

  my @all_ratings = $ratings->ratings;

=head1 SEE ALSO

L<Parse::CPAN::Ratings::Rating>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
