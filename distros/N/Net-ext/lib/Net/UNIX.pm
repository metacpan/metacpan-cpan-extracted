# Copyright 1995,2002 Spider Boardman.
# All rights reserved.
#
# Automatic licensing for this software is available.  This software
# can be copied and used under the terms of the GNU Public License,
# version 1 or (at your option) any later version, or under the
# terms of the Artistic license.  Both of these can be found with
# the Perl distribution, which this software is intended to augment.
#
# THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
# WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

# rcsid: "@(#) $Id: UNIX.dat,v 1.22 2002/03/30 10:11:08 spider Exp $"

package Net::UNIX;
use 5.004_04;			# new minimum Perl version for this package

use strict;
#use Carp;
sub carp { require Carp; goto &Carp::carp; }
sub croak { require Carp; goto &Carp::croak; }
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS *AUTOLOAD);

BEGIN {
    $VERSION = '1.0';
    eval "sub Version { __PACKAGE__ . ' v$VERSION' }";
}

use AutoLoader;
#use Exporter ();
use Net::Gen 1.0 qw(/pack_sockaddr$/ :sockvals :families);

BEGIN {
    @ISA = 'Net::Gen';

# Items to export into callers namespace by default.
# (Move infrequently used names to @EXPORT_OK below.)

    @EXPORT = qw(
    );

    @EXPORT_OK = qw(
	pack_sockaddr_un
	unpack_sockaddr_un
    );

    %EXPORT_TAGS = (
	routines	=> [qw(pack_sockaddr_un unpack_sockaddr_un)],
	ALL		=> [@EXPORT, @EXPORT_OK],
    );
    *AUTOLOAD = \$Net::Gen::AUTOLOAD;
}

;# sub AUTOLOAD inherited from Net::Gen

;# since 5.003_96 will break simple subroutines with inherited autoload, cheat
sub AUTOLOAD
{
    #$Net::Gen::AUTOLOAD = $AUTOLOAD;
    goto &Net::Gen::AUTOLOAD;
}


# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

;# No additional sockopts for UNIX-domain sockets (?)

my $sun_path_len =
    length(Socket::unpack_sockaddr_un(Socket::pack_sockaddr_un('')));

#& _canonpath($path) : returns NUL-padded $path for sun_addr
sub _canonpath ($)
{
    my $path = shift;
    my $ix;
    # extend to proper length
    $ix = index($path, "\0");
    if ($ix >= 0) {
	substr($path,$ix) = "\0" x ($sun_path_len - $ix)
	    if $ix < $sun_path_len;
    }
    else {
	$ix = length($path);
	if ($ix < $sun_path_len) {
	    $path .= "\0" x ($sun_path_len - $ix);
	}
	else {
	    $path .= "\0";
	}
    }
    $path;
}

#& pack_sockaddr_un([$family,] $path) : $packed_addr
sub pack_sockaddr_un ($;$)
{
    my(@args) = @_;
    unshift(@args, AF_UNIX) if @args == 1;
    pack_sockaddr($args[0], _canonpath($args[1]));
}

#& unpack_sockaddr_un($sockaddr_un) : [$fam,] $path
sub unpack_sockaddr_un ($)
{
    my $addr = shift;
    my ($fam,$path) = unpack_sockaddr($addr);
    my $nul = index($path, "\0");
    if ($nul >= 0) {
	substr($path, $nul) = '';
    }
    $fam ||= AF_UNIX;
    wantarray ? ($fam, $path) : $path;
}

my $debug = 0;

#& _debug($this, [$newval]) : oldval
sub _debug : locked
{
    my ($this,$newval) = @_;
    return $this->debug($newval) if ref $this;
    my $prev = $debug;
    $debug = 0+$newval if defined $newval;
    $prev;
}


my %keyhandlers = (thispath => \&_setbindpath,
		   destpath => \&_setconnpath,
		   unbuffered_IO => \&_setbuf_unbuf,
		   unbuffered_io => \&_setbuf_unbuf,
);

my @Keys = qw(unbuffered_input unbuffered_output);

my %Keys;			# for storing the registrations


