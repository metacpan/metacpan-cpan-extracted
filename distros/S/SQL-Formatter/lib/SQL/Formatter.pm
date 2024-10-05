use warnings;
use 5.020;
use experimental qw( signatures );

package SQL::Formatter 0.01 {

  # ABSTRACT: Format SQL using the rust sqlformat library


  use FFI::Platypus 2.00;
  use Class::Tiny {
    indent => 2,
    uppercase => 1,
    lines_between_queries => 1
  };

  my $ffi = FFI::Platypus->new( api => 2, lang => 'Rust' );
  $ffi->bundle;
  $ffi->mangler(sub ($name) { "sf_$name" });

  $ffi->attach( _free => ['opaque'] );

  $ffi->attach( format => ['string','u8','bool','u8'] => 'opaque' => sub ($xsub, $self, $sql) {
    my $ptr = $xsub->($sql // '', $self->indent, $self->uppercase, $self->lines_between_queries);
    my $str = $ffi->cast( 'opaque' => 'string', $ptr );
    _free($ptr);
    return $str;
  });

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SQL::Formatter - Format SQL using the rust sqlformat library

=head1 VERSION

version 0.01

=head1 SYNOPSIS

 my $f = SQL::Formatter->new;
 say $f->format('select foo.a, foo.b, bar.c from foo join bar on foo.a = bar.c where foo.b = 2');

prints:

 SELECT
   foo.a,
   foo.b,
   bar.c
 FROM
   foo
   JOIN bar ON foo.a = bar.c
 WHERE
   foo.b = 2

=head1 DESCRIPTION

Pretty print SQL using the rust crate C<sqlformat>.

=head1 ATTRIBUTES

The formatting options can be specified either when the object is constructed, or later using accessors.

 my $f = SQL::Format->new( indent => 4 );
 $f->indent(4);

=over 4

=item indent

Controls the length of indentation to use.  The default is C<2>.

=item uppercase

When set to true (the default), changes reserved keywords to ALL CAPS.

=item lines_between_queries

Controls the number of line breaks after a query.  The default is C<1>.

=back

=head1 METHODS

=head2 format

 my $pretty_sql = $f->format($sql);

Formats whitespace in a SQL string to make it easier to read.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
