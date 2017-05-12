# $File: //depot/libOurNet/BBSAgent/BBSAgent.pm $ $Author: autrijus $
# $Revision: #3 $ $Change: 6077 $ $DateTime: 2003/05/25 10:48:47 $

package OurNet::BBSAgent;
use 5.005;

$OurNet::BBSAgent::VERSION = '1.61';

use strict;
use vars qw/$AUTOLOAD/;
use fields qw/bbsname bbsaddr bbsport bbsfile lastmatch loadstack
              debug timeout state proc var netobj hook loop errmsg/;
use Carp;
use Net::Telnet;

=head1 NAME

OurNet::BBSAgent - Scriptable telnet-based virtual users

=head1 SYNOPSIS

    #!/usr/local/bin/perl
    # To run it, make sure you have a 'elixus.bbs' file in the same
    # directory. The actual content is listed just below this section.

    use strict;
    use OurNet::BBSAgent;

    my $remote  = 'elixus.bbs';		# template name
    my $timeout = undef;		# no timeout
    my $logfile = 'elixus.log';		# log file
    my $bbs	= OurNet::BBSAgent->new($remote, $timeout, $logfile);

    my ($user, $pass) = @ARGV;
    $user = 'guest' unless defined($user);

    $bbs->{debug} = 1;			# debugging flag
    $bbs->login($user, $pass);		# username and password

    # callback($bbs->message) while 1;	# procedural interface

    $bbs->Hook('message', \&callback);	# callback-based interface
    $bbs->Loop(undef, 10);		# loop indefinitely, send Ctrl-L
					# every 10 seconds (anti-idle)

    sub callback {
	my ($caller, $message) = @_;

	print "Received: $message\n";

	($bbs->logoff, exit) if ($message eq '!quit');
	$bbs->message_reply("$caller: $message");
    }

=head1 DESCRIPTION

OurNet::BBSAgent provides an object-oriented interface to TCP/IP
based interactive services, by simulating as a I<virtual user>
with action defined by a script language. 

The developer could then use the same methods to access different 
services, to easily implement interactive robots, spiders, or other 
cross-service agents.

The scripting language of B<OurNet::BBSAgent> features both
flow-control and event-driven capabilities, makes it especially
well-suited for dealing with automation tasks involved with
Telnet-based BBS systems.

This module is the foundation of the B<BBSAgent> back-end described
in L<OurNet::BBS>. Please consult its man page for more information.

=head2 Site Description File

