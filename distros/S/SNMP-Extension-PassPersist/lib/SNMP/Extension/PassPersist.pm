package SNMP::Extension::PassPersist;
use strict;
use warnings;

use parent qw< Class::Accessor >;

use Carp;
use Getopt::Long;
use File::Basename;
use IO::Handle;
use IO::Pipe;
use IO::Select;
use List::MoreUtils     qw< any >;
use Storable            qw< nfreeze thaw >;
use Sys::Syslog;


{
    no strict "vars";
    $VERSION = '0.07';
}

use constant HAVE_SORT_KEY_OID
                    => eval "use Sort::Key::OID 0.04 qw<oidsort>; 1" ? 1 : 0;


# early initialisations --------------------------------------------------------
my @attributes = qw<
    backend_collect
    backend_fork
    backend_init
    backend_pipe
    heap
    idle_count
    input
    oid_tree
    sorted_entries
    output
    refresh
    dispatch
>;

__PACKAGE__->mk_accessors(@attributes);


# constants --------------------------------------------------------------------
use constant SNMP_NONE                  => "NONE";
use constant SNMP_PING                  => "PING";
use constant SNMP_PONG                  => "PONG";
use constant SNMP_GET                   => "get";
use constant SNMP_GETNEXT               => "getnext";
use constant SNMP_SET                   => "set";
use constant SNMP_NOT_WRITABLE          => "not-writable";
use constant SNMP_WRONG_TYPE            => "wrong-type";
use constant SNMP_WRONG_LENGTH          => "wrong-length";
use constant SNMP_WRONG_VALUE           => "wrong-value";
use constant SNMP_INCONSISTENT_VALUE    => "inconsistent-value";


# global variables -------------------------------------------------------------
my %snmp_ext_type = (
    counter     => "counter",
    counter64   => "counter64",
    gauge       => "gauge",
    integer     => "integer",
    ipaddr      => "ipaddress",
    ipaddress   => "ipaddress",
    netaddr     => "ipaddress",
    objectid    => "objectid",
    octetstr    => "string",
#   opaque      => "opaque",
    string      => "string",
    timeticks   => "timeticks",
);



#
# new()
# ---
sub new {
    my ($class, @args) = @_;
    my %attrs;
    my $ref = ref $args[0];

    # see how arguments were passed
    if ($ref and $ref eq "HASH") {
        %attrs = %{$args[0]};
    }
    else {
        croak "error: Don't know how to handle \L$ref reference" if $ref;
        croak "error: Odd number of arguments"  if @args % 2 == 1;
        %attrs = @args;
    }

    # filter out unknown attributes
    my %known_attr;
    @known_attr{@attributes} = (1) x @attributes;
    !$known_attr{$_} && delete $attrs{$_} for keys %attrs;

    # check that code attributes are coderefs
    for my $code_attr (qw<backend_init backend_collect>) {
        croak "error: Attribute $code_attr must be a code reference"
            if defined $attrs{$code_attr} and ref $attrs{$code_attr} ne "CODE";
    }

    # default values
    %attrs = (
        backend_collect => sub {},
        backend_fork    => 0,
        backend_init    => sub {},
        heap            => {},
        input           => \*STDIN,
        output          => \*STDOUT,
        oid_tree        => {},
        sorted_entries  => [],
        idle_count      => 5,
        refresh         => 10,
        dispatch        => {
            lc(SNMP_PING)    => { nargs => 0,  code => \&ping        },
            lc(SNMP_GET)     => { nargs => 1,  code => \&get_oid     },
            lc(SNMP_GETNEXT) => { nargs => 1,  code => \&getnext_oid },
            lc(SNMP_SET)     => { nargs => 2,  code => \&set_oid     },
        },
        %attrs,
    );

    # create the object with Class::Accessor
    my $self = $class->SUPER::new(\%attrs);

    return $self
}


