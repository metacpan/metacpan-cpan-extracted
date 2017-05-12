# -*- perl -*-

# Net::FTPServer A Perl FTP Server
# Copyright (C) 2000 Bibliotech Ltd., Unit 2-3, 50 Carnwath Road,
# London, SW6 3EG, United Kingdom.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# $Id: FTPServer.pm,v 1.11 2005/07/15 10:10:22 rwmj Exp $

=pod

=head1 NAME

Net::FTPServer - A secure, extensible and configurable Perl FTP server

=head1 SYNOPSIS

  ftpd [--help] [-d] [-v] [-p port] [-s] [-S] [-V] [-C conf_file]
       [-P pidfile] [-o option=value]

=head1 DESCRIPTION

C<Net::FTPServer> is a secure, extensible and configurable FTP
server written in Perl.

Current features include:

 * Authenticated FTP access.
 * Anonymous FTP access.
 * Complete implementation of current RFCs.
 * ASCII or binary type file transfers.
 * Active or passive mode file transfers.
 * Run standalone or from inetd(8).
 * Security features: chroot, resource limits, tainting,
   protection against buffer overflows.
 * IP-based and/or IP-less virtual hosts.
 * Complete access control system.
 * Anonymous read-only FTP personality.
 * Virtual filesystem allows files to be served
   from a database.
 * Directory aliases and CDPATH support.
 * Extensible command set.
 * Generate archives on the fly.

=head1 INSTALLING AND RUNNING THE SERVER

A standard C<ftpd.conf> file is supplied with the distribution.
Full documentation for all the possible options which you
may use in this file is contained in this manual page. See
the section CONFIGURATION below.

After doing C<make install>, the standard C<ftpd.conf> file should
have been installed in C</etc/ftpd.conf>. You will probably need to
edit this file to suit your local configuration.

Also after doing C<make install>, several start-up scripts will have
been installed in C</usr/sbin/*ftpd.pl>. (On Debian in C</usr/bin> or
C</usr/local/bin>). Each start-up script starts the server in a
different configuration: either as a full FTP server, or as an
anonymous-only read-only FTP server, etc.

The commonly used scripts are:

 * /usr/sbin/ftpd.pl
 * /usr/sbin/ro-ftpd.pl

The first script is for the full FTP server.

These scripts assume that the C<perl> interpreter can be found on the
current C<$PATH>. In the rare situation when this is not the case, you
may need to edit these scripts.

=head2 STANDALONE SERVER

If you have a high load site, you will want to run C<Net::FTPServer>
as a standalone server. To start C<Net::FTPServer> as a standalone
server, do:

  /usr/sbin/ftpd.pl -S

You may want to add this to your local start-up files so that
the server starts automatically when you boot the machine.

To stop the server, do:

  killall ftpd.pl

(Note: C<Azazel> points out that the above is a Linux-ism. Solaris
administrators may get a nasty shock if they type C<killall> as C<root>!
Just kill the parent C<ftpd.pl> process by hand instead).

=head2 RUNNING FROM INETD

Add the following line to C</etc/inetd.conf>:

  ftp stream tcp nowait root /usr/sbin/tcpd ftpd.pl

(This assumes that you have the C<tcp-wrappers> package installed to
provide basic access control through C</etc/hosts.allow> and
C</etc/hosts.deny>. This access control is in addition to any access
control which you may configure through C</etc/ftpd.conf>.)

After editing this file you will need to inform C<inetd>:

  killall -HUP inetd

=head2 RUNNING FROM XINETD

C<xinetd> is a modern alternative to C<inetd> which is supposedly
simpler to configure. In practice, however, it has proven to be quite
difficult to configure services under C<xinetd> (mainly because
C<xinetd> gives no diagnostic information when things go wrong). The
following configuration has worked for me:

Create the file C</etc/xinetd.d/net-ftpserver> containing:

 # default: on
 # description: Net::FTPServer, a secure, \
 #              extensible, configurable FTP server.
 #
 service ftp
 {
        socket_type             = stream
        wait                    = no
        user                    = root
        server                  = /usr/sbin/ftpd.pl
        log_on_success          += DURATION USERID
        log_on_failure          += USERID
        disable                 = no
 }

Check any other possible FTP server configurations to ensure they
are all disabled (ie. C<disable = yes> in all other files).

Restart C<xinetd> using:

 /etc/init.d/xinetd restart

=head1 COMMAND LINE FLAGS

  --help           Display help and exit
  -d, -v           Enable debugging
  -p PORT          Listen on port PORT instead of the default port
  -s               Run in daemon mode (default: run from inetd)
  -S               Run in background and in daemon mode
  -V               Show version information and exit
  -C CONF          Use CONF as configuration file (default:
                   /etc/ftpd.conf)
  -P PIDFILE       Save pid into PIDFILE (daemon mode only)
  -o option=value  Override config file option with value
  --test           Test mode (used only in automatic testing scripts)

=head1 CONFIGURING AND EXTENDING THE SERVER

C<Net::FTPServer> can be configured and extended in a number
of different ways.

Firstly, almost all common server configuration can be carried
out by editing the configuration file C</etc/ftpd.conf>.

Secondly, commands can be loaded into the server at run-time
to provide custom extensions to the common FTP command set.
These custom commands are written in Perl.

Thirdly, one of several different supplied I<personalities> can be
chosen. Personalities can be used to make deep changes to the FTP
server: for example, there is a supplied personality which allows the
FTP server to serve files from a relational database. By subclassing
C<Net::FTPServer>, C<Net::FTPServer::DirHandle> and
C<Net::FTPServer::FileHandle> you may also write your own
personalities.

The next sections talk about each of these possibilities in turn.

=head2 CONFIGURATION

A standard C</etc/ftpd.conf> file is supplied with C<Net::FTPServer>
in the distribution. The possible configuration options are listed in
full below.

Simple configuration options can also be given on the command line
using the C<-o> option. Command line configuration options override
those from the configuration file.

=over 4

=item E<lt>Include filenameE<gt>

Use the E<lt>Include filenameE<gt> directive to include
the contents of C<filename> directly at the current point
within the configuration file.

You cannot use E<lt>IncludeE<gt> within a E<lt>HostE<gt>
section, or at least you I<can> but it wonE<39>t work the
way you expect.

=item E<lt>IncludeWildcard wildcardE<gt>

Include all files matching C<wildcard> at this point in
the file. The files are included in alphabetical order.

You cannot use E<lt>IncludeWildcardE<gt> within a E<lt>HostE<gt>
section, or at least you I<can> but it wonE<39>t work the
way you expect.

=item debug

Run with debugging. Equivalent to the command line C<-d> option.

Default: 0

Example: C<debug: 1>

=item port

The TCP port number on which the FTP server listens when
running in daemon mode (see C<daemon mode> option below).

Default: The standard ftp/tcp service port from C</etc/services>

Example: C<port: 8021>

=item daemon mode

Run as a daemon. If set, the FTP server will open a listening
socket on its default port number, accept new connections and
fork off a new process to handle each connection. If not set
(the default), the FTP server will handle a single connection
on stdin/stdout, which is suitable for use from inetd.

The equivalent command line options are C<-s> and C<-S>.

Default: 0

Example: C<daemon mode: 1>

=item run in background

Run in the background. If set, the FTP server will fork into
the background before running.

The equivalent command line option is C<-S>.

Default: 0

Example: C<run in background: 1>

=item error log

If set, then all warning and error messages are appended to
this file. If not set, warning and error messages get sent to
STDERR and to syslog.

Having an error log is I<highly recommended>.

Default: (not set, warnings and errors go to syslog)

Example: C<error log: /var/log/ftpd.errors>

=item rotate log files

If set, and if the log file names contain a '%' directive, then the
server will check if a new log file is needed whenever the system
accepts a new connection.  This implements a log rotation feature for
long-running servers.

If not set, then any '%' directive will be evaluated only when the log
files gets created.

Default: (not set, log file name evaluated only once)

Example: C<rotate log files: 1>

=item maintainer email

MaintainerE<39>s email address.

Default: root@I<hostname>

Example: C<maintainer email: bob@example.com>

=item class

Assign users into classes. One or more C<class> directives can be
added to the configuration file to aggregate individual users into
larger groups of users called classes.

By default all anonymous users are in class C<anonymous> and every
other user is in class C<users>.

The configuration file can contain zero or more C<class>
directives. The format of the class directive is either:

 class: CLASSNAME USERNAME[,USERNAME[,...]]

or:

 class: CLASSNAME { perl code ... }

Examples of the first form are:

 class: staff rich
 class: students ann,mary,pete

User C<rich> will be placed into class C<staff>, and users C<ann>,
C<mary> and C<pete> will be placed into class C<students>.

Examples of the second form are:

 class: family { /jones$/ }
 class: friends { $_ ne "jeff" }

Any username ending in C<jones> (eg. C<rjones>, C<timjones>) will be
in class C<family>. Any other user except C<jeff> will be placed in
class C<friends>. Note that the Perl code must be surrounded by
C<{...}> and must return a boolean true or false value. The username
is available as C<$_>. The Perl code is arbitrary: it might, for
example, use an external file or database lookup in order to work out
if a user belongs to a class.

C<class> directives are evaluated in the order in which they appear in
the configuration file until one matches the username.

Default: Anonymous users are assigned to class C<anonymous> and
everyone else is assigned to class C<users>.

=item timeout

Timeout on control connection. If a command has not been
received after this many seconds, the server drops the
connection. You may set this to zero to disable timeouts
completely (although this is not recommended).

Default: 900 (seconds)

Example: C<timeout: 600>

=item limit memory

=item limit nr processes

=item limit nr files

Resource limits. These limits are applied to each child
process and are important in avoiding denial of service (DoS)
attacks against the FTP server.

 Resource         Default   Unit
 limit memory       16384   KBytes  Amount of memory per child
 limit nr processes    10   (none)  Number of processes
 limit nr files        20   (none)  Number of open files

To instruct the server I<not> to limit a particular resource, set the
limit to C<-1>.

Example:

 limit memory:       32768
 limit nr processes:    20
 limit nr files:        40

 limit nr processes:    -1

=item max clients

Limit on the number of clients who can simultaneously connect.
If this limit is ever reached, new clients will immediately be
closed.  It will not even ask the client to login.  This
feature works in daemon mode only.

Default: 255

Example: C<max clients: 600>

=item max clients message

Message to display when ``max clients'' has been reached.

You may use the following % escape sequences within the
message for internal variables:

 %x  ``max clients'' setting that has been reached
 %E  maintainer email address (from ``maintainer email''
     setting above)
 %G  time in GMT
 %R  remote hostname or IP address if ``resolve addresses''
     is not set
 %L  local hostname
 %T  local time
 %%  just an ordinary ``%''

Default: Maximum connections reached

Example: C<max clients message: Only %x simultaneous connections allowed.  Please try again later.>

=item resolve addresses

Resolve addresses. If set, attempt to do a reverse lookup on
client addresses for logging purposes. If you set this then
some clients may experience long delays when they try to
connect. Not recommended on high load servers.

Default: 0

Example: C<resolve addresses: 1>

=item require resolved addresses

Require resolved addresses. If set, client addresses must validly resolve
otherwise clients will not be able to connect. If you set this
then some clients will not be able to connect, even though it is
probably the fault of their ISP.

Default: 0

Example: C<require resolved addresses: 1>

=item change process name

Change process name. If set (the default) then the FTP server will
change its process name to reflect the IP address or hostname of
the client. If not set then the FTP server will not try to change
its process name.

Default: 1

Example: C<change process name: 0>

=item greeting type

Greeting type. The greeting is printed before the user has logged in.
Possible greeting types are:

    full     Full greeting, including hostname and version number.
    brief    Hostname only.
    terse    Nothing
    text     Display greeting from ``greeting text'' option.

The SITE VERSION command can also reveal the version number. You
may need to turn this off by setting C<allow site version command: 0>
below.

Default: full

Example: C<greeting type: text>

=item greeting text

Greeting text. If the C<greeting type> is set to C<text> then this
contains the text to display.

Default: none

Example: C<greeting text: Hello. IE<39>ll be your server today.>

=item welcome type

Welcome type. The welcome is printed after a user has logged in.
Possible welcome types are:

    normal   Normal welcome message: ``Welcome <<username>>.''
    text     Take the welcome message from ``welcome text'' option.
    file     Take the welcome message from ``welcome file'' file.

Default: normal

Example: C<welcome type: text>

=item welcome text

If C<welcome type> is set to C<text>, then this contains the text
to be printed after a user has logged in.

You may use the following % escape sequences within the welcome
text to substitute for internal variables:

 %E  maintainer's email address (from ``maintainer email''
     setting above)
 %G  time in GMT
 %R  remote hostname or IP address if ``resolve addresses''
     is not set
 %L  local hostname
 %m  user's home directory (see ``home directory'' below)
 %T  local time
 %U  username given when logging in
 %u  currently a synonym for %U, but in future will be
     determined from RFC931 authentication, like wu-ftpd
 %%  just an ordinary ``%''

Default: none

Example: C<welcome text: Welcome to this FTP server.>

=item welcome file

If C<welcome type> is set to C<file>, then this contains the file
to be printed after a user has logged in.

You may use any of the % escape sequences defined in C<welcome text>
above.

Default: none

Example: C<welcome file: /etc/motd>

=item home directory

Home directory. This is the home directory where we put the
user once they have logged in. This only applies to non-anonymous
logins. Anonymous logins are always placed in "/", which is at the
root of their chrooted environment.

You may use an absolute path here, or else one of the following
special forms:

 %m   Use home directory from password file or from NSS.
 %U   Username.
 %%   A single % character.

For example, to force a user to start in C<~/anon-ftp> when they
log in, set this to C<%m/anon-ftp>.

Note that setting the home directory does not perform a chroot.
Use the C<root directory> setting below to jail users into a
particular directory.

Home directories are I<relative> to the current root directory.

In the anonymous read-only (ro-ftpd) personality, set home
directory to C</> or else you will get a warning whenever a user
logs in.

Default: %m

Examples:

 home directory: %m/anon-ftp
 home directory: /

=item root directory

Root directory. Immediately after logging in, perform a chroot
into the named directory. This only applies to non-anonymous
logins, and furthermore it only applies if you have a non-database
VFS installed. Database VFSes typically cannot perform chroot
(or, to be more accurate, they have a different concept of
chroot - typically assigning each user their own completely
separate namespace).

You may use %m and %U as above.

For example, to jail a user under C<~/anon-ftp> after login, do:

  home directory: /
  root directory: %m/anon-ftp

Notice that the home directory is I<relative> to the current
root directory.

Default: (none)

Example: C<root directory: %m/anon-ftp>

=item time zone

Time zone to be used for MDTM and LIST stat information.

Default: GMT

Examples:

 time zone: Etc/GMT+3
 time zone: Europe/London
 time zone: US/Mountain

=item local address

Local addresses. If you wish the FTP server (in daemon mode) to
only bind to a particular local interface, then give its address
here.

Default: none

Example: C<local address: 127.0.0.1>

=item allow anonymous

Allow anonymous access. If set, then allow anonymous access through
the C<ftp> and C<anonymous> accounts.

Default: 0

Example: C<allow anonymous: 1>

=item anonymous password check

=item anonymous password enforce

Validate email addresses. Normally when logging in anonymously,
you are asked to enter your email address as a password. These options
can be used to check and enforce email addresses in this field (to
some extent, at least -- you obviously canE<39>t force someone to
enter a true email address).

The C<anonymous password check> option may be set to C<rfc822>,
C<no browser>, C<trivial> or C<none>. If set to C<rfc822> then
the user must enter a valid RFC 822 email address as password. If
set to C<no browser> then a valid RFC 822 email address must be
entered, and various common browser email addresses like
C<mozilla@> and C<IEI<ver>User@> are refused. If set to C<trivial>
then we just check that the address contains an @ char. If set to
C<none>, then we do no checking. The default is C<none>.

If the C<anonymous password enforce> option is set and the
password fails the check above, then the user will not be allowed
to log in. The default is 0 (unset).

These options only have effect when C<allow anonymous> is set.

Example:

 anonymous password check: rfc822
 anonymous password enforce: 1

=item allow proxy ftp

Allow proxy FTP. If this is set, then the FTP server can be told to
actively connect to addresses and ports on any machine in the world.
This is not such a great idea, but required if you follow the RFC
very closely. If not set (the default), the FTP server will only
connect back to the client machine.

Default: 0

Example: C<allow proxy ftp: 1>

=item allow connect low port

Allow the FTP server to connect back to ports E<lt> 1024. This is rarely
useful and could pose a serious security hole in some circumstances.

Default: 0

Example: C<allow connect low port: 1>

=item passive port range

What range of local ports will the FTP server listen on in passive
mode? Choose a range here like C<1024-5999,49152-65535>. The special
value C<0> means that the FTP server will use a kernel-assigned
ephemeral port.

Default: 49152-65535

Example: C<passive port range: 0>

=item ftp data port

Which source port to use for active (non-passive) mode when connecting
to the client for PORT mode transfers.  The special value C<0> means
that the FTP server will use a kernel-assigned ephemeral port.  To
strictly follow RFC, this should be set to C<ftp-data(20)>.  This may
be required for certain brain-damaged firewall configurations.  However,
for security reasons, the default setting is intentionally set to C<0>
to utilize a kernel-assigned ephemeral port.  Use this directive at
your own risk!

SECURITY PRECAUTIONS:

1) Unfortunately, to use a port E<lt> 1024 requires super-user
privileges.  Thus, low ports will not work unless the FTP server is
invoked as super-user.  This also implies that all processes handling
the client connections must also I<remain> super-user throughout
the entire session.  It is highly discouraged to use a low port.

 http://cr.yp.to/ftp/security.html
 (See "Connection laundering" section)

2) There sometimes exists a danger of needing to connect to the
same remote host:port.  Using the same IP/port on both sides
will cause connect() to fail if the old socket is still being
broken down.  This condition will not occur if using an ephemeral
port.

 http://groups.google.com/groups?selm=fa.epucqgv.1l2kl0e@ifi.uio.no
 (See "unable to create socket" comment)

3) Many hackers use source port 20 to blindly circumvent certain
naive firewalls.  Using an ephemeral port (the default) may help
discourage such dangerous naivety.

 man nmap
 (See the -g option)

Default: 0

Example: C<ftp data port: ftp-data>

=item max login attempts

Maximum number of login attempts before we drop the connection
and issue a warning in the logs. Wu-ftpd defaults this to 5.

Default: 3

Example: C<max login attempts: 5>

=item pam authentication

Use PAM for authentication. Required on systems such as Red Hat Linux
and Solaris which use PAM for authentication rather than the normal
C</etc/passwd> mechanisms. You will need to have the C<Authen::PAM>
Perl module installed for this to work.

Default: 0

Example: C<pam authentication: 1>

=item pam application name

If PAM authentication is enabled, then this is the PAM application
name. I have used C<ftp> as the default which is the same name
that wu-ftpd chooses. FreeBSD users will want to use C<ftpd> here.

Default: ftp

Example: C<pam application name: ftpd>

=item password file

Only in the C<Full> personality, this allows you to specify a password
file which is used for authentication. If you enable this option, then
normal PAM or C</etc/passwd> is bypassed and this password file is
used instead.

Each line in the password file has the following format:

 username:crypted_password:unix_user[:root_directory]

Comments and blank lines are ignored.

For example, a line with:

 guest:ab01FAX.bQRSU:rich:/home/rich/guest-uploads

would allow someone to log in as C<guest> with password
C<123456>. After logging in, the FTP server will assume the identity
of the real Unix user C<rich>, and will chroot itself into the
C</home/rich/guest-uploads> directory.

(Note that because ordinary PAM/C<passwd> is bypassed, it would no
longer be possible for a user to log in directly with the username
C<rich>).

Crypted passwords can be generated using the following command:

 perl -e 'print crypt ("123456", "ab"), "\n"'

Replace C<123456> with the actual password, and replace C<ab> with two
random letters from the set C<[a-zA-Z0-9./]>. (The two random letters
are the so-called I<salt> and are used to make dictionary attacks
against the password file more difficult - see L<crypt(3)>).

The userE<39>s home directory comes from the real Unix password file
(or nsswitch-configured source) for the real Unix user.  You cannot
use password files to override this, and so if you are using the
optional C<root_directory> parameter, it would make sense to add
C<home directory: /> into your configuration file.

Anonymous logins are B<not> affected by the C<password file>
option. Use the C<allow anonymous> flag to control whether anonymous
logins are permitted in the C<Full> back-end.

Password files are not the height of security, but they are included
because they can sometimes be useful. In particular if the password
file can be read by untrusted users then it is likely that those same
users can run the I<crack> program and eventually find out your
passwords. Some small additional security is offered by having the
password file readable only by root (mode 0600). In future we may
offer MD5 or salted SHA-1 hashed passwords to make this harder.

A curious artifact of the implementation allows you to list the same
user with multiple different passwords. Any of the passwords is then
valid for logins (and you could even have the user map to different
real Unix users in different chrooted directories!)

Default: (none)

Example: C<password file: /etc/ftpd.passwd>

=item pidfile

Location of the file to store the process ID (PID).
Applies only to the deamonized process, not the child processes.

Default: (no pidfile created)

Example: C<pidfile: /var/run/ftpd.pid>

=item client logging

Location to store all client commands sent to the server.
The format is the date, the pid, and the command.
Following the pid is a "-" if not authenticated the
username if the connection is authenticated.
Example of before and after authentication:

 [Wed Feb 21 18:41:32 2001][23818:-]USER rob
 [Wed Feb 21 18:41:33 2001][23818:-]PASS 123456
 [Wed Feb 21 18:41:33 2001][23818:*]SYST

Default: (no logging)

Examples:

 client logging: /var/log/ftpd.log
 client logging: /tmp/ftpd_log.$hostname

=item xfer logging

Location of transfer log.  The format was taken from
wu-ftpd and ProFTPD xferlog. (See also "man xferlog")

Default: (no logging)

Examples:

 xfer logging: /var/log/xferlog
 xfer logging: /tmp/xferlog.$hostname

=item hide passwords in client log

If set to 1, then password (C<PASS>) commands will not be
logged in the client log. This option has no effect unless
client logging is enabled.

Default: 0 (PASS lines will be shown)

Example: C<hide passwords in client log: 1>

=item enable syslog

Enable syslogging. If set, then Net::FTPServer will send much
information to syslog. On many systems, this information will
be available in /var/log/messages or /var/adm/messages. If
clear, syslogging is disabled.

Default: 1

Example: C<enable syslog: 0>

=item ident timeout

Timeout for ident authentication lookups.
A timeout (in seconds) must be specified in order to
enable ident lookups.  There is no way to specify an
infinite timeout.  Use 0 to disable this feature.

Default: 0

Example: C<ident timeout: 10>

=item access control rule

=item user access control rule

=item retrieve rule

=item store rule

=item delete rule

=item list rule

=item mkdir rule

=item rename rule

=item chdir rule

Access control rules.

Access control rules are all specified as short snippets of
Perl script. This allows the maximum configurability -- you
can express just about any rules you want -- but at the price
of learning a little Perl.

You can use the following variables from the Perl:

 $hostname      Resolved hostname of the client [1]
 $ip            IP address of the client
 $user          User name [2]
 $class         Class of user [2]
 $user_is_anonymous  True if the user is an anonymous user [2]
 $pathname      Full pathname of the file being affected [2]
 $filename      Filename of the file being affected [2,3]
 $dirname       Directory name containing file being affected [2]
 $type          'A' for ASCII, 'B' for binary, 'L8' for local 8-bit
 $form          Always 'N'
 $mode          Always 'S'
 $stru          Always 'F'

Notes:

[1] May be undefined, particularly if C<resolve addresses> is not set.

[2] Not available in C<access control rule> since the user has not
logged in at this point.

[3] Not available for C<list directory rule>.

Access control rule. The FTP server will not accept any connections
from a site unless this rule succeeds. Note that only C<$hostname>
and C<$ip> are available to this rule, and unless C<resolve addresses>
and C<require resolved addresses> are both set C<$hostname> may
be undefined.

Default: 1

Examples:

 (a) Deny connections from *.badguys.com:

     access control rule: defined ($hostname) && \
                          $hostname !~ /\.badguys\.com$/

 (b) Only allow connections from local network 10.0.0.0/24:

     access control rule: $ip =~ /^10\./

User access control rule. After the user logs in successfully,
this rule is then called to determine if the user may be permitted
access.

Default: 1

Examples:

 (a) Only allow ``rich'' to log in from 10.x.x.x network:

     user access control rule: $user ne "rich" || \
                               $ip =~ /^10\./

 (b) Only allow anonymous users to log in if they come from
     hosts with resolving hostnames (``resolve addresses'' must
     also be set):

     user access control rule: !$user_is_anonymous || \
                               defined ($hostname)

 (c) Do not allow user ``jeff'' to log in at all:

     user access control rule: $user ne "jeff"

Retrieve rule. This rule controls who may retrieve (download) files.

Default: 1

Examples:

 (a) Do not allow anyone to retrieve ``/etc/*'' or any file anywhere
     called ``.htaccess'':

     retrieve rule: $dirname !~ m(^/etc/) && $filename ne ".htaccess"

 (b) Only allow anonymous users to retrieve files from under the
     ``/pub'' directory.

     retrieve rule: !$user_is_anonymous || $dirname =~ m(^/pub/)

Store rule. This rule controls who may store (upload) files.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to upload files anyway, so setting this rule has no
effect.

Default: 1

Examples:

 (a) Only allow users to upload files to the ``/incoming''
     directory.

     store rule: $dirname =~ m(^/incoming/)

 (b) Anonymous users can only upload files to ``/incoming''
     directory.

     store rule: !$user_is_anonymous || $dirname =~ m(^/incoming/)

 (c) Disable file upload.

     store rule: 0

Delete rule. This rule controls who may delete files or rmdir directories.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to delete files anyway, so setting this rule has no
effect.

Default: 1

Example: C<delete rule: 0>

List rule. This rule controls who may list out the contents of a
directory.

Default: 1

Example: C<list rule: $dirname =~ m(^/pub/)>

Mkdir rule. This rule controls who may create a subdirectory.

In the anonymous read-only (ro-ftpd) personality, it is not
possible to create directories anyway, so setting this rule has
no effect.

Default: 1

Example: C<mkdir rule: 0>

Rename rule. This rule controls which files or directories can be renamed.

Default: 1

Example: C<rename rule: $pathname !~ m(/.htaccess$)>

Chdir rule. This rule controls which directories are acceptable to a
CWD or CDUP.

Example: C<chdir rule: $pathname !~ m/private/>

=item chdir message file

Change directory message file. If set, then the first time (per
session) that a user goes into a directory which contains a file
matching this name, that file will be displayed.

The file may contain any of the following % escape sequences:

 %C  current working directory
 %E  maintainer's email address (from ``maintainer email''
     setting above)
 %G  time in GMT
 %R  remote hostname or IP address if ``resolve addresses''
     is not set
 %L  local hostname
 %m  user's home directory (see ``home directory'' below)
 %T  local time
 %U  username given when logging in
 %u  currently a synonym for %U, but in future will be
     determined from RFC931 authentication, like wu-ftpd
 %%  just an ordinary ``%''

Default: (none)

Example: C<chdir message file: .message>

=item allow rename to overwrite

Allow the rename (RNFR/RNTO) command to overwrite files. If unset,
then we try to test whether the rename command would overwrite a
file and disallow it. However there are some race conditions with
this test.

Default: 1

Example: C<allow rename to overwrite: 0>

=item allow store to overwrite

Allow the store commands (STOR/STOU/APPE) to overwrite files. If unset,
then we try to test whether the store command would overwrite a
file and disallow it. However there are some race conditions with
this test.

Default: 1

Example: C<allow store to overwrite: 0>

=item alias

Define an alias C<name> for directory C<dir>. For example, the command
C<alias: mirror /pub/mirror> would allow the user to access the
C</pub/mirror> directory directly just by typing C<cd mirror>.

Aliases only apply to the cd (CWD) command. The C<cd foo> command checks
for directories in the following order:

 foo in the current directory
 an alias called foo
 foo in each directory in the cdpath (see ``cdpath'' command below)

You may list an many aliases as you want.

Alias names cannot contain slashes (/).

Although alias dirs may start without a slash (/), this is unwise and
itE<39>s better that they always start with a slash (/) char.

General format: C<alias: I<name> I<dir>>

=item cdpath

Define a search path which is used when changing directories. For
example, the command C<cdpath: /pub/mirror /pub/sites> would allow
the user to access the C</pub/mirror/ftp.cpan.org> directory
directly by just typing C<cd ftp.cpan.org>.

The C<cd foo> command checks for directories in the following order:

 foo in the current directory
 an alias called foo (see ``alias'' command above)
 foo in each directory in the cdpath

General format: C<cdpath: I<dir1> [I<dir2> [I<dir3> ...]]>

=item allow site version command

SITE VERSION command. If set, then the SITE VERSION command reveals
the current Net::FTPServer version string. If unset, then the command
is disabled.

Default: 1

Example: C<allow site version command: 0>

=item allow site exec command

SITE EXEC command. If set, then the SITE EXEC command allows arbitrary
commands to be executed on the server as the current user. If unset,
then this command is disabled. The default is disabled for obvious
security reasons.

If you do allow SITE EXEC, you may need to increase the per process
memory, processes and files limits above.

Default: 0

Example: C<allow site exec command: 1>

=item enable archive mode

Archive mode. If set (the default), then archive mode is
enabled, allowing users to request, say, C<file.gz> and
get a version of C<file> which is gzip-compressed on the
fly. If zero, then this feature is disabled. See the
section ARCHIVE MODE elsewhere in this manual for details.

Since archive mode is implemented using external commands,
you need to ensure that programs such as C<gzip>,
C<compress>, C<bzip2>, C<uuencode>, etc. are available on
the C<$PATH> (even in the chrooted environment), and you also
need to substantially increase the normal per-process memory,
processes and files limits.

Default: 1

Example: C<enable archive mode: 0>

=item archive zip temporaries

Temporary directory for generating ZIP files in archive mode.
In archive mode, when generating ZIP files, the FTP server is
capable of either creating a temporary file on local disk
containing the ZIP contents, or can generate the file completely
in memory. The former method saves memory. The latter method
(only practical on small ZIP files) allows the server to work
more securely and in certain read-only chrooted environments.

(Unfortunately the ZIP file format itself prevents ZIP files
from being easily created on the fly).

If not specified in the configuration file, this option
defaults to using C</tmp>. If there are local users on the
FTP server box, then this can lead to various C<tmp> races,
so for maximum security you will probably want to change
this.

If specified, and set to a string, then the string is the
name of a directory which is used for storing temporary zip
files. This directory must be writable, and must exist inside
the chrooted environment (if chroot is being used).

If specified, but set to "0" or an empty string, then
the server will always generate the ZIP file in memory.

In any case, if the directory is found at runtime to be
unwritable, then the server falls back to creating ZIP
files in memory.

Default: C</tmp>

Example: C<archive zip temporaries: >

Example: C<archive zip temporaries: /var/ziptmp>

=item site command

Custom SITE commands. Use this command to define custom SITE
commands. Please read the section LOADING CUSTOMIZED SITE
COMMANDS in this manual page for more detailed information.

The C<site command> command has the form:

C<site command: I<cmdname> I<file>>

I<cmdname> is the name of the command (eg. for SITE README you
would set I<cmdname> == C<readme>). I<file> is a file containing the
code of the site command in the form of an anonymous Perl
subroutine. The file should have the form:

 sub {
   my $self = shift;		# The FTPServer object.
   my $cmd = shift;		# Contains the command itself.
   my $rest = shift;		# Contains any parameters passed by the user.

      :     :
      :     :

   $self->reply (RESPONSE_CODE, RESPONSE_TEXT);
 }

You may define as many site commands as you want. You may also
override site commands from the current personality here.

Example:

 site command: quota /usr/local/lib/ftp/quota.pl

and the file C</usr/local/lib/ftp/quota.pl> contains:

 sub {
   my $self = shift;		# The FTPServer object.
   my $cmd = shift;		# Contains "QUOTA".
   my $rest = shift;		# Contains parameters passed by user.

   # ... Some code to compute the user's quota ...

   $self->reply (200, "Your quota is $quota MB.");
 }

The client types C<SITE QUOTA> and the server responds with:

 "200 Your quota is 12.5 MB.".

=item E<lt>Host hostnameE<gt> ... E<lt>/HostE<gt>

E<lt>Host hostnameE<gt> ... E<lt>/HostE<gt> encloses
commands which are applicable only to a particular
host. C<hostname> may be either a fully-qualified
domain name (for IP-less virtual hosts) or an IP
address (for IP-based virtual hosts). You should read
the section VIRTUAL HOSTS in this manual page for
more information on the different types of virtual
hosts and how to set it up in more detail.

Note also that unless you have set C<enable virtual hosts: 1>,
all E<lt>HostE<gt> sections will be ignored.

=item enable virtual hosts

Unless this option is uncommented, virtual hosting is disabled
and the E<lt>HostE<gt> sections in the configuration file have no effect.

Default: 0

Example: C<enable virtual hosts: 1>

=item virtual host multiplex

IP-less virtual hosts. If you want to enable IP-less virtual
hosts, then you must set up your DNS so that all hosts map
to a single IP address, and place that IP address here. This
is roughly equivalent to the Apache C<NameVirtualHost> option.

IP-less virtual hosting is an experimental feature which
requires changes to clients.

Default: (none)

Example: C<virtual host multiplex: 1.2.3.4>

Example E<lt>HostE<gt> section. Allow the dangerous SITE EXEC command
on local connections. (Note that this is still dangerous).

 <Host localhost.localdomain>
   ip: 127.0.0.1
   allow site exec command: 1
 </Host>

Example E<lt>HostE<gt> section. This shows you how to do IP-based
virtual hosts. I assume that you have set up your DNS so that
C<ftp.bob.example.com> maps to IP C<1.2.3.4> and C<ftp.jane.example.com>
maps to IP C<1.2.3.5>, and you have set up suitable IP aliasing
in the kernel.

You do not need the C<ip:> command if you have configured reverse
DNS correctly AND you trust your local DNS servers.

 <Host ftp.bob.example.com>
   ip: 1.2.3.4
   root directory: /home/bob
   home directory: /
   user access control rule: $user eq "bob"
   maintainer email: bob@bob.example.com
 </Host>

 <Host ftp.jane.example.com>
   ip: 1.2.3.5
   root directory: /home/jane
   home directory: /
   allow anonymous: 1
   user access control rule: $user_is_anonymous
   maintainer email: jane@jane.example.com
 </Host>

These rules set up two virtual hosts called C<ftp.bob.example.com>
and C<ftp.jane.example.com>. The former is located under bob's
home directory and only he is allowed to log in. The latter is
located under jane's home directory and only allows anonymous
access.

Example E<lt>HostE<gt> section. This shows you how to do IP-less
virtual hosts. Note that IP-less virtual hosts are a highly
experimental feature, and require the client to support the
HOST command.

You need to set up your DNS so that both C<ftp.bob.example.com>
and C<ftp.jane.example.com> point to your own IP address.

 virtual host multiplex: 1.2.3.4

 <Host ftp.bob.example.com>
   root directory: /home/bob
   home directory: /
   user access control rule: $user eq "bob"
 </Host>

 <Host ftp.jane.example.com>
   root directory: /home/jane
   home directory: /
   allow anonymous: 1
   user access control rule: $user_is_anonymous
 </Host>

=item log socket type

Socket type for contacting syslog. This is the argument to
the C<Sys::Syslog::setlogsock> function.

Default: unix

Example: C<log socket type: inet>

=item listen queue

Length of the listen queue when running in daemon mode.

Default: 10

Example: C<listen queue: 20>

=item tcp window

Set TCP window. See RFC 2415
I<Simulation Studies of Increased Initial TCP Window Size>.
This setting only affects the data
socket. ItE<39>s not likely that you will need to or should change
this setting from the system-specific default.

Default: (system-specific TCP window size)

Example: C<tcp window: 4380>

=item tcp keepalive

Set TCP keepalive.

Default: (system-specific keepalive setting)

Example: C<tcp keepalive: 1>

=item command filter

Command filter. If set, then all commands are checked against
this regular expression before being executed. If a command
doesnE<39>t match the filter, then the command connection is
immediately dropped. This is equivalent to the C<AllowFilter>
command in ProFTPD. Remember to include C<^...$> around the filter.

Default: (no filter)

Example: C<command filter: ^[A-Za-z0-9 /]+$>

=item restrict command

Advanced command filtering. The C<restrict command> directive takes
the form:

 restrict command: "COMMAND" perl code ...

If the user tries to execute C<COMMAND>, then the C<perl code> is
evaluated first. If it evaluates to true, then the command is allowed
to proceed. Otherwise the server reports an error back to the user and
does not execute the command.

Note that the C<COMMAND> is the FTP protocol command, which is not
necessarily the same as the command which users will type in on their
FTP clients. Please read RFC 959 to see some of the more common FTP
protocol commands.

The Perl code has the same variables available to it as for access
control rules (eg. C<$user>, C<$class>, C<$ip>, etc.). The code
I<must not> alter the global C<$_> variable (which contains the
complete command).

Default: all commands are allowed by default

Examples:

Only allow users in the class C<nukers> to delete files and
directories:

 restrict command: "DELE" $class eq "nukers"
 restrict command: "RMD" $class eq "nukers"

Only allow staff to use the C<SITE WHO> command:

 restrict command: "SITE WHO" $class eq "staff"

Only allow C<rich> to run the C<SITE EXEC> command:

 allow site exec command: 1
 restrict command: "SITE EXEC" $user eq "rich"

=item command wait

Go slow. If set, then the server will sleep for this many seconds
before beginning to process each command. This command would be
a lot more useful if you could apply it only to particular
classes of connection.

Default: (no wait)

Example: C<command wait: 5>

=item no authentication commands

The list of commands which a client may issue before they have
authenticated themselves is very limited. Obviously C<USER> and
C<PASS> are allowed (otherwise a user would never be able to log
in!), also C<QUIT>, C<LANG>, C<HOST> and C<FEAT>. C<HELP> is also permitted
(although dubious). Any other commands not on this list will
result in a I<530 Not logged in.> error.

This list ought to contain at least C<USER>, C<PASS> and C<QUIT>
otherwise the server wonE<39>t be very functional.

Some commands cannot be added here -- eg. adding C<CWD> or C<RETR>
to this list is likely to make the FTP server crash, or else enable
users to read files only available to root. Hence use this with
great care.

Default: USER PASS QUIT LANG HOST FEAT HELP

Example: C<no authentication commands: USER PASS QUIT>

=item E<lt>PerlE<gt> ... E<lt>/PerlE<gt>

Use the E<lt>PerlE<gt> directive to write Perl code directly
into your configuration file. Here is a simple example:

 <Perl>
 use Sys::Hostname;
 $config{'maintainer email'} = "root\@" . hostname ();
 $config{port} = 8000 + 21;
 $config{debug} = $ENV{FTP_DEBUG} ? 1 : 0;
 </Perl>

As shown in the example, to set a configuration option called
C<foo>, you simply assign to the variable C<$config{foo}>.

All normal Perl functionality is available to you, including
use of C<require> if you need to run an external Perl script.

The E<lt>PerlE<gt> and E<lt>/PerlE<gt> directives must each appear
on a single line on their own.

To assign multiple configuration options with the same name,
use an array ref:

 <Perl>
 my @aliases = ( "foo /pub/foo",
		 "bar /pub/bar",
		 "baz /pub/baz" );
 $config{alias} = \@aliases;
 </Perl>

You cannot use a E<lt>PerlE<gt> section within a E<lt>HostE<gt>
section. Instead, you must simulate it by assigning to the
C<%host_config> variable like this:

 <Perl>
 $host_config{'localhost.localdomain'}{ip} = "127.0.0.1";
 $host_config{'localhost.localdomain'}{'allow site exec command'}= 1;
 </Perl>

The above is equivalent to the following ordinary E<lt>HostE<gt>
section:

 <Host localhost.localdomain>
   ip: 127.0.0.1
   allow site exec command: 1
 </Host>

You may also assign to the C<$self> variable in order to set
variables directly in the C<Net::FTPServer> object itself. This
is pretty hairy, and hence not recommended, but you dig your own
hole if you want. Here is a contrived example:

 <Perl>
 $self->{version_string} = "my FTP server/1.0";
 </Perl>

A cleaner, but more complex way to do this would be to use
a personality.

The E<lt>PerlE<gt> directive is potentially quite powerful.
Here is a good idea that Rob Brown had:

 <Perl>
 my %H;
 dbmopen (%H, "/etc/ftpd.db", 0644);
 %config = %H;
 dbmclose (%H);
 </Perl>

Notice how this allows you to crunch a possibly very large
configuration file into a hash, for very rapid loading at run time.

Another useful way to use E<lt>PerlE<gt> is to set environment
variables (particularly C<$PATH>).

 <Perl>
 $ENV{PATH} = "/usr/local/bin:$ENV{PATH}"
 </Perl>

HereE<39>s yet another wonderful way to use E<lt>PerlE<gt>.
Look in C</usr/local/lib/ftp/> for a list of site commands
and load each one:

 <Perl>

 my @files = glob "/usr/local/lib/ftp/*.pl";
 my @site_commands;

 foreach (@files)
  {
    push @site_commands, "$1 $_" if /([a-z]+)\.pl/;
  }

 $config{'site command'} = \@site_commands;

 </Perl>

To force a particular version of Net::FTPServer to be
used, include the following code in your configuration
file:

  <Perl>
  die "requires Net::FTPServer version >= 1.025"
    unless $Net::FTPServer::VERSION !~ /\..*\./ &&
           $Net::FTPServer::VERSION >= 1.025;
  </Perl>

=back 4

=head2 LOADING CUSTOMIZED SITE COMMANDS

It is very simple to write custom SITE commands. These
commands are available to users when they type "SITE XYZ"
in a command line FTP client or when they define a custom
SITE command in their graphical FTP client.

SITE commands are unregulated by RFCs. You may define any commands and
give them any names and any function you wish. However, over time
various standard SITE commands have been recognized and implemented
in many FTP servers. C<Net::FTPServer> also implements these. They
are:

  SITE VERSION      Display the server software version.
  SITE EXEC         Execute a shell command on the server (in
                    C<Net::FTPServer> this is disabled by default!)
  SITE ALIAS        Display chdir aliases.
  SITE CDPATH       Display chdir paths.
  SITE CHECKMETHOD  Implement checksums.
  SITE CHECKSUM
  SITE IDLE         Get or set the idle timeout.
  SITE SYNC         Synchronize hard disks.

The following commands are found in C<wu-ftpd>, but not currently
implemented by C<Net::FTPServer>: SITE CHMOD, SITE GPASS, SITE GROUP,
SITE GROUPS, SITE INDEX, SITE MINFO, SITE NEWER, SITE UMASK.

So when you are choosing a name for a SITE command, it is probably
best not to choose one of the above names, unless you are specifically
implementing or overriding that command.

Custom SITE commands have to be written in Perl. However, there
is very little you need to understand in order to write these
commands -- you will only need a basic knowledge of Perl scripting.

As our first example, we will implement a C<SITE README> command.
This command just prints out some standard information.

Firstly create a file called C</usr/local/lib/site_readme.pl> (you
may choose a different path if you want). The file should contain:

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (200,
		  "This is the README file for mysite.example.com.",
		  "Mirrors are contained in /pub/mirrors directory.",
		  "       :       :       :       :       :",
		  "End of the README file.");
  }

Edit C</etc/ftpd.conf> and add the following command:

site command: readme /usr/local/lib/site_readme.pl

and restart the FTP server (check your system log [/var/log/messages]
for any syntax errors or other problems). Here is an example of a
user running the SITE README command:

  ftp> quote help site
  214-The following commands are recognized:
  214-    ALIAS   CHECKMETHOD     EXEC    README
  214-    CDPATH  CHECKSUM        IDLE    VERSION
  214 You can also use HELP to list general commands.
  ftp> site readme
  200-This is the README file for mysite.example.com.
  200-Mirrors are contained in /pub/mirrors directory.
  200-       :       :       :       :       :
  200 End of the README file.

Our second example demonstrates how to use parameters
(the C<$rest> argument). This is the C<SITE ECHO> command.

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Split the parameters up.
    my @params = split /\s+/, $rest;

    # Quote each parameter.
    my $reply = join ", ", map { "'$_'" } @params;

    $self->reply (200, "You said: $reply");
  }

Here is the C<SITE ECHO> command in use:

  ftp> quote help site
  214-The following commands are recognized:
  214-    ALIAS   CHECKMETHOD     ECHO    IDLE
  214-    CDPATH  CHECKSUM        EXEC    VERSION
  214 You can also use HELP to list general commands.
  ftp> site echo hello how are you?
  200 You said: 'hello', 'how', 'are', 'you?'

Our third example is more complex and shows how to interact
with the virtual filesystem (VFS). The C<SITE SHOW> command
will be used to list text files directly (the user normally
has to download the file and view it locally). Hence
C<SITE SHOW readme.txt> should print the contents of the
C<readme.txt> file in the local directory (if it exists).

All file accesses B<must> be done through the VFS, not
by directly accessing the disk. If you follow this convention
then your commands will be secure and will work correctly
with different back-end personalities (in particular when
``files'' are really blobs in a relational database).

  sub {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Get the file handle.
    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    # File doesn't exist or not accessible. Return an error.
    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check it's a simple file.
    my ($mode) = $fileh->status;

    unless ($mode eq "f")
      {
	$self->reply (550,
		      "SITE SHOW command is only supported on plain files.");
	return;
      }

    # Try to open the file.
    my $file = $fileh->open ("r");

    unless ($file)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Copy data into memory.
    my @lines = ();

    while (defined ($_ = $file->getline))
      {
	# Remove any native line endings.
	s/[\n\r]+$//;

	push @lines, $_;
      }

    # Close the file handle.
    unless ($file->close)
      {
	$self->reply (550, "Close failed: ".$self->system_error_hook());
	return;
      }

    # Send the file back to the user.
    $self->reply (200, "File $filename:", @lines, "End of file.");
  }

This code is not quite complete. A better implementation would
also check the "retrieve rule" (so that people couldnE<39>t
use C<SITE SHOW> in order to get around access control limitations
which the server administrator has put in place). It would also
check the file more closely to make sure it was a text file and
would refuse to list very large files.

Here is an example (abbreviated) of a user using the
C<SITE SHOW> command:

  ftp> site show README
  200-File README:
  200-$Id: FTPServer.pm,v 1.11 2005/07/15 10:10:22 rwmj Exp $
  200-
  200-Net::FTPServer - A secure, extensible and configurable Perl FTP server.
  [...]
  200-To contact the author, please email: Richard Jones <rich@annexia.org>
  200 End of file.

=head2 STANDARD PERSONALITIES

Currently C<Net::FTPServer> is supplied with three standard
personalities. These are:

  Full    The complete read/write anonymous/authenticated FTP
          server which serves files from a standard Unix filesystem.

  RO      A small read-only anonymous-only FTP server similar
          in functionality to Dan Bernstein's publicfile
          program.

  DBeg1   An example FTP server which serves files to a PostgreSQL
          database. This supports files and hierarchical
          directories, multiple users (but not file permissions)
          and file upload.

The standard B<Full> personality will not be explained here.

The B<RO> personality is the Full personality with all code
related to writing files, creating directories, deleting, etc.
removed. The RO personality also only permits anonymous
logins and does not contain any code to do ordinary
authentication. It is therefore safe to use the RO
personality where you are only interested in serving
files to anonymous users and do not want to worry about
crackers discovering a way to trick the FTP server into
writing over a file.

The B<DBeg1> personality is a complete read/write
FTP server which stores files as BLOBs (Binary Large
OBjects) in a PostgreSQL relational database. The
personality supports file download and upload and
contains code to authenticate users against a C<users>
table in the database (database ``users'' are thus
completely unrelated to real Unix users). The
B<DBeg1> is intended only as an example. It does
not support advanced features such as file
permissions and quotas. As part of the schoolmaster.net
project Bibliotech Ltd. have developed an even more
advanced database personality which supports users,
groups, access control lists, quotas, recursive
moves and copies and many other features. However this
database personality is not available as source.

To use the DBeg1 personality you must first run a
PostgreSQL server (version 6.4 or above) and ensure
that you have access to it from your local user account.
Use the C<initdb>, C<createdb> and C<createuser>
commands to create the appropriate user account and
database (please consult the PostgreSQL administrators
manual for further information about this -- I do
not answer questions about basic PostgreSQL knowledge).

Here is my correctly set up PostgreSQL server, accessed
from my local user account ``rich'':

  cruiser:~$ psql
  Welcome to the POSTGRESQL interactive sql monitor:
    Please read the file COPYRIGHT for copyright terms of POSTGRESQL

     type \? for help on slash commands
     type \q to quit
     type \g or terminate with semicolon to execute query
   You are currently connected to the database: rich

  rich=> \d
  Couldn't find any tables, sequences or indices!

You will also need the following Perl modules installed:
DBI, DBD::Pg.

Now you will need to create a database called ``ftp'' and
populate it with data. This is how to do this:

  createdb ftp
  psql ftp < doc/eg1.sql

Check that no ERRORs are reported by PostgreSQL.

You should now be able to start the FTP server by running
the following command (I<not> as root):

  ./dbeg1-ftpd -S -p 2000 -C ftpd.conf

If the FTP server doesnE<39>t start correctly, you should
check the system log file [/var/log/messages].

Connect to the FTP server as follows:

  ftp localhost 2000

Log in as either rich/123456 or dan/123456 and then try
to move around, upload and download files, create and
delete directories, etc.

=head2 SUBCLASSING THE Net::FTPServer CLASSES

By subclassing C<Net::FTPServer>, C<Net::FTPServer::DirHandle> and/or
C<Net::FTPServer::FileHandle> you can create custom
personalities for the FTP server.

Typically by overriding the hooks in the C<Net::FTPServer> class
you can change the basic behaviour of the FTP server - turning
it into an anonymous read-only server, for example.

By overriding the hooks in C<Net::FTPServer::DirHandle> and
C<Net::FTPServer::FileHandle> you can create virtual filesystems:
serving files into and out of a database, for example.

The current manual page contains information about the
hooks in C<Net::FTPServer> which may be overridden.

See L<Net::FTPServer::DirHandle(3)> for information about
the methods in C<Net::FTPServer::DirHandle> which may be
overridden.

See L<Net::FTPServer::FileHandle(3)> for information about
the methods in C<Net::FTPServer::FileHandle> which may be
overridden.

The most reasonable way to create your own personality is
to extend one of the existing personalities. Choose the
one which most closely matches the personality that you
want to create. For example, suppose that you want to create
another database personality. A good place to start would
be by copying C<lib/Net/FTPServer/DBeg1/*.pm> to a new
directory C<lib/Net/FTPServer/MyDB/> (for example). Now
edit these files and substitute "MyDB" for "DBeg1". Then
examine each subroutine in these files and modify them,
consulting the appropriate manual page if you need to.

=head2 VIRTUAL HOSTS

C<Net:FTPServer> is capable of hosting multiple FTP sites on
a single machine. Because of the nature of the FTP protocol,
virtual hosting is almost always done by allocating a single
separate IP address per FTP site. However, C<Net::FTPServer>
also supports an experimental IP-less virtual hosting
system, although this requires modifications to the client.

Normal (IP-based) virtual hosting is carried out as follows:

 * For each FTP site, allocate a separate IP address.
 * Configure IP aliasing on your normal interface so that
   the single physical interface responds to multiple
   virtual IP addresses.
 * Add entries (A records) in DNS mapping each site's
   name to a separate IP address.
 * Add reverse entries (PTR records) in DNS mapping each
   IP address back to the site hostname. It is important
   that both forward and reverse DNS is set up correctly,
   else virtual hosting may not work.
 * In /etc/ftpd.conf you will need to add a virtual host
   section for each site like this:

     <Host sitename>

       ip: 1.2.3.4
       ... any specific configuration options for this site ...

     </Host>

   You don't in fact need the "ip:" part assuming that
   your forward and reverse DNS are set up correctly.
 * If you want to specify a lot of external sites, or
   generate the configuration file automatically from a
   database or a script, you may find the <Include filename>
   syntax useful.

There are examples in C</etc/ftpd.conf>. Here is how
IP-based virtual hosting works:

 * The server starts by listening on all interfaces.
 * A connection arrives at one of the IP addresses and a
   process is forked off.
 * The child process finds out which interface the
   client connected to and reverses the name.
 * If:
     the IP address matches one of the "ip:" declarations
     in any of the "Host" sections,
   or:
     there is a reversal for the name, and the name
     matches one of the "Host" sections in the configuration
     file,
   then:
     configuration options are read from that
     section of the file and override any global configuration
     options specified elsewhere in the file.
 * Otherwise, the global configuration options only
   are used.

IP-less virtual hosting is an experimental feature. It
requires the client to send a C<HOST> command very early
on in the command stream -- before C<USER> and C<PASS>. The
C<HOST> command explicitly gives the hostname that the
FTP client is attempting to connect to, and so allows
many FTP sites to be multiplexed onto a single IP
address. At the present time, I am not aware of I<any>
FTP clients which implement the C<HOST> command, although
they will undoubtedly become more common in future.

This is how to set up IP-less virtual hosting:

 * Add entries (A or CNAME records) in DNS mapping the
   name of each site to a single IP address.
 * In /etc/ftpd.conf you will need to list the same single
   IP address to which all your sites map:

     virtual host multiplex: 1.2.3.4

 * In /etc/ftpd.conf you will need to add a virtual host
   section for each site like this:

     <Host sitename>

       ... any specific configuration options for this site ...

     </Host>

Here is how IP-less virtual hosting works:

 * The server starts by listening on one interface.
 * A connection arrives at the IP address and a
   process is forked off.
 * The IP address matches "virtual host multiplex"
   and so no IP-based virtual host processing is done.
 * One of the first commands that the client sends is
   "HOST" followed by the hostname of the site.
 * If there is a matching "Host" section in the
   configuration file, then configuration options are
   read from that section of the file and override any
   global configuration options specified elsewhere in
   the file.
 * If there is no matching "Host" section then the
   global configuration options alone are used.

The client is not permitted to issue the C<HOST> command
more than once, and is not permitted to issue it after
login.

=head2 VIRTUAL HOSTING AND SECURITY

Only certain configuration options are available inside
the E<lt>HostE<gt> sections of the configuration file.
Generally speaking, the only configuration options you
can put here are ones which take effect after the
site name has been determined -- hence "allow anonymous"
is OK (since itE<39>s an option which is parsed after
determining the site name and during log in), but
"port" is not (since it is parsed long before any
clients ever connect).

Make sure your default global configuration is
secure. If you are using IP-less virtual hosting,
this is particularly important, since if the client
never sends a C<HOST> command, the client gets
the global configuration. Even with IP-based virtual
hosting it may be possible for clients to sometimes
get the global configuration, for example if your
local name server fails.

IP-based virtual hosting always takes precedence
above IP-less virtual hosting.

With IP-less virtual hosting, access control cannot
be performed on a per-site basis. This is because the
client has to issue commands (ie. the C<HOST> command
at least) before the site name is known to the server.
However you may still have a global "access control rule".

=head2 ARCHIVE MODE

Beginning with version 1.100, C<Net::FTPServer> is able
to generate certain types of compressed and archived files
on the fly. In practice what this means is that if a user
requests, say, C<file.gz> and this file does not actually
exist (but C<file> I<does> exist), then the server will
dynamically generate a gzip-compressed version of C<file>
for the user. This also works on directories, so that a
user might request C<dir.tar.gz> which does not exist
(but directory C<dir> I<does> exist), and the server tars
up and compresses the entire contents of C<dir> and
presents that back to the user.

Archive mode is enabled by default. However, it will
not work unless you substantially increase the per-process
memory, processes and files limits. The reason for this
is that archive mode works by forking external programs
such as C<gzip> to perform the compression. For the same
reason you may also need to ensure that at least
C<gzip>, C<compress>, C<bzip2> and C<uuencode> programs
are available on the current C<$PATH>, particularly if
you are using a chrooted environment.

To disable archive mode put C<enable archive mode: 0>
into the configuration file.

The following file extensions are supported:

 .gz      GZip compressed.      Requires gzip program on PATH.
 .Z       Unix compressed.      Requires compress program on PATH.
 .bz2     BZip2 compressed.     Requires bzip2 program on PATH.
 .uue     UU-encoded.           Requires uuencode program on PATH.
 .tar     Tar archive.          Requires Perl Archive::Tar module.
 .zip     DOS ZIP archive.      Requires Perl Archive::Zip module.
 .list    Return a list of all the files in this directory.

File extensions may be combined. Hence C<.tar.gz>,
C<.tar.bz2> and even C<.tar.gz.uue> will all work
as you expect.

Archive mode is, of course, extensible. It is particularly
simple to add another compression / filter format. In
your personality (or in a E<lt>PerlE<gt> section in the configuration
file) you need to add another key to the C<archive_filters>
hash.

  $ftps->{archive_filters}{".foo"} = &_foo_filter;

The value of this key should be a function as defined below:

  \%filter = _foo_filter ($ftps, $sock);

The filter should return a hash reference (undef if it fails).
The hash should contain the following keys:

  sock      Newly opened socket.
  pid       PID of filter program.

The C<_foo_filter> function takes the existing socket and
filters it, providing a new socket which the FTP server will
write to (for the data connection back to the client). If
your filter is a Unix program, then the simplest thing is
just to define C<_foo_filter> as:

  sub _foo_filter
  {
    return $_[0]->archive_filter_external ($_[1], "foo" [, args ...]);
  }

The C<archive_filter_external> function takes care of the
tricky bits for you.

Adding new I<generators> (akin to the existing tar and ZIP)
is more tricky. I suggest you look closely at the code and
consult the author for more information.

=head1 METHODS

=over 4

=cut

package Net::FTPServer;

use strict;

use vars qw($VERSION $RELEASE);

$VERSION = '1.122';
$RELEASE = 1;

# Non-optional modules.
use Config;
use Getopt::Long qw(GetOptions);
use Sys::Hostname;
use Socket;
use FileHandle;
use IO::Socket;
use IO::File;
use IO::Select;
use IO::Scalar;
use IO::Seekable;
use IPC::Open2;
use Carp;
use Carp::Heavy ;
use POSIX qw(setsid dup dup2 ceil strftime WNOHANG);
use Fcntl qw(F_SETOWN F_SETFD FD_CLOEXEC);
use Errno qw(EADDRINUSE) ;

use Net::FTPServer::FileHandle;
use Net::FTPServer::DirHandle;

# We require this to suppress warning messages from going to the client
# when it starts up, eg. Constant subroutine __need___va_list undefined ...
# (Thanks to Rob Brown for this fix.)

BEGIN {
  local $^W = 0;
  require Sys::Syslog;
}

# The following modules are optional, and therefore we need
# to eval the require/use statements. Before using the features
# of an optional module, make sure it exists first by checking
# ``exists $INC{"Module/Name.pm"}'' (see below for examples).
#eval "use Archive::Tar;";
eval "use Archive::Zip;";
eval "use BSD::Resource;";
eval "use Digest::MD5;";
eval "use File::Sync;";

# Global variables and constants.
use vars qw(@_default_commands
	    @_default_site_commands
	    @_supported_mlst_facts
	    $_default_timeout);

@_default_commands
  = (
     # Standard commands from RFC 959.
     "USER", "PASS", "ACCT", "CWD", "CDUP", "SMNT",
     "REIN", "QUIT", "PORT", "PASV", "TYPE", "STRU",
     "MODE", "RETR", "STOR", "STOU", "APPE", "ALLO",
     "REST", "RNFR", "RNTO", "ABOR", "DELE", "RMD",
     "MKD", "PWD", "LIST", "NLST", "SITE", "SYST",
     "STAT", "HELP", "NOOP",
     # RFC 1123 section 4.1.3.1 recommends implementing these.
     "XMKD", "XRMD", "XPWD", "XCUP", "XCWD",
     # From RFC 2389.
     "FEAT", "OPTS",
     # From ftpexts Internet Draft.
     "SIZE", "MDTM", "MLST", "MLSD",
     # Mail handling commands from obsolete RFC 765.
     "MLFL", "MAIL", "MSND", "MSOM", "MSAM", "MRSQ",
     "MRCP",
     # I18N support from RFC 2640.
     "LANG",
     # NcFTP sends the CLNT command, I know not from what RFC.
     "CLNT",
     # Experimental IP-less virtual hosting.
     "HOST",
    );

@_default_site_commands
  = (
     # Common extensions.
     "EXEC", "VERSION",
     # Wu-FTPD compatible extensions.
     "ALIAS", "CDPATH", "CHECKMETHOD", "CHECKSUM",
     "IDLE",
     # Net::FTPServer compatible extensions.
     "SYNC", "ARCHIVE",
    );

@_supported_mlst_facts
  = (
     "TYPE", "SIZE", "MODIFY", "PERM", "UNIX.MODE"
    );

$_default_timeout = 900;

# Allocate and initialize signal flags
use vars qw($GOT_SIGURG $GOT_SIGCHLD $GOT_SIGHUP $GOT_SIGTERM);
$GOT_SIGURG  = 0;
$GOT_SIGCHLD = 0;
$GOT_SIGHUP  = 0;
$GOT_SIGTERM = 0;

=pod

=item Net::FTPServer->run ([\@ARGV]);

This is the main entry point into the FTP server. It starts the
FTP server running. This function never normally returns.

If no arguments are given, then command line arguments are taken
from the global C<@ARGV> array.

=cut

sub run
  {
    my $class = shift;
    my $args = shift || [@ARGV];

    # Clean up the environment to allow tainting to work.
    $ENV{PATH} = "/usr/bin:/bin";
    $ENV{SHELL} = "/bin/sh";
    delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};

    # Create Net::FTPServer object.
    my $self = {};
    bless $self, $class;

    # Construct version string.
    $self->{version_string}
    = "Net::FTPServer/" .
      $Net::FTPServer::VERSION . "-" .
      $Net::FTPServer::RELEASE;

    # Save the hostname.
    $self->{hostname} = hostname;
    $self->{hostname} = $1 if $self->{hostname} =~ /^([\w\-\.]+)$/;

    # Construct a table of commands to subroutines.
    $self->{command_table} = {};
    foreach (@_default_commands) {
      my $subname = "_${_}_command";
      $self->{command_table}{$_} = \&$subname;
    }

    # Construct a list of SITE commands.
    $self->{site_command_table} = {};
    foreach (@_default_site_commands) {
      my $subname = "_SITE_${_}_command";
      $self->{site_command_table}{$_} = \&$subname;
    }

    # Construct a list of supported features (for FEAT command).
    $self->{features} = {
			 SIZE => undef,
			 REST => "STREAM",
			 MDTM => undef,
			 TVFS => undef,
			 UTF8 => undef,
			 MLST => join ("",
				       map { "$_*;" } @_supported_mlst_facts),
			 LANG => "EN*",
			 HOST => undef,
			};

    # Construct a list of supported options (for OPTS command).
    $self->{options} = {
			MLST => \&_OPTS_MLST_command,
		       };

    $self->pre_configuration_hook;

    # Global configuration.
    $self->{debug} = 0;
    $self->{_config_file} = "/etc/ftpd.conf";

    $self->options_hook ($args);
    $self->_get_configuration ($args);

    $self->post_configuration_hook;

    # Initialize Max Clients Settings
    $self->{_max_clients} =
      $self->config ("max clients") || 255;
    $self->{_max_clients_message} =
      $self->config ("max clients message") ||
	"Maximum connections reached";

    # Open syslog.
    $self->{_enable_syslog} =
      (!defined $self->config ("enable syslog") ||
       $self->config ("enable syslog")) &&
      !$self->{_test_mode};

    if ($self->{_enable_syslog})
      {
	if (defined $self->config ("log socket type")) {
	  Sys::Syslog::setlogsock $self->config ("log socket type")
	} else {
	  Sys::Syslog::setlogsock "unix";
	}

	Sys::Syslog::openlog "ftpd", "pid", "daemon";
      }

    # Handle error and warning messages. If error log is set (which
    # is highly recommended BTW), these are appended directly to
    # that file. If error log is not set, then we use a hack which
    # directs those messages to syslog.

    if (defined $self->config ("error log"))
      {
	$self->_open_error_log ;

	$SIG{__DIE__} = sub {
	  $self->log ("err", $_[0]);
	  confess $_[0];
	};
      }
    else
      {
	# Set up a hook for warn and die so that these cause messages to
	# be echoed to the syslog.
	$SIG{__WARN__} = sub {
	  $self->log ("warning", $_[0]);
	  warn $_[0];
	};
	$SIG{__DIE__} = sub {
	  $self->log ("err", $_[0]);
	  confess $_[0];
	};
      }

    # Just set a flag in order to be "signal safe"
    $SIG{URG}  = sub { $GOT_SIGURG  = 1; };
    $SIG{CHLD} = sub { $GOT_SIGCHLD = 1; };
    $SIG{HUP}  = sub { $GOT_SIGHUP  = 1; };
    $SIG{TERM} = sub { $GOT_SIGTERM = 1; };

    # The following signal handlers can be handled by Perl, since
    # all they are going to do is exit anyway.
    $SIG{PIPE} = sub {
      $self->log ("info", "client closed connection abruptly") if $self;
      exit;
    };
    $SIG{INT} = sub {
      $self->log ("info", "exiting on keyboard INT signal");
      exit;
    };
    $SIG{QUIT} = sub {
      $self->log ("info", "exiting on keyboard QUIT signal");
      exit;
    };
    $SIG{ALRM} = sub {
      $self->log ("info", "exiting on ALRM signal");
      print "421 Server closed the connection after idle timeout.\r\n";
      $self->_log_line ("[TIMED OUT!]");
      exit;
    };

    # Setup Client Logging.
    $self->_open_client_log ;

    # Setup xfer Logging.
    $self->_open_xfer_log ;

    # Convert FTP Data port service name to port number, if necessary.
    if (my $ftpdata = $self->config ("ftp data port"))
      {
	my $ftp_data_port =
	  $ftpdata =~ /^\d+$/
	    ? $ftpdata
	    : scalar (getservbyname ($ftpdata, 'tcp'));
	die "Unable to locate '$ftpdata' service"
	  unless defined $ftp_data_port;
	$self->{ftp_data_port} = $ftp_data_port;
      }

    # Load customized SITE commands.
    my @custom_site_commands = $self->config ("site command");
    foreach (@custom_site_commands)
      {
	my ($cmdname, $filename) = split /\s+/, $_;
	my $sub = do $filename;
	if ($sub)
	  {
	    if (ref $sub eq "CODE") {
	      $self->{site_command_table}{uc $cmdname} = $sub;
	    } else {
	      $self->log ("err", "site command: $filename: must return an anonymous subroutine when evaluated (skipping)");
	    }
	  }
	else
	  {
	    if ($!) {
	      $self->log ("err", "site command: $filename: $! (ignored)")
	    } else {
	      $self->log ("err", "site command: $filename: $@ (ignored)")
	    }
	  }
      }

    my $daemon_mode = $self->config ("daemon mode");
    my $run_in_background = $self->config ("run in background");

    # Display start-up string in syslog.
    $self->log ("info",
		$self->{version_string} . " running" .
		($daemon_mode ? " daemon" : "") .
		($run_in_background ? " background" : "") .
		($self->config ("port") ? " on port " . $self->config ("port")
		                        : ""));

    # Daemon mode?
    if ($daemon_mode)
      {
	# Fork into the background?
	$self->_fork_into_background if $run_in_background;

	$self->_save_pid;

	# Run as a daemon.
	$self->_be_daemon;
      }

    $| = 1;

    $self->log ("info", "in post accept stage") if $self->{debug};

    # Hook just after accepting the connection.
    $self->post_accept_hook;

    # Get the sockname of the socket so we know which interface
    # the client is bound to.
    my ($sockname, $sockport, $sockaddr, $sockaddrstring);

    unless ($self->{_test_mode})
      {
	$self->log ("info", "get socket name") if $self->{debug};

	$sockname = getsockname STDIN;
	if (!defined $sockname)
	  {
	    $self->reply(500, "inet mode requires a socket - use '$0 -S' for standalone.");
	    exit;
	  }
	($sockport, $sockaddr) = unpack_sockaddr_in ($sockname);
	$sockaddrstring = inet_ntoa ($sockaddr);

	# Added 21 Feb 2001 by Rob Brown
	# If MSG_OOB data arrives on STDIN send it inline and trigger SIGURG
	setsockopt (STDIN, SOL_SOCKET, SO_OOBINLINE, pack ("l", 1))
	  or warn "setsockopt: SO_OOBINLINE: $!";

	# Note by RWMJ: The following code always generates an error, so
	# I have commented it out for the present.
	#my $pid = pack ("l", $$);
	#fcntl (STDIN, F_SETOWN, $pid)
	#  or warn "fcntl: F_SETOWN $$: $!";
      }

    # Virtual hosts.
    my $sitename;

    if ($self->config ("enable virtual hosts"))
      {
	$self->log ("info", "virtual host configuration") if $self->{debug};

	my $virtual_host_multiplex = $self->config ("virtual host multiplex");

	# IP-based virtual hosting?
	unless ($virtual_host_multiplex &&
		$virtual_host_multiplex eq $sockaddrstring)
	  {
	    # Look for a matching "ip:" configuration option in
	    # a <Host> section.
	    $sitename = $self->ip_host_config ($sockaddrstring);

	    unless ($sitename)
	      {
		# Try reversing the IP address in DNS instead.
		$sitename = gethostbyaddr ($sockaddr, AF_INET);
	      }

	    if ($self->{debug})
	      {
		if ($sitename)
		  {
		    $self->log ("info",
				"IP-based virtual hosts: ".
				"set site to $sitename");
		  }
		else
		  {
		    $self->log ("info",
				"IP-based virtual hosts: ".
				"no site found");
		  }
	      }
	  }
      }

    $self->log ("info", "get peer name") if $self->{debug};

    # Get the peername and other details of this socket.
    my ($peername, $peerport, $peeraddr, $peeraddrstring);

    if ( $peername = getpeername STDIN )
      {
	($peerport, $peeraddr) = unpack_sockaddr_in ($peername);
	$peeraddrstring = inet_ntoa ($peeraddr);
      }
    else
      {
	$peerport = 0;
	$peeraddr = inet_aton ( $peeraddrstring = "127.0.0.1" );
      }

    $self->_log_line ("[CONNECTION FROM $peeraddrstring:$peerport] \#".
		      (1 + $self->concurrent_connections));

    # Resolve the address.
    my $peerhostname;
    if ($self->config ("resolve addresses"))
      {
	my $hostname = gethostbyaddr ($peeraddr, AF_INET);

	if ($hostname)
	  {
	    my $ipaddr = gethostbyname ($hostname);

	    if ($ipaddr && inet_ntoa ($ipaddr) eq $peeraddrstring)
	      {
		$peerhostname = $hostname;
	      }
	  }

	if ($self->config ("require resolved addresses") && !$peerhostname)
	  {
	    $self->log ("err",
			"cannot resolve address for connection from " .
			"$peeraddrstring:$peerport");
	    exit 0;
	  }
      }

    # Set up request information.
    $self->{sockname} = $sockname;
    $self->{sockport} = $sockport;
    $self->{sockaddr} = $sockaddr;
    $self->{sockaddrstring} = $sockaddrstring;
    $self->{sitename} = $sitename;
    $self->{peername} = $peername;
    $self->{peerport} = $peerport;
    $self->{peeraddr} = $peeraddr;
    $self->{peeraddrstring} = $peeraddrstring;
    $self->{peerhostname} = $peerhostname;
    $self->{authenticated} = 0;
    $self->{loginattempts} = 0;

    # Default port information, used if no PORT command is issued. This
    # is used by the open_data_connection function. See RFC 959 section 3.2.
    $self->{_hostport} = $peerport;
    $self->{_hostaddr} = $peeraddr;
    $self->{_hostaddrstring} = $peeraddrstring;

    # Default mode is active. Issuing the PASV command switches the
    # server into passive mode.
    $self->{_passive} = 0;

    # Set up default connection state.
    $self->{type} = 'A';
    $self->{form} = 'N';
    $self->{mode} = 'S';
    $self->{stru} = 'F';

    # Other per-connection state.
    $self->{_mlst_facts} = \@_supported_mlst_facts;
    $self->{_checksum_method} = "MD5";
    $self->{_idle_timeout} = $self->config ("timeout") || $_default_timeout;
    $self->{maintainer_email}
    = defined $self->config ("maintainer email") ?
      $self->config ("maintainer email") :
      "root\@$self->{hostname}";
    $self->{_chdir_message_cache} = {};

    # Support for archive mode.
    $self->{archive_mode} =
      !defined $self->config ("enable archive mode") ||
      $self->config ("enable archive mode");
    $self->{archive_filters} = {} unless exists $self->{archive_filters};
    $self->{archive_generators} = {} unless exists $self->{archive_generators};
    if ($self->{archive_mode})
      {
	# NB. Extension matching is case insensitive.
	$self->{archive_filters}{".z"} = \&_archive_filter_Z
	  if $self->_find_prog ("compress");
	$self->{archive_filters}{".gz"} = \&_archive_filter_gz
	  if $self->_find_prog ("gzip");
	$self->{archive_filters}{".bz2"} = \&_archive_filter_bz2
	  if $self->_find_prog ("bzip2");
	$self->{archive_filters}{".uue"} = \&_archive_filter_uue
	  if $self->_find_prog ("uuencode");

	$self->{archive_generators}{".zip"} = \&_archive_generator_zip
	  if exists $INC{"Archive/Zip.pm"};
#	$self->{archive_generators}{".tar"} = \&_archive_generator_tar
#	  if exists $INC{"Archive/Tar.pm"};
	$self->{archive_generators}{".list"} = \&_archive_generator_list;

	if ($self->{debug})
	  {
	    $self->log ("info",
			"archive mode enabled [%s]",
			join (", ",
			      keys %{$self->{archive_filters}},
			      keys %{$self->{archive_generators}}));
	  }
      }

    $self->log ("info", "in access control stage") if $self->{debug};

    my $r = $self->access_control_hook;
    exit if $r == -1;

    # Perform normal access control.
    if ($r == 0)
      {
	unless ($self->_eval_rule ("access control rule"))
	  {
	    $self->reply (421, "Client denied by server configuration. Goodbye.");
	    exit;
	  }
      }

    # Install per-process limits.
    $self->log ("info", "in process limits stage") if $self->{debug};

    $r = $self->process_limits_hook;
    exit if $r == -1;

    # Perform normal per-process limits.
    if ($r == 0)
      {
	my $limit = 1024 * ($self->config ("limit memory") || 16384);
	$self->_set_rlimit ("RLIMIT_DATA", $limit) if $limit >= 0;

	$limit = $self->config ("limit nr processes") || 10;
	$self->_set_rlimit ("RLIMIT_NPROC", $limit) if $limit >= 0;

	$limit = $self->config ("limit nr files") || 20;
	$self->_set_rlimit ("RLIMIT_NOFILE", $limit) if $limit >= 0;
      }

    unless ($self->{_test_mode})
      {
	# Log the connection information available.
	my $peerinfodpy
	  = $peerhostname ?
	    "$peerhostname:$peerport ($peeraddrstring:$peerport)" :
	    "$peeraddrstring:$peerport";

	$self->log ("info", "connection from $peerinfodpy");

	# Change name of process in process listing.
	unless (defined $self->config ("change process name") &&
		!$self->config ("change process name"))
	  {
	    $0 = "ftpd $peerinfodpy";
	  }
      }

    # Send the greeting.
    my $greeting_type = $self->config ("greeting type") || "full";

    if ($greeting_type eq "full")
      {
	$self->reply (220, "$self->{hostname} FTP server ($self->{version_string}) ready.");
      }
    elsif ($greeting_type eq "brief")
      {
	$self->reply (220, "$self->{hostname} FTP server ready.");
      }
    elsif ($greeting_type eq "terse")
      {
	$self->reply (220, "FTP server ready.");
      }
    elsif ($greeting_type eq "text")
      {
	my $greeting_text = $self->config ("greeting text")
	  or die "greeting type is text, but no greeting text configuration value";
	$self->reply (220, $greeting_text);
      }
    else
      {
	die "unknown greeting type: ${greeting_type}";
      }

    # Implement Identification Protocol as explained in RFC 1413.
    # Some firewalls block the auth port which could make this
    # operation slow.  Wait until after the greeting is sent to the
    # client to signify that it is okay for commands to be sent while
    # the ident authentication is taking place.  This timeout is used
    # for both the connection and the "patience" desired for the
    # remote ident response.  Having a timeout also helps to avoid a
    # possible DoS on the FTP server.  There is no way to specify an
    # infinite timeout.  The directive "ident timeout: 0" will disable
    # this feature.

    my $ident_timeout = $self->config ("ident timeout");
    if (defined $ident_timeout && $ident_timeout > 0 &&
	defined $self->{peerport} && defined $self->{sockport} &&
	defined $self->{peeraddrstring})
      {
	my $got_bored = 0;
	my $ident;
	eval
	  {
	    local $SIG{__WARN__} = 'DEFAULT';
	    local $SIG{__DIE__}  = 'DEFAULT';
	    local $SIG{ALRM} = sub { $got_bored = 1; die "timed out"; };
	    alarm $ident_timeout;
	    "0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
	    $ident = new IO::Socket::INET
	      (PeerAddr  => $self->{peeraddrstring},
	       PeerPort  => "auth");
	  };

	if ($got_bored)
	  {
	    # Took too long to connect to remote auth port
	    # (probably because of a client-side firewall).
	    $self->_log_line ("[Ident auth failed: connection timed out]");
	    $self->log ("warning", "ident auth failed for $self->{peeraddrstring}: connection timed out");
	  }
	else
	  {
	    if (defined $ident)
	      {
		my $response;
		eval
		  {
		    local $SIG{__WARN__} = 'DEFAULT';
		    local $SIG{__DIE__}  = 'DEFAULT';
		    local $SIG{ALRM}
		      = sub { $got_bored = 1; die "timed out"; };
		    alarm $ident_timeout;
		    $ident->print ("$self->{peerport} , ",
				   "$self->{sockport}\r\n");
		    $response = $ident->getline;
		  };
		$ident->close;

		# Took too long to respond?
		if ($got_bored)
		  {
		    $self->_log_line ("[Ident auth failed: response timed out]");
		    $self->log ("warning", "ident auth failed for $self->{peeraddrstring}: response timed out");
		  }
		else
		  {
		    if ($response =~ /:\s*USERID\s*:\s*OTHER\s*:\s*(\S+)/)
		      {
			$self->{auth} = $1;
			$self->_log_line ("[IDENT AUTH VERIFIED: $self->{auth}\@$self->{peeraddrstring}]");
			$self->log ("info", "ident auth: $self->{auth}\@$self->{peeraddrstring}");
		      }
		    else
		      {
			$self->_log_line ("[Ident auth failed: invalid response]");
			$self->log ("warning", "ident auth failed for $self->{peeraddrstring}: invalid response");
		      }
		  }
	      }
	    else
	      {
		$self->_log_line ("[Ident auth failed: Connection refused]");
		$self->log ("warning", "ident auth failed for $self->{peeraddrstring}: Connection refused");
	      }
	  }
      }

    # Get command filter, if set.
    my $cmd_filter = $self->config ("command filter");

    # Get restrict commands, if set, and parse them into a simpler format.
    my @restrict_commands = $self->config ("restrict command");

    foreach (@restrict_commands)
      {
	unless (/^"([a-zA-Z\s]+)"\s+(.*)/)
	  {
	    die "bad restrict command directive: restrict command: $_";
	  }

	my $pattern = uc $1;
	my $code = $2;

	# The pattern is something like "SITE WHO". Turn this into
	# a real regular expression "^SITE\s+WHO\b".
	$pattern =~ s/\s+/\\s+/g;
	$pattern = "^$pattern\\b";

	$_ = { pattern => $pattern, code => $code };
      }

    # Command the commands permitted when not authenticated.
    my %no_authentication_commands = ();

    if (defined $self->config ("no authentication commands"))
      {
	my @c = split /\s+/, $self->config ("no authentication commands");

	foreach (@c) { $no_authentication_commands{$_} = 1; }
      }
    else
      {
	%no_authentication_commands =
	  ("USER" => 1, "PASS" => 1, "LANG" => 1, "FEAT" => 1,
	   "HELP" => 1, "QUIT" => 1, "HOST" => 1);
      }

    # Start reading commands from the client.
  COMMAND:
    for (;;)
      {
	# Pre-command hook.
	$self->pre_command_hook;

	# Set an alarm to go off after so many seconds of idleness.
	alarm $self->{_idle_timeout};

	# Get next line of input from the client.
	# XXX This does not comply properly with RFC 2640 section 3.1 -
	# We should translate <CR><NUL> to <CR> and treat ONLY <CR><LF>
	# as a line ending character.
	last unless defined ($_ = <STDIN>);

	$self->_check_signals;

	# Immediately terminate if the parent died.
	# In standalone mode, this means the main daemon has terminated.
	# In inet mode, this means that inetd itself has terminated.
	# In either case, the system administrator may have new
	# configuration settings that need to be loaded so any current
	# FTP clients should not be able to run any new commands on the
	# old configuration for security reasons.
	if (getppid == 1)
	  {
	    $self->reply (421, "Manual Server Shutdown. Reconnect required.");
	    exit;
	  }

	# Restart alarm clock timer.
	alarm $self->{_idle_timeout};

	# When out-of-band data arrives (eg. when the client performs
	# an ABOR command), the client will send several telnet control
	# characters before the actual command. Drop those bytes now.
	s/^\377.// while m/^\377./;

	# Log client command if logging is enabled.
	$self->_log_line ($_)
	  unless /^PASS /i && $self->config ("hide passwords in client log");

	# Go slow?
	sleep $self->config ("command wait")
	  if $self->config ("command wait");

	# Remove trailing CRLF.
	s/[\n\r]+$//;

	# Command filter hook.
	$r = $self->command_filter_hook ($_);
	next if $r == -1;

	# Command filter.
	if ($r == 0)
	  {
	    if (defined $cmd_filter)
	      {
		unless ($_ =~ m/$cmd_filter/)
		  {
		    $self->reply (500,
				  "Command does not match command filter.");
		    next;
		  }
	      }

	    foreach my $rc (@restrict_commands)
	      {
		if ($_ =~ /$rc->{pattern}/i)
		  {
		    # Set up the variables.
		    my $hostname = $self->{peerhostname};
		    my $ip = $self->{peeraddrstring};
		    my $user = $self->{user};
		    my $class = $self->{class};
		    my $user_is_anonymous = $self->{user_is_anonymous};
		    my $type = $self->{type};
		    my $form = $self->{form};
		    my $mode = $self->{mode};
		    my $stru = $self->{stru};

		    my $rv = eval $rc->{code};
		    die if $@;

		    unless ($rv)
		      {
			$self->reply (500,
				  "Command restricted by site administrator.");
			next COMMAND;
		      }
		  }
	      }
	  }

	# Get the command.
	# See also RFC 2640 section 3.1.
	unless (m/^([A-Z]{3,4})\s?(.*)/i)
	  {
	    $self->log ("err",
			"badly formed command received: %s", _escape ($_));
	    $self->_log_line ("[Badly formed command]", _escape ($_));
	    exit 0;
	  }

	# The following strange 'eval' is necessary to work around a
	# very odd bug in Perl 5.6.0. The following assignment to
	# $cmd will fail in some cases unless you use $1 in some sort
	# of an expression beforehand.
	# - RWMJ 2002-07-05.
	eval '$1 eq $1';

	my ($cmd, $rest) = (uc $1, $2);

	$self->log ("info", "command: (%s, %s)",
		    _escape ($cmd), _escape ($rest))
	  if $self->{debug};

	# Command requires user to be authenticated?
	unless ($self->{authenticated} ||
		exists $no_authentication_commands{$cmd})
	  {
	    $self->reply (530, "Not logged in.");
	    next;
	  }

	# Handle the QUIT command specially.
	if ($cmd eq "QUIT")
	  {
	    $self->reply (221, "Goodbye. Service closing connection.");
	    last;
	  }

	# Got a command which matches in the table?
	unless (exists $self->{command_table}{$cmd})
	  {
	    $self->reply (500, "Unrecognized command.");
	    $self->log ("err",
			"unknown command received: %s", _escape ($_));
	    next;
	  }

	# Run the command.
	&{$self->{command_table}{$cmd}} ($self, $cmd, $rest);

	# Post-command hook.
	$self->post_command_hook ($cmd, $rest);

	# Write out any xferlog that may have built up from the command
	$self->xfer_flush if $self->{_xferlog};
      }

    $self->quit_hook ();

    unless ($self->{_test_mode})
      {
	$self->_log_line ("[ENDED BY CLIENT $self->{peeraddrstring}:$self->{peerport}]");
	$self->log ("info", "connection terminated normally");
      }

    # The return value is used by the test scripts.
    $self;
  }

# Signals are handled synchronously to get around the problem
# with unsafe signals which exists in Perl < 5.7.2. Call the
# following function periodically to check signals.
sub _check_signals
  {
    my $self = shift;

    if ($GOT_SIGURG)
      {
        $GOT_SIGURG  = 0;
        $self->_handle_sigurg;
      }

    if ($GOT_SIGCHLD)
      {
        $GOT_SIGCHLD = 0;
        $self->_handle_sigchld;
      }

    if ($GOT_SIGHUP)
      {
        $GOT_SIGHUP  = 0;
        $self->_handle_sighup;
      }

    if ($GOT_SIGTERM)
      {
        $GOT_SIGTERM = 0;
        $self->_handle_sigterm;
      }

  }

# Handle SIGURG signal in the parent process.
sub _handle_sigurg
  {
    my $self = shift;

    $self->{_urgent} = 1;
  }

# Handle SIGCHLD signal in the parent process.
sub _handle_sigchld
  {
    my $self = shift;

    # Clear up any zombie processes.
    while ((my $pid = waitpid (-1, WNOHANG)) > 0)
      {
	# Remove this PID from the children hash.
	delete $self->{_children}->{$pid};
      }
  }

# Handle SIGHUP signal synchronously in the parent process.
# This code mostly by Rob, rewritten and simplified by Rich for
# the new synchronous signal handling code. Note that this function
# has to be called synchronously (not from a signal handler, even
# in Perl >= 5.7.2) because otherwise the exec will happen with
# most signals blocked.
sub _handle_sighup
  {
    my $self = shift;

    # Clear FD_CLOEXEC bit on the listening socket because we are
    # intending to pass that socket to our exec'd child process.
    $self->{_ctrl_sock}->fcntl (F_SETFD, my $flags = "");

    # Make the socket available to the child process in the environment.
    $ENV{BIND} = $self->{_ctrl_sock}->fileno;

    # Print a message to syslog.
    $self->log ("info", "received SIGHUP, reloading");
    $self->_log_line ("[DAEMON Reloading]");

    # Restart self.
    exec ($0, @ARGV) or die "hup exec failed: $!";
  }

# Handle SIGTERM signal in the parent process.
sub _handle_sigterm
  {
    my $self = shift;

    $self->log ("info", "shutting down daemon");
    $self->_log_line ("[DAEMON Shutdown]");
    exit;
  }

# Added 20 Oct 2003 by Yair Lenga
# Rotating Log files - allow stftime '%' in the file name

sub _rotate_log
  {
    my $self = shift ;
    my $prop = "rotate log files";

    if (defined ($self->config($prop)) ? $self->config($prop) : 0)
      {
	$self->_open_error_log ;
	$self->_open_client_log ;
	$self->_open_xfer_log ;
      }
  }

sub _open_error_log
  {
    my $self = shift ;

    # Check for new error log (remember open log file in in _error_file)

    if ( my $log_file = $self->config("error log") ) {
      $log_file = $self->resolve_log_file_name($log_file) ;
      if (!defined $self->{_error_file} ||
	  $log_file ne $self->{_error_file}) {
	$self->log( 'notice', "Switch error log to $log_file") ;
	open STDERR, ">>$log_file"
	  or die "cannot append: $log_file: $!";
	$self->{_error_file} = $log_file;
      }
    }
    return 1
  }

sub _open_xfer_log
  {
    my $self = shift ;
    if ( my $log_file = $self->config("xfer logging") ) {
      $log_file = $self->resolve_log_file_name($log_file) ;
      if ( !defined $self->{_xfer_file} ||
          $log_file ne $self->{_xfer_file} ) {
	if ( my $io = $self->{_xferlog} ) {
	  $io->close ;
	  delete $self->{_xferlog} ;
	} ;
	$self->{_xfer_file} = $log_file;
	my $io = new IO::File $log_file, "a";
	if (defined $io) {
	  $io->autoflush (1);
	  $self->{_xferlog} = $io;
	  $self->log( 'notice', "Using xfer log: $log_file") ;
	} else {
	  die "cannot append: $log_file: $!";
	}
      }
    }
    return 1
  }

sub _open_client_log
  {
    my $self = shift ;
    if ( my $log_file = $self->config("client logging") ) {
      $log_file = $self->resolve_log_file_name($log_file) ;
      if (!defined $self->{_client_file} ||
          $log_file ne $self->{_client_file} ) {
	if ( my $io = $self->{_client_log} ) {
	  $io->close ;
	  delete $self->{_client_log} ;
	} ;
	$self->{_client_file} = $log_file;
	my $io = new IO::File $log_file, "a";
	if (defined $io) {
	  $io->autoflush (1);
	  $self->{_client_log} = $io;
	  $self->log( 'notice', "Starting client log: $log_file") ;
	} else {
	  die "cannot append: $log_file: $!";
	}
      }
    }
  }

sub resolve_log_file_name
  {
    my ($self, $log_file) = @_ ;

    $log_file =~ s/\$(\w+)/$self->{$1}/g
      if $log_file =~ /\$/ ;
    $log_file = strftime($log_file, localtime())
      if $log_file =~ /\%/ ;
    return $log_file;
  }

# Added 21 Feb 2001 by Rob Brown
# Client command logging
sub _log_line
  {
    my $self = shift;
    return unless exists $self->{_client_log};
    my $message = join ("",@_);
    my $io = $self->{_client_log};
    my $time = scalar localtime;
    my $authenticated = $self->{authenticated} ? $self->{user} : "-";
    $message =~ s/\n*$/\n/;
    $io->print ("[$time][$$:$authenticated]$message");
  }

# Added 08 Feb 2001 by Rob Brown
# Safely saves the process id to the specified pidfile.
# If no pidfile is specified, nothing happens.
sub _save_pid
  {
    my $self = shift;

    # Store pid into pidfile?
    $self->{_pidfile} = $self->config ("pidfile");

    if (defined $self->{_pidfile})
      {
	my $pidfile = $self->{_pidfile};

	# Swap $VARIABLE with corresponding attribute (i.e., $hostname)
	$pidfile =~ s/\$(\w+)/$self->{$1}/g;
	if ($pidfile =~ m%^([/\w\-\.]+)$%)
	  {
	    $self->{_pidfile} = $1;
	    open (PID, ">$self->{_pidfile}")
	      or die "cannot write $pidfile: $!";
	    print PID "$$\n";
	    close PID;
	    eval "END {unlink('$1') if \$\$ == $$;}";
	  }
	else
	  {
	    die "Refusing to create weird looking pidfile: $pidfile";
	  }
      }
  }

# Set a resource limit, by using the BSD::Resource module, if available.

sub _set_rlimit
  {
    my $self = shift;
    my $name = shift;
    my $value = shift;

    # The BSD::Resource module is optional, and may not be available.
    if (exists $INC{"BSD/Resource.pm"} &&
	exists get_rlimits()->{$name})
      {
	setrlimit (&{$ {BSD::Resource::}{$name}}, $value, $value)
	  or die "setrlimit: $!";
      }
    else
      {
	warn
	  "Resource limit $name cannot be set. This may be because ",
	  "the BSD::Resource module is not available on your ",
	  "system, or it may be because your operating system ",
	  "does not support $name. Without resource limits, the ",
	  "FTP server may be open to denial of service (DoS) ",
	  "attacks. The real error was: $@";
      }
  }

# Check for an external program (eg. "gzip"). This test is not
# bulletproof: In particular, it requires $PATH to be set correctly
# at the top of this file or in the config file.

sub _find_prog
  {
    my $self = shift;
    my $prog = shift;

    my @paths = split /:/, $ENV{PATH};
    foreach (@paths)
      {
	return 1 if -x "$_/$prog";
      }
    return 0;
  }

# This subroutine loads the command line options and configuration file
# and resolves conflicts. Command line options have priority over
# certain things in the configuration file.

sub _get_configuration
  {
    my $self = shift;
    my $args = shift;
    local @ARGV = @$args;

    my ($debug, $help, $port, $s_option, $S_option,
	$pidfile, $show_version, @overrides);

    Getopt::Long::Configure ("no_ignore_case");
    Getopt::Long::Configure ("pass_through");

    GetOptions (
		"C=s" => \$self->{_config_file},
		"d+" => \$debug,
		"help|?" => \$help,
		"o=s" => \@overrides,
		"p=i" => \$port,
		"P=s" => \$pidfile,
		"s" => \$s_option,
		"S" => \$S_option,
		"test" => \$self->{_test_mode},
		"v+" => \$debug,
		"V" => \$show_version,
	       );

    # Show version and exit?
    if ($show_version)
      {
	print $self->{version_string}, "\n";
	exit 0;
      }

    # Show help and exit?
    if ($help)
      {
	my $name = $0;
	$name =~ s,.*/,,;

	print <<EOT;
