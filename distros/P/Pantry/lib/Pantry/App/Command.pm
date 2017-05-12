use v5.14;
use warnings;

package Pantry::App::Command;
# ABSTRACT: Pantry command superclass
our $VERSION = '0.012'; # VERSION

use App::Cmd::Setup -command;

#--------------------------------------------------------------------------#
# global behaviors
#--------------------------------------------------------------------------#

sub opt_spec {
  my ($class, $app) = @_;
  # XXX should these be sorted on long name? -- xdg, 2012-05-03
  return (
    $class->options($app),
    # Universal
    [ 'help|h' => "This usage screen" ],
  )
}

sub validate_args {
  my ( $self, $opt, $args ) = @_;

  my ($command) = $self->command_names;
  my $command_type = $self->command_type;

  # redispatch to help if requested
  if ( $opt->{help} ) {
    $self->app->execute_command(
      $self->app->prepare_command("help", $command)
    );
    exit 0;
  }

  # everything other than default needs a type to operate on
  if ( $command_type ne 'DEFAULT' ) {
    my ($type) =  @$args;
    unless ($type) {
      $self->usage_error( "The '$command' command needs a type argument." );
    }
    unless ( grep { $type eq $_ } $self->valid_types ) {
      $self->usage_error( "Invalid type '$type'" );
    }
  }

  # things with targets need a name to operate on
  if ( grep { $command_type eq $_ } qw/TARGET CREATE DUAL_TARGET/ ) {
    my ($type, $name) = @$args;
    if ( ! length $name ) {
      $self->usage_error( "This command requires the name for the thing to modify" );
    }
  }

  # things with two targets need both
  if ( $command_type eq 'DUAL_TARGET' ) {
    my ($type, $name, $dest) = @$args;
    if ( ! length $dest) {
      $self->usage_error( "This command requires a destination name" );
    }
  }

  $self->validate( $opt, $args );
}

sub execute {
  my ($self, $opt, $args) = @_;

  my ($command) = $self->command_names;
  my $command_type = $self->command_type;
  my ($method, @params);

  if ($command_type eq 'DEFAULT') {
    $method = "_${command}";
  }
  else {
    my $type = shift @$args;
    $method = "_${command}_${type}";
  }

  unless ( $self->can($method) ) {
    die "No $method method defined for command $command";
  }

  # TARGET and CREATE types might read from STDIN
  if ( $command_type =~ /TARGET|CREATE/ && $args->[0] eq '-') {
    while ( my $name = <STDIN> ) {
      chomp $name;
      $self->$method($opt, $name);
    }
  }
  else {
    $self->$method($opt, @$args);
  }

  return;
}

sub _iterate_stdin {
  my ($self, $method, $opt) = @_;
}

sub pantry {
  my $self = shift;
  require Pantry::Model::Pantry;
  $self->{pantry} ||= Pantry::Model::Pantry->new;
  return $self->{pantry};
}

#--------------------------------------------------------------------------#
# override in subclasses to customize
#--------------------------------------------------------------------------#

sub valid_types {
  return;
}

sub options {
  return;
}

sub validate{
  return;
}

#--------------------------------------------------------------------------#
# help boilerplate
#--------------------------------------------------------------------------#

my %command_types = (
  DEFAULT => {
    usage => "%c CMD [OPTIONS]",
    target_desc => '',
  },
  TYPE => {
    usage => "%c CMD <TYPE> [OPTIONS]",
    target_desc => << 'HERE',
The TYPE parameter indicates what kind of pantry object to list.
Valid types include:

        node, nodes   lists nodes
        role, roles   lists roles
HERE
  },
  TARGET => {
    usage => "%c CMD <TARGET> [OPTIONS]",
    target_desc => << 'HERE',
The TARGET parameter consists of a TYPE and a NAME separated by whitespace.

The TYPE indicates what kind of pantry object to operate on and the NAME
indicates which specific one. (e.g. "node foo.example.com")

Valid TARGET types include:

        node      NAME refers to a node name in the pantry
        role      NAME refers to a role name in the pantry

If NAME is '-', then the command will be executed on a list of names
read from STDIN.
HERE
  },
  DUAL_TARGET => {
    usage => "%c CMD <TARGET> <DESTINATION> [OPTIONS]",
    target_desc => << 'HERE',
The TARGET parameter consists of a TYPE and a NAME separated by whitespace.

The TYPE indicates what kind of pantry object to operate on and the NAME
indicates which specific one. (e.g. "node foo.example.com")

Valid TARGET types include:

        node      NAME refers to a node name in the pantry
        role      NAME refers to a role name in the pantry

The DESTINATION parameter indicates where the NAME should be put.
HERE
  },
  CREATE => {
    usage => "%c CMD <TARGET> [OPTIONS]",
    target_desc => << 'HERE',
The TARGET parameter consists of a TYPE and a NAME separated by whitespace.

The TYPE indicates what kind of pantry object to operate on and the NAME
indicates which specific one. (e.g. "node foo.example.com")

Valid TARGET types include:

        node      NAME refers to a node name that is *NOT* in the pantry
        role      NAME refers to a role name that is *NOT* in the pantry
        cookbook  NAME refers to a cookbook that is *NOT* in the pantry

If NAME is '-', then the command will be executed on a list of names
read from STDIN.
HERE
  },
);

sub command_type {
  return 'DEFAULT';
}

sub usage_desc {
  my ($self) = shift;
  my ($cmd) = $self->command_names;
  my $usage = $command_types{$self->command_type}{usage};
  $usage =~ s/CMD/$cmd/;
  return $usage;
}

sub description {
  my ($self) = @_;
  my $target = $command_types{$self->command_type}{target_desc};
  return join("\n",
    $self->abstract . ".\n", ($target ? $target : ()), $self->options_desc
  );
}

sub options_desc {
  my ($self) = @_;
  return << 'HERE';
OPTIONS parameters provide additional data or modify how the command
runs.  Valid options include:
HERE
}

sub ssh_options {
  return (
    [ 'host=s'        => "override SSH hostname (nodes only)" ],
    [ 'port=i'        => "override SSH port     (nodes only)" ],
    [ 'user=s'        => "override SSH username (nodes only)"],
  );
}

sub data_options {
  return (
    [ 'recipe|r=s@'   => "A recipe (without 'recipe[...]')" ],
    [ 'role|R=s@'     => "A role (without 'role[...]')" ],
    [ 'default|d=s@'  => "Default attribute (as KEY or KEY=VALUE)" ],
    [ 'override=s@'   => "Override attribute (as KEY or KEY=VALUE) (roles only)" ],
  );
}

sub selector_options {
  return (
    [ 'env|E=s'       => "Deployment environment selector" ],
  );
}

sub sync_options {
  return (
    [ 'reboot'       => "Reboot nodes after sync" ],
  );
}

sub _check_name {
  my ($self, $type, $name) = @_;
  my $meth = "find_$type";
  my @objs = $self->pantry->$meth( $name );
  if (@objs == 0) {
    die "$type '$name' does not exist\n";
  }
  elsif ( @objs == 1 ) {
    return $objs[0];
  }
  else {
    die join("\n", "$type '$name' is ambiguous:", (map { "  " . $_->name } @objs), "");
  }
}

1;


# vim: ts=2 sts=2 sw=2 et:

__END__

=pod

=head1 NAME

Pantry::App::Command - Pantry command superclass

=head1 VERSION

version 0.012

=head1 DESCRIPTION

This internal implementation class defines common command line options
and provides methods needed by all command subclasses.

=for Pod::Coverage command_type
data_options
options
options_desc
pantry
selector_options
ssh_options
sync_options
valid_types
validate

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