#& new($class, [\%params]) : {$obj | undef}
sub new : locked
{
    my $whoami = $_[0]->_trace(\@_,1);
    my($class,@Args,$self) = @_;
    $self = $class->SUPER::new(@Args);
    $class = ref $class if ref $class;
    ($self || $class)->_trace(\@_,2,", self" .
			      (defined $self ? "=$self" : " undefined") .
			      " after sub-new");
    if ($self) {
	# register our keys and their handlers
	if (%Keys) {
	    $ {*$self}{Keys} = { %Keys };
	}
	else {
	    $self->register_param_keys(\@Keys) if @Keys;
	    $self->register_param_handlers(\%keyhandlers);
	    %Keys = %{ $ {*$self}{Keys} };
	}
	# register our socket options
	# none for AF_UNIX?
	# set our expected parameters
	$self->setparams({PF => PF_UNIX, AF => AF_UNIX,
			  unbuffered_output => 0,
			  unbuffered_input => 0,
			  type => SOCK_DGRAM},
			 -1);
	if ($class eq __PACKAGE__) {
	    unless ($self->init(@Args)) {
		local $!;	# protect errno
		undef $self;	# from the side-effects of this
		undef $self;	# another statement needed for unwinding
	    }
	}
    }
    if ($debug) {
	if ($self) {
	    print STDERR __PACKAGE__ . "::new returning self=$self\n";
	}
	else {
	    print STDERR __PACKAGE__ . "::new returning undef\n";
	}
    }
    $self;
}

#& _setbindpath($self, 'thispath', $path) : {'' | "carp string"}
sub _setbindpath
{
    my($self,$what,$path) = @_;
    my $ix;
    if (!defined($path)) {
	# removing, so cooperate
	delete $ {*$self}{Parms}{srcaddrlist};
	return '';
    }
    # canonicalize the path to be of the right length, if possible
    $path = _canonpath($path);
    $ix = index($path, "\0");	# check for NUL-termination
    if (!$ix) {			# empty path is not a bind
	delete $ {*$self}{Parms}{srcaddrlist};
	$_[2] = undef;
    }
    else {
	$ {*$self}{Parms}{srcaddrlist} =
	    [pack_sockaddr_un($self->getparam('AF',AF_UNIX,1), $path)];
    }
    '';
}

#& _setconnpath($self, 'destpath', $path) : {'' | "carp string"}
sub _setconnpath
{
    my($self,$what,$path) = @_;
    my $ix;
    if (!defined($path)) {
	# removing, so cooperate
	delete $ {*$self}{Parms}{dstaddrlist};
	return '';
    }
    # canonicalize the path to be of the right length, if possible
    $path = _canonpath($path);
    $ix = index($path, "\0");	# check for NUL-termination
    if (!$ix) {			# empty path?
	"$what parameter has no path: $path";
    }
    else {			# just try it here
	$ {*$self}{Parms}{dstaddrlist} =
	    [pack_sockaddr_un($self->getparam('AF',AF_UNIX,1), $path)];
	'';
    }
}

#& _init($self, whatpath[, $path][, \%params]) : {$self | undef}
sub _init : locked method
{
    my ($self,$what,@args,$path,$parms) = @_;
    if (@args == 1 or @args == 2) {
	$parms = $args[-1];
	$parms = undef
	    unless $parms and ref($parms) eq 'HASH';
	$path = $args[0];
	$path = undef
	    if defined($path) and ref($path);
    }
    croak("Invalid call to " . __PACKAGE__ . "::init(@_)")
	if @args == 2 and !$parms or @args > 2 or !$what;
    $parms ||= {};
    $$parms{$what} = $path if defined $path;
    return undef unless $self->SUPER::init($parms);
    if (scalar %$parms) {
	return undef unless $self->setparams($parms);
    }
    $self->setparams({netgen_fakeconnect=>1},-1) if
	$self->getparam('type') == SOCK_DGRAM;
    if ($self->getparams([qw(srcaddr srcaddrlist dstaddr dstaddrlist)],1) >0) {
	return undef unless $self->isopen or $self->open;
	if ($self->getparams([qw(srcaddr srcaddrlist)],1) > 0) {
	    return undef unless $self->isbound or $self->bind;
	}
	if ($self->getparams([qw(dstaddr dstaddrlist)],1) > 0) {
	    return undef unless $self->isconnected or $self->connect or
		$self->isconnecting and !$self->blocking;
	}
    }
    $self;
}