$name: $self->{version_string}

Usage:
  $name [-options]

Options:
  -?, --help            Print this help text and exit.
  -d, -v                Debug mode on.
  -p port               Specify listening port (defaults to FTP port, 21).
  -s                    Run in daemon mode (default: run from inetd).
  -S                    Run in background and in daemon mode.
  -V                    Show version information and exit.
  -C config_file        Specify configuration file (default: /etc/ftpd.conf).
  -P pidfile            Save process ID into pidfile.
  -o option=value       Override configuration file options.

Normal standalone usage:

  $name -S

Normal usage from inetd:

  ftp stream tcp nowait root /usr/sbin/tcpd $name

For further information, please read the full documentation in the
Net::FTPServer(3) manual page.
EOT
	exit 0;
      }

    # Read the configuration file.
    $self->{_config} = {};
    $self->{_config_ip_host} = {};
    $self->_open_config_file ($self->{_config_file});

    # Magically update configuration values with command line
    # argument values. Thus configuration entered on the command
    # line will override those present in the configuration file.
    if ($port)
      {
	$self->_set_config ("port", $port, splat => 1);
      }
    if ($s_option)
      {
	$self->_set_config ("daemon mode", 1, splat => 1);
      }
    if ($S_option)
      {
	$self->_set_config ("daemon mode", 1, splat => 1);
	$self->_set_config ("run in background", 1, splat => 1);
      }
    if ($pidfile)
      {
	$self->_set_config ("pidfile", $pidfile, splat => 1);
      }

    # Override other configuration file options.
    foreach (@overrides)
      {
	my ($key, $value) = split /=/, $_, 2;
	$self->_set_config ($key, $value, splat => 1);
      }

    # Set debugging state.
    if (defined $debug) {
      $self->{debug} = 1
    } elsif (defined $self->config ("debug")) {
      $self->{debug} = $self->config ("debug")
    }
  }

