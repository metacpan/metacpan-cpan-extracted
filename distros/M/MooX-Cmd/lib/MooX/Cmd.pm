package MooX::Cmd;

use strict;
use warnings;

our $VERSION = "0.015";

use Package::Stash;

sub import
{
    my ( undef, %import_options ) = @_;
    my $caller = caller;
    my @caller_isa;
    { no strict 'refs'; @caller_isa = @{"${caller}::ISA"} };

    #don't add this to a role
    #ISA of a role is always empty !
    ## no critic qw/ProhibitStringyEval/
    @caller_isa or return;

    my $execute_return_method_name = $import_options{execute_return_method_name};

    exists $import_options{execute_from_new} or $import_options{execute_from_new} = 1;    # set default until we want other way

    my $stash = Package::Stash->new($caller);
    defined $import_options{execute_return_method_name}
      and $stash->add_symbol( '&' . $import_options{execute_return_method_name},
        sub { shift->{ $import_options{execute_return_method_name} } } );
    defined $import_options{creation_method_name} or $import_options{creation_method_name} = "new_with_cmd";
    $stash->add_symbol( '&' . $import_options{creation_method_name}, sub { shift->_initialize_from_cmd(@_); } );

    my $apply_modifiers = sub {
        $caller->can('_initialize_from_cmd') and return;
        my $with = $caller->can('with');
        $with->('MooX::Cmd::Role');
        # XXX prove whether it can chained ...
        $import_options{with_config_from_file} and $with->('MooX::ConfigFromFile::Role');
        $import_options{with_config_from_file} and $with->('MooX::Cmd::Role::ConfigFromFile');
    };
    $apply_modifiers->();

    my %default_modifiers = (
        base                       => '_build_command_base',
        execute_method_name        => '_build_command_execute_method_name',
        execute_return_method_name => '_build_command_execute_return_method_name',
        creation_chain_methods     => '_build_command_creation_chain_methods',
        creation_method_name       => '_build_command_creation_method_name',
        execute_from_new           => '_build_command_execute_from_new',
    );

    my $around;
    foreach my $opt_key ( keys %default_modifiers )
    {
        exists $import_options{$opt_key} or next;
        $around or $around = $caller->can('around');
        $around->( $default_modifiers{$opt_key} => sub { $import_options{$opt_key} } );
    }

    return;
}

1;

=encoding utf8

=head1 NAME

MooX::Cmd - Giving an easy Moo style way to make command organized CLI apps

=head1 SYNOPSIS

  package MyApp;

  use Moo;
  use MooX::Cmd;

  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @extra_argv = @{$args_ref};
    my @chain = @{$chain_ref} # in this case only ( $myapp )
                              # where $myapp == $self
  }

  1;
 
  package MyApp::Cmd::Command;
  # for "myapp command"

  use Moo;
  use MooX::Cmd;

  # gets executed on "myapp command" but not on "myapp command command"
  # there MyApp::Cmd::Command still gets instantiated and for the chain
  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @chain = @{$chain_ref} # in this case ( $myapp, $myapp_cmd_command )
                              # where $myapp_cmd_command == $self
  }

  1;

  package MyApp::Cmd::Command::Cmd::Command;
  # for "myapp command command"

  use Moo;
  use MooX::Cmd;

  # gets executed on "myapp command command" and will not get instantiated
  # on "myapp command" cause it doesnt appear in the chain there
  sub execute {
    my ( $self, $args_ref, $chain_ref ) = @_;
    my @chain = @{$chain_ref} # in this case ( $myapp, $myapp_cmd_command,
                              # $myapp_cmd_command_cmd_command )
                              # where $myapp_cmd_command_cmd_command == $self
  }

  package MyZapp;

  use Moo;
  use MooX::Cmd execute_from_new => 0;

  sub execute {
    my ( $self ) = @_;
    my @extra_argv = @{$self->command_args};
    my @chain = @{$self->command_chain} # in this case only ( $myzapp )
                              # where $myzapp == $self
  }

  1;
 
  package MyZapp::Cmd::Command;
  # for "myapp command"

  use Moo;
  use MooX::Cmd execute_from_new => 0;

  # gets executed on "myapp command" but not on "myapp command command"
  # there MyApp::Cmd::Command still gets instantiated and for the chain
  sub execute {
    my ( $self ) = @_;
    my @extra_argv = @{$self->command_args};
    my @chain = @{$self->command_chain} # in this case ( $myzapp, $myzapp_cmd_command )
                              # where $myzapp_cmd_command == $self
  }

  1;
  package main;

  use MyApp;

  MyZapp->new_with_cmd->execute();
  MyApp->new_with_cmd;

  1;

=head1 DESCRIPTION

Eases the writing of command line utilities, accepting commands and
subcommands and so on. These commands can form a tree, which is
mirrored in the package structure. On invocation each command along
the path through the tree (starting from the toplevel command
through to the most specific one) is instanciated.

Each command needs to have an C<execute> function, accepting three
parameters:

=over

=item C<self>

A reference to the specific L<MooX::Cmd> object that is executing.

=item C<args>

An ArrayRef of arguments passed to C<self>. This only encompasses
arguments of the most specific (read: right-most) command.

=item C<chain>

An ArrayRef of C<MooX::Cmd>s along the tree path, as specified on
the command line.

=back

