#!/usr/bin/perl
package Term::ExtendedColor::Xresources;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.072';
  @ISA     = qw(Exporter);
  @EXPORT_OK = qw(
    set_xterm_color
    get_xterm_color
    get_xterm_colors

    set_background_color
    set_foreground_color
  );
}

use Carp qw(croak);
use Term::ReadKey;

*get_xterm_color = *get_xterm_colors;

sub get_xterm_colors {
  my $arg = shift;

  my $index = (exists($arg->{index})) ? $arg->{index} :  [0 .. 255];

  my @indexes;

  if(ref($index) eq 'ARRAY') {
    push(@indexes, @{$index});
  }
  elsif(ref($index) eq '') {
    push(@indexes, $index);
  }

  if( grep { $_ < 0 } @indexes ) {
    croak("Index must be a value within 0 .. 255, inclusive\n");
  }

  open(my $tty, '<', '/dev/tty') or croak("Can not open /dev/tty: $!\n");

  my $colors;
  for my $i(@indexes) {
    next if not defined $i;

    ReadMode('raw', $tty);

    print "\e]4;$i;?\a"; # the '?' indicates a query

    my $response = '';
    my ($r, $g, $b);
    while(1) {
      if ($response =~ m[ rgb: (.{4}) / (.{4}) / (.{4}) ]x) {
        ($r, $g, $b) = map { substr $_, 0, 2 } ($1, $2, $3);
        last;
      }
      else {
        $response .= ReadKey(0, $tty);
      }
    }

    ReadMode('normal');

    $colors->{$i}->{raw} = $response;
    # Return in base 10 by default
    if($arg->{type} eq 'hex') {
      $colors->{$i}->{red}   = $r; # ff
      $colors->{$i}->{green} = $g;
      $colors->{$i}->{blue}  = $b;
      $colors->{$i}->{rgb}   = "$r$g$b";
    }
    else {
      ($r, $g, $b) = (hex($r), hex($g), hex($b));

      $colors->{$i}->{red}   = $r; # 255
      $colors->{$i}->{green} = $g;
      $colors->{$i}->{blue}  = $b;
      $colors->{$i}->{rgb}   = "$r/$g/$b"; # 255/255/0
    }

    $colors->{$i}{r} = $colors->{$i}{red};
    $colors->{$i}{g} = $colors->{$i}{green};
    $colors->{$i}{b} = $colors->{$i}{blue};
  }
  return $colors;
}

sub set_xterm_color {
  # color => index
  my $old_colors = shift;

  if(ref($old_colors) ne 'HASH') {
    croak("Hash reference expected");
  }

  my %new_colors;

  for my $index(keys(%{ $old_colors })) {
    if( ($index < 0) or ($index > 255) ) {
      next;
    }
    if($old_colors->{$index} !~ /^[A-Fa-f0-9]{6}$/) {
      next;
    }

    my($r, $g, $b) = $old_colors->{$index} =~ m/(..)/g;


    my $term = $ENV{TERM};

    # This is for GNU Screen and Tmux
    # Tmux identifies itself as GNU Screen
    # "\eP\e]4;198;rgb:50/20/40\a\e\\"

    # echo -e "\033]12;green\007" should change the cursor color, but inside of
    #  screen, you have to wrap all that with "\eP" and "\a\e\\"

    if($term =~ m/^screen/) {
      $new_colors{ $index } = "\eP\e]4;$index;rgb:$r/$g/$b\a\e\\";
    }
    else {
      $new_colors{ $index } = "\e]4;$index;rgb:$r/$g/$b\e\\"
    }
  }
  if(!defined( wantarray() )) {
    print for values %new_colors;
  }
  else {
    return \%new_colors;
  }
}

sub set_background_color {
  my $color = shift;
  $color =~ s/^#//g;

  my $esc = "\e]11;#$color\007";

  if(!defined( wantarray() )) {
    print $esc;
  }
  else {
    return $esc;
  }
}

sub set_foreground_color {
  my $color = shift;
  $color =~ s/^#//g;

  my $esc = "\e]10;#$color\007";

  if(!defined( wantarray() )) {
    print $esc;
  }
  else {
    return $esc;
  }
}

1;

__END__

=pod

=head1 NAME

Term::ExtendedColor::Xresources - Query and set various Xresources

=head1 SYNOPSIS

    use Term::ExtendedColor::Xresources qw(
      get_xterm_color
      set_xterm_color
      set_foreground_color
      set_background_color
    );

    # make color index 220 represent red instead of yellow
    set_xterm_color({ 220 => 'ff0000'});

    # get RGB values for all defined colors
    my $colors = get_xterm_color({
      index => [0 .. 255], # default
      type  => 'hex',      # default is base 10
    });

    # change the background color to red...
    set_background_color('ff0000');

    # .. and the foreground color to yellow
    set_foreground_color('ffff00');

=head1 DESCRIPTION

B<Term::ExtendedColor::Xresources> provides functions for changing and querying
the underlying X terminal emulator for various X resources.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 set_xterm_color()

  # Switch yellow and red
  my $new_colors = set_xterm_color({
    220 => 'ff0000',
    196 => 'ffff00',
  });

  print $_ for values %{$new_colors};

  # or just...

  set_xterm_color({ 100 => ff0066});

Expects a hash reference where the keys are color indexes (0 .. 255) and the
values hexadecimal representations of the color values.

Changes the colors if called in void context. Else, returns a hash with the
indexes as keys and the appropriate escape sequences as values.

=head2 get_xterm_color()

  my $defined_colors = get_xterm_color({ index => [0 .. 255], type => 'dec' });

  print $defined_colors->{4}->{red}, "\n";
  print $defined_colors->{8}->{rgb}, "\n";

B<0 - 15> is the standard I<ANSI> colors, all above them are extended colors.

Returns a hash reference with the index colors as keys.
By default the color values are in decimal.

The color values can be accessed by using their name:

  my $red = $colors->{10}->{red};

Or by using the short notation:

  my $red = $colors->{10}->{r};

The full color string can be retrieved like so:

  my $rgb = $colors->{10}->{rgb};

The C<raw> element is the full, raw response from the terminal, including escape
sequences.

The following arguments are supported:

=over

=item index => $index | \@indexes

Arrayref of color indexes to look up and return. Defaults to [0..255], i.e.
all indexes. Alternately a single index may be passed.

=item type => 'dec' | 'hex'

May be 'dec' or 'hex'. The default is 'dec' (decimal) which returns color
values as integers between 0 and 255, and returns a 'rgb' string of the form
'$r/$g/$b' e.g. '255/0/0'. If 'hex' is passed, returns color values in
base 16, zero-padded to two characters (between 00 and ff) and a 'rgb' string
of the form '$r$g$b' e.g. 'ff0000'

=back

=head2 get_xterm_colors()

The same thing as B<get_xterm_color()>. Will be deprecated.

=head2 set_foreground_color()

  set_foreground_color('ff0000');

  my $fg = set_foreground_color('c0ffee');

Sets the foreground color if called in void context. Else, the appropriate
escape sequence is returned.

=head2 set_background_color()

  set_background_color('121212');

  my $bg = set_foreground_color('000000');

Sets the foreground color if called in void context. Else, the appropriate
escape sequence is returned.


=head1 SEE ALSO

L<Term::ExtendedColor>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the B<Term::ExtendedColor::Xresources> L</AUTHOR> and
L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
