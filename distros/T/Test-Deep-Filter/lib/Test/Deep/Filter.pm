use 5.006;    # our
use strict;
use warnings;

package Test::Deep::Filter;

our $VERSION = '0.001001';

# ABSTRACT: Perform a filter on a matched element before doing sub-matching

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

require Exporter;
*import = \&Exporter::import;    ## no critic (ProhibitCallsToUnexportedSubs)

our @EXPORT_OK = ('filter');

sub filter {
  my ( $code, $expected ) = @_;
  require Test::Deep::Filter::Object;
  return Test::Deep::Filter::Object->new( $code, $expected );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Deep::Filter - Perform a filter on a matched element before doing sub-matching

=head1 VERSION

version 0.001001

=head1 DESCRIPTION

This module exists so that one can apply some kind of transform of the content
of some node, before applying a deep testing structure against it.

This is especially the kind of domain Test::Deep::YAML and Test::Deep::JSON are
targeted at, but implemented in a more generic way.

  cmp_deeply( $got, { payload => filter(\&decode_json, { x => 1 }) } )

This would perform matching against a C<Perl> data structure called C<$got>,
and find its key called C<payload>, and, if existing, filter the key via
C<&decode_json>, and then compare the resulting structure with
C<< { x => 1 } >>.

This would in theory be equivalent to:

  cmp_deeply( $got, { payload => json({ x => 1 }) } )

Except may be tailored for what ever local decoding scheme you may require,
e.g.:

  cmp_deeply( $got, {
      payload => filter(sub {
        my ( $got ) = @_;
        return parse_ini( $got );
      }, { x => 1 })
  });

=head1 FUNCTIONS

=head2 C<filter>

  my $object = filter( \&filter_function, $expected );

  cmp_deeply( $got, filter( \&filter_function, $expected ));

A C<filter> can take any value into C<&filter_function>, and return any value
and the C<Test::Deep> infrastructure will handle the rest.

If the value cannot be parsed, or is of a type you cannot handle, or the
internal logic returns an invalid value ( including any failures in internal
logic that fail to parse, etc) then you must cause the function to throw an
exception with "die", and the nested C<$expected> will be assumed to be false.

The "die" message will be used as a diagnostic for why the match failed.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
