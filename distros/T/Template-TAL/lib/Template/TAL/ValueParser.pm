=head1 NAME

Template::TAL::ValueParser - parse attribute values

=head1 SYNOPSIS

  my $string = "path:/foo/bar/0/baz";
  my $value = Template::TAL::ValueParser->value( $string );
  
=head1 DESCRIPTION

This module is responsible for parsing the values of attributes in templates,
and returning them. It can also split multiple values up into a list, using
semicolons as list seperators. The way that values are parsed is based very
strongly on TALES (http://www.zope.org/Wikis/DevSite/Projects/ZPT/TALES)
but the actual TALES spec is provided by the language module
L<Template::TAL::Language::TALES>.

=cut

package Template::TAL::ValueParser;
use warnings;
use strict;
use Carp qw( croak );

=head1 METHODS

=over

=item split( string )

commands in 'string' can be split by ';' characters, with raw semicolons
represented as ';;'. This command splits the string on the semicolons, and
de-escapes the ';;' pairs. For instance:

  foo; bar; baz;; narf

splits to:

  ['foo', 'bar', 'baz; narf']

Not technically part of TALES, I think, but really useful for TAL anyway.

=cut

sub split {
  my ($class, $string) = @_;
  # TODO this is _hokey_. Do it properly.
  $string =~ s/;;/\x{12345}/g;
  my @list = grep {$_} split(/\s*;\s*/, $string);
  s/\x{12345}/;/g for @list;
  return @list;
}

=item value( expression, context arrayref, plugin arrayref )

parse a TALES expression in the first param, such as

  string:Hello there
  path:/a/b/c

using the passed contexts (in order) to look up path values. Contexts should
be hashes, and we will look in each context for a defined key of the given
path until we find one.

(note - I need the multiple contexts code because TAL lets you set
globals in define statements, so I need a local context, and a global
context)

The plugins value should be an arrayref of language plugins to ask about
the various types of string. At a minimum, this should probably include
Template::TAL::Language::TALES, or the module won't do a lot.

=cut

sub value {
  my ($class, $exp, $contexts, $plugins) = @_;
  Carp::croak("contexts must be arrayref, not ".ref($contexts)) unless ref($contexts) eq 'ARRAY';
  my ($type, $string) = $exp =~ /^\s*(?:(\w+):\s*)?(.*)/;
  $type ||= "path";
  my $sub = "process_tales_$type";
  for my $plugin (@{ $plugins || [] }) {
    if ($plugin->can($sub)) {
      return $plugin->$sub($string, $contexts, $plugins );
    }
  }
  die "unknown TALES type '$type'\n";
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
