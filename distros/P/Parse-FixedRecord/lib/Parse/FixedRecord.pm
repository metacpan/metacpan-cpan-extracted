package Parse::FixedRecord;
BEGIN {
  $Parse::FixedRecord::AUTHORITY = 'cpan:OSFAMERON';
}
{
  $Parse::FixedRecord::VERSION = '0.06';
}
# ABSTRACT: object oriented parser for fixed width records


use Moose 1.15 ();
use Parse::FixedRecord::Column;
use Moose::Exporter;
use Moose::Util::TypeConstraints;

Moose::Exporter->setup_import_methods(
    with_meta => ['column', 'pic', 'ignore'],
    also      => ['Moose'],
);

sub init_meta {
    shift;
    my %args = @_;

    Moose->init_meta(%args);

    Moose::Util::MetaRole::apply_metaroles(
        for => $args{for_class},
        class_metaroles => {
            class => ['Parse::FixedRecord::Meta::Role::Class'],
        },
    );

    my $meta = Class::MOP::class_of($args{for_class});
    $meta->superclasses('Parse::FixedRecord::Row');
}

sub pic {
    my $meta = shift;
    my $pic = shift;

    $meta->add_field($pic);
}

sub column {
    my $meta = shift;
    my ($name, %pars) = @_;
    $pars{isa} ||= 'Str';
    $pars{coerce}++ if do {
        my $t = find_type_constraint($pars{isa});
        $t && $t->has_coercion;
        };
    my $attr = $meta->add_attribute(
        $name => (
            traits => ['Column'],
            is     => 'ro',
            %pars,
            ));
    $meta->add_field($attr);
}

my $anon_idx = 0;

sub ignore {
    my $meta = shift;
    my %pars = (@_ % 2 ? (width => @_) : @_);
    $pars{isa} ||= 'Str';
    $pars{coerce}++ if do {
        my $t = find_type_constraint($pars{isa});
        $t && $t->has_coercion;
        };
    my $name = "Parse-FixedRecord-ANON-$anon_idx";
    $anon_idx++;
    my $attr = $meta->add_attribute(
        $name => (
            traits => ['Column'],
            is     => 'bare',
            %pars,
            ));
    $meta->add_field($attr);
}


1;

__END__
=pod

=head1 NAME

Parse::FixedRecord - object oriented parser for fixed width records

=head1 VERSION

version 0.06

=head1 SYNOPSIS

Assuming you have data like this:

  Fred Bloggs | 2009-12-08 | 01:05
  Mary Blige  | 2009-12-08 | 00:30

To create a parser:

  package My::Parser;
  use Parse::FixedRecord; # imports strict and warnings

  column first_name => width => 4, isa => 'Str';
  pic ' ';
  column last_name  => width => 6, isa => 'Str';
  pic ' | ';
  column date       => width => 10, isa => 'Date';
  pic ' | ';
  column duration   => width => 5, isa => 'Duration';
  1;

In your code:

  use My::Parser;
  while (my $line = <$fh>) {
    eval {
      my $object = My::Parser->parse( $line );
      say $object->first_name;
      do_something() if $ $object->duration->in_units('mins') > 60;
    };
  }

=head1 DESCRIPTION

C<Parse::FixedRecord> is a subclass of L<Moose> with a simple domain specific
language (DSL) to define parsers.

You may use any type constraints you like, as long as they have a coercion
from Str.  If you wish to output row objects in the same format, they should
also have an overload.

C<Parse::FixedRecord> provides C<Duration> and C<DateTime> constraints for
you out of the box.

=head2 Definition

To define the class, simply apply C<column> and C<pic> for each field, in
the order they appear in your input file.  They are defined as follows:

=head3 C<column>

This is a specialisation of C<Moose>'s C<has>, which applies the
L<Parse::FixedRecord::Column> trait.

You must supply a 'width' parameter.
Unless you specify otherwise, the trait will default to C<is =E<gt> 'ro'>,
so will be readonly.

  column foo => width => 10;                     # readonly accessor
  column bar => width => 5, is => 'rw';          # read/write
  column baz => width => 5, isa => 'Some::Type';

=head3 C<pic>

You may also supply delimiters.  As this is a fixed record parser, allowing
delimiters may seem odd.  But it may be convenient for some (odd) datasets,
and in any case, there is no requirement to use it.

  column foo => width => 5;
  pic ' | ';
  column bar => width => 5;

i.e. the record consists of two 5-char wide fields, split by the literal 
C<' | '>.

=head3 C<ignore>

Like C<pic>, but the actual contents of the delimiter are ignored. The
argument is the field width.

  column foo => width => 5;
  ignore 3;
  column bar => width => 5;

=head2 Parsing

=head3 C<$parser-E<gt>parse>

  my $obj = My::Parser->parse( $line );

If the C<column> and C<pic> definitions can be matched, including any
type constraints and object inflations, then a Moose object is returned.

Otherwise, an error is thrown, usually by the Moose type constraint failure.

=for Pod::Coverage init_meta

=head1 AUTHOR

osfameron <osfameron@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by osfameron.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

