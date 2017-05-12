package Parse::FieldPath;
{
  $Parse::FieldPath::VERSION = '0.005';
}

# ABSTRACT: Perl module to extract fields from objects

use strict;
use warnings;

use Exporter qw/import unimport/;
our @EXPORT_OK = qw/extract_fields/;

use Scalar::Util qw/reftype blessed/;
use List::Util qw/first/;
use Carp;

use Parse::FieldPath::Parser;

# Maximum number of times to allow _extract to recurse.
use constant RECURSION_LIMIT => 512;

sub extract_fields {
    my ( $obj, $field_path ) = @_;

    croak "extract_fields needs an object or a hashref"
      unless blessed($obj) || ( reftype($obj) && reftype($obj) eq 'HASH' );

    my $tree = _build_tree($field_path);
    return _extract( $obj, $tree, 0 );
}

sub _build_tree {
    my ($field_path) = @_;
    my $parser = Parse::FieldPath::Parser->new();
    return $parser->parse($field_path);
}

sub _extract {
    my ( $source, $tree, $recurse_count ) = @_;

    $recurse_count++;
    die "Maximum recursion limit reached" if $recurse_count > RECURSION_LIMIT;

    my $is_object;
    if ( blessed($source) ) {
        $is_object = 1;
    }
    elsif ( reftype($source) && reftype($source) eq 'HASH' ) {
        $is_object = 0;
    }
    else {
        return $source;
    }

    my $all_fields = [];
    if ($is_object) {
        $all_fields = $source->all_fields() if $source->can('all_fields');

        die "Expected $source->all_fields to return an arrayref"
          unless reftype($all_fields)
              && reftype($all_fields) eq 'ARRAY';
    }
    else {
        @$all_fields = keys %$source;
    }

    if ( exists $tree->{'*'} || !%$tree ) {

        # We've got an object, but not a list of fields. Get everything.
        $tree->{$_} = {} for @$all_fields;
    }

    $source->fields_requested( [ keys %$tree ] )
      if $is_object && $source->can('fields_requested');

    my %fields;
    for my $field ( keys %$tree ) {

        # Only accept fields that have been explicitly allowed
        next unless first { $_ eq $field } @$all_fields;

        my $branch = $tree->{$field};
        my $value  = $is_object ? $source->$field : $source->{$field};
        my $value_reftype = reftype($value) || '';

        if ( blessed($value) || $value_reftype eq 'HASH' ) {
            $fields{$field} = _extract( $value, $branch, $recurse_count );
        }
        elsif ( $value_reftype eq 'ARRAY' ) {
            $fields{$field} =
              [ map { _extract( $_, $branch, $recurse_count ) } @{$value} ];
        }
        else {
            if (%$branch) {

                # Unblessed object, but a sub-object has been requested.
                # Setting it to undef, maybe an error should be thrown here
                # though?
                $fields{$field} = undef;
            }
            else {
                $fields{$field} = $value;
            }
        }
    }

    return \%fields;
}

1;

=pod

=head1 NAME

Parse::FieldPath

=head1 ABSTRACT

Parses an XPath inspired field list and extracts those fields from an object
hierarchy.

Based on the "fields" parameter for the Google+ API:
http://developers.google.com/+/api/

=head1 SYNOPSIS

Say you have an object, with some sub-objects, that's initialized like this:

  my $cow = Cow->new();
  $cow->color("black and white");
  $cow->tail(Cow::Tail->new(floppy => 1));
  $cow->mouth(Cow::Tounge->new(
    tounge => Cow::Tounge->new,
    teeth  => Cow::Teeth->new,
  );

And you want a hash containing some of those fields (perhaps to pass to
JSON::XS, or something). Then you can do this:

  use Parse::FieldPath qw/extract_fields/;

  my $cow_hash = extract_fields($cow, "color,tail/floppy");
  # $cow_hash is now:
  # {
  #   color => 'black and white',
  #   tail  => {
  #     floppy => 1,
  #   }
  # }

=head1 FUNCTIONS

=over 4

=item B<extract_fields ($object_or_hashref, $field_path)>

Parses the C<field_path> and returns a hashref with the fields requested from
C<$object_or_hashref>.

C<$object_or_hashref>, and any sub-objects, will need to define a method called
C<all_fields()>. See L<CALLBACKS> for details.

C<field_path> is a string describing the fields to return. Each field is
separated by a comma, e.g. "a,b" will return fields "a" and "b".

To request a field from a sub-objects, use the form "subobject/field". If more
than one field from a sub-object is required, put the field names in
parenthesis, "subobject(field1,field2)".

C<field_path> can go as deep as necessary, for example, this works fine:
"a/b/c(d/e,f)"

=back

=head1 CALLBACKS

=over 4

=item B<all_fields()>

A method called C<all_fields()> should be defined for any object (including
sub-objects), that will be used with this module. It needs to return an
arrayref containing all the valid fields. Any field requested that's not in the
list returned by C<all_fields()> will be skipped.

A simple implementation would be:

  sub all_fields {
      my ($self) = @_;
      return [qw/field1 field2/];
  }

If the list doesn't change, a constant will work too:

  use constant all_fields => [qw/field1 field2/];

This method is required because simply allowing any method to be called would
be dangerous (e.g. if your object had a "delete_everything()" method, or
something). It's also necessary to know which fields constitute "everything"
for the object.

=item B<requested_fields($field_list)>

Called on an object right before the accessor methods are called. It's passed a
list of fields that are about to be requested. This method is completely
optional. It's intended to allow the object to fetch anything it needs to, in
order to make the requested data available.

=back

=head1 GitHub

https://github.com/pboyd/Parse-FieldPath

=head1 AUTHOR

Paul Boyd <pboyd@dev3l.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Paul Boyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