#
# run()
# ---
sub run {
    my ($self) = @_;

    # process command-line arguments
    Getopt::Long::Configure(qw<no_auto_abbrev no_ignore_case>);
    GetOptions(\my %options, qw<get|g=s  getnext|n=s  set|s=s>)
        or croak "fatal: An error occured while processing runtime arguments";

    my $name = $::COMMAND || basename($0);
    openlog($name, "ndelay,pid", "local0");

    my ($mode_pass, $mode_passpersist);
    my $backend_fork = $self->backend_fork;

    # determine the run mode
    if (any { defined $options{$_} } "get", "getnext", "set") {
        $mode_pass          = 1;
        $mode_passpersist   = 0;
    }
    else {
        $mode_pass          = 0;
        $mode_passpersist   = 1;
    }

    # execute the init and collect callback once, except in the case
    # where the backend run in a separate process
    unless ($mode_passpersist and $backend_fork) {
        # initialise the backend
        eval { $self->backend_init->($self); 1 }
            or croak "fatal: An error occurred while executing the backend "
                    ."initialisation callback: $@";

        # collect the information
        eval { $self->backend_collect->($self); 1 }
            or croak "fatal: An error occurred while executing the backend "
                    ."collecting callback: $@";
    }

    # Net-SNMP "pass" mode
    if ($mode_pass) {
        for my $op (qw<get getnext set>) {
            if ($options{$op}) {
                my @args = split /,/, $options{$op};
                my $coderef = $self->dispatch->{$op}{code};
                my @result = $coderef->($self, @args);
                $self->output->print(join "\n", @result, "");
            }
        }
    }
    # Net-SNMP "pass_persist" mode
    else {
        my $needed  = 1;
        my $delay   = $self->refresh;
        my $counter = $self->idle_count;
        my ($pipe, $child);

        # if the backend is to be run in a separate process,
        # create a pipe and fork
        if ($backend_fork) {
            $pipe = IO::Pipe->new;
            $self->backend_pipe($pipe);

            $child = fork;
            my $msg = "fatal: can't fork: $!";
            syslog err => $msg and die $msg
                unless defined $child;

            # child setup is handled in run_backend_loop()
            goto &run_backend_loop if $child == 0;

            # parent setup
            $pipe->reader;  # declare this end of the pipe as the reader
            $pipe->autoflush(1);
        }

        my $io = IO::Select->new;
        $io->add($self->input);
        $self->output->autoflush(1);

        if ($backend_fork) {
            $io->add($pipe);
            $SIG{CHLD} = sub { $io->remove($pipe); waitpid($child, 0); };
        }


        # main loop
        while ($needed and $counter > 0) {
            my $start_time = time;

            # wait for some input data
            my @ready = $io->can_read($delay);

            for my $fh (@ready) {
                # handle input data from netsnmpd
                if ($fh == $self->input) {
                    if (my $cmd = <$fh>) {
                        $self->process_cmd(lc($cmd), $fh);
                        $counter = $self->idle_count;
                    }
                    else {
                        $needed = 0
                    }
                }

                # handle input data from the backend process
                if ($backend_fork and $fh == $pipe) {
                    use bytes;

                    # read a first chunk from the child
                    $fh->sysread(my $buffer, 20);
                    last unless length $buffer;

                    # extract the header
                    my $headline= substr($buffer, 0, index($buffer, "\n")+1, "");
                    chomp $headline;
                    my %header  = map { split /=/, $_, 2 } split /\|/, $headline;

                    # read the date in Storable format
                    my $length  = $header{length};
                    $fh->sysread(my $freezed, $length);
                    $freezed    = $buffer.$freezed;

                    # decode the freezed data
                    my $struct  = thaw($freezed);
                    $self->add_oid_tree($struct);
                }
            }

            $delay = $delay - (time() - $start_time);

            if ($delay <= 0) {
                if (not $backend_fork) {
                    # collect information when the timeout has expired
                    eval { $self->backend_collect->($self); 1 }
                        or croak "fatal: An error occurred while executing "
                                ."the backend collecting callback: $@";
                }

                # reset delay
                $delay = $self->refresh;
                $counter--;
            }
        }

        if ($backend_fork) {
            kill TERM => $child;
            sleep 1;
            kill KILL => $child;
            waitpid($child, 0);
        }
    }
}


#
# run_backend_loop()
# ----------------
sub run_backend_loop {
    my ($self) = @_;

    my $pipe = $self->backend_pipe;
    $pipe->writer;  # declare this end of the pipe as the writer
    $pipe->autoflush(1);

    # execute the initialisation callback
    eval { $self->backend_init->($self); 1 }
        or croak "fatal: An error occurred while executing the backend "
                ."initialisation callback: $@";

    while (1) {
        my $start_time = time;

        # execute the collect callback
        eval { $self->backend_collect->($self); 1 }
            or croak "fatal: An error occurred while executing the backend "
                    ."collecting callback: $@";

        # freeze the OID tree using Storable
        use bytes;
        my $freezed = nfreeze($self->oid_tree);
        my $length  = length $freezed;
        my $output  = "length=$length\n$freezed";

        # send it to the parent via the pipe
        $pipe->syswrite($output);
        select(undef, undef, undef, .000_001);

        # wait before next execution
        my $delay = $self->refresh() - (time() - $start_time);
        sleep $delay;
    }
}


