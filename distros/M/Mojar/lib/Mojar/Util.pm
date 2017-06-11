package Mojar::Util;
use Mojo::Base -strict;

our $VERSION = 0.371;

use B;
use Carp 'croak';
use Exporter 'import';
use Mojo::File;
use Scalar::Util 'reftype';
use Storable 'dclone';

our @EXPORT_OK = qw(as_bool been_numeric check_exists dumper hash_or_hashref
    loaded_path lc_keys merge slurp_chomped snakecase spurt transcribe
    unsnakecase);

# Public functions

sub as_bool {
  my ($val) = shift;
  return !! $val if been_numeric($val) or not defined $val;
  $val = lc "$val";
  return !! 1
    if $val eq '1' or $val eq 'true' or $val eq 'yes' or $val eq 'on';
  return !! undef
    if $val eq '0' or $val eq 'false' or $val eq 'no' or $val eq 'off';
  return !! $val;
}

sub dumper {
  no warnings 'once';
  require Data::Dumper;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Sortkeys = 1;
  my $dump = Data::Dumper::Dumper(@_);
  $dump =~ s/\n\z//;
  return $dump;
}

sub lc_keys {
  my ($hr) = @_;
  croak q{Missing required hashref} unless reftype $hr eq 'HASH';
  %$hr = map +(lc $_ => $$hr{$_}), keys %$hr;
  return $hr;
}

sub slurp_chomped {
  my $t = Mojo::File->new(@_)->slurp;
  () while chomp $t;
  $t
}

sub snakecase {
  my ($string, $syllable_sep) = @_;
  $syllable_sep //= '_';
  return undef unless defined $string;
  
  my @words;
  # Absorb any leading lowercase chars
  push @words, $1 if $string =~ s/^([^A-Z]+)//;
  # Absorb each titlecase substring
  push @words, lcfirst $1 while $string =~ s/\A([A-Z][^A-Z]*)//;
  for (0 .. $#words - 1) {
    $words[$_] .= $syllable_sep unless $words[$_] =~ /[^a-z]$/;
  }
  return join '', @words;
}

sub unsnakecase {
  my ($string, $separator, $want_camelcase) = @_;
  $separator //= '_';
  return undef unless defined $string;
  
  my @words;
  # Absorb any leading separators
  push @words, $1 if $string =~ s/\A(\Q$separator\E+)//;
  # Absorb any leading component if doing camelcase
  if ($want_camelcase
      and $string =~ s/\A([^\Q$separator\E]+)\Q$separator\E?//) {
    push @words, $1;
    push @words, $1 if $string =~ s/\A(\Q$separator\E+)//;
  }
  # Absorb each substring as titlecase
  while ($string =~ s/\A([^\Q$separator\E]+)\Q$separator\E?//) {
    push @words, ucfirst lc $1;
    push @words, $1 if $string =~ s/\A(\Q$separator\E+)//;
  }
  # Fix any trailing separators
  $words[-1] .= $separator if @words && $words[-1] =~ /\A\Q$separator\E/;
  return join '', @words;
}

