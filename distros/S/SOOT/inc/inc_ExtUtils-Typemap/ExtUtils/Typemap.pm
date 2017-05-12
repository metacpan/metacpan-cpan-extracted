package ExtUtils::Typemap;
use 5.006001;
use strict;
use warnings;
our $VERSION = '0.04';
use Carp qw(croak);

our $Proto_Regexp = "[" . quotemeta('\$%&*@;[]') . "]";

=head1 NAME

ExtUtils::Typemap - Read/Write/Modify Perl/XS typemap files

=head1 SYNOPSIS

  # read/create file
  my $typemap = ExtUtils::Typemap->new(file => 'typemap');
  # alternatively create an in-memory typemap
  # $typemap = ExtUtils::Typemap->new();
  
  # add a mapping
  $typemap->add_typemap(ctype => 'NV', xstype => 'T_NV');
  $typemap->add_inputmap (xstype => 'T_NV', code => '$var = ($type)SvNV($arg);');
  $typemap->add_outputmap(xstype => 'T_NV', code => 'sv_setnv($arg, (NV)$var);');
  
  # remove a mapping (same for remove_typemap and remove_outputmap...)
  $typemap->remove_inputmap(xstype => 'SomeType');
  
  # save a typemap to a file
  $typemap->write(file => 'anotherfile.map');
  
  # merge the other typemap into this one
  $typemap->merge(typemap => $another_typemap);

=head1 DESCRIPTION

This module can read, modify, create and write Perl XS typemap files. If you don't know
what a typemap is, please confer the L<perlxstut> and L<perlxs> manuals.

The module is not entirely round-trip safe: For example it currently simply strips all comments.
The order of entries in the maps is, however, preserved.

We check for duplicate entries in the typemap, but do not check for missing
C<TYPEMAP> entries for C<INPUTMAP> or C<OUTPUTMAP> entries since these might be hidden
in a different typemap.

=head1 METHODS

=cut

=head2 new

Returns a new typemap object. Takes an optional C<file> parameter.
If set, the given file will be read. If the file doesn't exist, an empty typemap
is returned.

=cut

sub new {
  my $class = shift;
  
  my $self = bless {
    file            => undef,
    @_,
    typemap_section => [],
    input_section   => [],
    output_section  => [],
  }, $class;

  $self->_init();

  return $self;
}

sub _init {
  my $self = shift;
  $self->_parse() if defined $self->{file} and -e $self->{file};
}

=head2 file

Get/set the file that the typemap is written to when the
C<write> method is called.

=cut

sub file {
  $_[0]->{file} = $_[1] if @_ > 1;
  $_[0]->{file}
}

=head2 add_typemap

Add a C<TYPEMAP> entry to the typemap.

Required named arguments: The C<ctype> (e.g. C<ctype =E<gt> 'NV'>)
and the C<xstype> (e.g. C<xstype =E<gt> 'T_NV'>).

Optional named arguments: C<replace =E<gt> 1> forces removal/replacement of
existing C<TYPEMAP> entries of the same C<ctype>.

=cut

sub add_typemap {
  my $self = shift;
  my %args = @_;
  my $ctype = $args{ctype};
  croak("Need ctype argument") if not defined $ctype;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;
  if ($args{replace}) {
    $self->remove_typemap(ctype => $ctype);
  } else {
    $self->validate(typemap_xstype => $xstype, ctype => $ctype);
  }
  my $proto = $args{"prototype"} || '';
  push @{$self->{typemap_section}}, {
    tidy_ctype => _tidy_type($ctype),
    xstype     => $xstype,
    proto      => $proto,
    ctype      => $ctype,
  };
  return 1;
}

=head2 add_inputmap

Add an C<INPUT> entry to the typemap.

Required named arguments:
The C<xstype> (e.g. C<xstype =E<gt> 'T_NV'>)
and the C<code> to associate with it for input.

Optional named arguments: C<replace =E<gt> 1> forces removal/replacement of
existing C<INPUT> entries of the same C<xstype>.

=cut

sub add_inputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;
  my $code = $args{code};
  croak("Need code argument") if not defined $code;
  if ($args{replace}) {
    $self->remove_inputmap(xstype => $xstype);
  } else {
    $self->validate(inputmap_xstype => $xstype);
  }
  $code =~ s/^(?=\S)/\t/mg;
  push @{$self->{input_section}},
    {xstype => $xstype, code => $code};
  return 1;
}

=head2 add_outputmap

Add an C<OUTPUT> entry to the typemap.
Works exactly the same as C<add_inputmap>.

=cut


sub add_outputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;
  my $code = $args{code};
  croak("Need code argument") if not defined $code;
  if ($args{replace}) {
    $self->remove_outputmap(xstype => $xstype);
  } else {
    $self->validate(outputmap_xstype => $xstype);
  }
  $code =~ s/^(?=\S)/\t/mg;
  push @{$self->{output_section}},
    {xstype => $xstype, code => $code};
  return 1;
}

=head2 remove_typemap