#
# add_oid_entry()
# -------------
sub add_oid_entry {
    my ($self, $oid, $type, $value) = @_;

    croak "error: Unknown type '$type'" unless exists $snmp_ext_type{$type};
    $self->oid_tree->{$oid} = [$type => $value];

    # need to resort
    @{$self->sorted_entries} = ();

    return 1
}


#
# add_oid_tree()
# ------------
sub add_oid_tree {
    my ($self, $new_tree) = @_;

    croak "error: Unknown type"
        if any { !$snmp_ext_type{$_->[0]} } values %$new_tree;
    my $oid_tree = $self->oid_tree;
    @{$oid_tree}{keys %$new_tree} = values %$new_tree;

    # need to resort
    @{$self->sorted_entries} = ();

    return 1
}


#
# dump_oid_tree()
# -------------
sub dump_oid_tree {
    my ($self) = @_;

    my $oid_tree = $self->oid_tree;
    my $output   = $self->output;

    for my $oid (sort by_oid keys %$oid_tree) {
        my ($type, $value) = @{ $oid_tree->{$oid} };
        $output->print("$oid ($type) = $value\n");
    }
}


#
# ping()
# ----
sub ping {
    return SNMP_PONG
}


#
# get_oid()
# -------
sub get_oid {
    my ($self, $req_oid) = @_;

    my $oid_tree = $self->oid_tree;
    my @result = ();

    if ($oid_tree->{$req_oid}) {
        my ($type, $value) = @{ $oid_tree->{$req_oid} };
        @result = ($req_oid, $type, $value);
    }
    else {
        @result = (SNMP_NONE)
    }

    return @result
}


#
# getnext_oid()
# -----------
sub getnext_oid {
    my ($self, $req_oid) = @_;

    my $next_oid = $self->fetch_next_entry($req_oid)
                || $self->fetch_first_entry();

    return $self->get_oid($next_oid)
}


#
# set_oid()
# -------
sub set_oid {
    my ($self, $req_oid, $value) = @_;
    return SNMP_NOT_WRITABLE
}


# 
# process_cmd()
# -----------
# Process and dispatch Net-SNMP commands when in pass_persist mode.
# 
sub process_cmd {
    my ($self, $cmd, $fh) = @_;
    my @result = ();

    chomp $cmd;
    my $dispatch = $self->dispatch;

    if (exists $dispatch->{$cmd}) {

        # read the command arguments
        my @args = ();
        my $n    = $dispatch->{$cmd}{nargs};

        while ($n-- > 0) {
            chomp(my $arg = <$fh>);
            push @args, $arg;
        }

        # call the command handler
        my $coderef = $dispatch->{$cmd}{code};
        @result = $coderef->($self, @args);
    }
    else {
        @result = SNMP_NONE;
    }

    # output the result
    $self->output->print(join "\n", @result, "");
}


#
# fetch_next_entry()
# ----------------
sub fetch_next_entry {
    my ($self, $req_oid) = @_;

    my $entries = $self->sorted_entries;

    if (!@$entries) {
        @$entries = HAVE_SORT_KEY_OID
            ? oidsort(keys %{ $self->oid_tree })
            : sort by_oid keys %{ $self->oid_tree };
    }

    # find the index of the current entry
    my $curr_entry_idx = -1;

    for my $i (0..$#$entries) {
        # exact match of the requested entry
        $curr_entry_idx = $i and last if $entries->[$i] eq $req_oid;

        # prefix match of the requested entry
        $curr_entry_idx = $i - 1 and last
            if $curr_entry_idx == -1 and index($entries->[$i], $req_oid) >= 0;
    }

    # get the next entry if it exists, otherwise none
    my $next_entry_oid = $entries->[$curr_entry_idx + 1] || SNMP_NONE;

    return $next_entry_oid
}


