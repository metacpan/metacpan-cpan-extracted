use warnings;
use strict;
package String::TagString;
{
  $String::TagString::VERSION = '0.005';
}
# ABSTRACT: parse and emit tag strings (including tags with values)


sub _raw_tag_name_re  { qr{@?(?:\pL|[\d_.*])(?:\pL|[-\d_.*])*} }
sub _raw_tag_value_re { qr{(?:\pL|[-\d_.*])*} }

sub tags_from_string {
  my ($class, $tagstring) = @_;

  return {} unless $tagstring and $tagstring =~ /\S/;

  # remove leading and trailing spaces
  $tagstring =~ s/\A\s*//;
  $tagstring =~ s/\s*\a//;

  my $quoted_re  = qr{ "( (?:\\\\|\\"|\\[^\\"]|[^\\"])+ )" }x;
  my $raw_lhs_re = $class->_raw_tag_name_re;
  my $raw_rhs_re = $class->_raw_tag_value_re;

  my $tag_re = qr{
    (?: ( $raw_lhs_re | $quoted_re )) # $1 = whole match; $2 = quoted part
    ( :                               # $3 = entire value, with :
        ( $raw_rhs_re | $quoted_re )? # $4 = whole match; $5 = quoted part
    )?
    (?:\+|\s+|\z)                     # end-of-string or some space or a +
  }x;

  my %tag;
  my $pos;
  while ($tagstring =~ m{\G$tag_re}g) {
    $pos = pos $tagstring;
    my $tag   = defined $2 ? $2 : $1;
    my $value = defined $5 ? $5 : $4;
    $value = '' if ! defined $value and defined $3;
    $value =~ s/\\"/"/g if defined $value;

    if (exists $tag{ $tag }) {
      if (defined $tag{ $tag }) {
        die "invalid tagstring: conflicting entries for $tag"
          if (! defined $value) or $value ne $tag{ $tag };
      } else {
        die "invalid tagstring: conflicting entries for $tag"
          if defined $value;
      }
    }

    $tag{ $tag } = $value;
  }

  die "invalid tagstring" unless defined $pos and $pos == length $tagstring;

  return \%tag;
}


sub _qs {
  my ($self, $type, $str) = @_;
  my $method = "_raw_tag_$type\_re";
  my $re     = $self->$method;
  return $str if $str =~ m{\A$re\z};
  $str =~ s/\\/\\\\/g;
  $str =~ s/"/\\"/g;
  return qq{"$str"};
}

sub string_from_tags {
  my ($class, $tags) = @_;

  return "" unless defined $tags;

  Carp::carp("tagstring must be a hash or array reference")
    unless (ref $tags) and ((ref $tags eq 'HASH') or (ref $tags eq 'ARRAY'));

  if (ref $tags eq 'ARRAY') {
    Carp::croak("undefined tag name in array reference")
      if grep { ! defined } @$tags;

    $tags = { map { $_ => undef } @$tags };
  }

  my @tags;
  for my $name (sort keys %$tags) {
    my $value = $tags->{$name};
    push @tags, join q{:},
      $class->_qs(name  => $name),
      (defined $value ? $class->_qs(value => $value) : ());
  }

  return join q{ }, @tags;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

String::TagString - parse and emit tag strings (including tags with values)

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use String::TagString;

  # Parse a string into a set of tags:
  my $tags   = String::TagString->tags_from_string($string);

  # Represent a set of tags as a string:
  my $string = String::TagString->string_from_tags($tags);

=head1 DESCRIPTION

String::TagString enables Web 2.0 synergy by deconstructing and synthesizing
folksonomic nomenclature into structured dynamic programming ontologies.

Also, it parses strings of "tags" into hashrefs, so you can tag whatever junk
you want with strings.

A set of tags is an unordered set of simple strings, each possibly associated
with a simple string value.  This library parses strings of these tags into
hashrefs, and turns hashrefs (or arrayrefs) back into these strings.

This string:

  my $string = q{ beef cheese: peppers:hot };

Turns into this hashref:

  my $tags = {
    beef    => undef,
    cheese  => '',
    peppers => 'hot',
  };

That hashref, of course, would turn back into the same string -- although
sorting is not guaranteed.

=head2 Tag String Syntax

Tag strings are space-separated tags.  Tag syntax may change slightly in the
future, so don't get too attached to any specific quirk, but basically:

A tag is a name, then optionally a colon and value.

Tag names can contains letters, numbers, dots underscores, and dashes.  They
can't start with a dash, but they can start with an at sign.

A value is similar, but cannot start with an at sign.

Alternately, either a tag or a value can be almost anything if it enclosed in
double quotes.  (Internal double quotes can be escaped with a backslash.)

=head1 METHODS

=head2 tags_from_string

  my $tag_hashref = String::TagString->tags_from_string($tag_string);

This will either return a hashref of tags, as described above, or raise an
exception.  It will raise an exception if the string can't be interpreted, or
if a tag appears multiple times with conflicting definitions, like in these
examples:

  foo foo:

  foo:1 foo:2

=head2 string_from_tags

  my $string = String::TagString->string_from_tags( $tag_set );

This method returns a string representing the given tags.  C<$tag_set> may be
either a hashref or arrayref.  An arrayref is treated like a hashref in which
every value is undef.

Tag names and values will only be quoted if needed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