Removes a C<TYPEMAP> entry from the typemap.

Required named argument: C<ctype> to specify the entry to remove from the typemap.

=cut

sub remove_typemap {
  my $self = shift;
  my %args = @_;
  my $ctype = $args{ctype};
  croak("Need ctype argument") if not defined $ctype;
  $ctype = _tidy_type($ctype);
  
  return $self->_remove($ctype, 'tidy_ctype', $self->{typemap_section});
}

=head2 remove_inputmap

Removes an C<INPUT> entry from the typemap.

Required named argument: C<xstype> to specify the entry to remove from the typemap.

=cut

sub remove_inputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;
  
  return $self->_remove($xstype, 'xstype', $self->{input_section});
}

=head2 remove_inputmap

Removes an C<OUTPUT> entry from the typemap.

Required named argument: C<xstype> to specify the entry to remove from the typemap.

=cut

sub remove_outputmap {
  my $self = shift;
  my %args = @_;
  my $xstype = $args{xstype};
  croak("Need xstype argument") if not defined $xstype;
  
  return $self->_remove($xstype, 'xstype', $self->{output_section});
}

sub _remove {
  my $self  = shift;
  my $rm    = shift;
  my $key   = shift;
  my $array = shift;

  my $index = 0;
  foreach my $map (@$array) {
    last if $map->{$key} eq $rm;
    $index++;
  }
  if ($index < @$array) {
    splice(@$array, $index, 1);
    return 1;
  }
  return();
}

=head2 write

Write the typemap to a file. Optionally takes a C<file> argument. If given, the
typemap will be written to the specified file. If not, the typemap is written
to the currently stored file name (see C<-E<gt>file> above, this defaults to the file
it was read from if any).

=cut

sub write {
  my $self = shift;
  my %args = @_;
  my $file = defined $args{file} ? $args{file} : $self->file();
  croak("write() needs a file argument (or set the file name of the typemap using the 'file' method)")
    if not defined $file;

  open my $fh, '>', $file
    or die "Cannot open typemap file '$file' for writing: $!";
  print $fh $self->as_string();
  close $fh;
}

=head2 as_string

Generates and returns the string form of the typemap.

=cut

sub as_string {
  my $self = shift;
  my $typemap = $self->{typemap_section};
  my @code;
  push @code, "TYPEMAP\n";
  foreach my $entry (@$typemap) {
    # type kind proto
    # /^(.*?\S)\s+(\S+)\s*($Proto_Regexp*)$/o
    my $ctype = defined($entry->{ctype}) ? $entry->{ctype} : $entry->{tidy_ctype};
    push @code, "$ctype\t" . $entry->{xstype}
              . ($entry->{proto} ne '' ? "\t".$entry->{proto} : '') . "\n";
  }

  my $input = $self->{input_section};
  if (@$input) {
    push @code, "\nINPUT\n";
    foreach my $entry (@$input) {
      push @code, $entry->{xstype}, "\n", $entry->{code}, "\n";
    }
  }

  my $output = $self->{output_section};
  if (@$output) {
    push @code, "\nOUTPUT\n";
    foreach my $entry (@$output) {
      push @code, $entry->{xstype}, "\n", $entry->{code}, "\n";
    }
  }
  return join '', @code;
}

=head2 merge

Merges a given typemap into the object. Note that a failed merge
operation leaves the object in an inconsistent state so clone if necessary.

Mandatory named argument: C<typemap =E<gt> $another_typemap>

Optional argument: C<replace =E<gt> 1> to force replacement
of existing typemap entries without warning.

=cut

sub merge {
  my $self = shift;
  my %args = @_;
  my $typemap = $args{typemap};
  croak("Need ExtUtils::Typemap as argument")
    if not ref $typemap or not $typemap->isa('ExtUtils::Typemap');

  my $replace = $args{replace};

  # FIXME breaking encapsulation. Add accessor code.
  #
  foreach my $entry (@{$typemap->{typemap_section}}) {
    my $ctype = defined($entry->{ctype}) ? $entry->{ctype} : $entry->{tidy_ctype};
    $self->add_typemap(
      ctype       => $ctype,
      xstype      => $entry->{xstype},
      "prototype" => $entry->{proto},
      replace     => $replace,
    );
  }

  foreach my $entry (@{$typemap->{input_section}}) {
    $self->add_inputmap(
      code        => $entry->{code},
      xstype      => $entry->{xstype},
      replace     => $replace,
    );
  }

  foreach my $entry (@{$typemap->{output_section}}) {
    $self->add_outputmap(
      code        => $entry->{code},
      xstype      => $entry->{xstype},
      replace     => $replace,
    );
  }

  return 1;
}