#& init($self [, $destpath][, \%params]) : {$self | undef}
sub init
{
    my ($self,@args) = @_;
    $self->_init('destpath',@args);
}

#& connect($self [, $destpath] [, \%newparams]) : boolean
sub connect : locked method
{
    my($self,$path,$parms) = @_;
    if (@_ > 3 or @_ == 3 and (!ref($parms) or ref($path))) {
	croak("Invalid arguments to " . __PACKAGE__ . "::connect(@_), called");
    }
    if (@_ == 2 and ref $path) {
	$parms = $path;
	undef $path;
    }
    else {
	$parms ||= {};
    }
    if (defined $path) {
	$$parms{destpath} = $path;
    }
    if (@_ > 1) {
	return unless $self->setparams($parms);
    }
    $self->SUPER::connect;
}

#& format_addr({$class|$obj} , $sockaddr) : $string
sub format_addr
{
    my ($this,$addr) = @_;
    my ($fam,$sdata) = unpack_sockaddr($addr);
    if ($fam == AF_UNIX) {
	$sdata = unpack_sockaddr_un($addr);
    }
    else {
	$sdata = $this->SUPER::format_addr($addr);
    }
    $sdata;
}

1;


# autoloaded methods go after the END token (& pod) below

__END__

=head1 NAME

Net::UNIX - UNIX-domain sockets interface module

=head1 SYNOPSIS

    use Net::Gen;		# optional
    use Net::UNIX;

=head1 DESCRIPTION

The C<Net::UNIX> module provides services for UNIX-domain socket
communication.  It is layered atop the
L<C<Net::Gen>|Net::Gen>
module, which
is part of the same distribution.

=head2 Public Methods

The following methods are provided by the C<Net::UNIX> module
itself, rather than just being inherited from
L<C<Net::Gen>|Net::Gen>.

=over 4

=item new

Usage:

    $obj = new Net::UNIX;
    $obj = new Net::UNIX $pathname;
    $obj = new Net::UNIX \%parameters;
    $obj = new Net::UNIX $pathname, \%parameters;
    $obj = 'Net::UNIX'->new();
    $obj = 'Net::UNIX'->new($pathname);
    $obj = 'Net::UNIX'->new(\%parameters);
    $obj = 'Net::UNIX'->new($pathname, \%parameters);

Returns a newly-initialised object of the given class.  If called
for a derived class, no validation of the supplied parameters
will be performed.  (This is so that the derived class can add
the parameter validation it needs to the object before allowing
the validation.)  Otherwise, it will cause the parameters to be
validated by calling its C<init> method.  In particular, this
means that if a pathname is given, an object will be returned
only if a connect() call was successful.

The examples above show the indirect object syntax which many prefer,
as well as the guaranteed-to-be-safe static method call.  There
are occasional problems with the indirect object syntax, which
tend to be rather obscure when encountered.  See
http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/1998-01/msg01674.html
for details.

=item init

Usage:

    return undef unless $self = $self->init;
    return undef unless $self = $self->init(\%parameters);
    return undef unless $self = $self->init($pathname);
    return undef unless $self = $self->init($pathname, \%parameters);

Verifies that all previous parameter assignments are valid (via
C<checkparams>).  Returns the incoming object on success, and
C<undef> on failure.  Usually called only via a derived class's
C<init> method or its own C<new> call.

=item bind

Usage:

    $ok = $obj->bind;
    $ok = $obj->bind($pathname);
    $ok = $obj->bind($pathname,\%newparameters);

Updates the object with the supplied new parameters (if
supplied), then sets up the C<srcaddrlist> object parameter with
the specified $pathname argument (if supplied), and then returns
the value from the inherited C<bind> method.

Example:

    $ok = $obj->bind('/tmp/.fnord'); # start a service on /tmp/.fnord

=item connect

Usage:

    $ok = $obj->connect;
    $ok = $obj->connect($pathname);
    $ok = $obj->connect($pathname,\%newparameters);

