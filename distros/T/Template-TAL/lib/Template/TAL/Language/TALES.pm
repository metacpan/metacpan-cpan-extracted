=head1 NAME

Template::TAL::Language::TALES - methods to parse TALES strings

=head1 SYNOPSIS

  my $value = Template::TAL::Language::TALES->process_tales_path(
    "/foo/bar",
    { foo => { bar => "2" } },
  );
  
=head1 DESCRIPTION

TALES is the recommended syntax for TAL expressions. It is an
extensible syntax that allows you to define any number of expression
types and use them together. See
http://www.zope.org/Wikis/DevSite/Projects/ZPT/TALES
for the spec.

This module provides the parser hooks for a TALES implementation, and it is
called by Template::TAL::ValueParser.

=cut

package Template::TAL::Language::TALES;
use warnings;
use strict;
use base qw( Template::TAL::Language );
use Scalar::Util qw( blessed );
use Carp qw( croak );

=over

=item process_tales_path( path, contexts, plugins )

follows the path into the passed contexts. Will return the value of the
key if it is found in any of the contexts, searching first to last, or
undef if not. Path is something like

  /foo/bar/0/baz/narf

and this will map to (depending on the object types in the context)

  $context->{foo}->bar()->[0]->{baz}->narf();

=cut

# TODO - it would be very nice to distinguish between 'key not found' and
# 'key value is undef'.

sub process_tales_path {
  my ($class, $path, $contexts, $plugins) = @_;
  my @components = split(/\s*\|\s*/, $path);

  CONTEXT: for my $context (@$contexts) {

    COMPONENT: for my $component (@components) {
      $component =~ s!^/!!;
      my @atoms = split(m!/!, $component);
      my $local = $context;
      for my $atom (@atoms) {
        # TODO - unlike Template Toolkit, we use 'can' here, as opposed to
        # just trying it and looking for errors. Is this the right thing?
        if (ref($local) and blessed($local) and $local->can($atom) ) {
          $local = $local->$atom();
          # TODO what about objects that support hash de-referencing or something?
        } elsif (UNIVERSAL::isa($local, "HASH") or
	         overload::Method($local,'%{}')) {
          $local = $local->{ $atom };
        } elsif (UNIVERSAL::isa($local, "ARRAY") or
	         overload::Method($local,'@{}')) {
          no warnings 'numeric';
          if ($atom eq int($atom)) {
            $local = $local->[ $atom ];
          } else {
            #warn "$atom is not an array index\n";
            $local = undef;
          }
        } else {
          # TODO optional death here?
          #warn "Can't walk path '$atom' into object '$local'\n";
          $local = undef;
        }

      } # atom
      return $local if defined($local);

    } # component

  } # context
  return undef; # give up.
}

=item process_string( string, contexts, plugins )

interprets 'string' as a string, and returns it. This includes variable
interpolation from the contexts, for instance, the string

  This is my ${weapon}!

Where the context is

  { weapon => "boomstick' }

will be interpolated properly. Both ${this} and $this style of placeholder
will be interpolated.

=cut

# TODO if $foo = '$bar' and $bar = 3, then '${foo}' will be interpolated
# to '3', not '$bar'. Tricky? need more regexp-fu
sub process_tales_string {
  my ($class, $string, $contexts, $plugins) = @_;
  return unless defined($string);
  $string =~ s/\$\{(.*?)\}/Template::TAL::ValueParser->value($1, $contexts, $plugins)/eg;
  $string =~ s/\$(\w*)/Template::TAL::ValueParser->value($1, $contexts, $plugins)/eg;
  return $string;
}

=item process_not( value, contexts, plugins )

Evaluates 'value' as a TALES string in the context, and return the
boolean value that is its opposite. eg

  not:string:0 - true
  not:/foo/bar - the opposite of /foo/bar

=cut

sub process_tales_not {
  my ($class, $string, $contexts, $plugins) = @_;
  my $value = Template::TAL::ValueParser->value($string, $contexts, $plugins);
  return !$value;
}

=back

=head1 COPYRIGHT

Written by Tom Insam, Copyright 2005 Fotango Ltd. All Rights Reserved

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut



1;