#
# fetch_first_entry()
# -----------------
sub fetch_first_entry {
    my ($self) = @_;

    my $entries = $self->sorted_entries;

    if (!@$entries) {
        @$entries = HAVE_SORT_KEY_OID
            ? oidsort(keys %{ $self->oid_tree })
            : sort by_oid keys %{ $self->oid_tree };
    }
    my $first_entry_oid = $entries->[0];

    return $first_entry_oid
}


# 
# by_oid()
# ------
# sort() sub-function, for sorting by OID
#
sub by_oid ($$) {
    my (undef, @a) = split /\./, $_[0];
    my (undef, @b) = split /\./, $_[1];
    my $v = 0;
    $v ||= $a[$_] <=> $b[$_] for 0 .. $#a;
    return $v
}


__PACKAGE__

__END__


=head1 NAME

SNMP::Extension::PassPersist - Generic pass/pass_persist extension framework
for Net-SNMP


=head1 VERSION

This is the documentation of C<SNMP::Extension::PassPersist> version 0.07


=head1 SYNOPSIS

Typical setup for a C<pass> program:

    use strict;
    use SNMP::Extension::PassPersist;

    # create the object
    my $extsnmp = SNMP::Extension::PassPersist->new;

    # add a few OID entries
    $extsnmp->add_oid_entry($oid, $type, $value);
    $extsnmp->add_oid_entry($oid, $type, $value);

    # run the program
    $extsnmp->run;

Typical setup for a C<pass_persist> program:

    use strict;
    use SNMP::Extension::PassPersist;

    my $extsnmp = SNMP::Extension::PassPersist->new(
        backend_collect => \&update_tree
    );
    $extsnmp->run;


    sub update_tree {
        my ($self) = @_;

        # add a serie of OID entries
        $self->add_oid_entry($oid, $type, $value);
        ...

        # or directly add a whole OID tree
        $self->add_oid_tree(\%oid_tree);
    }


=head1 DESCRIPTION

This module is a framework for writing Net-SNMP extensions using the
C<pass> or C<pass_persist> mechanisms.

When in C<pass_persist> mode, it provides a mechanism to spare
ressources by quitting from the main loop after a given number of
idle cycles.

This module can use C<Sort::Key::OID> when it is available, for sorting
OIDs faster than with the internal pure Perl function.


=head1 METHODS

=head2 new()

Creates a new object. Can be given any attributes as a hash or hashref.
See L<"ATTRIBUTES"> for the list of available attributes.

B<Examples:>

For a C<pass> command, most attributes are useless:

    my $extsnmp = SNMP::Extension::PassPersist->new;

For a C<pass_persist> command, you'll usually want to at least set the
C<backend_collect> callback:

    my $extsnmp = SNMP::Extension::PassPersist->new(
        backend_collect => \&update_tree,
        idle_count      => 10,      # no more than 10 idle cycles
        refresh         => 10,      # refresh every 10 sec
    );

=head2 run()

This method does the following things:

=over

=item *

process the command line arguments in order to decide in which mode
the program has to be executed

=item *

call the backend init callback

=item *

call the backend collect callback a first time

=back

Then, when in C<pass> mode, the corresponding SNMP command is executed,
its result is printed on the output filehandle, and C<run()> returns.

When in C<pass_persist> mode, C<run()> enters a loop, reading Net-SNMP
queries on its input filehandle, processing them, and printing result
on its output filehandle. The backend collect callback is called every
C<refresh> seconds. If no query is read from the input after C<idle_count>
cycles, C<run()> returns.

=head2 add_oid_entry(FUNC_OID, FUNC_TYPE, FUNC_VALUE)

Add an entry to the OID tree.

=head2 add_oid_tree(HASH)

Merge an OID tree to the main OID tree, using the same structure as
the one of the OID tree itself.

=head2 dump_oid_tree()

Print a complete listing of the OID tree on the output file handle.


=head1 ATTRIBUTES

This module's attributes are generated by C<Class::Accessor>, and can
therefore be passed as arguments to C<new()> or called as object methods.

=head2 backend_collect

Set the code reference for the I<collect> callback. See also L<"CALLBACKS">.

=head2 backend_fork

When set to true, the backend callbacks will be executed in a separate
process. Default value is false.

=head2 backend_init

Set the code reference for the I<init> callback. See also L<"CALLBACKS">.

=head2 backend_pipe

Contains the pipe used to communicate with the backend child, when executed
in a separate process.

=head2 dispatch

Gives access to the internal dispatch table, stored as a hash with the
following structure:

    dispatch => {
        SNMP_CMD  =>  { nargs => NUMBER_ARGS,  code => CODEREF },
        ...
    }

