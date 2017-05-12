use strict;
use warnings;

package Number::Compare::Duration;

use base qw(Number::Compare);
use Carp ();
our $VERSION = '0.001';

my %mult = (
  s => 1,
  m => 60,
  h => 60 * 60,
  d => 60 * 60 * 24,
);

sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $expr = $class->parse_to_perl(shift);
  return bless eval
    "sub { $class->parse_input(\$_[0]) $expr }",
    $class;
}

sub parse_to_perl {
  my ($class, $test) = @_;

  $test =~ m{^
            ([<>]=?)?  # comparison
            (.*?)      # value
            ([smhd]?)? # magnitude
            $}x
    or Carp::croak "don't understand '$test' as a test";
  my $comp   = $1 || '==';
  my $target = $2;
  my $mag    = $3 || 's';
  $target *= $mult{$mag};
  return "$comp $target";
}

sub parse_input {
  my ($self, $expr) = @_;
  $expr =~ m{^ (.*?)([smhd]?)? $}x
    or Carp::croak "don't understand '$expr' as expression";
  return $1 * $mult{$2 || 's'};
}

1;
__END__

=head1 NAME

Number::Compare::Duration - numeric comparisons of time durations

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

    Number::Compare::Duration->new('>10d')->(86400 * 9);
    # false, 9 days is not more than 10

=head1 DESCRIPTION

See L<Number::Compare> for a basic description.

Number::Compare::Duration uses different magnitudes than Number::Compare.  They
are: C<s> for seconds, C<m> for minutes, C<h> for hours, C<d> for days.  No
accounting for daylight savings is done; each day is 86400 seconds.  The
default magnitude is C<s> (seconds).

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-number-compare-duration at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Number-Compare-Duration>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Number::Compare::Duration


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Number-Compare-Duration>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Number-Compare-Duration>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Number-Compare-Duration>

=item * Search CPAN

L<http://search.cpan.org/dist/Number-Compare-Duration>

=back


=head1 SEE ALSO

L<Number::Compare>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

=begin Pod::Coverage

  parse_input
  parse_to_perl
  new

=end Pod::Coverage

