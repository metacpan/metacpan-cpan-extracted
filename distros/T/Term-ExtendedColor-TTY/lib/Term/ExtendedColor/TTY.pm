package Term::ExtendedColor::TTY;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.030';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(
    set_tty_color
  );
}
use Carp qw(croak);


my %color_indexes = (
  0   => 'P0', #black
  1   => 'P8', # dark grey
  2   => 'P1', # dark red
  3   => 'P9', # red
  4   => 'P2', # dark green
  5   => 'PA', # green
  6   => 'P3', # brown
  7   => 'PB', # yellow
  8   => 'P4', # darkblue
  9   => 'PC', # blue
  10  => 'P5', # dark magenta
  11  => 'PD', # magenta
  12  => 'P6', # dark cyan
  13  => 'PE', # cyan
  14  => 'P7', # dark white
  15  => 'PF', # white
);


sub set_tty_color {
  my $map = shift;

  ref($map) eq 'HASH' or croak("set_tty_color() expects an hashref");

  my %results;

  for my $index(sort{ $a <=> $b } keys(%{$map})) {
    if( ($index < 0) or ($index > 15) ) {
      croak("'$index': color index must be between 0 and 15, inclusive\n");
    }
    if($map->{$index} !~ m/^(?:[A-Za-z0-9]{6}$)/) {
      croak(
        "'$map->{$index}' is not a valid hexadecimal color representation\n"
      );
    }

    $results{$index} = sprintf("\e]%s",
      $color_indexes{$index}
        . $map->{$index}, #P0ffffff
      );
  }

  return \%results;
}


1;


__END__


=pod

=head1 NAME

Term::ExtendedColor::TTY - Set colors in the TTY

=head1 SYNOPSIS

    use Term::ExtendedColor::TTY;

    my %colorscheme = (
      0   => '030303',
      1   => '1c1c1c',
      2   => 'ff4747',
      3   => 'ff6767',
      4   => '2b4626',
      5   => 'b03b31',
      6   => 'ff8f00',
      7   => 'bdf1ed',
      8   => '1165e9',
      9   => '5496ff',
      10  => 'aef7af',
      11  => 'b50077',
      12  => 'cb1c13',
      13  => '6be603',
      14  => 'ffffff',
    );

    my $result = set_tty_color( \%colorscheme );

    for my $index(sort(keys(%{$result}))) {
      print "Setting color index $index... $result->{$index}\n";
    }


=head1 DESCRIPTION

L<Term::ExtendedColor::TTY> provides functions for changing and querying the
Linux TTY (or Virtual Console, if you wish) for various resources, such as
colors.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 set_tty_color()

Parameters: \%colormap

Returns:    \%results

  my $ref = set_tty_color( \%colorscheme );

Returns a hash reference where its keys are the color indexes ( 0 .. 14) and the
values are escape sequences crafted together to be printed straight to the TTY.

=head1 SEE ALSO

L<Term::ExtendedColor>, L<Term::ExtendedColor::Xresources>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the B<Term::ExtendedColor::TTY>s L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
