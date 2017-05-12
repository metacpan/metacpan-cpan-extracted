#
# $Id: TCPwrappers.pm 161 2004-12-31 04:00:52Z james $
#

=head1 NAME

Net::TCPwrappers - Perl interface to tcp_wrappers.

=head1 SYNOPSIS

  use Net::TCPwrappers qw(RQ_DAEMON RQ_FILE request_init fromhost hosts_access);
  ...
  my $progname = 'yadd';
  while (accept(CLIENT, SERVER)) {
    my $req = request_init(RQ_DAEMON, $progname, RQ_FILE, fileno(CLIENT));
    fromhost($req);
    if (!hosts_access($req)) {
      # unauthorized access.
      ...
    }
    else {
      # service connecting client.
      ...
    }
  }

=cut

package Net::TCPwrappers;
use base 'Exporter';

require 5.006_001;

use strict;
use warnings;

use Carp;
use ExtUtils::Constant;
use XSLoader;

our $VERSION = '1.11';

our @EXPORT      = ();
our %EXPORT_TAGS = (
    constants => [ qw|
        RQ_CLIENT_ADDR
        RQ_CLIENT_NAME
        RQ_CLIENT_SIN
        RQ_DAEMON
        RQ_FILE
        RQ_SERVER_ADDR
        RQ_SERVER_NAME
        RQ_SERVER_SIN
        RQ_USER
    | ],
    functions => [ qw|
        request_init
        request_set
        fromhost
        hosts_access
        hosts_ctl
    | ],
);
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
    grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
                                                     
Exporter::export_ok_tags( 'all' );

# pull in the XS bits
XSLoader::load 'Net::TCPwrappers', $VERSION;

# let ExtUtils::Constant generate our AUTOLOAD function
my $autoload_func = ExtUtils::Constant::autoload('Net::TCPWrappers');
eval $autoload_func;
if( $@ ) {
    Carp::croak "can't set up Net::TCPWrappers::AUTOLOAD: $@";
}

# keep require happy
1;


__END__


=head1 ABSTRACT

Net::TCPwrappers offers perl programmers a convenient interface to the
libwrap.a library from tcp_wrappers, Wietse Venema's popular TCP/IP daemon
wrapper package.  Use it in your perl code to monitor and filter access to
TCP-based network services on unix hosts.

=head1 DESCRIPTION

Net::TCPwrappers mimics the libwrap.a library fairly closely - the names of
the functions and constants are identical, and calling arguments have been
altered only slightly to be more perl-like.

=head2 FUNCTIONS

This module defines all the public functions available in the libwrap.a
library: C<request_init>, C<request_set>, C<hosts_access>, and C<hosts_ctl>. 
None are exported by default; you must either add the package name when
calling them (eg, C<Net::TCPwrappers::request_init(...)>) or import them
explicitly (eg, C<use Net::TCPwrappers qw(request_init ...);>).

=over 4

=item request_init($key1, $value1, $key2, $value2, ...)

Creates a new request structure and initializes it using the supplied key /
value pairs.  The keys are used to specify the interpretation of the value
argument (eg, daemon name, file descriptor, host name, etc) and should be
one of the constants described below.  As many key / value pairs (for the
same request, of course) can be specified as desired.