B<Note that only the execute function of the most specific command is executed.>

=head3 L<MooX::Cmd> Attributes

Each command has some attributes set by L<MooX::Cmd> during
initialization:

=over

=item C<command_chain>

Same as C<chain> argument to C<execute>.

=item C<command_name>

TODO

=item C<command_commands>

TODO

=item C<command_args>

TODO

=item C<command_base>

TODO

=back

=head2 Examples

=head3 A Single Toplevel Command

  #!/usr/bin/env perl
  package MyApp;
  use Moo;
  use MooX::Cmd;

  sub execute {
    my ($self,$args,$chain) = @_;
    printf("%s.execute(\$self,[%s],[%s])\n",
      ref($self),                       # which command is executing?
      join(", ", @$args ),              # what where the arguments?
      join(", ", map { ref } @$chain)   # what's in the command chain?
    );
  }

  package main;
  MyApp->new_with_cmd();

Some sample invocations:

 $ ./MyApp.pl
 MyApp.execute($self,[],[MyApp])

 $./MyApp.pl --opt1
 MyApp.execute($self,[--opt1],[MyApp])

 $ ./MyApp.pl --opt1 arg
 MyApp.execute($self,[--opt1, arg],[MyApp])

=head3 Toplevel Command with Subcommand

  #!/usr/bin/env perl
  # let's define a base class containing our generic execute
  # function to save some typing...
  package CmdBase;
  use Moo;

  sub execute {
    my ($self,$args,$chain) = @_;
    printf("%s.execute(\$self,[%s],[%s])\n",
      ref($self),
      join(", ", @$args ),
      join(", ", map { ref } @$chain)
    );
  }

  package MyApp;
  # toplevel command/app
  use Moo;
  use MooX::Cmd;
  extends 'CmdBase';

  package MyApp::Cmd::frobnicate;
  # can be called via ./MyApp.pl frobnicate
  use Moo;
  use MooX::Cmd;
  extends 'CmdBase';

  package main;
  MyApp->new_with_cmd();

And some sample invocations:

  $ ./MyApp.pl frobnicate
  MyApp::Cmd::frobnicate.execute($self,[],[MyApp, MyApp::Cmd::frobnicate])

As you can see the chain contains our toplevel command object and
then the specififc one.

  $ ./MyApp.pl frobnicate arg1
  MyApp::Cmd::frobnicate.execute($self,[arg1],[MyApp, MyApp::Cmd::frobnicate])

Arguments are passed via the C<args> parameter.

  $ ./MyApp.pl some --stuff frobnicate arg1
  MyApp::Cmd::frobnicate.execute($self,[arg1],[MyApp, MyApp::Cmd::frobnicate])

Arguments to commands higher in the tree get ignored if they don't
match a command.

=head3 Access Toplevel Attributes via Chain

  #!/usr/bin/env perl
  package CmdBase;
  use Moo;

  sub execute {
    my ($self,$args,$chain) = @_;
    printf("%s.execute(\$self,[%s],[%s])\n",
      ref($self),
      join(", ", @$args ),
      join(", ", map { ref } @$chain)
    );
  }

  package MyApp;
  use Moo;
  use MooX::Cmd;
  extends 'CmdBase';

  has somevar => ( is => 'ro', default => 'someval' );

  package MyApp::Cmd::frobnicate;
  use Moo;
  use MooX::Cmd;
  extends 'CmdBase';

  around execute => sub {
    my ($orig,$self,$args,$chain) = @_;
    $self->$orig($args,$chain);
    # we can access toplevel attributes via the chain...
    printf("MyApp->somevar = '%s'\n", $chain->[0]->somevar);
  };

  package main;
  MyApp->new_with_cmd();

A sample invocation

  $ ./MyApp.pl some --stuff frobnicate arg1
  MyApp::Cmd::frobnicate.execute($self,[arg1],[MyApp, MyApp::Cmd::frobnicate])
  MyApp->somevar = someval


=head2 L<MooX::Options> integration

You can integrate L<MooX::Options> simply by using it and declaring
some options, like so:

  #!/usr/bin/env perl
  package MyApp;
  use Moo;
  use MooX::Cmd;
  use MooX::Options;

  option debug => ( is => 'ro' );

  sub execute {
    my ($self,$args,$chain) = @_;
    print "debugging enabled!\n" if $self->{debug};
  }

  package main;
  MyApp->new_with_cmd();

A sample invocation

  $ ./MyApp-Options.pl --debug
  debugging enabled!

B<Note, that each command and subcommand has its own options.>, so options are
parsed for the specific context and used for the instantiation:

  $ ./MyApp.pl --argformyapp command --argformyappcmdcommand ...

=head1 SUPPORT

Repository

  http://github.com/Getty/p5-moox-cmd
  Pull request and additional contributors are welcome

Issue Tracker

  http://github.com/Getty/p5-moox-cmd/issues
  http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooX-Cmd
  bug-moox-cmd at rt.cpan.org

=head1 THANKS

=over

=item Lukas Mai (mauke), Toby Inkster (tobyink)

Gave some helpful advice for solving difficult issues

=item Celogeek San

Integration into MooX::Options for better help messages and suit team play

=item Torsten Raudssus (Getty)

did the initial work and brought it to CPAN

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2013 Torsten Raudssus, Copyright 2013-2015 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut
