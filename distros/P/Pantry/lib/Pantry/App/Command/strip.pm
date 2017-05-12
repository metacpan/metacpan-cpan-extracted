use v5.14;
use warnings;

package Pantry::App::Command::strip;
# ABSTRACT: Implements pantry strip subcommand
our $VERSION = '0.012'; # VERSION

use Pantry::App -command;
use autodie;

use namespace::clean;

sub abstract {
  return 'Strip recipes or attributes from a node or role'
}

sub command_type {
  return 'TARGET';
}

sub options {
  my ($self) = @_;
  return ($self->data_options, $self->selector_options);
}

my %strippers = (
  node => {
    default => 'delete_attribute',
    override => undef,
  },
  role => {
    default => 'delete_default_attribute',
    override => 'delete_override_attribute',
  },
  environment => {
    default => 'delete_default_attribute',
    override => 'delete_override_attribute',
  },
  bag => {
    default => 'delete_attribute',
    override => undef,
  },
);

sub valid_types {
  return keys %strippers;
}

for my $t ( keys %strippers ) {
  no strict 'refs';
  *{"_strip_$t"} = sub {
    my ($self, $opt, $name) = @_;
    $self->_strip_obj($opt, $t, $name);
  };
}

sub _strip_obj {
  my ($self, $opt, $type, $name) = @_;

  my $options;
  $options->{env} = $opt->{env} if $opt->{env};
  my $obj = $self->_check_name($type, $name, $options);

  if ( $type eq 'node' ) {
    $self->_delete_runlist($obj, $opt)
  }
  elsif ( $type eq 'role' ) {
    if ( $options->{env} ) {
      $self->_delete_env_runlist($obj, $opt)
    }
    else {
      $self->_delete_runlist($obj, $opt)
    }
  }
  else {
    # nothing else has run lists
  }


  for my $k ( sort keys %{$strippers{$type}} ) {
    if ( my $method = $strippers{$type}{$k} ) {
      $self->_delete_attributes($obj, $opt, $k, $method);
    }
    elsif ( $opt->{$k} ) {
      $k = ucfirst $k;
      warn "$k attributes do not apply to $type objects.  Skipping them.\n";
    }
  }

  $obj->save;
  return;
}

sub _delete_runlist{
  my ($self, $obj, $opt) = @_;
  if ($opt->{role}) {
    $obj->remove_from_run_list(map { "role[$_]" } @{$opt->{role}});
  }
  if ($opt->{recipe}) {
    $obj->remove_from_run_list(map { "recipe[$_]" } @{$opt->{recipe}});
  }
  return;
}

sub _delete_env_runlist{
  my ($self, $obj, $opt) = @_;
  if ($opt->{role}) {
    $obj->remove_from_env_run_list($opt->{env}, [map { "role[$_]" } @{$opt->{role}}]);
  }
  if ($opt->{recipe}) {
    $obj->remove_from_env_run_list($opt->{env}, [map { "recipe[$_]" } @{$opt->{recipe}}]);
  }
  my $runlist = $obj->get_env_run_list($opt->{env});
  if ( $runlist && $runlist->is_empty ){
    $obj->delete_env_run_list($opt->{env});
  }
  return;
}

sub _delete_attributes {
  my ($self, $obj, $opt, $which, $method) = @_;
  if ($opt->{$which}) {
    for my $attr ( @{ $opt->{$which} } ) {
      my ($key, $value) = split /=/, $attr, 2; # split on first '='
      # if they gave a value, we ignore it
      $obj->$method($key);
    }
  }
  return;
}


1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App::Command::strip - Implements pantry strip subcommand

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  $ pantry strip node foo.example.com --recipe nginx --default nginx.port

=head1 DESCRIPTION

This class implements the C<pantry strip> command, which is used to strip recipes or attributes
from a node.

=for Pod::Coverage options validate

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
