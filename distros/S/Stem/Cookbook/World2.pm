package World2;

# This is  class level cell with no constructor or alias registration.
# It has two command message handlers, one to get the name and one to set it.

my $name = 'UNKNOWN' ;

sub hello_cmd {

    return "Hello world from $name\n";
}

sub name_cmd {

	my ( $self, $msg ) = @_ ;

	my $data = $msg->data() ;

	return unless $data ;

	$name = ${$data} ;

	return ;
}


=head1 Stem Cookbook - World2

=head1 NAME

World2 - A minimal class level B<Stem> cell with read/write data.

=head1 DESCRIPTION

This B<Stem> class level cell is an extension of the World1 class. It
still has a method named C<world_cmd> that will return the stored
name. The C<name_cmd> method takes a message and set the $name to its
data.

=head2 COMMAND METHOD

The following code snippet in the F<World2> class
cell is the method that will receive a hello command from a
remote sender.

    package World2;

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
World2 class level cell into existance in the B<Stem> environment.

[
        class	=>	'Stem::Console',
],
[
        class	=>	'World2',
]

The first entry is C<Stem::Console>, class level cell allows a user to
manually send command messages into the B<Stem> system.  It is not
required for this module, but it is used in this example to send
messages to the World2 class and to print responses from it.  The
second entry loads the C<World2> class. We can now refer to this class
cell as I<World2> when we want to send it a message.

=head1 USAGE

Execute C<run_stem world> from the command line to run this configuration.
You will be greeted with the B<StemE<gt>> prompt.  It is now
possible to send a message manually to I<World2>.  Type the following
command at the B<Stem> prompt:

B<World2 hello>

This is standard B<Stem> Console syntax, the cell address followed by
the command name.  This will send a message world_cmd method in the
C<World2> class cell. That method returns a value, which is converted
into a response message addressed to Stem::Console (the originator of
the command message), and its data will be printed on the console terminal.

B<"Hello world!">

=head1 SEE ALSO

F<Stem Cookbook Part 2>

F<Stem Cookbook Part 3>

=cut

1;
