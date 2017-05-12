package MooX::Cmd::Role;

use strict;
use warnings;

our $VERSION = "0.015";

use Moo::Role;

use Carp;
use Module::Runtime qw/ use_module /;
use Regexp::Common;
use Text::ParseWords 'shellwords';
use Module::Pluggable::Object;

use List::MoreUtils qw/first_index first_result/;
use Scalar::Util qw/blessed/;
use Params::Util qw/_ARRAY/;

=head1 NAME

MooX::Cmd::Role - MooX cli app commands do this

=head1 SYNOPSIS

=head2 using role and want behavior as MooX::Cmd

  package MyFoo;
  
  with MooX::Cmd::Role;
  
  sub _build_command_execute_from_new { 1 }

  package main;

  my $cmd = MyFoo->new_with_cmd;

=head2 using role and don't execute immediately

  package MyFoo;

  with MooX::Cmd::Role;
  use List::MoreUtils qw/ first_idx /;

  sub _build_command_base { "MyFoo::Command" }

  sub _build_command_execute_from_new { 0 }

  sub execute {
      my $self = shift;
      my $chain_idx = first_idx { $self == $_ } @{$self->command_chain};
      my $next_cmd = $self->command_chain->{$chain_idx+1};
      $next_cmd->owner($self);
      $next_cmd->execute;
  }

  package main;

  my $cmd = MyFoo->new_with_cmd;
  $cmd->command_chain->[-1]->run();

=head2 explicit expression of some implicit stuff

  package MyFoo;

  with MooX::Cmd::Role;

  sub _build_command_base { "MyFoo::Command" }

  sub _build_command_execute_method_name { "run" }

  sub _build_command_execute_from_new { 0 }

  package main;

  my $cmd = MyFoo->new_with_cmd;
  $cmd->command_chain->[-1]->run();

=head1 DESCRIPTION

MooX::Cmd::Role is made for modern, flexible Moo style to tailor cli commands.

=head1 ATTRIBUTES

=head2 command_args

ARRAY-REF of args on command line

=cut

has 'command_args' => ( is => "ro" );

=head2 command_chain

ARRAY-REF of commands lead to this instance

=cut

has 'command_chain' => ( is => "ro" );

=head2 command_chain_end

COMMAND accesses the finally detected command in chain

=cut

has 'command_chain_end' => ( is => "lazy" );

sub _build_command_chain_end { $_[0]->command_chain->[-1] }

=head2 command_name

ARRAY-REF the name of the command lead to this command

=cut

has 'command_name' => ( is => "ro" );

=head2 command_commands

HASH-REF names of other commands 

=cut

has 'command_commands' => ( is => "lazy" );

sub _build_command_commands
{
    my ( $class, $params ) = @_;
    defined $params->{command_base} or $params->{command_base} = $class->_build_command_base($params);
    my $base = $params->{command_base};

    # i have no clue why 'only' and 'except' seems to not fulfill what i need or are bugged in M::P - Getty
    my @cmd_plugins = grep {
        my $plug_class = $_;
        $plug_class =~ s/${base}:://;
        $plug_class !~ /:/;
      } Module::Pluggable::Object->new(
        search_path => $base,
        require     => 0,
      )->plugins;

    my %cmds;

    for my $cmd_plugin (@cmd_plugins)
    {
        $cmds{ _mkcommand( $cmd_plugin, $base ) } = $cmd_plugin;
    }

    \%cmds;
}

=head2 command_base

STRING base of command plugins

=cut

has command_base => ( is => "lazy" );

sub _build_command_base { $_[0] . '::Cmd'; }

=head2 command_execute_method_name

STRING name of the method to invoke to execute a command, default "execute"

=cut

has command_execute_method_name => ( is => "lazy" );

sub _build_command_execute_method_name { "execute" }

=head2 command_execute_return_method_name

STRING I have no clue what that is good for ...

=cut

has command_execute_return_method_name => ( is => "lazy" );

sub _build_command_execute_return_method_name { "execute_return" }

=head2 command_creation_method_name

STRING name of constructor

=cut

has command_creation_method_name => ( is => "lazy" );

sub _build_command_creation_method_name { "new_with_cmd" }

=head2 command_creation_chain_methods

ARRAY-REF names of methods to chain for creating object (from L</command_creation_method_name>)

=cut

has command_creation_chain_methods => ( is => "lazy" );

sub _build_command_creation_chain_methods { [ 'new_with_options', 'new' ] }

=head2 command_execute_from_new

BOOL true when constructor shall invoke L</command_execute_method_name>, false otherwise

=cut

has command_execute_from_new => ( is => "lazy" );

sub _build_command_execute_from_new { 0 }

=head1 METHODS

=head2 new_with_cmd

initializes by searching command line args for commands and invoke them

=cut

sub new_with_cmd { goto &_initialize_from_cmd; }