Attempts to establish a connection for the object.  If the
C<newparams> argument is specified, it will be used to update the
object parameters.  Then, if the $pathname argument is specified,
it will be used to set the C<dstaddrlist> object parameter.
Finally, the result of a call to the inherited C<connect> method
will be returned.

=item format_addr

Usage:

    $string = $obj->format_addr($sockaddr);
    $string = format_addr Module $sockaddr;

Returns a formatted representation of the socket address.  This
is normally just a pathname, or the constant string C<''>.

=item PRINT

Usage:

    $ok = $obj->PRINT(@args);
    $ok = print $tied_fh @args;

This method, intended to be used with tied filehandles, behaves like one
of two inherited methods from the
L<C<Net::Gen>|Net::Gen>
class, depending on the
setting of the object parameter C<unbuffered_output> and whether the
socket is a SOCK_STREAM (stream) socket or a datagram socket (the
default).  If that parameter is false (the default) or the socket
is a stream socket, then the normal print() builtin is used.
If the C<unbuffered_output> parameter is true for a datagram socket,
then each print()
operation will actually result in a call to the C<send> method.  The
value of the $\ variable is ignored in that case, but
the $, variable is still used if the C<@args> array has multiple
elements.

=item READLINE

Usage:

    $line_or_datagram = $obj->READLINE;
    $line_or_datagram = <TIED_FH>;
    $line_or_datagram = readline(TIED_FH);
    @lines_or_datagrams = $obj->READLINE;
    @lines_or_datagrams = <TIED_FH>;
    @lines_or_datagrams = readline(TIED_FH);

This method, intended to be used with tied filehandles, behaves
like one of two inherited methods from the L<C<Net::Gen>|Net::Gen> class,
depending on the setting of the object parameter
C<unbuffered_input> and whether the socket is a SOCK_STREAM (stream) socket
or a datagram socket (the default).  If that parameter is false (the default)
or the socket is a stream socket,
then this method does line-buffering of its input as defined by
the current setting of the $/ variable.  If the
C<unbuffered_input> parameter is true for a datagram socket,
then the input records will
be exact recv() datagrams, disregarding the setting of the $/
variable.

=back

=head2 Protected Methods

[See the description in L<Net::Gen/"Protected Methods"> for my
definition of protected methods in Perl.]

None.

=head2 Known Socket Options

There are no socket options known to the C<Net::UNIX> module itself.

=head2 Known Object Parameters

The following object parameters are registered by the C<Net::UNIX> module
(as distinct from being inherited from
L<C<Net::Gen>|Net::Gen>):

=over 4

=item unbuffered_input

If true, the C<READLINE> operation on tied filehandles which
are datagram sockets will return each recv()
buffer as though it were a single separate line, independently of the setting
of the $/ variable.  The default is false, which causes the C<READLINE>
interface to return lines split at boundaries as appropriate for $/.
(The C<READLINE> method for tied filehandles is the C<E<lt>FHE<gt>>
operation.)

=item unbuffered_output

If true, the C<PRINT> operation on tied filehandles which
are datagram sockets will result in calls to
the send() builtin rather than the print() builtin, as described in L</PRINT>
above.  The default is false, which causes the C<PRINT> method to use the
print() builtin.

=item unbuffered_IO

This object parameter's value is unreliable on C<getparam> or C<getparams>
method calls.  It is provided as a handy way to set both the
C<unbuffered_output> and C<unbuffered_input> object parameters to the same
value at the same time during C<new> calls.

=back

=head2 TIESCALAR

Tieing of scalars to a UNIX-domain handle is supported by
inheritance from the C<TIESCALAR> method of
L<C<Net::Gen>|Net::Gen/TIESCALAR>.  That
method only succeeds if a call to a C<new> method results in an
object for which the C<isconnected> method returns a true result.
Thus, for C<Net::UNIX>, C<TIESCALAR> will not succeed unless the
C<pathname> argument is given.

Each assignment to the tied scalar is really a call to the C<put>
method (via the C<STORE> method), and each read from the tied
scalar is really a call to the C<READLINE> method (via the
C<FETCH> method).

=head2 TIEHANDLE support

As inherited from
L<C<Net::Gen>|Net::Gen/TIEHANDLE>, with the addition of
unbuffered datagram I/O options for the C<FETCH>, C<READLINE>,
and C<PRINT> methods.

