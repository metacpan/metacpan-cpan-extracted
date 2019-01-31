package Term::ExtendedColor::Dzen;
use strict;
use warnings;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

  $VERSION = '0.002';
  @ISA     = qw(Exporter);

  @EXPORT_OK = qw(
    fgd
    bgd
  );

  %EXPORT_TAGS = (
    attributes => [ qw(fgd bgd) ],
    all        => [ @EXPORT_OK ],
  );
}


sub fgd {
  if(!@_) {
    return "^fg()"
  }
  my ($color, $data) = @_;
  $color = "#$color" unless $color =~ m/^#/;
  return "^fg($color)$data^fg()";
}

sub bgd {
  if(!@_) {
    return "^bg()"
  }
  my ($color, $data) = @_;
  $color = "#$color" unless $color =~ m/^#/;
  return "^bg($color)$data^bg()";
}




1;

__END__

=pod

=head1 NAME

Term::ExtendedColor::Dzen - Color input and add dzen(2) compatible attributes

=head1 SYNOPSIS

    use Term::ExtendedColor::Dzen qw(fgd bgd);

    print fgd('#ff0000', 'this is red foreground');
    print bgd('#fff00',  'this is yellow background');

    print fgd('#000', bgd('#ffffff', 'this is black on white background'));

=head1 DESCRIPTION

B<Term::ExtendedColor::Dzen> provides functionality for coloring input data
with dzen compatible attributes.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 fgd('#fff', $string)

Sets foreground color. When called without arguments, returns the fg
reset string.

    my $white_fg = fgd('#fff', 'white foreground');

=head2 bgd('#000', $string)

Sets background color. When called without arguments, returns the bg
reset string.

    my $black_bg = bg('#000', 'black background');

Like C<fgd()>, but sets background colors.

These two can be combined:

    my $str = fgd('#000', bgd('#ffffff', 'this is black on white background'));

which yields the combined string:

    ^fg(#000)^bg(#fff)this is black on white background^bg()^fg()


=head1 SEE ALSO

L<dzen|https://github.com/robm/dzen>

L<dzen2|https://github.com/minos-org/dzen2>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se

Copyright 2019- the B<Term::ExtendedColor::Dzen> L</AUTHOR>
and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
