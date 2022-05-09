package Term::hr 0.002;
use strict;
use warnings FATAL => 'all';

BEGIN {
  use Exporter;
  use vars qw(@ISA @EXPORT);
  @ISA = qw(Exporter);
  @EXPORT = qw(hr);
}

use Term::ExtendedColor qw(fg);

my %settings = (
  char      => '=',
  fg        => 'fg',
  bg        => 'bg',
  bold      => 0,
  crlf      => 0,
  italic    => 0,
  post      => 0,
  pre       => 0,
  reverse   => 0,
  underline => 0,
  width     => 80,
);

# Ability to provide us with a hash of settings
# directly in a use statement
my $params = \%settings;
sub import {
  goto &Exporter::import if ref $_[1] ne 'HASH';
  $params = splice @_, 1, 1;

  # let size be an alias to width
  if($params->{size} and not $params->{width}) {
    $settings{width} = $params->{size};
  }

  # replace user provided args in options hash
  # while keeping what's not provided
  for my $p(keys(%{ $params })) {
    $settings{$p} = $params->{$p};
  }

  goto &Exporter::import;
}


sub hr {
  my $arg = shift // \%settings;
  my $opt;

  # assume provided with a single char and no options
  # use default options except for that character
  if(ref $arg eq '') {
    $opt = \%settings;
    $opt->{char} = $arg;
  }
  elsif(ref $arg eq 'HASH') {
    $opt = $arg;

    # if not all options were provided...
    for my $setting(keys(%settings)) {
      $opt->{$setting} = $settings{$setting} unless exists $opt->{$setting};
    }
  }

  # craft the hr
  my $hr = sprintf "%s%s%s",
     # prepopulate with whitespace
     ' ' x $opt->{pre},

     # add characters
     $opt->{char} x _char_columns($opt),

     # postpopulate with whitespace
     ' ' x $opt->{post};

  $hr = _set_attr($hr, $opt);

  return sprintf "%s%s", $hr,
    $opt->{crlf} ? "\n" : '';
}

sub _char_columns{
  my $arg = shift;
  my $width = $arg->{width};

  return $width - ($arg->{pre} + $arg->{post});
}


sub _set_attr {
  my $str = shift;
  my $opt = shift;

  my $attributes;

  # The special case 'fg' and 'bg' means the default
  # terminal foreground/background color.
  if($opt->{fg} and $opt->{fg} ne 'fg') {
    $attributes .= sprintf ";38;5;%s", $opt->{fg};
  }

  if($opt->{bg} and $opt->{bg} ne 'bg') {
    $attributes .= sprintf ";48;5;%s", $opt->{bg};
  }

  if($opt->{bold}) {
    $attributes .= ';1';
  }
  if($opt->{italic}) {
    $attributes .= ';3';
  }

  if($opt->{underline}) {
    $attributes .= ';4';
  }

  if($opt->{reverse}) {
    $attributes .= ';7';
  }

  $attributes =~ s/^;//;

  # In the case of no attributes, we return the str as-is
  # Term::ExtendedColor can handle raw attribute escape sequences
  return $attributes
    ? fg($attributes, $str)
    : $str;
}


=encoding utf8

=head1 NAME

Term::hr - define a thematic change in the content of a terminal session

=head1 SYNOPSIS

  use Term::hr {
    char      => '=',   # character to use
    fg        => 'fg',  # foreground color, fg = default fg color
    bg        => 'bg',  # background color, bg = default bg color
    bold      => 0,     # no bold attribute
    crlf      => 1,     # add a newline to the returned hr
    italic    => 0,     # no italic attribute
    post      => 0,     # post whitespace
    pre       => 0,     # pre whitespace
    reverse   => 0,     # reverse video attribute
    underline => 0,     # underline attribute
    width     => 80,    # total width of the hr
  };

  ...
  print hr();
  ...


=head1 DESCRIPTION

Term::hr exports a single function into the callers namespace, C<hr>.
It exposes a feature very similar to the HTML <hr> tag; a simple way
to define a thematic change in content.

It gives you a way to divide output into sections when you or your program
produces a lot of output.

Normally one might want to define the looks of the hr a single time, in the
beginning of a program. That way, every invocation will be styled the same.

You can do that in the same statement as the use statement, as seen above.

There are however many reasons why you might want to setup a bunch of options as
your defaults, and later in your program modify them a bit to suit your needs.

Many different possibilities and combinations is allowed, see below.

=head1 EXAMPLES

  use Term::hr;
  use Term::Size;

  my $hr = hr(
    {
      char   => '#',
      fg     => 197,
      bg     => 'bg',
      bold   => 1,
      italic => 1,
      width  => ((Term::Size::chars())[0] / 4),
      pre    => 1,
      post   => 1,
      crlf   => 1,
    },
  );

  print $hr;

Because the hr above was crafted with provided options at invocation time,
they are temporary. This means that the hr below will have all B<module> default
options, except for the character.

  my $another_hr = hr('_');
  print $another_hr;

If you wanted to change the character, but keep all the other options
you crafted, set the options at use-time instead:

  use Term::hr {
    fg        => 196,  # foreground color, fg = default fg color
    bg        => 220,  # background color, bg = default bg color
  };

  # uses '=' as character
  print hr();

  # use another one
  my $hr = hr('_');

Combinations are possible, as well as unicode:

  use Term::hr {
    fg     => 197,
    bold   => 1,
    italic => 1,
    crlf   => 1,
  };

  print hr();
  print hr({char => '𝄘', italic => 0});
  print hr('𝄘');
  print hr({char => '𝄘', italic => 0, underline => 1,});
  print hr({char => '𝄘', reverse => 1, underline => 1,});

  ...

  $ ls; perl -MTerm::hr -E 'say hr({char=>"🌎",width=>15})'; date

Create a shell alias:

  $ alias hr"=perl -MTerm::hr -E 'say hr({fg=>196, char=> q[ ], bold=>1,underline=>1,italic=>1})'"
  $ cat /var/log/Xorg.0.log; hr; ls

=head1 Options and attributes

These are options that can be passed to hr as a key-value hash.

=head2 char

The character to use to build up the hr.
Defaults to '='.

=head2 width, size

The total width of the hr, including pre and post.
Defaults to 80.

=head2 fg

Foreground color.
Defaults to your default terminal foreground color.

=head2 bg

Background color.
Defaults to your default terminal background color.

=head2 crlf

If provided with a non-zero value, a newline will be added to the end of the hr.
Defaults to no newline added.

=head2 pre

Amount of whitespace to add before the hr string.
Defaults to zero.

=head2 post

Amount of whitespace to add after the hr string.
Defaults to zero.

=head2 bold

If provided with a non-zero value, bold attribute will be added.
Defaults to zero.

=head2 italic

If provided with a non-zero value, italic attribute will be added.
Defaults to zero.
=head2 underline

If provided with a non-zero value, underline attribute will be added.
Defaults to zero.

=head2 reverse

If provided with a non-zero value, reverse video attribute will be added.
Defaults to zero.

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  m@japh.se
  http://japh.se
  http://github.com/trapd00r

=head1 COPYRIGHT

Copyright 2022 B<THIS APPLICATION>s L</AUTHOR> and L</CONTRIBUTORS> as listed
above.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

42;