# Note: This is really inefficient. One could keep a hash to start with.
sub validate {
  my $self = shift;
  my %args = @_;

  my %xstypes;
  my %ctypes;
  $xstypes{$args{typemap_xstype}}++ if defined $args{typemap_xstype};
  $ctypes{$args{ctype}}++ if defined $args{ctype};

  foreach my $map (@{$self->{typemap_section}}) {
    my $ctype = $map->{tidy_ctype};
    croak("Multiple definition of ctype '$ctype' in TYPEMAP section")
      if exists $ctypes{$ctype};
    my $xstype = $map->{xstype};
    # TODO check this: We shouldn't complain about reusing XS types in TYPEMAP.
    #croak("Multiple definition of xstype '$xstype' in TYPEMAP section")
    #  if exists $xstypes{$xstype};
    $xstypes{$xstype}++;
    $ctypes{$ctype}++;
  }

  %xstypes = ();
  $xstypes{$args{inputmap_xstype}}++ if defined $args{inputmap_xstype};
  foreach my $map (@{$self->{input_section}}) {
    my $xstype = $map->{xstype};
    croak("Multiple definition of xstype '$xstype' in INPUTMAP section")
      if exists $xstypes{ $map->{xstype} };
    $xstypes{$xstype}++;
  }

  %xstypes = ();
  $xstypes{$args{outputmap_xstype}}++ if defined $args{outputmap_xstype};
  foreach my $map (@{$self->{output_section}}) {
    my $xstype = $map->{xstype};
    croak("Multiple definition of xstype '$xstype' in OUTPUTMAP section")
      if exists $xstypes{ $map->{xstype} };
    $xstypes{$xstype}++;
  }

  return 1;
}

sub _parse {
  my $self = shift;
  my $file = $self->{file};
  open my $fh, '<', $file
    or die "Cannot open typemap file '$file' for reading. $!";

  # TODO comments should round-trip, currently ignoring
  # TODO order of sections, multiple sections of same type
  # Heavily influenced by ExtUtils::ParseXS
  my $section = 'typemap';
  my $lineno = 0;
  my $junk = "";
  my $current = \$junk;
  my @typemap_expr;
  my @input_expr;
  my @output_expr;
  while (<$fh>) {
    ++$lineno;
    chomp;
    next if /^\s*#/;
    if (/^INPUT\s*$/) {
      $section = 'input';
      $current = \$junk;
      next;
    }
    elsif (/^OUTPUT\s*$/) {
      $section = 'output';
      $current = \$junk;
      next;
    }
    elsif (/^TYPEMAP\s*$/) {
      $section = 'typemap';
      $current = \$junk;
      next;
    }
    
    if ($section eq 'typemap') {
      my $line = $_;
      s/^\s+//; s/\s+$//;
      next if /^#/ or /^$/;
      my($type, $kind, $proto) = /^(.*?\S)\s+(\S+)\s*($Proto_Regexp*)$/o
        or warn("Warning: File '$file' Line $lineno '$line' TYPEMAP entry needs 2 or 3 columns\n"),
           next;
      my $tidytype = _tidy_type($type);
      $proto = '' if not $proto;
      # prototype defaults to '$'
      #$proto = '$' unless $proto;
      #warn("Warning: File '$file' Line $lineno '$line' Invalid prototype '$proto'\n")
      #  unless _valid_proto_string($proto);
      push @typemap_expr,
        {tidy_ctype => $tidytype, xstype => $kind, proto => $proto, ctype => $type};
    } elsif (/^\s/) {
      $$current .= $$current eq '' ? $_ : "\n".$_;
    } elsif (/^$/) {
      next;
    } elsif ($section eq 'input') {
      s/\s+$//;
      push @input_expr, {xstype=>$_, code=>''};
      $current = \$input_expr[-1]{code};
    } else { # output section
      s/\s+$//;
      push @output_expr, {xstype=>$_, code=>''};
      $current = \$output_expr[-1]{code};
    }

  } # end while lines

  close $fh;
  $self->{typemap_section} = \@typemap_expr;
  $self->{input_section}   = \@input_expr;
  $self->{output_section}  = \@output_expr;
  
  return $self->validate();
}

# taken from ExtUtils::ParseXS
sub _tidy_type {
  local $_ = shift;

  # rationalise any '*' by joining them into bunches and removing whitespace
  s#\s*(\*+)\s*#$1#g;
  s#(\*+)# $1 #g ;

  # trim leading & trailing whitespace
  s/^\s+//; s/\s+$//;

  # change multiple whitespace into a single space
  s/\s+/ /g;

  $_;
}


# taken from ExtUtils::ParseXS
sub _valid_proto_string {
  my $string = shift;
  if ($string =~ /^$Proto_Regexp+$/o) {
    return $string;
  }

  return 0 ;
}

# taken from ExtUtils::ParseXS (C_string)
sub _escape_backslashes {
  my $string = shift;
  $string =~ s[\\][\\\\]g;
  $string;
}

=head1 CAVEATS

Mostly untested and likely not fool proof.

Inherits some evil code from C<ExtUtils::ParseXS>.

=head1 SEE ALSO

The parser is heavily inspired from the one in L<ExtUtils::ParseXS>.

For details on typemaps: L<perlxstut>, L<perlxs>.

=head1 AUTHOR

Steffen Mueller C<<smueller@cpan.org>>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

1;