This module has its own scripting language, which looks like this in
a site description file:

    Elixus BBS
    elixus.org:23

    =login
    wait \e[7m
    send $[username]\n
    doif $[password]
        wait \e[7m
        send $[password]\nn\n
    endo
    # login failure, unsaved article, kick multi-logins
    send \n\n\n
    # skips splash screens (if any)
    send \x20\x20\x20

    =main
    send qqqqqqee
    wait \e[;H\e[2J\e[1;44;37m
    till ]\e[31m

    =logoff
    call main
    send g\ng\ny\ny\n\n\n
    exit

    =message
    wait \e[1;33;46m
    wait m/../
    till \x20\e[37;45m\x20
    till \x20\e[m
    exit

    =message_reply
    send \x12
    wait \e[m
    wait \e[23;1H
    send $[message]\n
    wait [Y]
    send \n
    wait \e[37;45m
    wait \e[m
    exit

The first two lines describe the service's title, its IP address and
port number. Any number of I<procedures> then begins with a C<=> sign
(e.g. =B<procname>), which could be called as
C<$object>-E<gt>C<procname>([I<arguments>]) in the program. 

=head2 Directives

All procedures are consisted of following directives:

=over 4

=item load I<FILENAME>

This directive must be used before any procedures. It loads another
BBS definition file under the same directory (or current directory).

If the I<FILENAME> has an extension other than C<.bbs> (eg. C<.board>,
C<.session>), BBSAgent will try to locate additional modules by 
expanding C<.> into C</>, and look for the required module with an
C<.inc> extension. For example, B<load> C<maple3.board> will look for
C<maple3/board.inc> in the same directory.  

=item wait I<STRING>

=item till I<STRING>

=item   or I<STRING>

Tells the agent to wait until STRING is sent by remote host. May time
out after C<$self>-E<gt>C<{timeout}> seconds. Each trailing B<or> directives
specifies an alternative string to match.

If STRING matches the regex C<m/.*/[imsx]*>, it will be treated as a regular
expression. Capturing parentheses are silently ignored.

The B<till> directive is functionally equivalent to B<wait>, except that
it will puts anything between the last B<wait> or B<till> and STRING 
into the return list.

=item send I<STRING>

Sends STRING to remote host.

=item doif I<CONDITION>

=item elif I<CONDITION>

=item else

=item endo

The usual flow control directives. Nested B<doif>...B<endo>s are supported.

=item goto I<PROCEDURE>

=item call I<PROCEDURE>

Executes another procedure in the site description file. A B<goto> never
returns, while a B<call> always does. Also, a B<call> will not occur if
the destination was the last executed procedure, which does not end with
B<exit>.

=item exit

Marks the termination of a procedure; also denotes that this procedure is
not a I<state> - that is, multiple B<call>s to it will all be executed.

=item setv I<VAR> I<STRING>

Sets a global, non-overridable variable (see below).

=item idle I<NUMBER>

Sleep that much seconds.

=back

=head2 Variable Handling

Whenever a variable in the form of $[name] is encountered as part 
of a directive, it will be looked up in the global B<setv> hash 
B<$self-E<gt>{var}> first, then at the procedure-scoped variable hash, 
then finally B<shift()>ed from the argument list if none are found.

For example:

    setv foo World!

    =login
    send $[bar] # sends the first argument
    send $[foo] # sends 'World!'
    send $[baz] # sends the second argument
    send $[bar] # sends the first argument again

A notable exception are digits-only subscripts (e.g. B<$[1]>), which
contains the matched string in the previous B<wait> or B<till> directive.
If there are multiple strings via B<or> directives, the subscript correspond
to the matched alternative.

For example:

    =match
    wait foo
      or m/baz+/
    doif $[1] # 'foo' matched
        send $[1] # sends 'foo'
    else
        send $[2] # sends 'bazzzzz...'
    endo

=head2 Event Hooks

In addition to call the procedures one-by-one, you can B<Hook> those
that begins with B<wait> (optionally preceded by B<call>) so whenever
the strings they expected are received, the responsible procedure is
immediately called. You may also supply a call-back function to handle
its results.

For example, the code in L</SYNOPSIS> above I<hooks> a callback function
to procedure B<message>, then enters a event loop by calling B<Loop>, 
which goes on forever until the agent receives C<!quit> via the C<message>
procedure.

The internal hook table could be accessed by C<$obj>-E<gt>C<{hook}>.

=head1 METHODS

Following methods are offered by B<OurNet::BBSAgent>:

=head2 new($class, $bbsfile, [$timeout], [$logfile])

Constructor class method. Takes the BBS description file's name and 
two optional arguments, and returns a B<OurNet::BBSAgent> object.

If no files are found at C<$bbsfile>, the method will try to locate
it on the B<OurNet/BBSAgent> sub-directory of each @INC entries.

=cut

sub new {
    my $class = shift;
    my OurNet::BBSAgent $self = ($] > 5.00562) 
	? fields::new($class) 
	: do { no strict 'refs'; bless [\%{"$class\::FIELDS"}], $class };

    $self->{bbsfile} = shift
	or croak('You need to specify the bbs definition file');

    $self->{timeout} = shift;

    croak("Cannot find bbs definition file: $self->{bbsfile}")
        unless -f ($self->{bbsfile} = _locate($self->{bbsfile}));

    open(local *_FILE, $self->{bbsfile});

    $self->{bbsname} = _readline(\*_FILE);
    $self->{bbsaddr} = _readline(\*_FILE);

    if ($self->{bbsaddr} =~ /^(.*?)(:\d+)?\r?$/) {
        $self->{bbsaddr} = $1;
        $self->{bbsport} = $2 ? substr($2, 1) : 23;
    }
    else {
        croak("Malformed location line: $self->{bbsaddr}");
    }

    close *_FILE;

    local $^W; # work around 'numeric' Net::Telnet 3.12 bug

    $self->loadfile($self->{bbsfile});

    $self->{netobj} = Net::Telnet->new(
    	Timeout => $self->{timeout},
    );

    $self->{netobj}->open(
	Host => $self->{bbsaddr},
	Port => $self->{bbsport},
    );

    $self->{netobj}->output_record_separator('');
    $self->{netobj}->input_log($_[0]) if $_[0];
    $self->{state} = '';

    return $self;
}

sub _locate {
    my $file = shift;
    my $pkg = __PACKAGE__; $pkg =~ s|::|/|g;

    return $file if -f $file;
	
    foreach my $path (map { $_, "$_/$pkg" } ('.', @INC)) {
        return "$path/$file" if -f "$path/$file";
        return "$path/$file.bbs" if -f "$path/$file.bbs";
    }
}

sub _plain {
    my $str = $_[0];

    $str =~ s/([\x00-\x20])/sprintf('\x%02x', ord($1))/eg;

    return $str;
}

=head2 loadfile($self, $bbsfile, [$path])

Reads in a BBS description file, parse its contents, and return
the object itself. The optional C<$path> argument may be used
to specify a root directory where files included by the B<load>
directive should be found.

=cut

sub _readline {
    my $fh = shift; my $line;

    while ($line = readline(*{$fh})) {
        last unless $line =~ /^#|^\s*$/;
    }

    $line =~ s/\r?\n?$// if defined($line);

    return $line;
}

sub loadfile {
    my ($self, $bbsfile, $path) = @_;

    return if $self->{loadstack}{$bbsfile}++; # prevents recursion

    $bbsfile =~ tr|\\|/|;
    $path ||= substr($bbsfile, 0, rindex($bbsfile, '/') + 1);

    open(local *_FILE, $bbsfile) or croak "cannot find file: $bbsfile";

    # skips headers
    _readline(\*_FILE);
    _readline(\*_FILE) if $bbsfile =~ /\.bbs$/i;

    while (my $line = _readline(\*_FILE)) {
        $line =~ s/\s+(?:\#\s+.+)?$//;

        if ($line =~ /^=(\w+)$/) {
            $self->{state}    = $1;
            $self->{proc}{$1} = [];
        }
        elsif (
	    $line =~ /^\s*(
		idle|load|doif|endo|goto|call|wait|send|else|till|setv|exit
	    )\s*(.*)$/x
	) {
            if (!$self->{state}) {
                # directives must belong to procedures...

                if ($1 eq 'setv') { # ...but 'setv' is an exception.
                    my ($var, $val) = split(/\s/, $2, 2);

                    $val =~ s/\x5c\x5c/_!!!_/g;
                    $val =~ s/\\n/\015\012/g;
                    $val =~ s/\\e/\e/g;
		    #$val =~ s/\\c./qq("$&")/eeg; 
		    $val =~ s/\\c(.)/"$1" & "\x1F"/eg;
                    $val =~ s/\\x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
                    $val =~ s/_!!!_/\x5c/g;

                    $val =~ s{\$\[([^\]]+)\]}{
                         (exists $self->{var}{$1})
			    ? $self->{var}{$1} 
			    : croak("variable $1 not defined")
                    }e;

                    $self->{var}{$var} = $val;
                }
                elsif ($1 eq 'load') { # ...and 'load' is another exception.
		    my $file = $2;

		    if ($file !~ /\.bbs$/) {
			$file =~ tr|.|/|;
			$file = "$path$file.inc" unless -e $file;
			$file =~ s|^(\w+)/\1/|$1/|;
		    }

		    croak("cannot read file: $file") unless -e $file;

                    $self->loadfile($file, $path);

                    $self->{state} = '';
                }
                else {
                    croak("Not in a procedure: $line");
                }
            }
            push @{$self->{proc}{$self->{state} || ''}}, $1, $2;
        }
        elsif ($line =~ /^\s*or\s*(.+)$/) {
            croak('Not in a procedure') unless $self->{state};
            croak('"or" directive not after a "wait" or "till"')
                unless $self->{proc}{$self->{state}}->[-2] eq 'wait'
                    or $self->{proc}{$self->{state}}->[-2] eq 'till';

            ${$self->{proc}{$self->{state}}}[-1] .= "\n$1";
        }
        else {
            carp("Error parsing '$line'");
        }
    }

    return $self;
}


=head2 Hook($self, $procedure, [\&callback], [@args])

Adds a procedure to the trigger table, with an optional callback
function and parameters on invoking that procedure.

If specified, the callback function will be invoked after the
hooked procedure's execution, using its return value as arguments.

=cut

sub Hook {
    my ($self, $sub, $callback) = splice(@_, 0, 3);

    if (exists $self->{proc}{$sub}) {
        my ($state, $wait, %var) = '';
        my @proc = @{$self->{proc}{$sub}};

        ($state, $wait) = $self->_chophook(\@proc, \%var, [@_]);

        print "Hook $sub: State=$state, Wait=$wait\n" if $self->{debug};

        $self->{hook}{$state}{$sub} = [$sub, $wait, $callback, @_];
    }
    else {
        croak "Hook: Undefined procedure '$sub'";
    }
}

=head2 Unhook($self, $procedure)

Unhooks the procedure from event table. Raises an error if the
specified procedure did not exist.

=cut

sub Unhook {
    my ($self, $sub) = @_;

    if (exists $self->{proc}{$sub}) {
        my ($state, %var);
        my @proc = @{$self->{proc}{$sub}};

        $state = $self->_chophook(\@proc, \%var, \@_);

        print "Unhook $sub\n" if $self->{debug};
        delete $self->{hook}{$state}{$sub};
    }
    else {
        croak "Unhook: undefined procedure '$sub'";
    }
}

=head2 Loop($self, [$timeout], [$refresh])

Causes a B<Expect> loop to be executed for C<$timeout> seconds, or
indefinitely if not specified. If the C<$refresh> argument is
specified, B<BBSAgent> will send out a Ctrl-L (C<\cL>) upon entering
the loop, and then every C<$refresh> seconds during the Loop.

=cut

sub Loop {
    my ($self, $timeout, $refresh) = @_;
    my $time = time;

    $self->{netobj}->send("\cL") if $refresh;

    do {
        $self->Expect(
	    undef, defined $refresh ? $refresh :
		   defined $timeout ? $timeout : -1
	);
	$self->{netobj}->send("\cL") if $refresh;
    } until (defined $timeout and time - $time < $timeout);
}

=head2 Expect($self, [$string], [$timeout])

Implements the B<wait> and B<till> directives; all hooked procedures
are also checked in parallel.

Note that multiple strings could be specified in one C<$string> by
using \n as the delimiter.

=cut

sub Expect {
    my ($self, $param, $timeout) = @_;

    $timeout ||= $self->{timeout};

    if ($self->{netobj}->timeout ne $timeout) {
        $self->{netobj}->timeout($timeout);
        print "Timeout change to $timeout\n" if $self->{debug};
    }

    my (@keys, $retval, $retkey, $key, $val, %wait);

    while (($key, $val) = each %{$self->{hook}{$self->{state}}}) {
        push @keys, $val->[1] unless exists $wait{$val->[1]};
        $wait{$val->[1]} = $val;
    }

    if (defined $self->{state}) {
        while (($key, $val) = each %{$self->{hook}{''}}) {
            push @keys, $val->[1] unless exists $wait{$val->[1]};
            $wait{$val->[1]} = $val;
        }
    }

    if (defined $param) {
        foreach my $key (split('\n', $param)) {
            push @keys, $key unless exists $wait{$key};
            $wait{$key} = undef;
        }
    }

    # Let's see the counts...
    return unless @keys;

    print "Waiting: [", _plain(join(",", @keys)), "]\n" if $self->{debug};

    undef $self->{errmsg};
    eval {($retval, $retkey) = ($self->{netobj}->waitfor(map {
	m|^m/.*/[imsx]*$| ? ('Match' => $_) : ('String' => $_)
    } @keys)) };

    $self->{errmsg} = $@ if $@;

    if ($retkey) {
        # which one matched?
        $self->{lastmatch} = [];

        foreach my $idx (0 .. $#keys) {
            $self->{lastmatch}[$idx+1] =
                ($keys[$idx] =~ m|^m/.*/[imsx]*$|
                    ? (eval{"\$retkey =~ $keys[$idx]"})
                    : $retkey eq $keys[$idx]) ? $retkey : undef;
        }
    }

    return if $self->{errmsg};

    if ($wait{$retkey}) {
        # Hook call.
        my $sub  = $AUTOLOAD = $wait{$retkey}->[0];
        my $code = $wait{$retkey}->[2];

        if (UNIVERSAL::isa($code, 'CODE')) {
	    $self->Unhook($sub);
            $code->($self->AUTOLOAD(\'1', @{$wait{$retkey}}[3 .. $#{$wait{$retkey}}]));
            $self->Hook($sub, $code);
        }
        else {
            $self->AUTOLOAD(\'1', @{$wait{$retkey}}[3 .. $#{$wait{$retkey}}])
        }
    }
    else {
        # Direct call.
        return (defined $retval ? $retval : '') if defined wantarray;
    }
}

# Chops the first one or two lines from a procedure to determine
# if it could be used as a hook, and performs assorted magic.

sub _chophook {
    my ($self, $procref, $varref, $paramref) = @_;
    my ($state, $wait);
    my $op = shift(@{$procref});

    if ($op eq 'call') {
        $state = shift(@{$procref});
        $state =~ s/\$\[(.+?)\]/$varref->{$1} ||
                               ($varref->{$1} = shift(@{$paramref}))/eg;

        # Chophook won't cut the wait op under scalar context.
        return $state if (defined wantarray xor wantarray);

        $op    = shift(@{$procref});
    }

    if ($op eq 'wait') {
        $wait = shift(@{$procref});
        $wait =~ s/\$\[(.+?)\]/$varref->{$1} ||
                              ($varref->{$1} = shift(@{$paramref}))/eg;

        # Don't bother any more under void context.
        return unless wantarray;

        $wait =~ s/\x5c\x5c/_!!!_/g;
        $wait =~ s/\\n/\015\012/g;
        $wait =~ s/\\e/\e/g;
	$wait =~ s/\\c(.)/"$1" & "\x1F"/eg;
        $wait =~ s/\\x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
        $wait =~ s/_!!!_/\x5c/g;
    }
    else {
        croak "Chophook: Procedure does not start with 'wait'";
    }

    return ($state, $wait);
}


=head2 AUTOLOAD($self, [@args])

The actual implementation of named procedures. All method calls made to a
B<OurNet::BBSAgent> object would resolve to the corresponding procedure
defined it its site description file, which pushes values to the return
stack through the B<till> directive.

An error is raised if the procedure called is not found.

=cut

sub AUTOLOAD {
    my $self   = shift;
    my $flag   = ${shift()} if ref($_[0]);
    my $params = join(',', @_) if @_;
    my $sub    = $AUTOLOAD; $sub =~ s/^.*:://;

    croak "Undefined procedure '$sub' called"
	unless (exists $self->{proc}{$sub});

    local $^W = 0; # no warnings here

    my @proc = @{$self->{proc}{$sub}};
    my @cond = 1; # the condition stack
    my (@result, %var);

    print "Entering $sub ($params)\n" if $self->{debug};

    $self->_chophook(\@proc, \%var, \@_) if $flag;

    while (my $op = shift(@proc)) {
	my $param = shift(@proc);

	# condition tests
	pop(@cond),		next if $op eq 'endo';
	$cond[-1] = !$cond[-1],	next if $op eq 'else';
	next unless ($cond[-1]);

	$param =~ s/\x5c\x5c/_!!!_/g;
	$param =~ s/\\n/\015\012/g;
	$param =~ s/\\e/\e/g;
	$param =~ s/\\c(.)/"$1" & "\x1F"/eg;
	$param =~ s/\\x([0-9a-fA-F][0-9a-fA-F])/chr(hex($1))/eg;
	$param =~ s/_!!!_/\x5c/g;

	$param =~ s{\$\[([\-\d]+)\]}{
	    $self->{lastmatch}[$1]
	}eg unless $op eq 'call';

	$param =~ s{\$\[([^\]]+)\]}{
	    $var{$1} || ($var{$1} = (exists $self->{var}{$1}
		? $self->{var}{$1} : shift))
	}eg unless $op eq 'call';

	print "*** $op ", _plain($param), "\n" if $self->{debug};

	if ($op eq 'doif') {
	    push(@cond, $param);
	}
	elsif ($op eq 'call') {
	    # for kkcity
	    $param =~ s{\$\[([^\]]+)\]}{
		$var{$1} || ($var{$1} = (exists $self->{var}{$1}
		    ? $self->{var}{$1} : shift))
	    }eg;

	    my @params = split(',', $param);
	    ($param, $params[0]) = split(/\s/, $params[0], 2);

	    s{\$\[(.+?)\]}{
		$var{$1} || ($var{$1} = (exists $self->{var}{$1}
		    ? $self->{var}{$1} : shift))
	    }eg foreach @params;

	    $self->$param(@params)
		unless $self->{state} eq "$param ".join(',',@params);

	    print "Return from $param (",join(',',@params),")\n"
		if $self->{debug};
	}
	elsif ($op eq 'goto') {
	    $self->$param() unless $self->{state} eq $param;
	    return wantarray ? @result : $result[0];
	}
	elsif ($op eq 'wait') {
	    defined $self->Expect($param) or return;
	}
	elsif ($op eq 'till') {
	    my $lastidx = $#result;
	    push @result, $self->Expect($param);
	    return if $lastidx == $#result;
	}
	elsif ($op eq 'send') {
	    undef $self->{errmsg};
	    $self->{netobj}->send($param);
	    return if $self->{errmsg};
	}
	elsif ($op eq 'exit') {
	    $result[0] = '' unless defined $result[0];
	    return wantarray ? @result : $result[0];
	}
	elsif ($op eq 'setv') {
	    my ($var, $val) = split(/\s/, $param, 2);
	    $self->{var}{$var} = $val;
	}
	elsif ($op eq 'idle') {
	    sleep $param;
	}
	else {
	    die "No such operator: $op";
	}
    }

    $self->{state} = "$sub $params";

    print "Set State: $self->{state}\n" if $self->{debug};
    return wantarray ? @result : $result[0];
}

sub DESTROY {}

1;

__END__

=head1 SEE ALSO

L<Net::Telnet>, L<OurNet::BBS>

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

=head1 COPYRIGHT

Copyright 2001, 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
