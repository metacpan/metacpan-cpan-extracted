package Parse::CPAN::Ratings::Rating;
use Moose;
use MooseX::StrictConstructor;

has 'distribution' => ( is => 'ro', isa => 'Str' );
has 'rating'       => ( is => 'ro', isa => 'Num' );
has 'review_count' => ( is => 'ro', isa => 'Int' );

no Moose;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Parse::CPAN::Ratings::Rating - Parse CPAN ratings

=head1 SYNOPSIS

  my $ratings
      = Parse::CPAN::Ratings->new( filename => 't/all_ratings_100.csv' );

  my $rating = $ratings->rating('Archive-Zip');
  print $rating->distribution . "\n"; # Archive-Zip
  print $rating->rating . "\n";       # 3.8
  print $rating->review_count . "\n"; # 6

=head1 DESCRIPTION

This module represents a CPAN rating.

=head1 SEE ALSO

L<Parse::CPAN::Ratings>.

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2009, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
