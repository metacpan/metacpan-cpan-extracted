package Params::Validate::Micro;

use strict;
use warnings;
use Params::Validate qw(:all);
use Scalar::Util qw(reftype);
use Carp qw(croak confess);

require Exporter;
our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
  all => [qw(micro_validate micro_translate)],
);
our @EXPORT_OK = (@{ $EXPORT_TAGS{all} });

=head1 NAME

Params::Validate::Micro - Validate parameters concisely

=head1 VERSION

Version 0.032

=cut

our $VERSION = '0.032';

=head1 SYNOPSIS

  use Params::Validate::Micro qw(:all);
  use Params::Validate::Micro qw(micro_validate micro_translate);

=head1 DESCRIPTION

Params::Validate::Micro allows you to concisely represent a
list of arguments, their types, and whether or not they are
required.

Nothing is exported by default.  Use C<< :all >> or the
specific function name you want.

=head1 FORMAT

Micro argument strings are made up of lists of parameter
names.  Each name may have an optional sigil (one of C<< $@%
>>), which translate directly to the Params::Validate
constrations of SCALAR | OBJECT, ARRAYREF, and HASHREF, respectively.

There may be one semicolon (C<< ; >>) in your argument
string.  If present, any parameters listed after the
semicolon are marked as optional.

Examples:

=over 4

=item Single scalar argument

  $text

=item Hashref and optional scalar

  %opt; $verbose

=item Two arrayrefs and an untyped argument

  @addrs @lines message

=back

You may also have an empty argument string.  This indicates
that you want no parameters at all.

=head1 FUNCTIONS

=head3 C<< micro_translate >>

  my %spec = micro_translate($string, $extra);

Turns C<< $string >> into a Params::Validate spec as
described in L</FORMAT>, then merges the resultant spec and
the optional C<< $extra >> hashref.

This returns a list, which just happens to be a set of key
=> value pairs.  This matters because it means that if you
wanted to you could treat it as an array for long enough to
figure out what order the parameters were specified in.  You
could use this to do your own optional positional
validation.

=head3 C<< micro_validate >>

  my $arg = micro_validate(\%arg,  $string, $extra);
  my $arg = micro_validate(\@args, $string, $extra);

Use C<< micro_translate >> with C<< $string >> and C<<
$extra >>, then passes the whole thing to Params::Validate.

Named parameters should be passed in as a hashref, and
positional parameters as an arrayref.  Positional parameters
will be associated with names in the order specified in C<<
$string >>.  For example:

  micro_validate({ a => 1 }, q{$a; $b});
  micro_validate([ 1 ], q{$a; $b});

Both will return this:

  { a => 1 }

When passing positional parameters, C<< micro_validate >>
will die if there are either too many for the spec or not
enough to fill all non-optional parameters.

Returns a hashref of the validated arguments.

=cut

my $BARE_VAR  = qr/[a-z_]\w*/i;

my $SIGIL_VAR = qr/[%\$\@]?$BARE_VAR/i;

my $EXTRACT_VARS = qr/\A 
                      (
                        (?: \s* ; \s*)?
                        $SIGIL_VAR
                        (?: 
                          (?: \s* ; )? 
                          \s+ $SIGIL_VAR
                        )*
                      )?
                      \z/x;

my %PVSPEC = (
  '%' => {
    type => HASHREF,
  },
  '@' => {
    type => ARRAYREF,
  },
  '$' => {
    type => SCALAR | OBJECT,
  },
);

my ($SIGIL) = map { qr/$_/ } '[' . join("", keys %PVSPEC) . ']';

sub micro_translate {
  my ($string, $extra) = @_;
  $string =~ s/^\s*//;
  $string =~ s/\s*$//;
  croak "'$string' does not appear to be a micro-spec"
    unless $string =~ $EXTRACT_VARS;

  # maybe they want to say "no args at all"
  return unless defined $1;

  my @vspecs = grep {
    length($_)
  } map {
    # make sure that semicolons are their own 'word'
    s/;/ ; /g;
    split /\s+/;
  } $string =~ $EXTRACT_VARS;

  my $optional;
  my @spec;
  for my $vspec (@vspecs) {
    if ($vspec eq ';') {
      if ($optional++) {
        croak "micro-spec '$string' contains multiple semicolons";
      }
      next;
    }
    my $vname = $vspec;
    my $spart = {};
    while ($vname =~ s/^($SIGIL)//) {
      my $sigil = $1;
      $spart = { %$spart, %{$PVSPEC{$sigil} || {}} };
    }
    unless ($vname =~ /\A$BARE_VAR\z/) {
      croak "illegal parameter name: '$vname'";
    }
    if ($optional) {
      $spart->{optional} = 1;
    }
    if ($extra->{$vname}) {
      # as of now, the only things that may be already set in $spart are 'type'
      # and 'optional'.  it is therefore safe to naively join the hashes, since
      # we don't need to worry about more complex cases like merging nested
      # 'callbacks' entries.  re-evaluate this if more complex specs are
      # being generated automatically.  -- hdp, 2007-04-10
      %$spart = (%$spart, %{$extra->{$vname}});
    }
    unless (%$spart) {
      $spart = 1;
    }
    push @spec, $vname => $spart;
  }

  return @spec;
}

sub _pos_to_named {
  my ($string, $args, $spec) = @_;
  my @tmpspec = @$spec;
  my @tmpargs = @$args;
  my $return = {};
  while (my ($key, $val) = splice @tmpspec, 0, 2) {
    unless (@tmpargs) {
      if (ref($val) eq 'HASH' and $val->{optional}) {
        last;
      } else {
        confess "not enough arguments for '$string' (only got @$args)";
      }
    }
    $return->{$key} = shift(@tmpargs);
  }
  if (@tmpargs) {
    confess "too many arguments for '$string' (leftover: @tmpargs)";
  }
  return $return;
}

sub micro_validate {
  my ($args, $string, $extra) = @_;
  $args   ||= {};
  $string ||= "";
  $extra  ||= {};

  my $spec = [ micro_translate($string, $extra) ];

  if ($args and reftype($args) eq 'ARRAY') {
    $args = _pos_to_named($string, $args, $spec);
  }
  unless ($args and reftype($args) eq 'HASH') {
    croak "first argument to micro_validate must be hashref or arrayref";
  }

  return {
    validate_with(
      params => $args,
      spec   => { @$spec },
    )
  };
}

=head1 SEE ALSO

L<Params::Validate>

=head1 AUTHOR

Hans Dieter Pearcey, C<< <hdp@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-params-validate-micro@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Params-Validate-Micro>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Hans Dieter Pearcey, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Params::Validate::Micro
