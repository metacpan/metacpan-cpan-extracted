use v5.14;
use strict;
use warnings;
package Pantry::Role::Serializable;
# ABSTRACT: A role to save/load data to/from JSON files
our $VERSION = '0.012'; # VERSION

use MooseX::Role::Parameterized;
use Moose::Util qw/get_all_attribute_values/;
use namespace::autoclean;

use File::Basename qw/dirname/;
use File::Path qw/mkpath/;
use File::Slurp qw/read_file write_file/;
use Storable qw/dclone/;
use JSON 2;

parameter freezer => (
  isa => 'Str',
);

parameter thawer => (
  isa => 'Str',
);

role {
  my $params = shift;
  my $freezer = $params->freezer;
  my $thawer = $params->thawer;


  method new_from_file => sub {
    my ($class, $file) = @_;

    my $str_ref = read_file( $file, { binmode => ":raw", scalar_ref => 1 } );

    # XXX check if string needs UTF-8 decoding?
    my $data = $class->_json_thaw( $str_ref );

    if ($thawer) {
      $data = $class->$thawer($data);
    }

    $data->{_path} = $file;
    return $class->new( $data );
  };


  method save_as => sub {
    my ($self, $file) = @_;

    my $data = get_all_attribute_values($self->meta, $self);
    delete $data->{$_} for grep { /^_/ } keys %$data; # delete private attributes

    if ($freezer) {
      $data = $self->$freezer(dclone $data);
    }

    # XXX check if string needs UTF-8 encoding?
    my $str_ref = $self->_json_freeze( $data );

    mkpath( dirname( $file ) );
    return write_file( $file, { binmode => ":raw", atomic => 1 }, $str_ref );
  };

  method _json_freeze => sub {
    my ($self, $data) = @_;
    my $string = to_json($data, { utf8 => 1, pretty => 1 });
    return \$string;
  };

  method _json_thaw => sub {
    my ($self, $str_ref) = @_;
    my $data = from_json($$str_ref, { utf8 => 1, pretty => 1 });
    return $data;
  };
};

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::Role::Serializable - A role to save/load data to/from JSON files

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  with 'Pantry::Role::Serializable' => {
    freezer => '_freeze',
    thawer => '_thaw',
  };

=head1 DESCRIPTION

This parameterizable Moose role provides methods for saving/loading Pantry
objects as JSON.

=head1 METHODS

=head2 new_from_file

  my $obj = $class->new_from_file( $path );

Constructs a new object from JSON data found in the given file.

=head2 save_as

  $obj->save_as( $path );

Stores object data as JSON in a file at the given path location.  Attributes
with leading underscores are considered "private" and are omitted.

=head1 USAGE

Customizing the serialization behavior can be done with the optional C<freezer>
and C<thawer> role parameters.  If either C<freezer> or C<thawer> is omitted,
data will not be modified during saving/loading (respectively), except that
private attributes are always omitted when saving.

=head2 freezer

This role parameter takes the name of a method to use for modifying the object data during
freezing.  It takes a hashref of data representing the object's attributes (excluding any
private attributes) and must return a hashref of data which will be serialized as JSON.

=head2 thawer

This role parameter takes the name of a method to use for modifying the object
data during thawing.  It takes a hashref of data deserialized from JSON and
must return a hashref of data suitable for passing to the object constructor.

=head1 SEE ALSO

=over 4

=item *

L<MooseX::Storage> -- this didn't quite meet my needs as it

mandates a C<__CLASS__> key which causes problems when Chef consumes saved data

=back

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
