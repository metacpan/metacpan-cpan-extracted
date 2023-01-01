use strict;
use warnings;
package RTF::VimColor 0.002;
# ABSTRACT: generate colorized RTF using Vim's syntax highlighting

use File::ShareDir;
use File::Spec;
use Graphics::ColorUtils qw(name2rgb);
use RTF::Writer;
use Text::VimColor;

#pod =head1 SYNOPSIS
#pod
#pod B<Achtung!>  You I<probably> want to just use the L<synrtf> command included
#pod with this distribution.  If not, though...
#pod
#pod   my $rtf_textref = RTF::VimColor->new->rtf_for_file(
#pod     $filename,
#pod     { filetype => 'forth' },
#pod   );
#pod
#pod   print $$rtf_textref;
#pod
#pod =cut

sub new {
  Carp::croak("no arguments taken to $_[0]->new") if @_ > 1;
  return bless {}, $_[0];
}

#pod =method rtf_for_file
#pod
#pod   my $rtf_textref = RTF::VimColor->new->rtf_for_file($filename, \%arg);
#pod
#pod Given the name of a file, this method will return a reference to a string of
#pod RTF.
#pod
#pod Valid arguments for C<%arg> are:
#pod
#pod   colorscheme - a path to a Vim colorscheme file (default is manxome.vim)
#pod   filetype    - the Vim filetype to use for syntax highlighting (default: guess)
#pod   font_face   - the font face to use; defaults to Courier New
#pod   font_size   - the font size, in points, to use; defaults to 14
#pod   default_bg  - default background color ("#ab01ef" or a name)
#pod   default_fg  - default foreground color (same format)
#pod
#pod =cut

sub rtf_for_file {
  my ($self, $filename, $arg) = @_;

  my $syn = Text::VimColor->new(
    file => $filename,
    ($arg->{filetype} ? (filetype => $arg->{filetype}) : ()),
    vim_let => { perl_sub_signatures => 1 },
  );

  my $rtf = RTF::Writer->new_to_string(\my $str);

  my $colors = RTF::VimColor::ColorScheme->new_from_file(
    $arg->{colorscheme} || File::Spec->catfile(
      File::ShareDir::dist_dir('RTF-VimColor'),
      "manxome.vim",
    ),
    {
      default_bg => $arg->{default_bg} || $self->_color_to_rgb('black'),
      default_fg => $arg->{default_fg} || $self->_color_to_rgb('grey'),
    },
  );

  # RTF::Writer "helpfully" converts - to "non-breaking hyphen," which Apple's
  # RTF does not seem to support.  This overrides that. -- rjbs, 2007-09-05
  local $RTF::Writer::Escape[ ord('-') ] = '-';

  # It's easier to human-read the RTF if the linebreaks are only in the same
  # place. -- rjbs, 2007-09-05
  local $RTF::Writer::AUTO_NL = 0;

  $rtf->prolog(
    fonts  => [ $arg->{font_face} ],
    colors => [ $colors->all_colors ],
  );

  my $hp_size = $arg->{font_size} * 2; # RTF uses half-points for font size

  # Set size, font, and background color.
  $rtf->print(
    \"\\fs$hp_size\\f0",
    $colors->color_controls_for('Normal'),
  );

  my $tokens = $syn->marked;

  while (my $pair = shift @$tokens) {
    my ($type, $text) = @$pair;

    $rtf->print(
      $colors->color_controls_for($type), " ",
      $text,
    );
  }

  $rtf->close;

  return \$str;
}

sub _color_to_rgb {
  my ($self, $str) = @_;

  if ($str =~ /\A#([0-9a-f]{6})\z/i) {
    return [ map { hex } unpack "(a2)*", $1 ]
  }

  my @rgb = name2rgb($str);
  return unless @rgb;
  return \@rgb;
}

package
  RTF::VimColor::ColorScheme;

sub new_from_file {
  my ($class, $filename, $arg) = @_;

  my $self = bless {}, $class;

  $self->_initialize_from_file(
    $filename,
    {
      default_bg => $arg->{default_bg} || RTF::VimColor->_color_to_rgb('black'),
      default_fg => $arg->{default_fg} || RTF::VimColor->_color_to_rgb('grey'),
    },
  );

  return $self;
}

sub _read_vim_color_scheme {
  my ($self, $filename) = @_;

  open my $fh, '<', $filename or die "couldn't open $filename to read: $!";

  my %color;

  LINE: while (my $line = <$fh>) {
    chomp $line;
    $line =~ s/\A\s+//;
    next LINE unless $line =~ /\Ahi(?:ghlight)?/;

    my ($group) = $line =~ /\Ahi(?:ghlight)?\s+(\w+)/;

    my %attr;

    if (my ($fg) = $line =~ /guifg=(\S+)/) {
      $attr{fg} = RTF::VimColor->_color_to_rgb($1);
    }

    if (my ($bg) = $line =~ /guibg=(\S+)/) {
      $attr{bg} = RTF::VimColor->_color_to_rgb($bg);
    }

    $color{ $group } = \%attr;
  }

  return \%color;
}

sub _initialize_from_file {
  my ($self, $filename, $arg) = @_;
  my %color_pos;
  my @colors;

  my $group = $self->_read_vim_color_scheme($filename);

  # Allow this to be set by constructor args. -- rjbs, 2015-02-20
  $group->{Normal} ||= {};
  $group->{Normal}{bg} ||= $arg->{default_bg};
  $group->{Normal}{fg} ||= $arg->{default_fg};

  for my $this_group (keys %$group) {
    for my $which (qw(fg bg)) {
      next unless my $rgb = $group->{ $this_group }{ $which };

      my $pos = $color_pos{ join('-', @$rgb) };

      unless (defined $pos) {
        push @colors, $rgb;
        $pos = $color_pos{ join('-', @$rgb) } = $#colors;
      }

      $color_pos{ "$this_group:$which" } = $pos;
    }
  }

  $self->{colors} = \@colors;
  $self->{color_pos} = \%color_pos;

  return;
}

sub color_controls_for {
  my ($self, $group) = @_;

  my $ctrl = '';
  for (qw(f b)) {
    $ctrl .= "\\c$_"
          .  (defined $self->{color_pos}{"$group:${_}g"}
             ? $self->{color_pos}{"$group:${_}g"}
             : $self->{color_pos}{"Normal:${_}g"});
  }

  return \$ctrl;
}

sub all_colors {
  my ($self) = @_;
  @{ $self->{colors} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

RTF::VimColor - generate colorized RTF using Vim's syntax highlighting

=head1 VERSION

version 0.002

=head1 SYNOPSIS

B<Achtung!>  You I<probably> want to just use the L<synrtf> command included
with this distribution.  If not, though...

  my $rtf_textref = RTF::VimColor->new->rtf_for_file(
    $filename,
    { filetype => 'forth' },
  );

  print $$rtf_textref;

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 rtf_for_file

  my $rtf_textref = RTF::VimColor->new->rtf_for_file($filename, \%arg);

Given the name of a file, this method will return a reference to a string of
RTF.

Valid arguments for C<%arg> are:

  colorscheme - a path to a Vim colorscheme file (default is manxome.vim)
  filetype    - the Vim filetype to use for syntax highlighting (default: guess)
  font_face   - the font face to use; defaults to Courier New
  font_size   - the font size, in points, to use; defaults to 14
  default_bg  - default background color ("#ab01ef" or a name)
  default_fg  - default foreground color (same format)

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
