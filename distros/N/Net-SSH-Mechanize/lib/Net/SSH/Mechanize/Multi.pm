package Net::SSH::Mechanize::Multi;
use Moose;
use Net::SSH::Mechanize;
use Carp qw(croak);
use Coro;

our $VERSION = '0.1.3'; # VERSION

######################################################################
# attributes

has 'ssh_instances' => (
    isa => 'ArrayRef[Net::SSH::Mechanize]',
    is => 'ro',
    default => sub { [] },
);


has 'names' => (
    isa => 'HashRef[Net::SSH::Mechanize]',
    is => 'ro',
    default => sub { +{} },
);

has 'constructor_defaults' => (
    isa => 'HashRef',
    is => 'rw',
    default => sub { +{} },
);

######################################################################

sub _to_ssh {
    my $self = shift;
    my @instances;
    my $defaults = $self->constructor_defaults;

    while(@_) {
        my ($name, $connection) = splice @_, 0, 2;
        $connection = Net::SSH::Mechanize->new(%$defaults, %$connection)
            if ref $connection eq 'HASH';

        $connection = Net::SSH::Mechanize->new(%$defaults, connection_params => $connection)
            if blessed $connection 
                && $connection->isa('Net::SSH::Mechanize::ConnectParams');
        
        croak "Connection '$name' is not a hashref, Net::SSH::Mechanize::ConnectParams instance, nor a",
            "Net::SSH::Mechanize instance (it is $connection)"
                unless blessed $connection
                    && $connection->isa('Net::SSH::Mechanize');

        push @instances, $connection;
    }

    return @instances;
}


sub add {
    my $self = shift;
    croak "uneven number of name => connection parameters"
        if @_ % 2;

    my %new_instances = @_;

    my @new_names = keys %new_instances;
    my $names = $self->names;
    my @defined = grep { $names->{$_} } @new_names;

    croak "These names are already defined: @defined"
        if @defined;

    my @new_instances = $self->_to_ssh(%new_instances);
    
    my $instances = $self->ssh_instances;

    @$names{@new_names} = @new_instances;
    push @$instances, @new_instances;

    return @new_instances;
}


sub in_parallel {
    my $self = shift;
    my $cb = pop;
    croak "you must supply a callback"
        unless ref $cb eq 'CODE';
    
    my @names = @_;
    my $known_names = $self->names;
    my @instances = map { $known_names->{$_} } @names;
    if (@names != grep { defined } @instances) {
        my @unknown = grep { !$known_names->{$_} } @names;
        croak "These names are unknown: @unknown";
    }

    my @threads;
    my $ix = 0;

    foreach my $ix (0..$#instances) {
        push @threads, async {
            my $name = $names[$ix];
            my $ssh = $instances[$ix];
            
            eval {
                $cb->($name, $ssh);
                1;
            } or do {
                print "error ($name): $@";
            };
        }
    }

    return \@threads;
}



__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Net::SSH::Mechanize::Multi - parallel ssh invocation 

=head1 VERSION

version 0.1.3

=head1 SYNOPSIS

    my $manager = Net::SSH::Mechanize::Multi->new(

        # Set the default parameters for the Net::SSH::Mechanize
        # instances we will create
        constructor_defaults => { login_timeout => 180 },

    );

    # Add connection definitions as a list of connection-name to
    # Net::SSH::Mechanize instance pairs (or shorthand equivalents, as
    # illustrated).
    $manager->add(

        # This defines the connection using a
        # Net::SSH::Mechanize::ConnectParams instance (or subclass
        # thereof)
        connection1 => Net::SSH::Mechanize::ConnectParams->new(
            hostname => 'host1.com',
        ),

        # This defines it using a hashref of constructor parameters
        # for Net::SSH::Mechanize
        connection2 => {
            user => 'joe',
            hostname => 'host1.com',
            login_timeout => 60,
        },
        
        # This passes a Net::SSH::Mechanize instance directly
        connection3 => Net::SSH::Mechanize->new(
            user => 'joe',
            hostname => 'host2.com',
            login_timeout => 60,
        ),

        # ...        
    );

    # At this point no hosts have been contacted.

    # Connect to a named subset of them all in parallel like this.
    # The callback should expect the name and the appropriate
    # Net::SSH::Mechanize instance as arguments.
    # Synchronous commands in the callback work asyncronously 
    # thanks to Coro::AnyEvent.
    my @names = qw(host1 host2);
    my $threads = $manager->in_parallel(@names => sub {
        my ($name, $ssh) = @_;

        printf "About to connect to %s using;\n'$s'\n\n",
            $name, $ssh->connection_params->ssh_cmd

        # note, the login is done implicitly when you access the
        # ->session parameter, or a method which delegates to it.

        # do stuff... 
        print "checking git status of config definition:\n";
        print $ssh->sudo_capture("cd /root/config; git status");
        
        # ...
    });

    # Wait for them all to complete.
    $_->join for @$threads;

    print "done\n";