=head2 Non-Method Subroutines

=over 4

=item pack_sockaddr_un

Usage:

    $connect_address = pack_sockaddr_un($family, $pathname);
    $connect_address = pack_sockaddr_un($pathname);

Returns the packed C<struct sockaddr_un> corresponding to the
provided $family and $pathname arguments.  The $family argument
as assumed to be C<AF_UNIX> if it is missing.  This is otherwise
the same as the pack_sockaddr_un() routine in the C<Socket>
module.

=item unpack_sockaddr_un

Usage:

    ($family, $pathname) = unpack_sockaddr_un($connected_address);
    $pathname = unpack_sockaddr_un($connected_address);

Returns the address family and pathname (if known) from the
supplied packed C<struct sockaddr_un>.  This is the inverse of
pack_sockaddr_un().  It differs from the implementation in the
C<Socket> module in its return of the C<$family> value, and in
that it trims the returned pathname at the first null character.

=back

=head2 Exports

=over 4

=item default

None.

=item exportable

C<pack_sockaddr_un> C<unpack_sockaddr_un>

=item tags

The following I<:tags> are available for grouping exportable items:

=over 6

=item :routines

C<pack_sockaddr_un> C<unpack_sockaddr_un>

=item :ALL

All of the above exportable items.

=back

Z<>

=back

=head1 THREADING STATUS

This module has been tested with threaded perls, and should be as thread-safe
as perl itself.  (As of 5.005_03 and 5.005_57, that's not all that safe
just yet.)  It also works with interpreter-based threads ('ithreads') in
more recent perl releases.

=head1 SEE ALSO

L<Net::Gen(3)|Net::Gen>,
L<Net::UNIX::Server(3)|Net::UNIX::Server>

=head1 AUTHOR

Spider Boardman E<lt>spidb@cpan.orgE<gt>

=cut

#other sections should be added, sigh.

#any real autoloaded methods go after this line


#& setdebug($this, [bool, [norecurse]]) : oldvalues
sub setdebug : locked
{
    my $this = shift;
    $this->_debug($_[0]) .
	((@_ > 1 && $_[1]) ? '' : $this->SUPER::setdebug(@_));
}

#& bind($self [, $destpath] [, \%newparams]) : boolean
sub bind : locked method
{
    my($self,$path,$parms) = @_;
    if (@_ > 3 or @_ == 3 and (!ref($parms) or ref($path))) {
	my $whoami = $self->_trace;
	croak("Invalid arguments to ${whoami}(@_), called");
    }
    if (@_ == 2 and ref $path) {
	$parms = $path;
	undef $path;
    }
    else {
	$parms ||= {};
    }
    if (defined $path) {
	$$parms{thispath} = $path;
    }
    if (@_ > 1) {
	return undef unless $self->setparams($parms);
    }
    $self->SUPER::bind;
}

#& _setbuf_unbuf($self, $param, $newvalue) : {'' | "carp string"}
sub _setbuf_unbuf
{
    my ($self,$what,$newval) = @_;
    $self->setparams({unbuffered_input => $newval,
		      unbuffered_output => $newval});
    '';
}

#& PRINT($self, @args) : boolean OKness
sub PRINT : locked method
{
    my $self = shift;
    if ($self->getparam('type',SOCK_DGRAM,1) != SOCK_STREAM and
	$self->getparam('unbuffered_output'))
    {
	$self->send(join $, , @_);
    }
    else {
	print {$self} @_;
    }
}

#& READLINE($self) : $line | undef || @lines
sub READLINE : locked method
{
    my $whoami = $_[0]->_trace(\@_,5);
    carp "Excess arguments to ${whoami}, ignored" if @_ > 1;
    my $self = shift;
    if ($self->getparam('type',SOCK_DGRAM,1) != SOCK_STREAM and
	$self->getparam('unbuffered_input'))
    {
	if (wantarray) {
	    my ($line,@lines);
	    push @lines, $line while defined($line = $self->recv);
	    @lines;
	}
	else {
	    $self->recv;
	}
    }
    else {
	$self->SUPER::READLINE;
    }
}