# Fork into the background (command line -S option).

sub _fork_into_background
  {
    my $self = shift;

    my $pid = fork;
    die "fork: $!" unless defined $pid;

    # Parent process ends here.
    exit if $pid > 0;

    # Start a new session.
    setsid;

    # Close connection to tty and reopen 0, 1 as /dev/null.
    # Note that 2 points to the error log.
    open STDIN, "</dev/null";
    open STDOUT, ">>/dev/null";

#   $self->log ("info", "forked into background");
  }

# Be a daemon (command line -s option).

sub _be_daemon
  {
    my $self = shift;

#   $self->log ("info", "operating in daemon mode");
    $self->_log_line ("[DAEMON Started]");

    # Jump to a safe place because this is a deamon
    chdir "/";

    # If the process receives SIGHUP, then it passes in the socket
    # fd here through the BIND environment variable. Check for this,
    # because if so we don't need to open a new listening socket.
    if (exists $ENV{BIND} && $ENV{BIND} =~ /^(\d+)$/)
      {
	my $bind_fd = $1;
	"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
	$self->{_ctrl_sock} = new IO::Socket::INET;
	$self->{_ctrl_sock}->fdopen ($bind_fd, "w")
	  or die "socket: $!";
      }
    # Otherwise do open a new listening socket.
    else
      {
	# Discover the default FTP port from /etc/services or equivalent.
	my $default_port = getservbyname ("ftp", "tcp") || 21;

	# Construct argument list to socket.
	my @args = (Reuse => 1,
		    Proto => "tcp",
		    Type => SOCK_STREAM,
		    LocalPort =>
		    (defined $self->config ("port")
		       ? $self->config ("port")
		       : $default_port));

	# Get length of listen queue.
	if (defined $self->config ("listen queue")) {
	  push @args, Listen => $self->config ("listen queue");
	} else {
	  push @args, Listen => 10;
	}

	# Get the local bind address.
	if (defined $self->config ("local address")) {
	  push @args, LocalAddr => $self->config ("local address")
	}

	# Open a socket on the control port.
	"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
	$self->{_ctrl_sock} =
	  new IO::Socket::INET (@args)
	    or die "socket: $!";
      }

    # Set TCP keepalive?
    if (defined $self->config ("tcp keepalive"))
      {
	$self->{_ctrl_sock}->sockopt (SO_KEEPALIVE, 1)
	  or warn "setsockopt: SO_KEEPALIVE: $!";
      }

    # Initialize the children hash ref for max clients enforcement
    $self->{_children} = {};

    $self->post_bind_hook;

    # Accept new connections and fork off new process to handle it.
    for (;;)
      {
	# Possibly rotate the log files to a new name.
	$self->_rotate_log ;

	$self->pre_accept_hook;
	if (!$self->{_ctrl_sock}->opened)
	  {
	    die "control socket crashed somehow";
	  }

	# ACCEPT may be undefined if, for example, the TCP-level 3-way
	# handshake is not completed. If this happens, all we really want
	# to do is to retry the accept, not die. Thanks to
	# Rob Brown for pointing this one out :-)

	# Because we are now handling signals synchronously, and because
	# signals are restartable, we want to periodically check for
	# signals. Thus the following code swaps between blocking on the
	# accept for 3 seconds and checking signals. The load on the
	# processor is insignificant (if you're worried about the load,
	# perhaps you should be using inetd?).

	my $sock;

        my $selector = new IO::Select;
        $selector->add ($self->{_ctrl_sock});

        until (defined $sock)
          {
            my @ready = $selector->can_read (3);

            $self->_check_signals;

            if (@ready > 0)
            {
              $sock = $self->{_ctrl_sock}->accept;
              warn "accept: $!" unless defined $sock;
            }
          }

	# Possibly rotate the log files to a new name.
	$self->_rotate_log ;

	if ($self->concurrent_connections >= $self->{_max_clients})
	  {
	    $sock->print ("500 ".
			  $self->_percent_substitutions ($self->{_max_clients_message}).
			  "\r\n");
	    $sock->close;
	    warn "Max connections $self->{_max_clients} reached!";
	    $self->_log_line ("[Max connections $self->{_max_clients} reached]");
	    next;
	  }

	# Fork off a process to handle this connection.
	my $pid = fork;
	if (defined $pid)
	  {
	    if ($pid == 0)		# Child process.
	      {
		$self->log ("info", "starting child process")
		  if $self->{debug};

		# Don't handle SIGCHLD in the child process, in case the
		# personality tries to launch subprocesses.
		$SIG{CHLD} = "DEFAULT";

		# SIGHUP in the child process exits immediately.
		$SIG{HUP} = sub {
		  $self->log ("info", "exiting on HUP signal");
		  exit;
		};

		$SIG{TERM} = sub {
		  $self->log ("info", "exiting on TERM signal");
		  $self->reply (421, "Manual shutdown from server");
		  $self->_log_line ("[TERM RECEIVED]");
		  exit;
		};

		# Wipe the hash within the child process to save memory
		$self->{_children} = $self->concurrent_connections;

		# Shutdown accepting file descriptor to allow successful
		# port bind() in case of a future daemon restart
		$self->{_ctrl_sock}->close;

		# Duplicate the socket so it looks like we were called
		# from inetd.
		dup2 ($sock->fileno, 0);
		dup2 ($sock->fileno, 1);

		# Return to the main process to handle the rest of
		# the connection.
		return;
	      }			# End of child process.
	  }
	else			# Error during fork(2).
	  {
	    warn "fork: $!";
	    sleep 5;		# Back off in case system is overloaded.
	  }

	# A child has been successfully spawned.
	# So don't forget the kid's birthday!
	$self->{_children}->{$pid} = time;
      }				# End of for (;;) loop in ftpd parent process.
  }

sub concurrent_connections
  {
    my $self = shift;

    if (exists $self->{_children})
      {
	if (ref $self->{_children})
	  {
	    # Main Parent Server (exactly accurate)
	    return scalar keys %{$self->{_children}};
	  }
	else
	  {
	    # Child Process (slightly outdated count)
	    return $self->{_children};
	  }
      }
    else
      {
	# Not running as a daemon (eg. running from inetd). We don't
	# know the number of connections, but it's not likely to be
	# high, so just return 1.
	return 1;
      }
  }

# Open configuration file and prepare to read configuration.