Returns an integer representing a pointer to the newly created request
structure.  In the unlikely event of failure, the function returns undef. 
This may arise because memory can not be allocated for the request structure
or because the key / value pairs are not of the correct types.  [If the
later, make sure you're using the proper constants as described below.]

Note: the pointer to the request structure is blessed into the class
Request_infoPtr and will be automatically destroyed when the program exits.

=item request_set($request, $key1, $value1, $key2, $value2, ...)

Copies an existing request structure (represented by the pointer
C<$request>) into a new one and updates it using the supplied key / value
pairs, which are described above.

Returns an integer representing a pointer to the updated request structure. 
In the unlikely event of failure, the function returns undef.  This may
arise because memory can not be allocated for the request structure or
because the key / value pairs are not of the correct types.  [If the later,
make sure you're using the proper constants as described below.]

Note: the pointer to the request structure is blessed into the class
Request_infoPtr and will be automatically destroyed when the program exits.

=item fromhost($request))

Updates an existing request structure (pointed to by C<$request>) with the
port and address information obtained from the client and server endpoints.

Note: this should be used after C<request_init> or C<request_set> if either
is called with C<RQ_FILE>.

=item hosts_access($request)

Determines whether to allow access based on information in the request
structure pointed to by C<$request> along with the host access tables (see
L<hosts_access>).

Returns 0 if access should be denied. 

=item hosts_ctl($daemon, $client_name, $client_addr [, $client_user])

Determines whether to allow access based on the supplied daemon name, host
name, host IP address, and optionally username of the client host making the
request.

Returns 0 if access should be denied. 

Note: this is implemented in libwrap.a as a wrapper around the
C<request_init> and C<hosts_access> functions.

=back

=head2 CONSTANTS

The keys used in the functions C<request_init> and C<request_set> and
their meanings are:

=over 4

=item RQ_CLIENT_ADDR

A string representing the client's IP address. 

=item RQ_CLIENT_NAME

A string representing the client's hostname. 

=item RQ_CLIENT_SIN

A pointer to the client's C<sockaddr_in> structure, representing its host
address and port.

=item RQ_DAEMON

A string representing the daemon's name as it appears in the access
control tables. 

Note: a key / value pair with C<RQ_DAEMON> must be supplied via either
C<request_init> or C<request_set> if calling C<hosts_access>.

=item RQ_FILE

An integer representing the file descriptor associated with the request. 

Note: C<fromhost> should be called after C<request_init> or C<request_set>
if using this key.

=item RQ_SERVER_ADDR

A string representing the server's IP address. 

=item RQ_SERVER_NAME

A string representing the server's hostname. 

=item RQ_SERVER_SIN

A pointer to the server's C<sockaddr_in> structure, representing its host
address and port.

=item RQ_USER

A string representing the name of the user making the request from the
client host.

=back

None of these are exported by default.

=head1 RATIONALE

At first blush, this module might seem like overkill.  "Why not just write
the necessary code myself and include that in my programs?" you're probably
thinking.  Sure, any competent programmer can easily do that.  Moreover,
perl, with its regular expressions, affords extremely flexible matching of
host names / addresses.

Yet by rolling your own you would likely miss out on the following:

=over 4

=item *

A common facility for controlling host access.  As distributed, tcp_wrappers
works not only with daemons started via inetd but also with a wide variety
of C programs that support it (eg, sendmail, OpenSSH, Nessus, etc). With
Net::TCPwrappers, this support is now available to perl programs.

=item *

Access controls are stored apart from programs and are re-read each time a
check is done. This makes it trivial to adjust access controls, whether by
hand as your needs evolve or automatically, as in the case of an intrusion
detection system.

=back

=head1 INSTALLATION

Installation of Net::TCPWrappers requires a working installation of Wietse
Venema's TCP/IP daemon wrapper package, tcp_wrappers, including the
libwrap.a library.  The latest version currently is 7.6, released in March
1997; earlier versions may also work as it appears the library interface has
been rather stable.

If you need a copy, visit <ftp://ftp.porcupine.org/pub/security/> for the
source code or check with your favourite software respository for
pre-compiled binaries (eg, RPMs for Linux, Packages for Sun, etc).

=head2 BUILDING

To build and test the module, type the following:

  perl Build.PL
  ./Build
  ./Build test

Check the L<troubleshooting section|"TROUBLESHOOTING"> if you encounter any
problems or any of the tests fail.

To install it, type:

  ./Build install

Note: you probably need to do this as root to have it installed
system-wide. 

At this point, you may wish to look at the sample programs in the
examples directory to give you some ideas about how to use this
module.

=head2 TROUBLESHOOTING

Build.PL will look for libwrap.{so,a} and tcpd.h in the following
prefixes:

  /usr
  /usr/local
  /opt
  /opt/local
  /opt/libwrap
  /opt/tcpwrappers

If your copy of TCP wrappers is not in one of these directories, pass the
prefix (not including the 'include' and 'lib' directories) to Build.PL:

  perl Build.PL /opt/tcpd-7.6

Build.PL normally prompts for confirmation when it has found a suitable
library and include file.  To suppress this behaviour and use the first
match found, pass C<--noprompt> to Build.PL on the command line:

  perl Build.PL --noprompt

If one or more of the tests fail, run them in verbose mode (eg, C<./Build
test verbose=1>). This may give you an idea of which specific tests fail and
why.

Another option involves modifying the file TCPwrappers.xs.  Edit the file and change the line
near the top that reads:

  #if 0

to:

  #if 1

and recompile.  This will turn on tracing of the XSUBs, which provide the
glue between libwrap.a and Perl.  Because this is a compiled-in change, it
should be used only in extreme situations to send debug information to the
author.  To disable tracing, re-edit the file and recompile / reinstall.

=head1 TODO

The current maintainer of this module wrote another Perl wrapper for libwrap
called Authen::Libwrap.  It didn't cover the API as comprehensively, and
very little feedback was ever received on it.  The original author of
Net::TCPWrappers offered his source code for possible integration, but it
turned out to be easier to integrate what little unique functional was in
Authen::Libwrap into Net::TCPWrappers.

The tests for Authen::Libwrap are part of the test suite for
Net::TCPWrappers, but many of them are expected to fail at present.  The
goal is to get those tests to pass, at which point Authen::Libwrap can be
deprecated in favour of this module.

Other specific tasks:

=over 4

=item * develop an OO interface

=back

=head1 BUGS

None currently reported.  If you find one, first read the L<troubleshooting
section|"TROUBLESHOOTING"> and then check for a newer version of
Net::TCPwrappers on CPAN.  If problems still persist, submit a bug report
via the bug tracker at http://rt.cpan.org/.

If you like this module, please rate it on it's CPAN page:

http://cpanratings.perl.org/rate/?distribution=Net-TCPwrappers

In your bug report, please include as much information as possible, including:

=over 4

=item *

Your platform and OS version (eg, "uname -a"). If using Linux, also include
your glibc version (eg, "ls -al /lib/libc*").

=item *

The ANSI C/C++ compiler name and version (eg, "gcc -v").

=item *

Perl's configuration, obtained by running "perl -V".

=item *

The version of tcp_wrappers installed on your system and how it got there
(ie, from an RPM, compiled yourself, etc).

=item *

Results from running C<./Build test verbose=1> after building this module.

=back

=head1 DIAGNOSTICS

The routines in libwrap.a report problems via the syslog daemon.

=head1 SEE ALSO

L<hosts_access>, libwrap.a documentation.

=head1 AUTHOR

George A. Theall, E<lt>theall@tifaware.comE<gt>

Currently maintained by James FitzGibbon, E<lt>jfitz@CPAN.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002, George A. Theall. All Rights Reserved.

Copyright (c) 2004, James FitzGibbon.  All Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

#
# EOF
