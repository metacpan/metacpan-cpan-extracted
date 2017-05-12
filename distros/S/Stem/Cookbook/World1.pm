package World1;

# This is  class level cell with no constructor or alias registration.
# It has one simple command message handler

sub hello_cmd {

    return "Hello world!\n";
}

=head1 Stem Cookbook - World1

=head1 NAME

World1 - A minimal class level B<Stem> cell.

=head1 DESCRIPTION

This is the simplest possible B<Stem> class level cell.  It contains a
single method named C<world_cmd>.  Because this method ends in C<_cmd>
it is capable of being invoked remotely via a command message and have
its return value sent back as a response message to the sender, which
in this example is the Stem::Console cell.

=head2 COMMAND METHOD

The following code snippet in the F<World1> class cell is the method
that will receive a hello command from a remote sender.

    package World1;

    sub hello_cmd {

	return "Hello world!\n";
    }

B<Stem> makes the creation of Command message handling methods very
I<easy>.  Any return with defined data will automatically be sent back
to the sender of this command in a response type message. In the
method above we return the "Hello world!\n" string which will get printed on 
the console.

For more information on how a message is routed to its destination
cell in B<Stem> please see the F<Stem Messaging Design Notes>.

=head1 THE CONFIGURATION FILE

The following B<Stem> configuration file is used to bring a
World1 class level cell into existance in the B<Stem> environment.

-
 class: Stem::Console
-
 class: World1

The first entry is C<Stem::Console>, a class level cell allows a user
to manually send command messages into the B<Stem> system.  It is not
required for this module, but it is used in this example to send
messages to the World1 class and to print responses from it.  The
second entry loads the C<World1> class. We can now refer to this class
cell as I<World1> when we want to send it a message.

=head1 USAGE

Execute C<run_stem world> from the command line to run this configuration.
You will be greeted with the B<StemE<gt>> prompt.  It is now
possible to send a message manually to I<World1>.  Type the following
command at the B<Stem> prompt:

B<World1 hello>

This is standard B<Stem> Console syntax, the cell address followed by
the command name.  This will send a message world_cmd method in the
C<World1> class cell. That method returns a value, which is converted
into a response message addressed to Stem::Console (the originator of
the command message), and its data will be printed on the console terminal.

B<"Hello world!">

=cut

1 ;