sub _open_config_file
  {
    my $self = shift;
    my $config_file = shift;

    my $config = new IO::File "<$config_file";
    unless ($config)
      {
	die "cannot open configuration file: $config_file: $!";
      }

    my $lineno = 0;
    my $sitename;

    # Read in the configuration options from the file.
    while (defined ($_ = $config->getline))
      {
	$lineno++;

	# Remove trailing \n and \r.
	s/[\n\r]+$//;

	# Ignore blank lines and comments.
	next if /^\s*\#/;
	next if /^\s*$/;

	# More lines?
	while (/\\$/)
	  {
	    $_ =~ s/\\$//;
	    my $nextline = $config->getline;
	    $nextline =~ s/^\s+//;
	    $nextline =~ s/[\n\r]+$//;
	    $_ .= $nextline;
	    $lineno++;
	  }

	# Special treatment: <Include> files.
	if (/^\s*<Include\s+(.*)>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: cannot use <Include> inside a <Host> section. It will not do what you expect. See the Net::FTPServer(3) manual page for information.";
	      }

	    $self->_open_config_file ($1);
	    next;
	  }

	# Special treatment: <IncludeWildcard> files.
	if (/^\s*<IncludeWildcard\s+(.*)>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: cannot use <IncludeWildcard> inside a <Host> section. It will not do what you expect. See the Net::FTPServer(3) manual page for information.";
	      }

	    my @files = sort glob $1;
	    foreach (@files)
	      {
		$self->_open_config_file ($_);
	      }
	    next;
	  }

	# Special treatment: <Host> sections.
	if (/^\s*<Host\s+(.*)>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: unfinished <Host> section";
	      }

	    $sitename = $1;
	    next;
	  }

	if (/^\s*<\/Host>\s*$/i)
	  {
	    unless ($sitename)
	      {
		die "$config_file:$lineno: unmatched </Host>";
	      }

	    $sitename = undef;
	    next;
	  }

	# Special treatment: <Perl> sections.
	if (/^\s*<Perl>\s*$/i)
	  {
	    if ($sitename)
	      {
		die "$config_file:$lineno: cannot use <Perl> inside a <Host> section. It will not do what you expect. See the Net::FTPServer(3) manual page for information on the %host_config variable.";
	      }

	    # Suck in lines verbatim until we reach the end of this section.
	    my $perl_code = "";

	    while (defined ($_ = $config->getline))
	      {
		$lineno++;
		last if /^\s*<\/Perl>\s*$/i;
		$perl_code .= $_;
	      }

	    unless ($_)
	      {
		die "$config_file:$lineno: unfinished <Perl> section";
	      }

	    # Untaint this code: it comes from a trusted source, namely
	    # the configuration file.
	    $perl_code =~ /(.*)/s;
	    $perl_code = $1;

#	    warn "executing perl code:\n$perl_code\n";

	    # Run it. It will write into local variables %config and
	    # %host_config.
	    my %config;
	    my %host_config;

	    eval $perl_code;
	    if ($@)
	      {
		die "$config_file:$lineno: $@";
	      }

	    # Examine what it's written into %config and %host_config
	    # and add those to the configuration.
	    foreach (keys %config)
	      {
		my $value = $config{$_};

		unless (ref $value) {
		  $self->_set_config ($_, $value,
				      file => $config_file, line => $lineno);
		} else {
		  foreach my $v (@$value) {
		    $self->_set_config ($_, $v,
					file => $config_file, line =>$lineno);
		  }
		}
	      }

	    my $host;
	    foreach $host (keys %host_config)
	      {
		foreach (keys %{$host_config{$host}})
		  {
		    my $value = $host_config{$host}{$_};

		    unless (ref $value) {
		      $self->_set_config ($_, $value,
					  sitename => $host,
					  file => $config_file,
					  line => $lineno);
		    } else {
		      foreach my $v (@$value) {
			$self->_set_config ($_, $v,
					    sitename => $host,
					    file => $config_file,
					    line => $lineno);
		      }
		    }
		  }
	      }

	    next;
	  }

	if (/^\s*<\/Perl>\s*$/i)
	  {
	    die "$config_file:$lineno: unmatched </Perl>";
	  }

	# Split the line on the first : character.
	unless (/^(.*?):(.*)$/)
	  {
	    die "$config_file:$lineno: syntax error in configuration file";
	  }

	my $key = $1;
	my $value = $2;

	$key =~ s/^\s+//;
	$key =~ s/\s+$//;

	$value =~ s/^\s+//;
	$value =~ s/\s+$//;

	$self->_set_config ($key, $value,
			    sitename => $sitename,
			    file => $config_file,
			    line => $lineno);
      }
  }

sub _set_config
  {
    my $self = shift;
    my $key = shift;
    my $value = shift;
    my %params = @_;

    my $sitename = $params{sitename};
    my $config_file = $params{file} || "no file";
    my $lineno = $params{line} || "0";
    my $splat = $params{splat};

    # Convert the key to standard form so that small errors in the
    # FTP config file won't matter too much.
    $key = lc ($key);
    $key =~ tr/ / /s;

    # If the key is ``ip:'' then we treat it specially - adding it
    # to a hash from IP addresses to sites.
    if ($key eq "ip")
      {
	unless ($sitename)
	  {
	    print STDERR "$config_file:$lineno: ``ip:'' must only appear inside a <Host> section. See the Net::FTPServer(3) manual page for more information.\n";
	    exit 1;
	  }

	$self->{_config_ip_host}{$value} = $sitename;
      }

    # Prefix the sitename, if defined.
    $key = "$sitename:$key" if $sitename;

#    warn "configuration ($key, $value)";

    # Save this.
    $self->{_config}{$key} = [] if $splat || ! exists $self->{_config}{$key};
    push @{$self->{_config}{$key}}, $value;
  }

# Before printing something received from the user to syslog, escape
# any strange characters using this function.

sub _escape
  {
    local $_ = shift;
    s/([^ -~])/sprintf ("\\x%02x", ord ($1))/ge;
    $_;
  }

=item $regex = $ftps->wildcard_to_regex ($wildcard)

This is a general library function shared between many of
the back-end database personalities. It converts a general
wildcard (eg. *.c) into a regular expression (eg. ^.*\.c$ ).

Thanks to: Terrence Monroe Brannon E<lt>terrence.brannon@oracle.comE<gt>.

=cut

sub wildcard_to_regex
  {
    my $self = shift;
    my $wildcard = shift;

    $wildcard =~ s,([^?*a-zA-Z0-9]),\\$1,g; # Escape punctuation.
    $wildcard =~ s,\*,.*,g; # Turn * into .*
    $wildcard =~ s,\?,.,g;  # Turn ? into .
    $wildcard = "^$wildcard\$"; # Bracket it.

    $wildcard;
}

=item $regex = $ftps->wildcard_to_sql_like ($wildcard)

This is a general library function shared between many of
the back-end database personalities. It converts a general
wildcard (eg. *.c) into the strange wildcardish format
used by SQL LIKE operator (eg. %.c).

=cut

sub wildcard_to_sql_like
  {
    my $self = shift;
    my $wildcard = shift;

    $wildcard =~ s/%/\\%/g;     # Escape any existing % and _.
    $wildcard =~ s/_/\\_/g;
    $wildcard =~ tr/*?/%_/;     # Translate to wierdo format.

    $wildcard;
}

=item $ftps->reply ($code, $line, [$line, ...])

This function sends a standard single line or multi-line FTP
server reply to the client. The C<$code> should be one of the
standard reply codes listed in RFC 959. The one or more
C<$line> arguments are the (free text) of the reply. Do
I<not> include carriage returns at the end of each C<$line>.
This function adds the correct line ending format as specified
in the RFC.

=cut

sub reply
  {
    my $self = shift;

    my $code = shift;
    die "response code $code is not in RFC 959 format"
      unless $code =~ /^[1-5][0-5][0-9]$/;

    die "reply must contain one or more lines of text"
      unless @_ > 0;

    if (@_ == 1)		# Single-line response.
      {
	print $code, " ", $_[0], "\r\n";
      }
    else			# Multi-line response.
      {
	for (my $i = 0; $i < @_-1; ++$i)
	  {
	    print $code, "-", $_[$i], "\r\n";
	  }
	print $code, " ", $_[@_-1], "\r\n";
      }

    $self->log ("info", "reply: $code") if $self->{debug};
  }

=item $ftps->log ($level, $message, ...);

This function is identical to the normal C<syslog> function
to be found in C<Sys::Syslog>. However, it only uses syslog
if the C<enable syslog> configuration option is set to true.

Use this function instead of calling C<syslog> directly.

=cut

sub log
  {
    my $self = shift;

    Sys::Syslog::syslog @_ if $self->{_enable_syslog};
  }

=pod

=item $ftps->config ($name);

Read configuration option C<$name> from the configuration file.

=cut

sub config
  {
    my $self = shift;
    my $key = shift;

    # Convert the key to standard form.
    $key = lc ($key);
    $key =~ tr/ / /s;

    # Try site-specific configuration option.
    if ($self->{sitename} &&
	exists $self->{_config}{"$self->{sitename}:$key"})
      {
	unless (wantarray)
	  {
	    # Return scalar value, but warn if there are many values
	    # for this configuration operation.
	    if (@{$self->{_config}{"$self->{sitename}:$key"}} > 1)
	      {
		warn "called config in scalar context for an array valued key: $key";
	      }

	    return $self->{_config}{"$self->{sitename}:$key"}[0];
	  }
	else
	  {
	    return @{$self->{_config}{"$self->{sitename}:$key"}};
	  }
      }

    # Try global configuration option.
    if (exists $self->{_config}{$key})
      {
	unless (wantarray)
	  {
	    # Return scalar value, but warn if there are many values
	    # for this configuration operation.
	    if (@{$self->{_config}{$key}} > 1)
	      {
		warn "called config in scalar context for an array valued key: $key";
	      }

	    return $self->{_config}{$key}[0];
	  }
	else
	  {
	    return @{$self->{_config}{$key}};
	  }
      }

    # Nothing found.
    unless (wantarray) { return undef } else { return () }
  }

=pod

=item $ftps->ip_host_config ($ip_addr);

Look for a E<lt>HostE<gt> section which contains "ip: $ip_addr".
If one is found, return the site name of the Host section. Otherwise
return undef.

=cut

sub ip_host_config
  {
    my $self = shift;
    my $ip_addr = shift;

    if (exists $self->{_config_ip_host}{$ip_addr})
      {
	return $self->{_config_ip_host}{$ip_addr};
      }

    return undef;
  }

sub _archive_filter_Z
  {
    my $self = shift;
    my $sock = shift;

    return archive_filter_external ($self, $sock, "compress");
  }

sub _archive_filter_gz
  {
    my $self = shift;
    my $sock = shift;

    return archive_filter_external ($self, $sock, "gzip");
  }

sub _archive_filter_bz2
  {
    my $self = shift;
    my $sock = shift;

    return archive_filter_external ($self, $sock, "bzip2");
  }

sub _archive_filter_uue
  {
    my $self = shift;
    my $sock = shift;

    return archive_filter_external ($self, $sock, "uuencode", "file");
  }

=pod

=item $filter = $ftps->archive_filter_external ($sock, $cmd [, $args]);

Apply C<$cmd> as a filter to socket C<$sock>. Returns a hash reference
which contains the following keys:

  sock      Newly opened socket.
  pid       PID of filter program.

If it fails, returns C<undef>.

See section ARCHIVE MODE elsewhere in this manual for more information.

=cut

sub archive_filter_external
  {
    my $self = shift;
    my $sock = shift;

    my ($new_sock, $pid) = (FileHandle->new);

    # Perl is forcing me to go through unnecessary hoops here ...
    open AFE_SOCK, ">&" . fileno ($sock) or die "dup: $!";
    close $sock;

    eval {
      $pid = open2 (">&AFE_SOCK", $new_sock, @_);
    };
    if ($@)
      {
	if ($@ =~ /^open2:/)
	  {
	    warn (join (" ", @_), ": ", $@);
	    return undef;
	  }
	die;
      }

    # According to the open2 documentation, it should close AFE_SOCK
    # for me. Apparently not, so I'll close it myself.
    close AFE_SOCK;

    my %filter_object = (sock => $new_sock, pid => $pid);

    return \%filter_object;
  }

sub _archive_generator_list
  {
    my $self = shift;
    my $dirh = shift;

    my @files = ();

    # Recursively visit all files and directories contained in $dirh.
    $self->visit
      ($dirh,
       { 'f' =>
	 sub {
	   push @files, $_->pathname;
	 },
	 'd' =>
	 sub {
	   my $pathname = $_->pathname;

	   push @files, $pathname;

	   # Only visit a directory if we are allowed to by the list rule.
	   # Otherwise this could be used as a backdoor way to list
	   # forbidden directories.
	   return $self->_eval_rule ("list rule",
				     undef, undef, $pathname);
	 }
       }
      );

    my $str = join ("\n", @files) . "\n";

    return new IO::Scalar \$str;
  }

sub _archive_generator_zip
  {
    my $self = shift;
    my $dirh = shift;

    # Create the zip file.
    my $zip = Archive::Zip->new ();

    # Recursively visit all files and directories contained in $dirh.
    $self->visit
      ($dirh,
       { 'f' =>
	 sub {
	   my $fileh = $_;

	   if ($self->_eval_rule ("retrieve rule",
				  $fileh->pathname,
				  $fileh->filename,
				  $fileh->dirname))
	       {
		 # Add file to archive. Archive::Zip has a nice
		 # extensible "Member" concept. We create our own
		 # member type (Net::FTPServer::ZipMember) which understands
		 # our own file handles and serves them back to the
		 # main Archive::Zip program on demand. This means
		 # that at most only a small part of the file is
		 # held in memory at any one time.
		 my $memb
		   = Net::FTPServer::ZipMember->_newFromFileHandle ($fileh);

		 unless ($memb)
		   {
		     warn "zip: error reading ", $fileh->filename, ": ",
		     $self->system_error_hook, " (ignored)";
		     return;
		   }

		 $zip->addMember ($memb);
		 $memb->desiredCompressionMethod
		   (&{$ {Archive::Zip::}{COMPRESSION_DEFLATED}});
		 $memb->desiredCompressionLevel (9);
	       }
	 },
	 'd' =>
	 sub {
	   # Only visit a directory if we are allowed to by the list rule.
	   # Otherwise this could be used as a backdoor way to list
	   # forbidden directories.
	   return $self->_eval_rule ("list rule", undef, undef, $_->pathname);
	 }
       }
      );

    # Is a temporary directory available? Is it writable? If so, dump
    # the ZIP file there. Otherwise, write it to an IO::Scalar (ie. in
    # memory).
    my $tmpdir =
      defined $self->config ("archive zip temporaries")
      ? $self->config ("archive zip temporaries")
      : "/tmp";

    my $file;

    if ($tmpdir)
      {
	my $tmpname = "$tmpdir/ftps.az.tmp.$$";
	$file = new IO::File ($tmpname, "w+");

	if ($file)
	  {
	    unlink $tmpname;
	    $zip->writeToFileHandle ($file, 1) == &{$ {Archive::Zip::}{AZ_OK}}
	      or die "failed to write to zip file: $!";
	    $file->seek (0, 0);
	  }
      }

    unless ($file)
      {
	$file = new IO::Scalar;
	$zip->writeToFileHandle ($file, 1) == &{$ {Archive::Zip::}{AZ_OK}}
	  or die "failed to write to zip file: $!";
	$file->seek (0, 0);
      }

    return $file;
  }

=pod

=item $ftps->visit ($dirh, \%functions);

The C<visit> function recursively "visits" every file and directory
contained in C<$dirh> (which must be a directory handle).

C<\%functions> is a reference to a hash of file types to functions.
For example:

  'f' => \&visit_file,
  'd' => \&visit_directory,
  'l' => \&visit_symlink,
  &c.

When a file of the known type is encountered, the appropriate
function is called with C<$_> set to the file handle. (All functions
are optional: if C<visit> encounters a file with a type not listed
in the C<%functions> hash, then that file is just ignored).

The return value from functions is ignored, I<except> for the
return value from the directory ('d') function. The directory
function should return 1 to indicate that C<visit> should recurse
into that directory. If the directory function returns 0, then
C<visit> will skip that directory.

C<visit> will call the directory function once for C<$dirh>.

=cut

sub visit
  {
    my $self = shift;
    my $dirh = shift;
    my $functions = shift;

    my $recurse = 1;

    if (exists $functions->{d})
      {
	local $_ = $dirh;
	$recurse = &{$functions->{d}} ();
      }

    if ($recurse)
      {
	my $files = $dirh->list_status ();

	my $file;
	foreach $file (@$files)
	  {
	    my $mode = $file->[2][0];
	    my $fileh = $file->[1];

	    if ($mode eq 'd')
	      {
		$self->visit ($fileh, $functions);
	      }
	    elsif (exists $functions->{$mode})
	      {
		local $_ = $fileh;
		&{$functions->{$mode}} ();
	      }
	  }
      }
  }

sub _HOST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # HOST with no parameters just prints out the current site name.
    if ($rest eq "")
      {
	if ($self->{sitename}) {
	  $self->reply (200, "HOST is set to $self->{sitename}.");
	} else {
	  $self->reply (200, "HOST is not set.");
	}
	return;
      }

    # The user may only issue HOST before log in.
    if ($self->{authenticated})
      {
	$self->reply (501, "Cannot issue HOST command after logging in.");
	return;
      }

    # You cannot change HOST.
    if ($self->{sitename} && $self->{sitename} ne $rest)
      {
	$self->reply (501, "HOST already set to $self->{sitename}.");
	return;
      }

    # Check that the name is reasonable.
    unless ($rest =~ /^[-a-z0-9.]+$/i)
      {
	$self->reply (501, "HOST syntax error.");
	return;
      }

    # Allow the change.
    $self->{sitename} = $rest;
    $self->reply (200, "HOST set to $self->{sitename}.");
  }

sub _USER_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If the user issues this command when logged in, generate an error.
    # We have to do this basically because of chroot and setuid stuff we
    # can't ``relogin'' as a different user.
    if ($self->{authenticated})
      {
	$self->reply (503, "You are already logged in.");
	return;
      }

    # Just save the username for now.
    $self->{user} = $rest;

    # Tried to log in anonymously?
    if ($rest eq "ftp" || $rest eq "anonymous")
      {
	unless ($self->config ("allow anonymous"))
	  {
	    $self->reply (421, "Anonymous logins not permitted.");
	    $self->_log_line ("[No anonymous allowed]");
	    exit 0;
	  }

	$self->{user_is_anonymous} = 1;
      }
    else
      {
	delete $self->{user_is_anonymous};
      }

    unless ($self->{user_is_anonymous})
      {
	$self->reply (331, "Username OK, please send password.");
      }
    else
      {
	$self->reply (331, "Anonymous login OK, please send your email address as password.");
      }
  }

sub _PASS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If the user issues this command when logged in, generate an error.
    if ($self->{authenticated})
      {
	$self->reply (503, "You are already logged in.");
	return;
      }

    # Have we received a username?
    unless ($self->{user})
      {
	$self->reply (503, "Please send your username first.");
	return;
      }

    # If this is an anonymous login, check that the password conforms.
    my @anon_passwd_warning = ();

    if ($self->{user_is_anonymous})
      {
	my $cktype = $self->config ("anonymous password check") || "none";
	my $enforce = $self->config ("anonymous password enforce") || 0;

	# If the password ends with @, append hostname.
	my $hostname
	  = $self->{peerhostname} ?
	    $self->{peerhostname} :
	    $self->{peeraddrstring};

	$rest .= $hostname if $rest =~ /\@$/;

	if ($cktype ne "none")
	  {
	    my $valid;

	    if ($cktype eq "rfc822")
	      {
		$valid = $self->_anon_passwd_validate_rfc822 ($rest);
	      }
	    elsif ($cktype eq "nobrowser")
	      {
		$valid = $self->_anon_passwd_validate_nobrowser ($rest);
	      }
	    elsif ($cktype eq "trivial")
	      {
		$valid = $self->_anon_passwd_validate_trivial ($rest);
	      }
	    else
	      {
		die "unknown password check type: $cktype";
	      }

	    # Defer the warning until later on in the function.
	    unless ($valid)
	      {
		push @anon_passwd_warning,
		"The response \"$rest\" is not valid.",
		"Please use your email address as your password.",
		"  For example: joe\@$hostname",
		"($hostname will be added if password ends with \@).";
	      }

	    # ... unless we have been told to enforce it now.
	    if ($enforce && !$valid)
	      {
		$self->reply (530, @anon_passwd_warning);
		return;
	      }
	  }
      }

    # OK, now the real authentication check.
    my $fail_code =
      $self->authentication_hook ($self->{user}, $rest,
				  $self->{user_is_anonymous}) ;

    if ( $fail_code < 0 )
      {
	# See RFC 2577 section 5.
	sleep 5 unless $fail_code == -2 ;

	# Login failed.
	$self->{loginattempts}++;

	if ($self->{loginattempts} >=
	    ($self->config ("max login attempts") || 3))
	  {
	    $self->log ("notice", "repeated login attempts from %s:%d",
			   $self->{peeraddrstring},
			   $self->{peerport});

	    # See RFC 2577 section 5.
	    $self->reply (421, "Too many login attempts. Goodbye.");
	    $self->_log_line ("[Max logins reached]");
	    exit 0;
	  }

	$self->reply (530, "Login failed.");
	return;
      }

    # Perform user access control step.
    unless ($self->_eval_rule ("user access control rule"))
      {
	$self->reply (421, "User denied by server configuration. Goodbye.");
	$self->_log_line ("[Client denied]");
	exit;
      }

    # Login was officially OK.
    $self->{authenticated} = 1;

    # Compute user's class.
    $self->{class} =
      $self->_username_to_class ($rest, $self->{user_is_anonymous});

    # Compute home directory. We may need it when we display the
    # welcome message.
    unless ($self->{user_is_anonymous})
      {
	if (defined $self->config ("home directory"))
	  {
	    $self->{home_directory} = $self->config ("home directory");

	    $self->{home_directory} =~ s/%m/(getpwnam $self->{user})[7]/ge;
	    $self->{home_directory} =~ s/%U/$self->{user}/ge;
	    $self->{home_directory} =~ s/%%/%/g;
	  }
	else
	  {
	    $self->{home_directory} = (getpwnam $self->{user})[7] || "/";
	  }
      }
    else
      {
	# Anonymous users always get "/" as their home directory.
	$self->{home_directory} = "/";
      }

    # Send a welcome message -- before the chroot since we may
    # need to read a file in the real root.
    my $welcome_type = $self->config ("welcome type") || "normal";

    if ($welcome_type eq "normal")
      {
	if (! $self->{user_is_anonymous})
	  {
	    $self->reply (230,
			  @anon_passwd_warning,
			  "Welcome " . $self->{user} . ".");
	  }
	else
	  {
	    $self->reply (230,
			  @anon_passwd_warning,
			  "Welcome $rest.");
	  }
      }
    elsif ($welcome_type eq "text")
      {
	my $welcome_text = $self->config ("welcome text")
	  or die "welcome type is text, but no welcome text configuration value";

	$welcome_text = $self->_percent_substitutions ($welcome_text);

	$self->reply (230,
		      @anon_passwd_warning,
		      $welcome_text);
      }
    elsif ($welcome_type eq "file")
      {
	my $welcome_file = $self->config ("welcome file")
	  or die "welcome type is file, but no welcome file configuration value";

	my @lines = ();

	if (my $io = new IO::File $welcome_file, "r")
	  {
	    while (<$io>) {
	      s/[\n\r]+$//;
	      push @lines, $self->_percent_substitutions ($_);
	    }
	    $io->close;
	  }
	else
	  {
	    @lines =
	      ( "The server administrator has configured a welcome file,",
		"but the file is missing." );
	  }

	$self->reply (230, @anon_passwd_warning, @lines);
      }
    else
      {
	die "unknown welcome type: $welcome_type";
      }

    # Set the timezone for responses.
    $ENV{TZ} = defined $self->config ("time zone")
      ? $self->config ("time zone")
      : "GMT";

    # Patch fom John Jetmore <jetmore@cinergycom.com>.  The following
    # line is necessary to open /etc/localtime in the chroot environment.
    scalar (localtime (time));

    # Open /etc/protocols etc., in case we chroot. And yes, doing the
    # setprotoent _twice_ is necessary to work around a bug in Perl or
    # glibc (thanks Abraham Ingersoll <abe@dajoba.com>). Jamie Hill
    # <hill@cinergycom.com> says that the getprotobyname ("tcp") call
    # is necessary for Solaris too.
    setprotoent 1;
    setprotoent 1;
    $_ = getprotobyname ("tcp");
    sethostent 1;
    setnetent 1;
    setservent 1;
    setpwent;
    setgrent;

    # Perform chroot, etc., as required.
    $self->user_login_hook ($self->{user},
			    $self->{user_is_anonymous});

    # Set CWD to /.
    $self->{cwd} = $self->root_directory_hook;

    # Move to home directory.
    my $new_cwd;

    if ($new_cwd = $self->_chdir ($self->{cwd}, $self->{home_directory}))
      {
	$self->{cwd} = $new_cwd;
      }
    else
      {
	$self->log ("warning",
		    "no home directory for user: $self->{user}");
      }

  }

# Convert a username to a class by using the class directives
# in the configuration file.

sub _username_to_class
  {
    my $self = shift;
    my $username = shift;
    my $user_is_anonymous = shift;

    my @classes = $self->config ("class");

    local $_;

    foreach my $class (@classes)
      {
	# class: CLASSNAME { perl code ... }
	if ($class =~ /^(\w+)\s+\{(.*)\}\s*$/)
	  {
	    my $classname = $1;
	    my $code = $2;

	    $_ = $username;

	    my $rv = eval $code;
	    die if $@;

	    return $classname if $rv;
	  }
	# class: CLASSNAME USERNAME[,USERNAME[,...]]
	elsif ($class =~ /^(\w*)\s+(.*)/)
	  {
	    my $classname = $1;
	    my @users = split /[,\s]+/, $2;

	    foreach (@users)
	      {
		return $classname if $_ eq $username;
	      }
	  }
	else
	  {
	    die "bad class directive: class: $_";
	  }
      }

    # Default cases.
    return "anonymous" if $user_is_anonymous;
    return "users";
  }

sub _percent_substitutions
  {
    my $self = shift;
    local $_ = shift;

    # See CONFIGURATION section on ``welcome text'' for a list of
    # the substitutions available.
    s/%C/$self->{cwd}->pathname/ge;
    s/%E/$self->{maintainer_email}/ge;
    s/%G/gmtime/ge;
    s/%R/$self->{peerhostname} ? $self->{peerhostname} : $self->{peeraddrstring}/ge;
    s/%L/$self->{hostname}/ge;
    s/%m/$self->{home_directory}/ge;
    s/%T/localtime/ge;
    s/%U/$self->{user}/ge;
    s/%u/$self->{user}/ge;
    s/%x/$self->{_max_clients}/ge;
    s/%%/%/g;

    return $_;
  }

sub _anon_passwd_validate_rfc822
  {
    my $self = shift;
    my $pass = shift;

    # RFC 822 section 6.1, ``addr-spec''.
    # But in fact this is not very careful about checking
    # the address. There's probably a Perl library I should
    # be using here ... XXX
    return $pass =~ /^\S+\@\S+\.\S+$/;
  }

sub _anon_passwd_validate_nobrowser
  {
    my $self = shift;
    my $pass = shift;

    return
      $self->_anon_passwd_validate_rfc822 ($pass) &&
      $pass !~ /^mozilla@/ &&
      $pass !~ /^IE[0-9]+User@/ &&
      $pass !~ /^nobody@/;
  }

sub _anon_passwd_validate_trivial
  {
    my $self = shift;
    my $pass = shift;

    return $pass =~ /\@/;
  }

# Assuming we are running as root, drop privileges and change
# to user called $username who has uid $uid and gid $gid. There
# is no interface to initgroups, so we have to do that by
# hand -- yuck.
sub _drop_privs
  {
    my $self = shift;
    my $uid = shift;
    my $gid = shift;
    my $username = shift;

    # Get the list of extra groups to pass to setgroups(2).
    my @groups = ();

    my @g;
    while (@g = getgrent)
      {
	my ($gr_name, $gr_passwd, $gr_gid, $gr_members) = @g;
	my @members = split /\s+/, $gr_members;

	foreach (@members)
	  {
	    push @groups, $gr_gid if $_ eq $username;
	  }
      }

    setgrent;			# Rewind the pointer.

    # Set the effective GID/UID.
    $) = join (" ", $gid, $gid, @groups);
    $> = $uid;

    # set the real GID/UID if we are going to use non-priv port
    # Otherwise, keep root access so we can bind to the port
    if (my $ftpdata = $self->{ftp_data_port})
      {
	if ( $ftpdata >= 1024 )
	  {
	    $( = $gid;
	    $< = $uid;
	  }
      }
  }

sub _ACCT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Not likely that the ACCT command will ever be implemented,
    # unless there is some strange login method that needs to be
    # supported.
    $self->reply (500, "Command not implemented.");
  }

sub _CWD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $new_cwd;

    # Look relative to the current directory first.
    if ($new_cwd = $self->_chdir ($self->{cwd}, $rest))
      {
        # Access control
        unless ($self->_eval_rule ("chdir rule",
                                   $new_cwd->pathname, $new_cwd->filename,
                                   $new_cwd->pathname))
          {
            $self->reply (550, "CWD command denied by server configuration.");
            return;
          }

        $self->{cwd} = $new_cwd;
        $self->_chdir_message;
        return;
      }

    # Look for an alias called ``$rest''.
    if ($rest !~ /\//)
      {
	my @aliases = $self->config ("alias");

	foreach (@aliases)
	  {
	    my ($name, $dir) = split /\s+/, $_;

	    if ($name eq $rest &&
		($new_cwd = $self->_chdir ($self->{cwd}, $dir)))
	      {
		$self->{cwd} = $new_cwd;
		$self->_chdir_message;
		return;
	      }
	  }
      }

    # Look for a directory on the cdpath.
    if ($self->config ("cdpath"))
      {
	my @cdpath = split /\s+/, $self->config ("cdpath");

	foreach (@cdpath)
	  {
	    if (($new_cwd = $self->_chdir ($self->{cwd}, $_)) &&
		($new_cwd = $self->_chdir ($new_cwd, $rest)))
	      {
		$self->{cwd} = $new_cwd;
		$self->_chdir_message;
		return;
	      }
	  }
      }

    # All change directory methods failed.
    $self->reply (550, "Directory not found.");
  }

sub _CDUP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if (my $new_cwd = $self->_chdir ($self->{cwd}, ".."))
      {
        # Access control
        unless ($self->_eval_rule ("chdir rule",
                                   $new_cwd->pathname, $new_cwd->filename,
                                   $new_cwd->pathname))
          {
            $self->reply (550, "CDUP command denied by server configuration.");
            return;
          }

        $self->{cwd} = $new_cwd;
        $self->_chdir_message;
      }
    else
      {
        $self->reply (550, "Directory not found.");
      }
  }

# This little function displays the contents of a special
# message file the first time a user visits a directory,
# if this capability has been configured in.

sub _chdir_message
  {
    my $self = shift;

    my $filename = $self->config ("chdir message file");
    my $file;

    if ($filename &&
	! exists $self->{_chdir_message_cache}{$self->{cwd}->pathname} &&
	($file = $self->{cwd}->open ($filename, "r")))
      {
	my @lines = ();
	local $_;

	# Read the file into memory and perform % escaping.
	while (defined ($_ = $file->getline))
	  {
	    s/[\n\r]+$//;
	    push @lines, $self->_percent_substitutions ($_);
	  }
	$file->close;

	# Remember that we've visited this directory once in
	# this session.
	$self->{_chdir_message_cache}{$self->{cwd}->pathname} = 1;

	$self->reply (250, @lines, "Changed directory OK.");
      }
    else
      {
	$self->reply (250, "Changed directory OK.");
      }
  }

sub _SMNT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Not a very useful command.
    $self->reply (500, "Command not implemented.");
  }

sub _REIN_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This command is not implemented, because we do not allow a
    # user to revoke permissions and relogin (without disconnecting
    # and reconnecting anyway).
    $self->reply (500, "The REIN command is not supported. You must QUIT and reconnect.");
  }

sub _QUIT_command
  {
    # This function should never be called. The server main command loop
    # now deals with the "QUIT" command as a special case.
    die;
  }

sub _PORT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # The arguments to PORT are a1,a2,a3,a4,p1,p2 where a1 is the
    # most significant part of the address (eg. 127,0,0,1) and
    # p1 is the most significant part of the port.
    #
    # Some clients (eg. IE 6.0.2600.0000 and IBM mainframes) send
    # leading zeroes in front of the numbers, and apparently the RFC
    # doesn't prevent this. So we must use the 'int' function to
    # remove these leading zeroes.
    unless ($rest =~ /^\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})/)
      {
	$self->reply (501, "Syntax error in PORT command.");
	return;
      }

    my $a1 = int ($1);
    my $a2 = int ($2);
    my $a3 = int ($3);
    my $a4 = int ($4);
    my $p1 = int ($5);
    my $p2 = int ($6);

    # Check host address.
    unless ($a1 > 0 && $a1 < 224 &&
	    $a2 >= 0 && $a2 < 256 &&
	    $a3 >= 0 && $a3 < 256 &&
	    $a4 >= 0 && $a4 < 256)
      {
	$self->reply (501, "Invalid host address.");
	return;
      }

    # Construct host address.
    my $hostaddrstring = "$a1.$a2.$a3.$a4";

    # Are we connecting back to the client?
    unless ($self->config ("allow proxy ftp"))
      {
	if (!$self->{_test_mode} && $hostaddrstring ne $self->{peeraddrstring})
	  {
	    # See RFC 2577 section 3.
	    $self->reply (504, "Proxy FTP is not allowed on this server.");
	    return;
	  }
      }

    # Construct port number.
    my $hostport = $p1 * 256 + $p2;

    # Check port number.
    unless ($hostport > 0 && $hostport < 65536)
      {
	$self->reply (501, "Invalid port number.");
      }

    # Allow connections back to ports < 1024?
    unless ($self->config ("allow connect low port"))
      {
	if ($hostport < 1024)
	  {
	    # See RFC 2577 section 3.
	    $self->reply (504, "This server will not connect back to ports < 1024.");
	    return;
	  }
      }

    $self->{_hostaddrstring} = $hostaddrstring;
    $self->{_hostaddr} = inet_aton ($hostaddrstring);
    $self->{_hostport} = $hostport;
    $self->{_passive} = 0;

    $self->reply (200, "PORT command OK.");
  }

sub _PASV_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Open a listening socket - but don't actually accept on it yet.
    # RFC 2577 section 8 suggests using random local port numbers.
    # In order to make firewall rules on FTP servers more sane, make
    # the range of local port numbers configurable, and default to
    # only opening ports in the range 49152-65535 (see:
    # http://www.isi.edu/in-notes/iana/assignments/port-numbers for
    # rationale).
    my $port_range = $self->config ("passive port range");
    $port_range = "49152-65535" unless defined $port_range;

    my $sock;

    if ($port_range eq "0")
      {
	# Use the standard kernel determined ephemeral port
	# by leaving off LocalPort parameter.
	"0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
	$sock = IO::Socket::INET->new
	  (Listen => 1,
	   LocalAddr => $self->{sockaddrstring},
	   Reuse => 1,
	   Proto => "tcp",
	   Type => SOCK_STREAM);
      }
    else
      {
	# Parse the $port_range string and assign a port from the
	# range at random.
	my @ranges = split /\s*,\s*/, $port_range;
	my $total_width = 0;
	foreach (@ranges)
	  {
	    my ($min, $max) = split /\s*-\s*/, $_;
	    $_ = [ $min, $max, $max - $min + 1 ];
	    $total_width += $_->[2];
	  }

	# XXX We need to use a secure source of random numbers here, otherwise
	# this is a little bit pointless.
	my $count = 100;

	until (defined $sock || --$count == 0)
	  {
	    my $n = int (rand $total_width);
	    my $port;
	    foreach (@ranges)
	      {
		if ($n < $_->[2])
		  {
		    $port = $_->[0] + $n;
		    last;
		  }
		$n -= $_->[2];
	      }

	    "0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
	    $sock = IO::Socket::INET->new
	      (Listen => 1,
	       LocalAddr => $self->{sockaddrstring},
	       LocalPort => $port,
	       Reuse => 1,
	       Proto => "tcp",
	       Type => SOCK_STREAM);
	  }
      }

    unless ($sock)
      {
	# Return a code 550 here, even though this is not in the RFC. XXX
	$self->reply (550, "Can't open a listening socket.");
	return;
      }

    $self->{_passive} = 1;
    $self->{_passive_sock} = $sock;

    # Get our port number.
    my $sockport = $sock->sockport;

    # Split the port number into high and low components.
    my $p1 = int ($sockport / 256);
    my $p2 = $sockport % 256;

    unless ($self->{_test_mode})
      {
	my $sockaddrstring = $self->{sockaddrstring};

	# We will need to revise this for IPv6 XXX
	die
	  unless $sockaddrstring =~ /^([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)$/;

	# Be very precise about this error message, since most clients
	# will have to parse the whole of it.
	$self->reply (227, "Entering Passive Mode ($1,$2,$3,$4,$p1,$p2)");
      }
    else
      {
	# Test mode: connect back to localhost.
	$self->reply (227, "Entering Passive Mode (127,0,0,1,$p1,$p2)");
      }
  }