where the SNMP command is always in lowercase, C<nargs> gives the number
of arguments expected by the command and C<code> the callback reference.

You should not modify this table unless you really know what you're doing.

=head2 heap

Give access to the heap.

=head2 idle_count

Get/set the number of idle cycles before ending the run loop.

=head2 input

Get/set the input filehandle.

=head2 oid_tree

Gives access to the internal OID tree, stored as a hash with the
following structure:

    oid_tree => {
        FUNC_OID  =>  [ FUNC_TYPE, FUNC_VALUE ],
        ...
    }

where C<FUNC_OID> is the absolute OID of the SNMP function, C<FUNC_TYPE>
the function type (C<"integer">, C<"counter">, C<"gauge">, etc), and
C<FUNC_VALUE> the function value.

You should not directly modify this hash but instead use the appropriate
methods for adding OID entries.

=head2 output

Get/set the output filehandle.

=head2 refresh

Get/set the refresh delay before calling the backend collect callback
to update the OID tree.


=head1 CALLBACKS

The callbacks are invoked with the corresponding object as first argument,
as for a normal method. A heap is available for storing user-defined data.

In the specific case of a programm running in C<pass_persist> mode with
a forked backend, the callbacks are only executed in the child process
(the forked backend).

The currently implemented callbacks are:

=over

=item * init

This callback is called once, before the first I<collect> invocation
and before the main loop. It can be accessed and modified through the
C<backend_init> attribute.

=item * collect

This callback is called every C<refresh> seconds so the user can update
the OID tree using the C<add_oid_entry()> and C<add_oid_tree()> methods.

=back

=head2 Examples

For simple needs, only the I<collect> callback needs to be defined:

    my $extsnmp = SNMP::Extension::PassPersist->new(
        backend_collect => \&update_tree,
    );

    sub update_tree {
        my ($self) = @_;

        # fetch the number of running processes
        my $nb_proc = @{ Proc::ProcessTable->new->table };

        $self->add_oid_entry(".1.3.6.1.4.1.32272.10", gauge", $nb_proc);
    }

A more advanced example is when there is a need to connect to a database,
in which case both the I<init> and I<collect> callback need to be defined:

    my $extsnmp = SNMP::Extension::PassPersist->new(
        backend_init    => \&connect_db,
        backend_collect => \&update_tree,
    );

    sub connect_db {
        my ($self) = @_;
        my $heap = $self->heap;

        # connect to a database
        my $dbh = DBI->connect($dsn, $user, $password);
        $heap->{dbh} = $dbh;
    }

    sub update_tree {
        my ($self) = @_;
        my $heap = $self->heap;

        # fetch the number of records from a given table
        my $dbh = $heap->{dbh};
        my $sth = $dbh->prepare_cached("SELECT count(*) FROM whatever");
        $sth->execute;
        my ($count) = $sth->fetchrow_array;

        $self->add_oid_entry(".1.3.6.1.4.1.32272.20", "gauge", $count);
    }



=head1 SEE ALSO

L<SNMP::Persist> is another pass_persist backend for writing Net-SNMP 
extensions, but relies on threads.

The documentation of Net-SNMP, especially the part on how to configure
a C<pass> or C<pass_persist> extension:

=over

=item *

main site: L<http://www.net-snmp.org/>

=item *

configuring a pass or pass_persist extension:
L<http://www.net-snmp.org/docs/man/snmpd.conf.html#lbBB>

=back


=head1 BUGS

Please report any bugs or feature requests to 
C<bug-snmp-extension-passpersist at rt.cpan.org>, 
or through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=SNMP-Extension-PassPersist>.
I will be notified, and then you'll automatically be notified of 
progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SNMP::Extension::PassPersist


You can also look for information at:

=over

=item * Search CPAN

L<http://search.cpan.org/dist/SNMP-Extension-PassPersist>

=item * Meta CPAN

L<https://metacpan.org/release/SNMP-Extension-PassPersist>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=SNMP-Extension-PassPersist>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SNMP-Extension-PassPersist>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SNMP-Extension-PassPersist>

=back


=head1 AUTHOR

SE<eacute>bastien Aperghis-Tramoni, C<< <sebastien at aperghis.net> >>


=head1 COPYRIGHT & LICENSE

Copyright 2008-2011 SE<eacute>bastien Aperghis-Tramoni, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