sub _mkcommand
{
    my ( $package, $base ) = @_;
    $package =~ s/^${base}:://g;
    lc($package);
}

my @private_init_params =
  qw(command_base command_execute_method_name command_execute_return_method_name command_creation_chain_methods command_execute_method_name);

my $required_method = sub {
    my ( $tgt, $method ) = @_;
    $tgt->can($method) or croak( "You need an '$method' in " . ( blessed $tgt || $tgt ) );
};

my $call_required_method = sub {
    my ( $tgt, $method, @args ) = @_;
    my $m = $required_method->( $tgt, $method );
    return $m->( $tgt, @args );
};

my $call_optional_method = sub {
    my ( $tgt, $method, @args ) = @_;
    my $m = $tgt->can($method) or return;
    return $m->( $tgt, @args );
};

my $call_indirect_method = sub {
    my ( $tgt, $name_getter, @args ) = @_;
    my $g = $call_required_method->( $tgt, $name_getter );
    my $m = $required_method->( $tgt, $g );
    return $m->( $tgt, @args );
};

sub _initialize_from_cmd
{
    my ( $class, %params ) = @_;

    my @args = shellwords( join ' ', map { quotemeta } @ARGV );

    my ( @used_args, $cmd, $cmd_name, $cmd_name_index );

    my %cmd_create_params = %params;
    delete @cmd_create_params{ qw(command_commands), @private_init_params };

    defined $params{command_commands} or $params{command_commands} = $class->_build_command_commands( \%params );
    if ( ( $cmd_name_index = first_index { $cmd = $params{command_commands}->{$_} } @args ) >= 0 )
    {
        @used_args = splice @args, 0, $cmd_name_index;
        $cmd_name = shift @args;    # be careful about relics

        use_module($cmd);
        defined $cmd_create_params{command_execute_method_name}
          or $cmd_create_params{command_execute_method_name} =
          $call_optional_method->( $cmd, "_build_command_execute_method_name", \%cmd_create_params );
        defined $cmd_create_params{command_execute_method_name}
          or $cmd_create_params{command_execute_method_name} = "execute";
        $required_method->( $cmd, $cmd_create_params{command_execute_method_name} );
    }
    else
    {
        @used_args = @args;
        @args      = ();
    }

    defined $params{command_creation_chain_methods}
      or $params{command_creation_chain_methods} = $class->_build_command_creation_chain_methods( \%params );
    my @creation_chain =
      _ARRAY( $params{command_creation_chain_methods} )
      ? @{ $params{command_creation_chain_methods} }
      : ( $params{command_creation_chain_methods} );
    ( my $creation_method = first_result { defined $_ and $class->can($_) } @creation_chain )
      or croak "Can't find a creation method on $class";

    @ARGV                 = @used_args;
    $params{command_args} = [@args];
    $params{command_name} = $cmd_name;
    defined $params{command_chain} or $params{command_chain} = [];
    my $self = $creation_method->( $class, %params );
    push @{ $self->command_chain }, $self;

    if ($cmd)
    {
        @ARGV = @args;
        my ( $creation_method, $creation_method_name, $cmd_plugin );
        $cmd->can("_build_command_creation_method_name")
          and $creation_method_name = $cmd->_build_command_creation_method_name( \%params );
        $creation_method_name and $creation_method = $cmd->can($creation_method_name);
        if ($creation_method)
        {
            @cmd_create_params{qw(command_chain)} = @$self{qw(command_chain)};
            $cmd_plugin = $creation_method->( $cmd, %cmd_create_params );
            $self->{ $self->command_execute_return_method_name } =
              [ @{ $call_indirect_method->( $cmd_plugin, "command_execute_return_method_name" ) } ];
        }
        else
        {
            ( $creation_method = first_result { defined $_ and $cmd->can($_) } @creation_chain )
              or croak "Can't find a creation method on " . $cmd;
            $cmd_plugin = $creation_method->($cmd);
            push @{ $self->command_chain }, $cmd_plugin;

            my $cemn = $cmd_plugin->can("command_execute_method_name");
            my $exec_fun = $cemn ? $cemn->() : $self->command_execute_method_name();
            $self->command_execute_from_new
              and $self->{ $self->command_execute_return_method_name } =
              [ $call_required_method->( $cmd_plugin, $exec_fun, \@ARGV, $self->command_chain ) ];
        }
    }
    else
    {
        $self->command_execute_from_new
          and $self->{ $self->command_execute_return_method_name } =
          [ $call_indirect_method->( $self, "command_execute_method_name", \@ARGV, $self->command_chain ) ];
    }

    return $self;
}

=head2 execute_return

returns the content of $self->{execute_return}

=cut

# XXX should be an r/w attribute - can be renamed on loading ...
sub execute_return { $_[0]->{execute_return} }

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Torsten Raudssus, Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