sub _TYPE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    if ($rest =~ /^([AI])$/i)
      {
	$self->{type} = uc $1;
      }
    elsif ($rest =~ /^([AI])\sN$/i)
      {
	$self->{type} = uc $1;
      }
    elsif ($rest =~ /^L\s8$/i)
      {
	$self->{type} = 'L8';
      }
    else
      {
	$self->reply (504, "This server does not support TYPE $rest.");
	return;
      }

    $self->reply (200, "TYPE changed to $rest.");
  }

sub _STRU_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    # Although this defies the RFC, I'm not going to support
    # record or page structure. TOPS-20 didn't really take off
    # as an operating system in the 90s ...
    if ($rest =~ /^F$/i)
      {
	$self->{stru} = 'F';
      }
    else
      {
	$self->reply (504, "This server does not support STRU $rest.");
	return;
      }

    $self->reply (200, "STRU changed to $rest.");
  }

sub _MODE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 section 5.3.2.
    if ($rest =~ /^S$/i)
      {
	$self->{mode} = 'S';
      }
    else
      {
	$self->reply (504, "This server does not support MODE $rest.");
	return;
      }

    $self->reply (200, "MODE changed to $rest.");
  }

sub _RETR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Find file by name.
    my ($dirh, $fileh, $filename) = $self->_get ($rest);
    my ($generator, @filters);

    unless ($fileh)
      {
	# No simple file by that name exists. Perhaps the user is
	# requesting an automatic archive download? You are not
	# expected to understand the following code unless you've
	# read doc/archives.txt.

	# Check archive mode is enabled.
	unless ($self->{archive_mode})
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }

      ARCHIVE_CHECK:
	for (;;)
	  {
	    # Matches filter extension?
	    foreach (keys %{$self->{archive_filters}})
	      {
		if (lc (substr ($rest, -length ($_))) eq lc ($_))
		  {
		    substr ($rest, -length ($_), length ($_), "");
		    push @filters, $self->{archive_filters}{$_};

		    # Does remainder of $rest correspond to a file?
		    ($dirh, $fileh, $filename) = $self->_get ($rest);

		    if ($fileh)
		      {
			my ($mode) = $fileh->status;

			if ($mode eq "f")
			  {
			    last ARCHIVE_CHECK;
			  }
		      }

		    next ARCHIVE_CHECK;
		  }
	      }

	    # Matches directory + generator extension?
	    foreach (keys %{$self->{archive_generators}})
	      {
		if (lc (substr ($rest, -length ($_))) eq lc ($_))
		  {
		    my $tmp = substr ($rest, 0, -length ($_));
		    my $tmp_gen = $self->{archive_generators}{$_};

		    ($dirh, $fileh, $filename) = $self->_get ($tmp);

		    if ($fileh)
		      {
			my ($mode) = $fileh->status;

			if ($mode eq "d")
			  {
			    $rest = $tmp;
			    $generator = $tmp_gen;
			    last ARCHIVE_CHECK;
			  }
		      }
		  }
	      }

	    $self->reply (550, "File or directory not found.");
	    return;
	  } # ARCHIVE_CHECK: for (;;)
      } # unless ($fileh)

    # Check access control.
    unless ($self->_eval_rule ("retrieve rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "RETR command denied by server configuration.");
	return;
      }

    # Check it's a simple file (unless we're using a generator to archive
    # a directory, in which case it's OK).
    unless ($generator)
      {
	my ($mode) = $fileh->status;
	unless ($mode eq "f")
	  {
	    $self->reply (550,
			  "RETR command is only supported on plain files.");
	    return;
	  }
      }

    # Try to open the file.
    my $file = !$generator ? $fileh->open ("r") : &$generator ($self, $fileh);

    unless ($file)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    $self->reply (150,
		  "Opening " .
		  ($self->{type} eq 'A' ? "ASCII mode" : "BINARY mode") .
		  " data connection for file $filename.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # If there are any filters to apply, do that now.
    my @filter_objects;
    foreach (@filters)
      {
	my $filter = &$_ ($self, $sock);

	unless ($filter)
	  {
	    $self->reply (500, "Can't open filter program in archive mode.");
	    close $sock;
	    $self->_cleanup_filters (@filter_objects);
	    return;
	  }

	unshift @filter_objects, $filter;
	$sock = $filter->{sock};
      }

    # Outgoing bandwidth
    $self->xfer_start ($fileh->pathname, "o") if $self->{_xferlog};

    my $transfer_hook;

    # What mode are we sending this file in?
    unless ($self->{type} eq 'A') # Binary type.
      {
	my ($r, $buffer, $n, $w);

	# Restart the connection from previous point?
	if ($self->{_restart})
	  {
	    # VFS seek method only required to support relative forward seeks
	    #
	    # In Perl = 5.00503, SEEK_CUR is exported by IO::Seekable,
	    # in Perl >= 5.6, SEEK_CUR is exported by both IO::Seekable
	    # and Fcntl. Hence we 'use IO::Seekable' at the top of the
	    # file to get this symbol reliably in both cases.
	    $file->sysseek ($self->{_restart}, SEEK_CUR);
	    $self->{_restart} = 0;
	  }

	# Copy data.
	while ($r = $file->sysread ($buffer, 65536))
	  {
	    $self->xfer ($r) if $self->{_xferlog};

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook
		= $self->transfer_hook ("r", $file, $sock, \$buffer))
	      {
		close $sock;
		$file->close;
		$self->_cleanup_filters (@filter_objects);
		$self->reply (426,
			      "File retrieval error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    for ($n = 0; $n < $r; )
	      {
#		$w = $sock->syswrite ($buffer, $r - $n, $n);
		$w = syswrite $sock, $buffer, $r - $n, $n;

		unless (defined $w)
		  {
		    # There was an error.
		    my $reason = $self->system_error_hook();

		    close $sock;
		    $file->close;
		    $self->_cleanup_filters (@filter_objects);
		    $self->reply (426,
				  "File retrieval error: $reason",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }

	    $self->_check_signals;

	    # Transfer aborted by client?
	    if ($self->{_urgent})
	      {
		close $sock;
		$file->close;
		$self->_cleanup_filters (@filter_objects);
		$self->reply (426, "Transfer aborted. Data connection closed.");
		$self->{_urgent} = 0;
		return;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    my $reason = $self->system_error_hook();

	    close $sock;
	    $file->close;
	    $self->_cleanup_filters (@filter_objects);
	    $self->reply (426,
			  "File retrieval error: $reason",
			  "Data connection has been closed.");
	    return;
	  }
      }
    else			# ASCII type.
      {
	# Restart the connection from previous point?
	if ($self->{_restart})
	  {
	    for (my $i = 0; $i < $self->{_restart}; ++$i)
	      {
		$file->getc;
	      }
	    $self->{_restart} = 0;
	  }

	# Copy data.
	while (defined ($_ = $file->getline))
	  {
	    $self->xfer (length $_) if $self->{_xferlog};

	    # Remove any native line endings.
	    s/[\n\r]+$//;

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook = $self->transfer_hook ("r", $file, $sock, \$_))
	      {
		close $sock;
		$file->close;
		$self->_cleanup_filters (@filter_objects);
		$self->reply (426,
			      "File retrieval error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    $self->_check_signals;

	    # Write the line with telnet-format line endings.
	    $sock->print ("$_\r\n");
	    if ($self->{_urgent})
	      {
		close $sock;
		$file->close;
		$self->_cleanup_filters (@filter_objects);
		$self->reply (426, "Transfer aborted. Data connection closed.");
		$self->{_urgent} = 0;
		return;
	      }
	  }
      }

    unless (close ($sock) && $file->close)
      {
	my $reason = $self->system_error_hook();
	$self->reply (550, "File retrieval error: $reason");
	return;
      }

    # Clean up any outstanding filter objects.
    $self->_cleanup_filters (@filter_objects);

    $self->xfer_complete if $self->{_xferlog};
    $self->reply (226, "File retrieval complete. Data connection has been closed.");
  }

sub _cleanup_filters
  {
    my $self = shift;

    foreach (@_)
      {
	if (exists $_->{pid})
	  {
	    waitpid $_->{pid}, 0;
	  }
      }
  }

sub _STOR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest);
  }

sub _STOU_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest, unique => 1);
  }

sub _APPE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->_store ($rest, append => 1);
  }

sub _ALLO_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # RFC 959 Section 4.1.3: Treat this as a NOOP. Note that djb
    # recommends replying with 202 here [http://cr.yp.to/ftp/stor.html].
    $self->reply (200, "OK");
  }

sub _REST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    unless ($rest =~ /^([1-9][0-9]*|0)$/)
      {
	$self->reply (501, "REST command needs a numeric argument.");
	return;
      }

    $self->{_restart} = $1;
    $self->reply (350, "Restarting next transfer at $1.");
  }

sub _RNFR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Access control.
    unless ($self->_eval_rule ("rename rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "RNFR command denied by server configuration.");
	return;
      }

    # Store the file handle so we can complete the operation.
    $self->{_rename_fileh} = $fileh;

    $self->reply (350, "OK. Send RNTO command to complete rename operation.");
  }

sub _RNTO_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Seen a previous RNFR command?
    unless ($self->{_rename_fileh})
      {
	$self->reply (503, "Send RNFR command first.");
	return;
      }

    # Get the directory name.
    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    if (!$dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Access control.
    unless ($self->_eval_rule ("rename rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "RNTO command denied by server configuration.");
	return;
      }

    # Are we trying to overwrite a previously existing file?
    if (defined $fileh &&
	defined $self->config ("allow rename to overwrite") &&
	! $self->config ("allow rename to overwrite"))
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    # Attempt the rename operation.
    if ($self->{_rename_fileh}->move ($dirh, $filename) < 0)
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    delete $self->{_rename_fileh};

    $self->reply (250, "File has been renamed.");
  }

sub _ABOR_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (226, "Command aborted successfully.");
  }

# Note that in the current implementation, DELE and RMD are synonyms.
sub _DELE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("delete rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "DELE command denied by server configuration.");
	return;
      }

    # Attempt to delete the file.
    if ($fileh->delete < 0)
      {
	$self->reply (550, "Cannot delete file.");
	return;
      }

    $self->reply (250, "File has been deleted.");
  }

sub _RMD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("delete rule",
			       $fileh->pathname, $filename, $dirh->pathname))
      {
	$self->reply (550, "RMD command denied by server configuration.");
	return;
      }

    # Attempt to delete the file.
    if ($fileh->delete < 0)
      {
	$self->reply (550, "Cannot delete file.");
	return;
      }

    $self->reply (250, "File has been deleted.");
  }

sub _MKD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    if (!$dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    if ($fileh)
      {
	$self->reply (550, "File or directory already exists.");
	return;
      }

    # Access control.
    unless ($self->_eval_rule ("mkdir rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "MKD command denied by server configuration.");
	return;
      }

    # Try to create a subdirectory with the appropriate filename.
    if ($dirh->mkdir ($filename) < 0)
      {
	$self->reply (550, "Could not create directory.");
	return;
      }

    $self->reply (250, "Directory has been created.");
  }

sub _PWD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # See RFC 959 Appendix II and draft-ietf-ftpext-mlst-11.txt section 6.2.1.
    my $pathname = $self->{cwd}->pathname;
    $pathname =~ s,/+$,, unless $pathname eq "/";
    $pathname =~ tr,/,/,s;

    $self->reply (257, "\"$pathname\"");
  }

sub _LIST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This is something of a hack. Some clients expect a Unix server
    # to respond to flags on the 'ls command line'. Remove these flags
    # and ignore them. This is particularly an issue with ncftp 2.4.3.
    $rest =~ s/^-[a-zA-Z0-9]+\s?//;

    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $dirh->pathname))
      {
	$self->reply (550, "LIST command denied by server configuration.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # Outgoing bandwidth
    $self->xfer_start ($dirh->pathname, "o") if $self->{_xferlog};

    # If the path ($rest) contains a directory name, extract it so that
    # we can prefix it to every filename listed. Thanks Rob Brown
    # for pointing this problem out.
    my $prefix = (($fileh || $wildcard) && $rest =~ /(.*\/).*/) ? $1 : "";

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$self->_list_file ($sock, $fileh, $prefix . $filename);
      }
    else			# Wildcard or full directory $dirh.
      {
	unless ($wildcard)
	  {
	    # Synthesize "total" field.
	    my $header = "total 1\r\n";
	    $self->xfer (length $header);
	    $sock->print ($header);
	  }

	my $r = $dirh->_list_status ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];
	    my $statusref = $_->[2];

	    $self->_list_file ($sock, $handle, $prefix . $filename, $statusref);
	  }
      }

    unless ($sock->close)
      {
	$self->reply (550, "Error closing data connection: $!");
	return;
      }

    $self->xfer_complete if $self->{_xferlog};
    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _NLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This is something of a hack. Some clients expect a Unix server
    # to respond to flags on the 'ls command line'.
    # Handle the "-l" flag by just calling LIST instead of NLST.
    # This is particularly an issue with ncftp 2.4.3,
    # emacs / Ange-ftp, commandline "ftp" on Windows Platform,
    # netftp, and some old versions of WSFTP.  I would think that if
    # the client wants a nice pretty listing, that they should use
    # the LIST command, but for some reasons they insist on trying
    # to pass arguments to NLST and expect them to work.
    # Examples:
    # NLST -al /.
    # NLST -AL *.htm
    return $self->_LIST_command ($cmd, $rest) if $rest =~ /^\-\w*l/i;
    $rest =~ s/^-\w+\s?//;

    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $dirh->pathname))
      {
	$self->reply (550, "NLST command denied by server configuration.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # Outgoing bandwidth
    $self->xfer_start ($dirh->pathname, "o") if $self->{_xferlog};

    # If the path ($rest) contains a directory name, extract it so that
    # we can prefix it to every filename listed. Thanks Rob Brown
    # for pointing this problem out.
    my $prefix = (($fileh || $wildcard) && $rest =~ /(.*\/).*/) ? $1 : "";

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	$sock->print ($prefix . $filename, "\r\n");
      }
    else			# Wildcard or full directory $dirh.
      {
	my $r = $dirh->list ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];   # handle not used?
	    my $line = "$prefix$filename\r\n";
	    $self->xfer (length $line);
	    $sock->print ($line);
	  }
      }

    unless ($sock->close)
      {
	$self->reply (550, "Error closing data connection: $!");
	return;
      }

    $self->xfer_complete if $self->{_xferlog};
    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _SITE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Find the command.
    # See also RFC 2640 section 3.1.
    # "Brian Freeman" <Brian.Freeman@eby-brown.com> wants to be able to use
    # non-alpha characters in SITE command names. Fine by me as far as I can
    # tell.
    unless ($rest =~ /^(\S{3,})\s?(.*)/i)
      {
	$self->reply (501, "Syntax error in SITE command.");
	return;
      }

    ($cmd, $rest) = (uc $1, $2);

    # Find the appropriate command and run it.
    unless (exists $self->{site_command_table}{$cmd})
      {
	$self->reply (501, "Unknown SITE command.");
	return;
      }

    &{$self->{site_command_table}{$cmd}} ($self, $cmd, $rest);
  }