There is a full implementation of this kind of usage is in the
C<gofer> script included in this distribution.

=head1  CLASS METHODS

=head2 C<< $obj = $class->new(%params) >>

Creates a new instance.  Parameters is a hash or a list of key-value
parameters.  Valid parameter keys are:

=over 4

=item C<constructor_defaults>

This is an optional parameter which can be used to define a hashref of
default parameters to pass to C<Net::SSH::Mechanize> instances created
by this class.  These defaults can be overridden in individual cases.

=back 

Currently it is also possible to pass parameters to initialise the
C<names> and C<ssh_instances> attributes, but since the content of
those are intended to be correlated this is definitely not
recommended.  Use C<< ->add >> instead.

=head1 INSTANCE ATTRIBUTES

=head2 C<< $hashref = $obj->constructor_defaults >>
=head2 C<< $obj->constructor_defaults(\%hashref) >>

This is an read-write accessor which allows you to specify the default
parameters to pass to the C<Net::SSH::Mechanize> constructor. These
defaults can be overridden in individual cases.

=head2 C<< $hashref = $obj->names >>

This is a hashref of connection names mapped to C<Net::SSH::Mechanize>
instances.  It is not recommend you change this directly, use the 
C<< ->add >> method instead.

=head2 C<< $hashref = $obj->ssh_instances >>

This is an arrayref listing C<Net::SSH::Mechanize> instances we have
created, in the order they have been defined via C<< ->add >> (which
is also the order they will be iterated over within C<< ->in_parallel >>).

=head1 INSTANCE METHODS

=head2 C<< @mech_instances = $obj->add(%connections) >>

Adds one or more named connection definitions.

C<%connections> is a hash or list of name-value pairs defining what to
connect to. The order in which they are defined here is preserved and
used when iterating over them in C<< ->in_parallel >>.

The names are simple string aliases, and can be anything unique (to
this instance).  If a duplicate is encountered, an exception will be
thrown.

The values can be: 

=over 4

=item B<<A C<Net::SSH::Mechanize> instance>>

The instance will be used as given to connect to a host.

=item B<<A C<Net::SSH::Mechanize::ConnectParams>> instance>>

The instance will be used to create a C<Net::SSH::Mechanize> instance to use.

=item B<A hashref of constructor paramters for C<Net::SSH::Mechanize> >>

The hashref will be passed to C<< Net::SSH::Mechanize->new >> to get an instance to use.

=back

A list of the C<Net::SSH::Mechanize> instances are returned, in the
order they were defined.

This method can be called any number of times, so long as the
connection names are never duplicated.


=head2 C<< @threads = $obj->in_parallel(@names, \&actions) >>

This method accepts a list of host-names, and a callback.  The callback
should expect two parameters: a connection name, and a
C<Net::SSH::Mechanize> instance.

It first checks that all the names have been defined in an earlier 
C<< ->add >> invocation.  If any are unknown, an exception is thrown.

Otherwise, it iterates over the names in the order given, and invokes
the callback with the name and the appropriate C<Net::SSH::Mechanize>
instance.

Note: the callback is invoked each time as a I<co-routine>. See
L<Coro> and L<Coro::AnyEvent> for more information about this, but it
essentially means that each one is asynchronously run in parallel.
This method returns a list of C<Coro> threads, immediately, before the
callbacks have completed.

Your program is then free to do other things, and/or call C<< ->join >>
on each of the threads to wait for their termination.

=head1 AUTHOR

Nick Stokoe  C<< <wulee@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2011, Nick Stokoe C<< <wulee@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
