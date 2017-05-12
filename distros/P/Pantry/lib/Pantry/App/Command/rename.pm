use v5.14;
use warnings;

package Pantry::App::Command::rename;
# ABSTRACT: Implements pantry rename subcommand
our $VERSION = '0.012'; # VERSION

use Pantry::App -command;
use autodie;

use namespace::clean;

sub abstract {
  return 'Rename an item in a pantry (nodes, roles, etc.)';
}

sub command_type {
  return 'DUAL_TARGET';
}

my @types = qw/node role environment bag/;

sub valid_types {
  return @types;
}

for my $t (@types) {
  no strict 'refs';
  *{"_rename_$t"} = sub {
    my ($self, $opt, $name, $dest) = @_;
    return $self->_rename_obj($opt, $t, $name, $dest);
  };
}

sub _rename_obj {
  my ($self, $opt, $type, $name, $dest) = @_;

  my $obj = $self->_check_name($type, $name);
  my $dest_path;
  if ( $type eq 'node' ) {
    $dest_path = $self->pantry->$type( $dest, {env => $obj->env} )->path;
  }
  else {
    $dest_path = $self->pantry->$type( $dest )->path;
  }

  if ( ! -e $obj->path ) {
    die( "$type '$name' doesn't exist\n" );
  }
  elsif ( -e $dest_path ) {
    die( "$type '$dest' already exists. Won't over-write it.\n" );
  }
  else {
    $obj->save_as( $dest_path );
    unlink $obj->path;
  }

  return;
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App::Command::rename - Implements pantry rename subcommand

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  $ pantry create node foo.example.com

=head1 DESCRIPTION

This class implements the C<pantry create> command, which is used to create a new node data file
in a pantry.

=for Pod::Coverage options validate

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