sub _SITE_EXEC_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # This command is DISABLED by default.
    unless ($self->config ("allow site exec command"))
      {
	$self->reply (502, "SITE EXEC is disabled at this site.");
	return;
      }

    # Don't allow this command for anonymous users.
    if ($self->{user_is_anonymous})
      {
	$self->reply (502, "SITE EXEC is not permitted for anonymous logins.");
	return;
      }

    # We trust everything the client sends us implicitly. Foolish? Probably.
    $rest = $1 if $rest =~ /(.*)/;

    # Run it and collect the output.
    unless (open OUTPUT, "$rest |")
      {
	$self->reply (451, "Error running command: $!");
	return;
      }

    my @result, ();

    while (<OUTPUT>)
      {
	# Remove trailing \n, \r.
	s/[\n\r]+$//;

	push @result, $_;
      }

    close OUTPUT;

    # Return the result to the client.
    $self->reply (200, "Result from command $rest:", @result);
  }

sub _SITE_VERSION_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $enabled
      = defined $self->config ("allow site version command")
	? $self->config ("allow site version command") : 1;

    unless ($enabled)
      {
	$self->reply (502, "SITE VERSION is disabled at this site.");
	return;
      }

    # Return the version string.
    $self->reply (200, $self->{version_string});
  }

sub _SITE_ALIAS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my @aliases = $self->config ("alias");

    # List out all aliases?
    if ($rest eq "")
      {
	$self->reply (214,
		      "The following aliases are defined:",
		      @aliases,
		      "End of alias list.");
	return;
      }

    # Find a particular alias.
    foreach (@aliases)
      {
	my ($name, $dir) = split /\s+/, $_;
	if ($name eq $rest)
	  {
	    $self->reply (214, "$name is an alias for $dir.");
	    return;
	  }
      }

    # No alias found.
    $self->reply (502,
		"Unknown alias $rest. Note that aliases are case sensitive.");
  }

sub _SITE_CDPATH_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my $cdpath = $self->config ("cdpath");

    unless (defined $cdpath)
      {
	$self->reply (502, "No CDPATH is defined in this server.");
	return;
      }

    my @cdpath = split /\s+/, $cdpath;

    $self->reply (214, "The current CDPATH is:", @cdpath, "End of CDPATH.");
  }

sub _SITE_CHECKMETHOD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $rest = uc $rest;

    if ($rest eq "MD5")
      {
	$self->{_checksum_method} = $rest;
	$self->reply (200, "Checksum method is now: $rest");
      }
    elsif ($rest eq "")
      {
	$self->reply (200, "Checksum method is now: $self->{_checksum_method}");
      }
    else
      {
	$self->reply (500, "Unknown checksum method. I know about MD5.");
      }
  }

sub _SITE_CHECKSUM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    unless (exists $INC{"Digest/MD5.pm"})
      {
	$self->reply (500, "SITE CHECKSUM is not supported on this server.");
	return;
      }

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    my ($mode) = $fileh->status;

    unless ($mode eq 'f')
      {
	$self->reply (550, "SITE CHECKSUM only works on plain files.");
	return;
      }

    my $file = $fileh->open ("r");

    unless ($file)
      {
	$self->reply (550, "File not found.");
	return;
      }

    my $ctx = "Digest::MD5"->new;
    $ctx->addfile ($file);	# IO::Handles are also filehandle globs.

    $self->reply (200, $ctx->hexdigest . " " . $filename);
  }

sub _SITE_IDLE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if ($rest eq "")
      {
	$self->reply (200, "Current idle timeout is $self->{_idle_timeout} seconds.");
	return;
      }

    # As with wu-ftpd, we only allow idle timeouts to be set between
    # 30 seconds and the current maximum set in the configuration file.
    # In test mode, allow the idle timeout to be set to as small as 1
    # second -- useful for testing without having to hang around.
    my $min_timeout = ! $self->{_test_mode} ? 30 : 1;
    my $max_timeout = $self->config ("timeout") || $_default_timeout;

    unless ($rest =~ /^[1-9][0-9]*$/ &&
	    $rest >= $min_timeout && $rest <= $max_timeout)
      {
	$self->reply (500, "Idle timeout must be between $min_timeout and $max_timeout seconds.");
	return;
      }

    $self->{_idle_timeout} = $rest;

    $self->reply (200, "Current idle timeout set to $self->{_idle_timeout} seconds.");
  }

sub _SITE_SYNC_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    unless (exists $INC{"File/Sync.pm"})
      {
	$self->reply (500, "Synchronization not available on this server.");
	return;
      }

    File::Sync::sync ();

    $self->reply (200, "Disks synchronized.");
  }

sub _SITE_ARCHIVE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if (defined $self->config ("enable archive mode") &&
	!$self->config ("enable archive mode"))
      {
	$self->reply (500, "Archive mode is not enabled on this server.");
	return;
      }

    if (!$rest)
      {
	$self->reply (200,
		      "Archive mode is ".
		      ($self->{archive_mode} ? "ON" : "OFF"). ".");
	return;
      }

    if (uc ($rest) eq "ON")
      {
	$self->{archive_mode} = 1;
	$self->reply (200, "Archive mode turned ON.");
	return;
      }

    if (uc ($rest) eq "OFF")
      {
	$self->{archive_mode} = 0;
	$self->reply (200, "Archive mode turned OFF.");
	return;
      }

    $self->reply (500, "Usage: SITE ARCHIVE ON|OFF");
  }

sub _SYST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (215, "UNIX Type: L8");
  }

sub _SIZE_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Get the mode, size etc. Remember to check the mode.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    if ($mode ne "f")
      {
	$self->reply (550, "SIZE command is only supported on plain files.");
	return;
      }

    if ($self->{type} eq 'A')
      {
	# ASCII mode: we have to count the characters by hand.
	if (my $file = $fileh->open ("r"))
	  {
	    $size = 0;
	    $size++ while (defined ($file->getc));
	    $file->close;
	  }
      }

    $self->reply (213, "$size");
  }

sub _STAT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # STAT is a very strange command. It can either be used to show
    # general internal information about the server in a free format,
    # or else it can be used to list a directory over the control
    # connection. See RFC 959 Section 4.1.3.

    if ($rest eq "")
      {
	# Internal status.
	my %status = ();

	unless (defined $self->config ("allow site version command") &&
		! $self->config ("allow site version command"))
	  {
	    $status{Version} = $self->{version_string};
	  }

	$status{TYPE} = $self->{type};
	$status{MODE} = $self->{mode};
	$status{FORM} = $self->{form};
	$status{STRUcture} = $self->{stru};

	$status{"Data Connection"} = "None"; # XXX

	if ($self->{peeraddrstring} && $self->{peerport})
	  {
	    $status{Client} = "$self->{peeraddrstring}:$self->{peerport}";
	    $status{Client} .= " ($self->{peerhostname}:$self->{peerport})"
	      if $self->{peerhostname};
	  }

	unless ($self->{user_is_anonymous})
	  {
	    $status{User} = $self->{user};
	  }
	else
	  {
	    $status{User} = "anonymous";
	  }

	my @status = map { $_ . ": " . $status{$_} } sort keys %status;

	$self->reply (211, "FTP server status:", @status, "End of status");
      }
    else
      {
	# Act like the LIST command.
	my ($dirh, $wildcard, $fileh, $filename)
	  = $self->_list ($rest);

	unless ($dirh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }

	my @lines = ();

	# OK, we're either listing a full directory, listing a single
	# file or listing a wildcard.
	if ($fileh)		# Single file in $dirh.
	  {
	    push @lines, $filename;
	  }
	else			# Wildcard or full directory $dirh.
	  {
	    my $r = $dirh->list_status ($wildcard);

	    foreach (@$r)
	      {
		my $filename = $_->[0];

		push @lines, $filename;
	      }
	  }

	# Send them back to the client.
	$self->reply (213, "Status of $rest:", @lines, "End of status");
      }
  }

sub _HELP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my @version_info = ();

    # Dan Bernstein recommends sending the server version info here.
    unless (defined $self->config ("allow site version command") &&
	    ! $self->config ("allow site version command"))
      {
	@version_info = ( $self->{version_string} );
      }

    # Without any arguments, return a list of commands supported.
    if ($rest eq "")
      {
	my @lines = _format_list (sort keys %{$self->{command_table}});

	$self->reply (214,
		      @version_info,
		      "The following commands are recognized:",
		      @lines,
		      "You can also use HELP SITE to list site specific commands.");
      }
    # HELP SITE.
    elsif (uc $rest eq "SITE")
      {
	my @lines = _format_list (sort keys %{$self->{site_command_table}});

	$self->reply (214,
		      @version_info,
		      "The following commands are recognized:",
		      @lines,
		      "You can also use HELP to list general commands.");
      }
    # No other form of HELP available right now.
    else
      {
	$self->reply (214,
		      "No command-specific help is available right now. Use HELP or HELP SITE.");
      }
  }

sub _format_list
  {
    my @lines = ();
    my ($r, $c);
    my $rows = int (ceil (@_ / 4.));

    for ($r = 0; $r < $rows; ++$r)
      {
	my @r = ();

	for ($c = 0; $c < 4; ++$c)
	  {
	    my $n = $c * $rows + $r;

	    push @r, $_[$n] if $n < @_;
	  }

	push @lines, "\t" . join "\t", @r;
      }

    return @lines;
  }

sub _NOOP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (200, "OK");
  }

sub _XMKD_command
  {
    return shift->_MKD_command (@_);
  }

sub _XRMD_command
  {
    return shift->_RMD_command (@_);
  }

sub _XPWD_command
  {
    return shift->_PWD_command (@_);
  }

sub _XCUP_command
  {
    return shift->_CDUP_command (@_);
  }

sub _XCWD_command
  {
    return shift->_CWD_command (@_);
  }

sub _FEAT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    if ($rest ne "")
      {
	$self->reply (501, "Unexpected parameters to FEAT command.");
	return;
      }

    # Print out the extensions supported. Don't use $self->reply, since
    # it doesn't have the exact guaranteed behaviour (it instead immitates
    # wu-ftpd by putting the server code in each line).
    #
    # See RFC 2389 section 3.2.
    print "211-Extensions supported:\r\n";

    foreach (sort keys %{$self->{features}})
      {
	unless ($self->{features}{$_})
	  {
	    print " $_\r\n";
	  }
	else
	  {
	    print " $_ ", $self->{features}{$_}, "\r\n";
	  }
      }

    print "211 END\r\n";
  }

sub _OPTS_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # RFC 2389 section 4.
    # See also RFC 2640 section 3.1.
    unless ($rest =~ /^([A-Z]{3,4})\s?(.*)/i)
      {
	$self->reply (501, "Syntax error in OPTS command.");
	return;
      }

    ($cmd, $rest) = (uc $1, $2);

    # Find the appropriate command.
    unless (exists $self->{options}{$cmd})
      {
	$self->reply (501, "Command has no settable options.");
	return;
      }

    # The command should print either a 200 or a 451 reply.
    &{$self->{options}{$cmd}} ($self, $cmd, $rest);
  }

sub _MSAM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MRSQ_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MLFL_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MRCP_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MAIL_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MSND_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _MSOM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    $self->reply (502, "Obsolete RFC 765 mail commands not implemented.");
  }

sub _LANG_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # The beginnings of language support.
    #
    # XXX To complete language support we need to implement the FEAT
    # command for language properly, put gettext around all strings
    # and also arrange for strings to be translated. See RFC 2640.

    # If no argument, then we want to find the current language.
    if ($rest eq "")
      {
	my $lang = $ENV{LANGUAGE} || "en";
	$self->reply (200, "Language is $lang.");
	return;
      }

    # We limit the whole tag to 8 chars since (a) it's highly unlikely
    # that any genuine language code would be longer than this and
    # (b) there are all sorts of possible libc exploits available if
    # the user is allowed to set this to arbitrary values.
    unless (length ($rest) <= 8 &&
	    $rest =~ /^[A-Z]{1,8}(-[A-Z]{1-8})*$/i)
      {
	$self->reply (504, "Incorrect language.");
	return;
      }

    $ENV{LANGUAGE} = $rest;
    $self->reply (200, "Language changed to $rest.");
  }

sub _CLNT_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # NcFTP sends the CLNT command. I don't know what RFC this
    # comes from.
    $self->reply (200, "Hello $rest.");
  }

sub _MDTM_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    my ($dirh, $fileh, $filename) = $self->_get ($rest);

    unless ($fileh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Get the status.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    # Format the modification time. See draft-ietf-ftpext-mlst-11.txt
    # sections 2.3 and 3.1.
    my $fmt_time = strftime "%Y%m%d%H%M%S", gmtime ($time);

    $self->reply (213, $fmt_time);
  }

sub _MLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # If not file name is given, then we need to return
    # status on the current directory. Else we return
    # status on the file or directory name given.
    my $fileh = $self->{cwd};
    my $dirh = $fileh->dir;
    my $filename = ".";

    if ($rest ne "")
      {
	($dirh, $fileh, $filename) = $self->_get ($rest);

	unless ($fileh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $fileh->pathname))
      {
	$self->reply (550, "LIST command denied by server configuration.");
	return;
      }

    # Get the status.
    my ($mode, $perms, $nlink, $user, $group, $size, $time)
      = $fileh->status;

    # Return the requested information over the control connection.
    my $info = $self->_mlst_format ($filename, $fileh, $dirh);

    # Can't use $self->reply since it produces the wrong format.
    print "250-Listing of $filename:\r\n";
    print " ", $info, "\r\n";
    print "250 End of listing.\r\n";
  }

sub _MLSD_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # XXX Note that this is slightly wrong. According to the Internet
    # Draft we shouldn't handle wildcards in the MLST or MLSD commands.
    my ($dirh, $wildcard, $fileh, $filename)
      = $self->_list ($rest);

    unless ($dirh)
      {
	$self->reply (550, "File or directory not found.");
	return;
      }

    # Check access control.
    unless ($self->_eval_rule ("list rule",
			       undef, undef, $dirh->pathname))
      {
	$self->reply (550, "MLSD command denied by server configuration.");
	return;
      }

    $self->reply (150, "Opening data connection for file listing.");

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # Outgoing bandwidth
    $self->xfer_start ($dirh->pathname, "o") if $self->{_xferlog};

    # OK, we're either listing a full directory, listing a single
    # file or listing a wildcard.
    if ($fileh)			# Single file in $dirh.
      {
	# Do not bother logging xfer of the status of one file
	$sock->print ($self->_mlst_format ($filename, $fileh, $dirh), "\r\n");
      }
    else			# Wildcard or full directory $dirh.
      {
	my $r = $dirh->list_status ($wildcard);

	foreach (@$r)
	  {
	    my $filename = $_->[0];
	    my $handle = $_->[1];
	    my $statusref = $_->[2];
	    my $line = $self->_mlst_format ($filename,
					    $handle, $dirh, $statusref).
					   "\r\n";
	    $self->xfer (length $line) if $self->{_xferlog};
	    $sock->print ($line);
	  }
      }

    unless ($sock->close)
      {
	$self->reply (550, "Error closing data connection: $!");
	return;
      }

    $self->xfer_complete if $self->{_xferlog};
    $self->reply (226, "Listing complete. Data connection has been closed.");
  }

sub _OPTS_MLST_command
  {
    my $self = shift;
    my $cmd = shift;
    my $rest = shift;

    # Break up the list of facts.
    my @facts = split /;/, $rest;

    $self->{_mlst_facts} = [];

    # Check that all the facts asked for are supported.
    foreach (@facts)
      {
	$_ = uc;

	if ($_ ne "")
	  {
	    if ($self->_is_supported_mlst_fact ($_))
	      {
		push @{$self->{_mlst_facts}}, $_;
	      }
	  }
      }

    # Return the list of facts enabled.
    $self->reply (200,
		  "MLST OPTS " .
		  join ("",
			map { "$_;" } @{$self->{_mlst_facts}}));

    # Update the FEAT list.
    $self->{features}{MLST} = $self->_mlst_features;
  }

sub _is_supported_mlst_fact
  {
    my $self = shift;
    my $fact = shift;

    foreach my $supported_fact (@_supported_mlst_facts)
      {
	return 1 if $fact eq $supported_fact;
      }

    return 0;
  }

sub _mlst_features
  {
    my $self = shift;
    my $out = "";

    foreach my $supported_fact (@_supported_mlst_facts)
      {
	if ($self->_is_enabled_fact ($supported_fact)) {
	  $out .= "$supported_fact*;"
	} else {
	  $out .= "$supported_fact;"
	}
      }

    return $out;
  }

sub _is_enabled_fact
  {
    my $self = shift;
    my $fact = shift;

    foreach my $enabled_fact (@{$self->{_mlst_facts}})
      {
	return 1 if $fact eq $enabled_fact;
      }
    return 0;
  }

use vars qw(%_mode_to_mlst_unix_type);

# XXX I made these up. Is there a list anywhere?
%_mode_to_mlst_unix_type = (
			    l => "LINK",
			    p => "PIPE",
			    s => "SOCKET",
			    b => "BLOCK",
			    c => "CHAR",
			   );

sub _mlst_format
  {
    my $self = shift;
    my $filename = shift;
    my $fileh = shift;
    my $dirh = shift;
    my $statusref = shift;
    local $_;

    # Get the status information.
    my @status;
    if ($statusref) { @status = @$statusref }
    else            { @status = $fileh->status }

    # Break out the fields of the status information.
    my ($mode, $perms, $nlink, $user, $group, $size, $mtime) = @status;

    # Get the directory status information.
    my ($dir_mode, $dir_perms) = ('d', $perms);
    ($dir_mode, $dir_perms) = $dirh->status if $dirh;

    # Return the requested facts.
    my @facts = ();

    foreach (@{$self->{_mlst_facts}})
      {
	if ($_ eq "TYPE")
	  {
	    if ($mode eq "f") {
	      push @facts, "$_=file";
	    } elsif ($mode eq "d") {
	      if ($filename eq ".") {
		push @facts, "$_=cdir";
	      } elsif ($filename eq "..") {
		push @facts, "$_=pdir";
	      } else {
		push @facts, "$_=dir";
	      }
	    } else {
	      push @facts, "$_=OS.UNIX=$_mode_to_mlst_unix_type{$mode}";
	    }
	  }
	elsif ($_ eq "SIZE")
	  {
	    push @facts, "$_=$size";
	  }
	elsif ($_ eq "MODIFY")
	  {
	    my $fmt_time = strftime "%Y%m%d%H%M%S", localtime ($mtime);
	    push @facts, "$_=$fmt_time";
	  }
	elsif ($_ eq "PERM")
	  {
	    if ($mode eq "f")
	      {
		push @facts,
		"$_=" . ($perms & 0400     ? "r" : "") . # read
			($perms & 0200     ? "w" : "") . # write
			($perms & 0200     ? "a" : "") . # append
			($dir_perms & 0200 ? "f" : "") . # rename
			($dir_perms & 0200 ? "d" : "");	 # delete
	      }
	    elsif ($mode eq "d")
	      {
		push @facts,
		"$_=" . ($perms & 0200     ? "c" : "") . # write
			($dir_perms & 0200 ? "d" : "") . # delete
			($perms & 0100     ? "e" : "") . # enter
			($perms & 0500     ? "l" : "") . # list
			($dir_perms & 0200 ? "f" : "") . # rename
			($perms & 0200     ? "m" : "");	 # mkdir
	      }
	    else
	      {
		# Pipes, block specials, etc.
		push @facts,
		"$_=" . ($perms & 0400     ? "r" : "") . # read
			($perms & 0200     ? "w" : "") . # write
			($dir_perms & 0200 ? "f" : "") . # rename
			($dir_perms & 0200 ? "d" : "");  # delete
	      }
	  }
	elsif ($_ eq "UNIX.MODE")
	  {
	    my $unix_mode = sprintf ("%s%s%s%s%s%s%s%s%s",
				     ($perms & 0400 ? 'r' : '-'),
				     ($perms & 0200 ? 'w' : '-'),
				     ($perms & 0100 ? 'x' : '-'),
				     ($perms & 040 ? 'r' : '-'),
				     ($perms & 020 ? 'w' : '-'),
				     ($perms & 010 ? 'x' : '-'),
				     ($perms & 04 ? 'r' : '-'),
				     ($perms & 02 ? 'w' : '-'),
				     ($perms & 01 ? 'x' : '-'));
	    push @facts, "$_=$unix_mode";
	  }
	else
	  {
	    die "unknown MLST fact: $_";
	  }
      }

    # Return the facts to the user in a string.
    return join (";", @facts) . "; " . $filename;
  }

# Routine: xfer_start
# Purpose: Initialize the beginning of a transfer.
# PreCond:
#   Takes full pathname and direction as arguments.
#   _xferlog should be set to a writeable file handle.
#   Should not already have xfer_start'ed a transfer
#    or already finished it with a xfer_flush call.
sub xfer_start
  {
    my $self = shift;
    # If old data still exists, write to log
    # (This should not happen.)
    $self->xfer_flush if $self->{xfer};
    $self->{xfer} = {
      status => "i",  # Default to incomplete transfer status
      start  => time, # Started right now
      bytes  => 0,    # Nothing transferred yet
      path   => shift,
      direct => shift,
    };
  }

# Routine: xfer
# Purpose: Log transfer chunk.
# PreCond:
#   Takes the number of bytes just transferring.
#   Should have called xfer_start first.
sub xfer
  {
    my $self = shift;
    return unless $self->{xfer};
    $self->{xfer}->{bytes} += shift;
  }

# Routine: xfer_complete
# Purpose: Mark that the transfer completed successfully.
# PreCond:
#   Should have called xfer_start first.
sub xfer_complete
  {
    my $self = shift;
    return unless $self->{xfer};
    $self->{xfer}->{status} = 'c';
    $self->xfer_flush;
  }

# Routine: xfer_flush
# Purpose: Write to the xferlog and clean up.
# PreCond:
#   Should have called xfer_start first.
sub xfer_flush
  {
    my $self = shift;
    # If no xfer ref, then it's already flushed
    my $xfer = $self->{xfer} or return;
    return unless $self->{_xferlog};

    # Wipe xfer ref to signify that it's flushed
    delete $self->{xfer};

    # Never log if zero bytes transferred
    return unless $xfer->{bytes};

    # Send information in the right format
    $self->{_xferlog}->print
      (join " ",
       scalar(localtime($xfer->{start})),                    # current-time
       (time() - $xfer->{start}),                            # transfer-time
       ($self->{peerhostname} || $self->{peeraddrstring}),   # remote-host
       $xfer->{bytes},                                       # file-size
       $xfer->{path},                                        # filename
       ($self->{type} eq 'A' ? "a" : "b"),                   # transfer-type
       "_",  # Compression not implemented?                  # special-action-flag
       $xfer->{direct},                                      # direction
       ($self->{user_is_anonymous} ? "a" : "r"),             # access-mode
       $self->{user},                                        # username
       "ftp",                                                # service-name
       "0",  # RFC931 stuff?                                 # authentication-method
       "*",  # RFC931 stuff?                                 # authenticated-user-id
       "$xfer->{status}".                                    # completion-status
       "\n");
    return;
  }


# Evaluate an access control rule from the configuration file.

sub _eval_rule
  {
    my $self = shift;
    my $rulename = shift;
    my $pathname = shift;
    my $filename = shift;
    my $dirname = shift;

    my $rule
      = defined $self->config ($rulename) ? $self->config ($rulename) : "1";

    # Set up the variables.
    my $hostname = $self->{peerhostname};
    my $ip = $self->{peeraddrstring};
    my $user = $self->{user};
    my $class = $self->{class};
    my $user_is_anonymous = $self->{user_is_anonymous};
    my $type = $self->{type};
    my $form = $self->{form};
    my $mode = $self->{mode};
    my $stru = $self->{stru};

    my $rv = eval $rule;
    die if $@;

    return $rv;
  }

# Move from one directory to another. Return the new directory handle.