sub transcribe {
  my $string = shift;
  my $translator = ref $_[-1] eq 'CODE' ? pop : undef;
  return undef unless defined $string;

  my $parts = [ $string ];  # arrayref tree with strings at leaves
  my @joiners = ();  # joining string for each level
  my @level_parts = ( $parts );  # array of arrayrefs, each containing a string
  my @next_level_parts = ();  # array of arrayrefs, each containing a string
  my ($old, $new);
  while (($old, $new) = (shift, shift) and defined $new) {
    push @joiners, $new;
    foreach my $p (@level_parts) {
      # $p is arrayref containing a string
      my @components = split /\Q$old/, $p->[0], -1;
      # Modify $parts tree
      @$p = map [ $_ // '' ], @components;
      # $p is arrayref containing arrayrefs, each containing a string
      # Set up next level
      push @next_level_parts, @$p;
    }
    @level_parts = @next_level_parts;
    @next_level_parts = ();
  }
  while ($translator and my $p = shift @level_parts) {
    $p->[0] = $translator->($p->[0]);
  }

  my @traverse = ( [0, $parts] );
  while (my $next = pop @traverse) {
    my ($depth, $ref) = @$next[0,1];
    if (ref $$ref[0]) {
      if (my @deeper = grep ref($_->[0]), @$ref) {
        # Found some children not ready to be joined
        push @traverse, [$depth, $ref], map [$depth + 1, $_], @deeper;
      }
      else {
        # Children all strings => join them
        @$ref = join $joiners[$depth], map +($_->[0] //= ''), @$ref;
      }
    }
    # else string => do nothing
  }

  return $parts->[0] // '';
}

sub loaded_path {
  my ($self) = @_;
  # Try .pm
  (my $module = (ref $self // $self) .'.pm') =~ s{::}{/};
  return $INC{$module} if exists $INC{$module};

  # Try .pl
  $module =~ s{\.pm$}{.pl};
  return $INC{$module} if exists $INC{$module};

  return undef;
}

sub been_numeric {
  my $value = shift;
  # From Mojo::JSON
  return 1 if B::svref_2object(\$value)->FLAGS & (B::SVp_IOK | B::SVp_NOK)
      and 0 + $value eq $value and $value * 0 == 0;
}

sub spurt (@) {
  my $path = shift;
  my $lines = ref $_[-1] eq 'ARRAY' ? pop : \@_;
  my $count = 0;

  die qq{Can't open file "$path": $!} unless open my $file, '>', $path;
  $file->syswrite('');
  local $_;
  $file->syswrite($_), $file->syswrite($/) and ++$count for @$lines;
  close $file;
  return $count;
}

sub hash_or_hashref {
  return { @_ } if @_ % 2 == 0;  # hash
  return $_[0] if ref $_[0] eq 'HASH' or reftype $_[0] eq 'HASH';
  croak sprintf 'Hash not identified (%s)', join ',', @_;
}

sub check_exists {
  my $requireds = shift;
  my $param = hash_or_hashref(@_);
  $requireds = [$requireds] unless ref $requireds eq 'ARRAY';

  exists $param->{$_} or croak "Missing required param ($_)" for @$requireds;
  return @$param{@$requireds};
}

# Private function
sub _merge ($;$) {
  my ($left, $right) = @_;
  if (reftype $left eq 'ARRAY') {
    if (reftype $right eq 'ARRAY') {
      %{$left->[0]} = (%{$left->[0]}, %{ dclone($right->[0]) });
    }
    else {
      # $right : HASHREF
      %{$left->[0]} = (%{$left->[0]}, %{ dclone($right) });
    }
  }
  else {
    # $left : HASHREF
    if (reftype($right) eq 'ARRAY') {
      %$left = (%$left, %{ dclone($right->[0]) });
    }
    else {
      # $right : HASHREF
      %$left = (%$left, %{ dclone($right) });
    }
  }
  return $left;
}

sub merge (@);
sub merge (@) {
  # Both class & object function
#  my $class = (@_ and not ref $_[0]) ? shift : undef;
  my $class = shift unless ref $_[0];
  # defined($class) <=> class method
  return undef unless @_;
  my $left = shift;

  # $left is a ref; @right could be various things

  # If called as object method
  # 'owning' (ie leftmost) object gets modified
  # If called as class method
  # a new object is created for the result

  # It is important that the merge associates to the left
  # [ie ($a merge $b) merge $c], in contrast to Hash::Util::Simple.

  # class method => new object
  # this is done at most once per original call
  if ($class) {
    if ($left->can('clone')) {
      return merge $left->clone, @_;
    }
    elsif ($left->can('new')) {
      return merge $left->new, @_;
    }
    elsif (ref $left eq 'HASH') {
      $left = dclone($left);
    }
    else {
      croak "Unable to clone first argument\n". dumper $left;
    }
  }

  # Base case
  unless (@_) {
    return $left;
  }
  # Recurse
  elsif (@_ == 1 and ref $_[0]) {
    # object or maybe hash ref
    return _merge($left, $_[0]);
  }
  elsif (@_ > 1 and ref $_[0]) {
    # object or maybe hash ref
    my $right = shift;
    return merge _merge($left, $right), @_;
  }
  elsif (@_ > 1 and @_ % 2 == 0) {
    # assume plain hash
    return _merge($left, { @_ });
  }
  else {
    croak 'Tried to merge incompatible/non-object'. $/ . dumper(@_);
  }
}

1;
__END__

=head1 NAME

Mojar::Util - General utility functions

=head1 SYNOPSIS

  use Mojar::Util 'transcribe';

  my $replaced = transcribe $original, '_' => '-', '-' => '_';

=head1 DESCRIPTION

Miscellaneous utility functions.

=head1 FUNCTIONS

=head2 as_bool

  $boolean = as_bool($val);

Convert arbitrary scalar to a Boolean, intended to accommodate strings
equivalent to on/off, true/false, yes/no.  The following are true.

  as_bool('ON'), as_bool('true'), as_bool(42), as_bool('Yes'), as_bool('NO!')

The following are false.

  as_bool('off'), as_bool('False'), as_bool(0), as_bool('NO'), as_bool(undef)

=head2 been_numeric

  $probably_a_number = been_numeric($val);

Introspects a flag indicating whether the value has been treated as a number.
cf: L<Scalar::Util::looks_like_number>.

=head2 snakecase

  $snakecase = snakecase $titlecase;
  $snakecase = snakecase $titlecase => $separator;

Convert title-case string to snakecase.  Also converts from camelcase.

  snakecase 'iFooBar';
  # "i_foo_bar"

Rather than using an underscore, a different separator can be specified.

  snakecase 'FooBar' => '-';
  # "foo-bar"

  snakecase 'FFooBar/BazZoo' => '-';
  # "f-foo-bar/baz-zoo"

=head2 unsnakecase

  $titlecase = unsnakecase $snakecase;
  $titlecase = unsnakecase $snakecase => $separator;
  $titlecase = unsnakecase $snakecase => $separator, $want_camelcase;

Convert snake-case string to titlecase, with optional additional translations.

  unsnakecase 'foo_bar';
  # "FooBar"

  unsnakecase 'foo-bar' => '-';
  # "FooBar"

An undefined separator defaults to underscore, which is useful when you only
want to specify a camelcase result.

  unsnakecase 'foo_bar' => undef, 1;
  # "fooBar"

  unsnakecase i_foo_bar => undef, 1;
  # 'iFooBar';

There is only one level of separator; for more see C<transcribe>.

  unsnakecase 'foo-bar_baz' => '-';
  # "FooBar_baz"

Leading separators pass through.

  unsnakecase '--foo-bar' => '-';
  # "--FooBar"

As do trailing separators.

  unsnakecase '__bar_baz__';
  # "__BarBaz__"

=head2 transcribe

  $template_base = transcribe $url_path, '/' => '_';

  $controller_class =
      transcribe $url_path, '/' => '::', sub { unsnakecase $_[0] => '-' };

  $with_separators_swapped = transcribe $string, '_' => '-', '-' => '_';

Repeatedly replaces a character/string with another character/string.  Can even
swap between values, as shown in that last example.

=head2 dumper

  say dumper $object;
  print dumper($object), "\n";
  $log->debug(dumper $hashref, $arrayref, $string, $numeric);

Based on Data::Dumper it is simply a tidied (post-processed) version.  It is
argument-greedy and if passed more than one argument will wrap them in an
arrayref and then later strip away that dummy layer.  In the resulting string,
"TOP" refers to the top-most (single, possibly invisible) entity.

This is intended to be clear and succinct to support error messages and debug
statements.  It is not suitable for serialising entities because it does not try
to maintain round trip stability.  (ie Don't try to evaluate its output.)

=head2 hash_or_hashref

  $hashref = hash_or_hashref({ A => 1, B => 2 });
  $hashref = hash_or_hashref($object);  # $object if hashref-based
  $hashref = hash_or_hashref(A => 1, B => 2);
  $hashref = hash_or_hashref();  # {}

Takes care of those cases where you want to handle both hashes and hashrefs.
Always gives a hashref if it can, otherwise dies.

=head2 check_exists

  sub something {
    my ($self, %param) = @_;
    check_exists [qw(dbh log)], %param;

  sub something2 {
    my $self = shift;
    my ($dbh, $log) = check_exists [qw(dbh log)], @_;

  sub something3 {
    my ($self, $param) = @_;
    my ($dbh) = check_exists 'dbh', $param;

  package MyClass;
  use Mojar::Util ();
  sub exists = {
    my $keys = ref $_[0] eq 'ARRAY' ? $_[0] : [ @_ ];
    return Mojar::Util::exists($keys, $self);
  }

Checks that required parameters have been passed.  Takes a string or arrayref of
strings that are required keys, and a hash or hashref of parameters.  Throws an
exception if one or more strings do not exist as keys in the parameters;
otherwise returns the list of parameter values.

=head1 SEE ALSO

L<Mojo::Util>, L<String::Util>, L<Data::Dump>.