sub _chdir
  {
    my $self = shift;
    my $dirh = shift;
    my $path = shift;
    local $_;

    # If the path starts with a "/" then it's an absolute path.
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
      }

    # Split the path into its component parts and process each separately.
    my @elems = split /\//, $path;

    foreach (@elems)
      {
	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    # Go into subdirectory, if it exists.
	    $dirh = $dirh->get ($_);

	    return undef
	      unless $dirh && $dirh->isa ("Net::FTPServer::DirHandle");
	  }
      }

    return $dirh;
  }

# The list command understands the following forms for $path:
#
#   <<empty>>         List current directory.
#   file              List single file in cwd.
#   wildcard          List files by wildcard in cwd.
#   path/to/dir       List contents of directory, relative to cwd.
#   /path/to/dir      List contents of directory, absolute.
#   path/to/file      List single file, relative to cwd.
#   /path/to/file     List single file, absolute.
#   path/to/wildcard  List files by wildcard, relative to cwd.
#   /path/to/wildcard List files by wildcard, absolute.

sub _list
  {
    my $self = shift;
    my $path = shift;

    my $dirh = $self->{cwd};

    # Absolute path?
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
      }

    # Parse the first elements of the path until we find the appropriate
    # working directory.
    my @elems = split /\//, $path;
    my ($wildcard, $fileh, $filename);
    local $_;

    for (my $i = 0; $i < @elems; ++$i)
      {
	$_ = $elems[$i];
	my $lastelement = $i == @elems-1;

	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    # What is it?
	    my $handle = $dirh->get ($_);

	    if (!$lastelement)
	      {
		if (!$handle)
		  {
		    return ();
		  }
		elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
		  {
		    return ();
		  }
		else
		  {
		    $dirh = $handle;
		  }
	      }
	    else # it's the last element - treat it nicely.
	      {
		if (!$handle)
		  {
		    # But it could be a wildcard ...
		    if (/\*/ || /\?/)
		      {
			$wildcard = $_;
		      }
		    else
		      {
			return ();
		      }
		  }
		elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
		  {
		    # So it's a file.
		    $fileh = $handle;
		    $filename = $_;
		  }
		else
		  {
		    $dirh = $handle;
		  }
	      }
	  }
      } # for

    return ($dirh, $wildcard, $fileh, $filename);
  }

# The get command understands the following forms for $path:
#
#   file              List single file in cwd.
#   path/to/file      List single file, relative to cwd.
#   /path/to/file     List single file, absolute.
#
# Returns ($dirh, $fileh, $filename) where:
#
#   $dirh is set if the directory exists
#   $fileh is set if the directory and the file exist
#   $filename is just the last component part of the path
#     and is always set if $dirh is set.

sub _get
  {
    my $self = shift;
    my $path = shift;

    my $dirh = $self->{cwd};

    # Absolute path?
    if (substr ($path, 0, 1) eq "/")
      {
	$dirh = $self->root_directory_hook;
	$path =~ s,^/+,,;
	$path = "." if $path eq "";
      }

    # Parse the first elements of path until we find the appropriate
    # working directory.
    my @elems = split /\//, $path;
    my $filename = pop @elems;

    unless (defined $filename && length $filename)
      {
	return ();
      }

    foreach (@elems)
      {
	if ($_ eq "" || $_ eq ".") { next } # Ignore these.
	elsif ($_ eq "..")
	  {
	    # Go to parent directory.
	    $dirh = $dirh->parent;
	  }
	else
	  {
	    my $handle = $dirh->get ($_);

	    if (!$handle)
	      {
		return ();
	      }
	    elsif (!$handle->isa ("Net::FTPServer::DirHandle"))
	      {
		return ();
	      }
	    else
	      {
		$dirh = $handle;
	      }
	  }
      }

    # Get the file handle.
    my $fileh =
      ($filename eq ".") ? $dirh :
	($filename eq "..") ? $dirh->parent :
	  $dirh->get($filename);

    return ($dirh, $fileh, $filename);
  }

=pod

=item $sock = $self->open_data_connection;

Open a data connection. Returns the socket (an instance of C<IO::Socket>) or undef if it fails for some reason.

=cut

sub open_data_connection
  {
    my $self = shift;
    my $sock;

    if (! $self->{_passive})
      {
        # Active mode - connect back to the client.
	my $source_addr = $self->{sockaddrstring};
	my $target_addr = $self->{_hostaddrstring};
        my $target_port = $self->{_hostport};
        if (my $source_port = $self->{ftp_data_port})
          {
            # Temporarily jump back to super user just
            # long enough to bind the privileged port.
            local $) = 0;
            local $> = 0;
	    for (1..5) {
	      "0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
              $sock = new IO::Socket::INET
	        LocalAddr => $source_addr,
                LocalPort => $source_port,
                PeerAddr => $target_addr,
                PeerPort => $target_port,
                Proto => "tcp",
                Type => SOCK_STREAM,
                Reuse => 1,
                or warn "PID $$ Failed to bind() ($!)";
              last if $sock;
	      print STDERR "    PID $$ Socket [${source_addr}:${source_port}] to [${target_addr}:${target_port}]\n"
		if $_ == 1;
	      last unless $!{EADDRINUSE};
	      print STDERR
		"    PID $$ Retrying data connection (Attempt $_)\n" ;
	      sleep 1;
	    }
	    return undef unless $sock ;
          }
	else
	  {
            "0" =~ /(0)/; # Perl 5.7 / IO::Socket::INET bug workaround.
            $sock = new IO::Socket::INET
	      LocalAddr => $self->{sockaddrstring},
              PeerAddr => $self->{_hostaddrstring},
              PeerPort => $self->{_hostport},
              Proto => "tcp",
              Type => SOCK_STREAM,
              Reuse => 1,
              or return undef;
          }
      }
    else
      {
	# Passive mode - wait for a connection from the client.
	$sock = $self->{_passive_sock}->accept or return undef;

	# Check that the peer address of the connection is the
	# client's own IP address.
	# XXX This test is commented out because it causes Netscape 4
	# to fail on loopback connections.
#	unless ($self->config ("allow proxy ftp"))
#	  {
#	    my $peeraddrstring = inet_ntoa ($sock->peeraddr);

#	    if ($peeraddrstring ne $self->{peeraddrstring})
#	      {
#		$self->reply (504, "Proxy FTP is not allowed on this server.");
#		return;
#	      }
#	  }
      }

    # Set TCP keepalive?
    if (defined $self->config ("tcp keepalive"))
      {
	$sock->sockopt (SO_KEEPALIVE, 1)
	  or warn "setsockopt: SO_KEEPALIVE: $!";
      }

    # Set TCP initial window size?
    if (defined $self->config ("tcp window"))
      {
	$sock->sockopt (SO_SNDBUF, $self->config ("tcp window"))
	  or warn "setsockopt: SO_SNDBUF: $!";
	$sock->sockopt (SO_RCVBUF, $self->config ("tcp window"))
	  or warn "setsockopt: SO_RCVBUF: $!";
      }

    return $sock;
  }

# $self->_list_file ($sock, $fileh, [$filename, [$statusref]]);
#
# List a single file over the data connection $sock.

sub _list_file
  {
    my $self = shift;
    my $sock = shift;
    my $fileh = shift;
    my $filename = shift || $fileh->filename;
    my $statusref = shift;

    # Get the status information.
    my @status;
    if ($statusref) { @status = @$statusref }
    else            { @status = $fileh->status }

    # Break out the fields of the status information.
    my ($mode, $perms, $nlink, $user, $group, $size, $mtime) = @status;

    # Generate printable date (this logic is taken from GNU fileutils:
    # src/ls.c: print_long_format).
    my $time = time;
    my $fmt;
    if ($time > $mtime + 6 * 30 * 24 * 60 * 60 || $time < $mtime - 60 * 60)
      {
	$fmt = "%b %e  %Y";
      }
    else
      {
	$fmt = "%b %e %H:%M";
      }

    my $fmt_time = strftime $fmt, localtime ($mtime);

    # Generate printable permissions.
    my $fmt_perms = join "",
      ($perms & 0400 ? 'r' : '-'),
      ($perms & 0200 ? 'w' : '-'),
      ($perms & 0100 ? 'x' : '-'),
      ($perms & 040 ? 'r' : '-'),
      ($perms & 020 ? 'w' : '-'),
      ($perms & 010 ? 'x' : '-'),
      ($perms & 04 ? 'r' : '-'),
      ($perms & 02 ? 'w' : '-'),
      ($perms & 01 ? 'x' : '-');

    # Printable file type.
    my $fmt_mode = $mode eq 'f' ? '-' : $mode;

    # If it's a symbolic link, display the link.
    my $link;
    if ($mode eq 'l')
      {
	$link = $fileh->readlink;
	die "readlink: $!" unless defined $link;
      }
    my $fmt_link = defined $link ? " -> $link" : "";

    # Display the file.
    my $line = sprintf
      ("%s%s%4d %-8s %-8s %8d %s %s%s\r\n",
       $fmt_mode,
       $fmt_perms,
       $nlink,
       $user,
       $group,
       $size,
       $fmt_time,
       $filename,
       $fmt_link);
    $self->xfer (length $line) if $self->{_xferlog};
    $sock->print ($line);
  }

# Implement the STOR, STOU (store unique) and APPE (append) commands.

sub _store
  {
    my $self = shift;
    my $path = shift;
    my %params = @_;

    my $unique = $params{unique} || 0;
    my $append = $params{append} || 0;

    my ($dirh, $fileh, $filename, $transfer_hook);

    unless ($unique)
      {
	# Get the directory.
	($dirh, $fileh, $filename) = $self->_get ($path);

	unless ($dirh)
	  {
	    $self->reply (550, "File or directory not found.");
	    return;
	  }
      }
    else			# STOU command -- ignore any parameters.
      {
	$dirh = $self->{cwd};

	# Choose a unique name for this file.
	my $i = 0;
	while ($dirh->get ("X$i")) {
	  $i++;
	}

	$filename = "X$i";
      }

    # Check access control.
    unless ($self->_eval_rule ("store rule",
			       $dirh->pathname . $filename,
			       $filename, $dirh->pathname))
      {
	$self->reply (550, "Store command denied by server configuration.");
	return;
      }

    # Are we trying to overwrite a previously existing file?
    if (! $append &&
	defined $fileh &&
	defined $self->config ("allow store to overwrite") &&
	! $self->config ("allow store to overwrite"))
      {
	$self->reply (550, "Cannot rename file.");
	return;
      }

    # Try to open the file.
    my $file = $dirh->open ($filename, ($append ? "a" : "w"));

    unless ($file)
      {
	$self->reply (550, "Cannot create file $filename.");
	return;
      }

    unless ($unique)
      {
	$self->reply (150,
		      "Opening " .
		      ($self->{type} eq 'A' ? "ASCII mode" : "BINARY mode") .
		      " data connection for file $filename.");
      }
    else
      {
	# RFC 1123 section 4.1.2.9.
	$self->reply (150, "FILE: $filename");
      }

    # Open a path back to the client.
    my $sock = $self->open_data_connection;

    unless ($sock)
      {
	$self->reply (425, "Can't open data connection.");
	return;
      }

    # Incoming bandwidth
    $self->xfer_start ($dirh->pathname . $filename, "i") if $self->{_xferlog};

    # What mode are we receiving this file in?
    unless ($self->{type} eq 'A') # Binary type.
      {
	my ($r, $buffer, $n, $w);

	# XXX Do we need to support REST?

	# Copy data.
	while ($r = $sock->sysread ($buffer, 65536))
	  {
	    $self->xfer ($r) if $self->{_xferlog};

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook
		= $self->transfer_hook ("w", $file, $sock, \$buffer))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    for ($n = 0; $n < $r; )
	      {
		$w = $file->syswrite ($buffer, $r - $n, $n);

		unless (defined $w)
		  {
		    # There was an error.
		    my $reason = $self->system_error_hook();

		    $sock->close;
		    $file->close;
		    $self->reply (426,
				  "File store error: $reason",
				  "Data connection has been closed.");
		    return;
		  }

		$n += $w;
	      }
	  }

	unless (defined $r)
	  {
	    # There was an error.
	    my $reason = $self->system_error_hook();

	    $sock->close;
	    $file->close;
	    $self->reply (426,
			  "File store error: $reason",
			  "Data connection has been closed.");
	    return;
	  }
      }
    else			# ASCII type.
      {
	# XXX Do we need to support REST?

	# Copy data.
	while (defined ($_ = $sock->getline))
	  {
	    $self->xfer (length $_) if $self->{_xferlog};

	    # Remove any telnet-format line endings.
	    s/[\n\r]*$//;

	    # Restart alarm clock timer.
	    alarm $self->{_idle_timeout};

	    if ($transfer_hook = $self->transfer_hook ("w", $file, $sock, \$_))
	      {
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $transfer_hook",
			      "Data connection has been closed.");
		return;
	      }

	    # Write the line with native format line endings.
	    my $w = $file->print ("$_\n");
	    unless (defined $w)
	      {
		my $reason = $self->system_error_hook();
		# There was an error.
		$sock->close;
		$file->close;
		$self->reply (426,
			      "File store error: $reason",
			      "Data connection has been closed.");
		return;
	      }
	  }
      }

    unless ($sock->close && $file->close)
      {
	my $reason = $self->system_error_hook();
	$self->reply (550, "File retrieval error: $reason");
	return;
      }

    $self->xfer_complete if $self->{_xferlog};
    $self->reply (226, "File store complete. Data connection has been closed.");
  }

=pod

=item $self->pre_configuration_hook ();

Hook: Called before command line arguments and configuration file
are read.

Status: optional.

Notes: You may append your own information to C<$self-E<gt>{version_string}>
from this hook.

=cut

sub pre_configuration_hook
  {
  }

=pod

=item $self->options_hook (\@args);

Hook: Called before command line arguments are parsed.

Status: optional.

Notes: You can use this hook to supply your own command line arguments.
If you parse any arguments, you should remove them from the @args
array.

=cut

sub options_hook
  {
  }

=pod

=item $self->post_configuration_hook ();

Hook: Called after all command line arguments and configuration file
have been read and parsed.

Status: optional.

=cut

sub post_configuration_hook
  {
  }

=pod

=item $self->post_bind_hook ();

Hook: Called only in daemon mode after the control port is bound
but before starting the accept infinite loop block.

Status: optional.

=cut

sub post_bind_hook
  {
  }

=pod

=item $self->pre_accept_hook ();

Hook: Called in daemon mode only just before C<accept(2)> is called
in the parent FTP server process.

Status: optional.

=cut

sub pre_accept_hook
  {
  }

=pod

=item $self->post_accept_hook ();

Hook: Called both in daemon mode and in inetd mode just after the
connection has been accepted. This is called in the child process.

Status: optional.

=cut

sub post_accept_hook
  {
  }

=pod

=item $rv = $self->access_control_hook;

Hook: Called after C<accept(2)>-ing the connection to perform access
control. Detailed request information is contained in the $self
object.  If the function returns -1 then the socket is immediately
closed and no FTP processing happens on it. If the function returns 0,
then normal access control is performed on the socket before FTP
processing starts. If the function returns 1, then normal access
control is I<not> performed on the socket and FTP processing begins
immediately.

Status: optional.

=cut

sub access_control_hook
  {
    return 0;
  }

=pod

=item $rv = $self->process_limits_hook;

Hook: Called after C<accept(2)>-ing the connection to perform
per-process limits (eg. by using the setrlimit(2) system
call). Access control has already been performed and detailed
request information is contained in the C<$self> object.

If the function returns -1 then the socket is immediately closed and
no FTP processing happens on it. If the function returns 0, then
normal per-process limits are applied before any FTP processing
starts. If the function returns 1, then normal per-process limits are
I<not> performed and FTP processing begins immediately.

Status: optional.

=cut

sub process_limits_hook
  {
    return 0;
  }

=pod

=item $rv = $self->authentication_hook ($user, $pass, $user_is_anon)

Hook: Called to perform authentication. If the authentication
succeeds, this should return 0 (or any positive integer E<gt>= 0).
If the authentication fails, this should return -1.

Status: required.

=cut

sub authentication_hook
  {
    die "authentication_hook is required";
  }

=pod

=item $self->user_login_hook ($user, $user_is_anon)

Hook: Called just after user C<$user> has successfully logged in. A good
place to change uid and chroot if necessary.

Status: optional.

=cut

sub user_login_hook
  {
  }

=pod

=item $dirh = $self->root_directory_hook;

Hook: Return an instance of a subclass of Net::FTPServer::DirHandle
corresponding to the root directory.

Status: required.

=cut

sub root_directory_hook
  {
    die "root_directory_hook is required";
  }

=pod

=item $self->pre_command_hook;

Hook: This hook is called just before the server begins to wait for
the client to issue the next command over the control connection.

Status: optional.

=cut

sub pre_command_hook
  {
  }

=pod

=item $rv = $self->command_filter_hook ($cmdline);

Hook: This hook is called immediately after the client issues
command C<$cmdline>, but B<before> any checking or processing
is performed on the command. If this function returns -1, then
the server immediately goes back to waiting for the next
command. If this function returns 0, then normal command filtering
is carried out and the command is processed. If this function
returns 1 then normal command filtering is B<not> performed
and the command processing begins immediately.

Important Note: This hook must be careful B<not> to overwrite
the global C<$_> variable.

Do not use this function to add your own commands. Instead
use the C<$self-E<gt>{command_table}> and C<$self-E<gt>{site_command_table}>
hashes.

Status: optional.

=cut

sub command_filter_hook
  {
    return 0;
  }


=pod

=item $error = $self->transfer_hook ($mode, $file, $sock, \$buffer);

  $mode     -  Open mode on the File object (Either reading or writing)
  $file     -  File object as returned from DirHandle::open
  $sock     -  Data IO::Socket object used for transfering
  \$buffer  -  Reference to current buffer about to be written

The \$buffer is passed by reference to minimize the stack overhead
for efficiency purposes only.  It is B<not> meant to be modified by
the transfer_hook subroutine.  (It can cause corruption if the
length of $buffer is modified.)

Hook: This hook is called after reading $buffer and before writing
$buffer to its destination.  If arg1 is "r", $buffer was read
from the File object and written to the Data socket.  If arg1 is
"w", $buffer will be written to the File object because it was
read from the Data Socket.  The return value is the error for not
being able to perform the write.  Return undef to avoid aborting
the transfer process.

Status: optional.

=cut

sub transfer_hook
  {
    return undef;
  }

=pod

=item $self->post_command_hook ($cmd, $rest)

Hook: This hook is called after all command processing has been
carried out on this command. C<$cmd> is the command, and
C<$rest> is the remainder of the command line.

Status: optional.

=cut

sub post_command_hook
  {
  }

=pod

=item $self->system_error_hook

Hook: This hook is used instead of $! when what looks like a system error
occurs during a virtual filesystem handle method.  It can be used by the
virtual filesystem to provide explanatory text for a virtual filesystem
failure which did not actually set the real $!.

Status: optional.

=cut

sub system_error_hook
  {
    return "$!";
  }

=pod

=item $self->quit_hook

Hook: This hook is called after the user has C<QUIT> or if the FTP
client cleanly drops the connection. Please note, however, that this
hook is I<not> called whenever the FTP server exits, particularly in
cases such as:

 * The FTP server, the Perl interpreter or the personality
   crashes unexpectedly.
 * The user fails to log in.
 * The FTP server detects a fatal error, sends a "421" error code,
   and abruptly exits.
 * Idle timeouts.
 * Access control violations.
 * Manual server shutdowns.

Unfortunately it is not in general easily possible to catch these
cases and cleanly call a hook. If your personality needs to do cleanup
in all cases, then it is probably better to use an C<END> block inside
your Server object (see L<perlmod(3)>). Even using an C<END> block
cannot catch cases where the Perl interpreter crashes.

Status: optional.

=cut

sub quit_hook
  {
  }

#----------------------------------------------------------------------

# The Net::FTPServer::ZipMember class is used to implement the ZIP
# file generator (in archive mode). This class is carefully and
# cleverly designed so that it doesn't break if Archive::Zip is not
# present. This class is mostly based on Archive::Zip::NewFileMember.

package Net::FTPServer::ZipMember;

use strict;

use vars qw(@ISA);
@ISA = qw(Archive::Zip::Member);

use Net::FTPServer::FileHandle;

# Verify this exists first by using ``exists $INC{"Archive/Zip.pm"}''.
eval "use Archive::Zip";

sub _newFromFileHandle
  {
    my $class = shift;
    my $fileh = shift;

    return undef unless exists $INC{"Archive/Zip.pm"};

    my $self = $class->new (@_);

    $self->{fileh} = $fileh;

    my $filename = $fileh->filename;
    $self->fileName ($filename);
    $self->{externalFileName} = $filename;

    $self->{compressionMethod} = &{$ {Archive::Zip::}{COMPRESSION_STORED}};

    my ($mode, $perms, $nlink, $user, $group, $size, $time) = $fileh->status;
    $self->{compressedSize} = $self->{uncompressedSize} = $size;
    $self->desiredCompressionMethod
      ($self->compressedSize > 0
       ? &{$ {Archive::Zip::}{COMPRESSION_DEFLATED}}
       : &{$ {Archive::Zip::}{COMPRESSION_STORED}});
    $self->unixFileAttributes ($perms);
    $self->setLastModFileDateTimeFromUnix ($time);
    $self->isTextFile (0);

    $self;
  }

sub externalFileName
  {
    shift->{externalFileName};
  }

sub fh
  {
    my $self = shift;

    return $self->{fh} if $self->{fh};

    $self->{fh} = $self->{fileh}->open ("r")
      or return &{$ {Archive::Zip::}{AZ_IO_ERROR}};

    $self->{fh};
  }

sub rewindData
  {
    my $self = shift;

    my $status = $self->SUPER::rewindData (@_);
    return $status if $status != &{$ {Archive::Zip::}{AZ_OK}};

    return &{$ {Archive::Zip::}{AZ_IO_ERROR}} unless $self->fh;

    # Not all personalities can seek backwards in the stream. Close
    # the file and reopen it instead.
    $self->endRead == &{$ {Archive::Zip::}{AZ_OK}}
      or return &{$ {Archive::Zip::}{AZ_IO_ERROR}};
    $self->fh;

    return &{$ {Archive::Zip::}{AZ_OK}};
  }

sub _readRawChunk
  {
    my $self = shift;
    my $dataref = shift;
    my $chunksize = shift;

    return (0, &{$ {Archive::Zip::}{AZ_OK}}) unless $chunksize;

    my $bytesread = $self->fh->sysread ($$dataref, $chunksize)
      or return (0, &{$ {Archive::Zip::}{AZ_IO_ERROR}});

    return ($bytesread, &{$ {Archive::Zip::}{AZ_OK}});
  }

sub endRead
  {
    my $self = shift;

    if ($self->{fh})
      {
	$self->{fh}->close
	  or return &{$ {Archive::Zip::}{AZ_IO_ERROR}};
	delete $self->{fh};
      }
    return &{$ {Archive::Zip::}{AZ_OK}};
  }

1 # So that the require or use succeeds.

__END__

=back 4


=head1 BUGS

The SIZE, REST and RETR commands probably do not work correctly
in ASCII mode.

REST does not work before STOR/STOU/APPE (is it supposed to?)

User upload/download limits.

Limit number of clients by host or IP address.

The following commands are recognized by C<wu-ftpd>, but are not yet
implemented by C<Net::FTPServer>:

  SITE CHMOD   There is a problem supporting this with our VFS.
  SITE GPASS   Group functions are not really relevant for us.
  SITE GROUP   -"- ditto -"-
  SITE GROUPS  -"- ditto -"-
  SITE INDEX   This is a synonym for SITE EXEC.
  SITE MINFO   This command is no longer supported by wu-ftpd.
  SITE NEWER   This command is no longer supported by wu-ftpd.
  SITE UMASK   This command is difficult to support with VFS.

Symbolic links are not handled elegantly (or indeed at all) yet.

Equivalent of ProFTPDE<39>s ``DisplayReadme'' function.

The ability to hide dot files (probably best to build this
into the VFS layer). This should apply across all commands.
See ProFTPDE<39>s ``IgnoreHidden'' function.

Access to LDAP authentication database (can currently be done using a
PAM module). In general, we should support pluggable authentication.

Log formatting similar to ProFTPD command LogFormat.

More timeouts to avoid various denial of service attacks. For example,
the server should always timeout when waiting too long for an
active data connection.

Support for IPv6 (see RFC 2428), EPRT, EPSV commands.

See also "XXX" comments in the code for other problems, missing features
and bugs.

=head1 FILES

  /etc/ftpd.conf
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/DirHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/FileHandle.pm
  /usr/lib/perl5/site_perl/5.005/Net/FTPServer/Handle.pm

=head1 AUTHORS

Richard Jones (rich@annexia.org),
Rob Brown (bbb@cpan.org),
Keith Turner (keitht at silvaco.com),
Azazel (azazel at azazel.net),
and many others.

=head1 COPYRIGHT

Copyright (C) 2000 Biblio@Tech Ltd., Unit 2-3, 50 Carnwath Road,
London, SW6 3EG, UK.

Copyright (C) 2000-2003 Richard Jones (rich@annexia.org) and
other contributors.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 SEE ALSO

L<Net::FTPServer::Handle(3)>,
L<Net::FTPServer::FileHandle(3)>,
L<Net::FTPServer::DirHandle(3)>,
L<Net::FTP(3)>,
L<perl(1)>,
RFC 765,
RFC 959,
RFC 1579,
RFC 2389,
RFC 2428,
RFC 2577,
RFC 2640,
Extensions to FTP Internet Draft draft-ietf-ftpext-mlst-NN.txt.

=cut
