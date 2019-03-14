package Net::FullAuto;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2019  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or
#    modify it under the terms of the GNU Affero General Public License
#    as published by the Free Software Foundation, either version 3 of
#    the License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################


our $VERSION='1.0000465';


use 5.005;


use strict;
use warnings;

BEGIN {
   my @ARGS=@ARGV;
   my $quiet=0;
   my $args='';
   foreach (@ARGS) {
      if ($_ eq '--password') {
         $args.='--password ';
         shift @ARGS;
         $args.='******** '
            if ($ARGS[0] && ((length $ARGS[0]<3) || 
            (unpack('a2',$ARGS[0]) ne '--')));
         next;
      } elsif ($_ eq '--quiet' ||
               $_ eq '--version' ||
               $_ =~ /^-[a-uw-zA-UW-Z]*[Vv]/ ||
               $_ =~ '--cat') {
         $quiet=1; 
      }
      $args.="$_ ";
   } chop $args;
   my $nl=(grep { $_ eq '--cron' } @ARGV)?'':"\n";
   print "Command Line -> $0 $args\n" if !$nl;
   print "STARTING FullAuto© on ". localtime() . "\n"
      if !$quiet && (-1<index $0,'fullauto.pl');

   our $toppath='';our $cpu='';
   $main::planarg||='';$main::cronarg||='';
   if ($main::planarg || $main::cronarg) {
      if (-e '/usr/bin/top') {
         $toppath='/usr/bin/';
      } elsif (-e '/bin/top') {
         $toppath='/bin/';
      } elsif (-e '/usr/local/bin/top') {
         $toppath='/usr/local/bin/';
      }
      if ($toppath) {
         my $top_timeout=60;
         eval {
            $SIG{ALRM} = sub { die "alarm\n" }; # \n required
            alarm($top_timeout);
            &Net::FullAuto::FA_Core::acquire_semaphore(1111,
               "Top CPU check Timed Out at Line: ".__LINE__);
            open(OH,"${toppath}top -b -n2 -d.1|") ||
               die "Cannot run ${toppath}top -b -n2 -d.1`: $!\n";
            while (my $line=<OH>) {
               chomp $line;
               $cpu=$line if -1<index $line,"idle";
            }
            close OH;
            &Net::FullAuto::FA_Core::release_semaphore(1111);
            alarm(0);
         };
         if ($@ eq "alarm\n") {
            print "\n\n";
            &handle_error(
               "Time for Top CPU check has Expired.",
               '__cleanup__');
         }
      }
   } 
}

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(fa_login connect_ssh connect_sftp connect_secure cleanup
                 connect_ftp connect_telnet connect_shell acquire_fa_lock
                 release_fa_lock send_email ls_parse fetch log);

use Term::Menus 2.54;
use Tie::Cache;
use Sort::Versions;
use Crypt::CBC;
use Crypt::DES;
use JSON;
use URI;
use HTTP::Date;
use Capture::Tiny;
use Net::Telnet;
use Email::Sender;
use MIME::Entity;
use IO::Pty;
use BerkeleyDB;

sub fa_login
{
   return &Term::Menus::fa_login(@_);
}

sub connect_ssh
{
   package connect_ssh;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_ssh(@_);
}

sub connect_shell
{
   package connect_shell;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_shell(@_);
}

sub connect_sftp
{
   package connect_sftp;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_sftp(@_);
}

sub connect_secure
{
   package connect_secure;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_secure(@_);
}

sub connect_ftp
{
   package connect_ftp;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_ftp(@_);
}

sub connect_telnet
{
   package connect_telnet;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::connect_telnet(@_);
}

sub cleanup
{
   package cleanup;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::cleanup(@_);
}

sub acquire_fa_lock
{
   package acquire_fa_lock;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::acquire_fa_lock(@_);
}

sub release_fa_lock
{
   package release_fa_lock;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::release_fa_lock(@_);
}

sub send_email
{
   package send_email;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::send_email(@_);
}

sub fetch
{
   package fetch;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::fetch(@_);
}

sub log
{
   package log;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::log(@_);
}

sub ls_parse
{
   package ls_parse;
   use Net::FullAuto::FA_Core;
   return Net::FullAuto::FA_Core::ls_parse(@_);
}

1;

__END__;


######################## User Documentation ##########################


## To format the following documentation into a more readable format,
## use one of these programs: perldoc; pod2man; pod2html; pod2text.
## For example, to nicely format this documentation for printing, you
## may use pod2man and groff to convert to postscript:
##   pod2man FullAuto.pm | groff -man -Tps > FullAuto.ps

=head1 Name

C<Net::FullAuto> - Fully Automate ANY Workload with *Persistent* SSH/SFTP from One Host

=head1 Note to Users

Please contact me or my team at the following email addresses -

=over 4 

=item

B<Brian.Kelly@fullauto.com> or B<team@fullauto.com>

=back

and let us know of any and all bugs, issues, problems, questions
as well as suggestions for improvements to both the documentation
and module itself. We will make every effort to get back to you quickly.

Update the module from CPAN *often* - as we anticipate adding
documentation and fixing bugs and making improvements often. 

Brian Kelly, March 9, 2016

=head1 License

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU Affero General Public License for more details.

=head1 Shell Synopsis - simple "Hello World"

=over 4

=item

   use Net::FullAuto;
   $localhost=connect_shell();
   ($stdout,$stderr,$exitcode)=$localhost->cmd("echo 'Hello World'");
   print $stdout;

=back

=head1 SSH & SFTP Combined Synopsis

=over 4

=item

   use Net::FullAuto;

   my $ip_or_hostname = $ARGV[0] || 'localhost';
   my $username       = $ARGV[1] || getlogin || getpwuid($<);
   my $identity_file  = $ARGV[2] || ''; # required unless password or
                                        # or key-based login
   my $password       = $ARGV[3] || ''; # required unless identity file
                                        # or key-based login
   my $remote_host_block={

      Label => 'Remote Host',
      Hostname => $ip_or_hostname,
      Login => $username,
      IdentityFile => $identity_file,  # can leave out if password or
                                       # or key-based login
      Password => $password,        # can leave out if identity file
                                    # or key-based login
                                 # password is CLEAR TEXT, which
                                 # is poor security. Consider
                                 # IdentityFile or key-based login
      #log => 1,
      #debug => 1,
      #quiet => 1,

   };

   my ($remote_host_handle,$error)=('','');   # Define and scope variables

   ($remote_host_handle,$error)=connect_secure($remote_host_block);
   die "Connect_SSH ERROR!: $error\n" if $error;

   my ($stdout,$stderr,$exitcode)=('','',''); # Define and scope variables

   ($stdout,$stderr,$exitcode)=
      $remote_host_handle->cmd('hostname'); # Run 'hostname' command in
   die $stderr if $stderr;                  # remote command line environment

   print "REMOTE HOSTNAME IS: $stdout\n";

   ($stdout,$stderr,$exitcode)=
      $remote_host_handle->cwd('/'); # Change working directory to the
   die $stderr if $stderr;           # root of the remote host

   ($stdout,$stderr,$exitcode)=$remote_host_handle->cmd('pwd');
   die $stderr if $stderr;

   print "REMOTE HOST CURRENT DIRECTORY VIA SSH IS: $stdout\n";

   ($stdout,$stderr,$exitcode)=$remote_host_handle->cwd('/');
   die $stderr if $stderr;

   my @stdout=$remote_host_handle->sftp('pwd');
   print "REMOTE HOST CURRENT DIRECTORY VIA SFTP IS: $stdout[1]<==\n";

   $remote_host_handle->lcd('~');

   @stdout=$remote_host_handle->sftp('!pwd');

   print "LOCAL HOST CURRENT DIRECTORY VIA SFTP IS: $stdout[1]<==\n";

   #$remote_host_handle->close(); # Use this -OR- cleanup method
   cleanup; # Use this routine for faster cleanup

=back

=head1 SSH Synopsis

=over 4

=item

   use Net::FullAuto;

   my $ip_or_hostname = $ARGV[0] || 'localhost';
   my $username       = $ARGV[1] || getlogin || getpwuid($<);
   my $identity_file  = $ARGV[2] || ''; # required unless password or
                                        # or key-based login
   my $password       = $ARGV[3] || ''; # required unless identity file
                                        # or key-based login

   my $remote_host_block={

      Label => 'Remote Host',
      Hostname => $ip_or_hostname,
      Login => $username,
      IdentityFile => $identity_file,  # can leave out if password or
                                       # or key-based login
      Password => $password,        # can leave out if identity file
                                    # or key-based login
                                 # password is CLEAR TEXT, which
                                 # is poor security. Consider
                                 # IdentityFile or key-based login
      #log => 1,
      #debug => 1,
      #quiet => 1,

   };

   my ($remote_host_handle,$error)=('','');   # Define and scope variables

   ($remote_host_handle,$error)=connect_ssh($remote_host_block);
   die "Connect_SSH ERROR!: $error\n" if $error;

   my ($stdout,$stderr,$exitcode)=('','',''); # Define and scope variables

   ($stdout,$stderr,$exitcode)=
      $remote_host_handle->cmd('hostname'); # Run 'hostname' command in
   die $stderr if $stderr;                  # remote command line environment

   print "REMOTE HOSTNAME IS: $stdout\n";

   ($stdout,$stderr,$exitcode)=
      $remote_host_handle->cwd('/'); # Change working directory to the
   die $stderr if $stderr;           # root of the remote host

   ($stdout,$stderr,$exitcode)=$remote_host_handle->cmd('pwd');
   die $stderr if $stderr;

   print "CURRENT DIRECTORY IS: $stdout\n";

   #$remote_host_handle->close(); # Use this -OR- cleanup method
   cleanup; # Use this routine for faster cleanup

=back

=head1 SFTP Synopsis

=over 4

=item

   use Net::FullAuto;

   my $ip_or_hostname = $ARGV[0] || 'localhost';
   my $username       = $ARGV[1] || getlogin || getpwuid($<);
   my $identity_file  = $ARGV[2] || ''; # required unless password or
                                        # or key-based login
   my $password       = $ARGV[3] || ''; # required unless identity file
                                        # or key-based login

   my $remote_host_block={

      Label => 'Remote Host',
      HostName => $ip_or_hostname,
      LoginID => $username,
      IdentityFile => $identity_file, # can leave out if password or
                                      # or key-based login
      Password => $password,       # can leave out if identity file
                                   # or key-based login
                                # password is CLEAR TEXT, which
                                # is poor security. Consider
                                # IdentityFile or key-based login
      #log => 1,
      #debug => 1,
      #quiet => 1,

   };

   my ($remote_host_handle,$error)=connect_sftp($remote_host_block);
   die "Connect_SFTP ERROR!: $error\n" if $error;

   my ($stdout,$stderr)=('','',''); # Define and scope variables

   my @stdout=$remote_host_handle->cmd('pwd');

   print "REMOTE DIRECTORY IS: @stdout\n";

   ($stdout,$stderr)=$remote_host_handle->cwd('/');
   die $stderr if $stderr;

   @stdout=$remote_host_handle->cmd('pwd');

   print "CURRENT DIRECTORY IS: @stdout\n";

   #$remote_host_handle->close(); # Use this -OR- cleanup method
   cleanup; # Use this routine for faster cleanup

=back

=head1 FullAuto Framework (Coming Soon) Synopsis (Beta/Experimental)

=over 4

The FullAuto Framework utilizes the C<fa> command line utility. Limited functionality is already available, and is documented in various sections below. Only the "Framework" is experimental. FullAuto itself is fully released. The rest of the documentation describes fully released FullAuto functionality. See the L<Coming Soon|/Coming Soon> section below for more information on the FullAuto Framework and other features currently in development. You can preview elements of the FullAuto Framework with this command:

   fa --new-user

Using Term::Menus, the FullAuto "new user experience" demonstrates how a command environment solution (which is or should be the domain of most distributed workload automation) can be I<self-documenting>, without the need, overhead and cost of a web (or any other GUI) infrastructure. Self-documenting solutions are particularly needed for automated processes, because when they work I<properly>, an automated solution can go months or even years without a human examining it in detail - often long after the orginal implementers have left the organization. This is the first "page" of the "new user experience":


                         ___     _ _   _       _
                        | __|  _| | | /_\ _  _| |_  |
   (   /_ /_   _  _     | _| || | | |/ _ \ || |  _/ | \
   |/|/(-(( ()//)(-  To |_| \_,_|_|_/_/ \_\_,_|\__\___/c  username

   Items with the arrow character  >  are the current selection, Just
   press ENTER or Scroll with UP and DOWN arrow keys. You can also type
   the number of your selection, and then press ENTER to activate your
   selection.

      It appears that username is new to FullAuto,
      for there is no FullAuto Setup for this user.

   >   1      Getting Started (quickly) with FullAuto.
                   Recommended for beginners.

       2      Setup User username (Advanced Users)
       3      Continue with Login (No setup for username) &
                   Do Not Show this Screen Again
       4      Continue with Login (No setup for username)

   (Press [F1] for HELP)

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:


=back

=head1 Description

C<Net::FullAuto>S<  > (aka C<FullAuto>) is a Perl module and workload automation functionality that transforms Perl into a true multi-host scripting language. It accomplishes this with multiple B<*PERSISTENT*> SSH and SFTP connections to multiple hosts simultaneously. With FullAuto entire hosts are encapsulated in a single filehandle. Think of each filehandle as an always available SSH client (like PuTTY) and SFTP client (like WinSCP) that are available I<programmatically> to the script.

The importance of I<persistent> connections when attempting to programmatically control remote hosts cannot be over stated. Essentially, it means that FullAuto can "fully" automate just about B<EVERYTHING>.

To see FullAuto in action, please download and explore the "Self Service Demonstration" at L<http://sourceforge.net/projects/fullauto>. The demo contains an embedded YouTube video (L<https://youtu.be/gRwa1QoOS7M>) explaining and showing the entire automated process of setting up a complex multi-host infrastructure in the Amazon EC2 Cloud. After watching or while watching the video, you can run the demo and standup your own cloud infrastructure in just a few minutes.

The Hadoop demo is particularly interesting and timely given the recent explosion of BIG DATA and the need to access it more powerfully. The Hadoop demo utilizes a special FullAuto L<Instruction Set|http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/Hadoop_is.pm>" that stands up a complete 4 node/server cluster in the Amazon EC2 Cloud. Every element of the build and stand up is automated including using the EC2 API to launch servers, connecting to all 4 servers automatically with SSH & SFTP, downloading and compiling Hadoop source code from L<http://hadoop.apache.org|http://hadoop.apache.org>, downloading and installing Java and all other dependencies, and then cross-configuring all 4 nodes with discovered IP addresses and other information that was unknown at the beginning of the standup - and finally starting the cluster and launching an admin web portal.

Imagine a scripting language that can essentially turn an entire network of computers into a truly interactive collective. This is precisely what FullAuto does.

FullAuto utilizesS<  >C<ssh>S<  >andS<  >C<sftp>S<  >(can also useS<  >C<telnet>S<  >andS<  >C<ftp>, though for security reasons, this is NOT recommended) to bring the command environments of any number of remote computers (Operating System of remote computer does not matter), together in one convenient scripting space. With FullAuto, you write code once, on one computer, and have it execute on multiple computers simultaneously, in an interactive dynamic fashion, as if the many computers were truly one.

How is FullAuto different from programs like Chef (http://www.chef.io) and Puppet (http://www.puppetlabs.com) and Ansible (http://www.ansible.com) and Salt (http://www.saltstack.com)? All of which assert the same ability and functionality?

Chef and Puppet and Salt require the use of agents on remote hosts. FullAuto has no such dependency, as it is agent-less. It works against any SSH server implementation on any operating system. Ansible claims to be "agent-less" but actually has a dependency on the Python scripting language being available on the remote host, as well as requiring that the OpenSSH daemon on remote nodes be configured to utilize the ControlPersist feature. FullAuto has no such dependency (FullAuto does not even require Perl on the remote nodes), and if any manual terminal program or utility can connect to a device viaS<  >C<ssh>S<  >orS<  >C<sftp>S<  >orS<  >C<scp>S<  >or evenS<  >C<telnet>S<  >orS<  >C<ftp>,S<  >FullAuto can connect as well - persistently.

FullAuto goes beyond these packages in its unique ability to L<PROXY-CHAIN|/Proxy> multiple hosts with the same persistent connection capability. This means, without agents or any special configuration, FullAuto can L<proxy|/proxy> connect through any number of hosts and navigate multiple network segments to get you to the host and data you need - in REAL time! Real time interactive command channels and data feeds are the next "big thing", but till now have been incredibly difficult to setup, maintain and keep secure (not to mention "expensive"). With FullAuto, it is now possible for a single ssh process to proxy out through a firewall to a box in the DMZ, from that host go any distance across the internet to another ssh host in another organization's DMZ, proxy through that host and through the firewall, and continue navigating proxies until the process arrives at the host, functionality and data it needs. For additional security, the destination organization can also use FullAuto to host a real time "SSH Service API" (similar to web services) and allow a distant process controlled and precise access to hosts and data just as is provided with web services - without the burden of certificates, https, tokens, etc. - and with better performance (due to the simplicity and direct connect capability of FullAuto's architecture). Web services are still predominantly "stateless" due to the architecture of the http protocol. FullAuto is state-FULL, insuring the most direct access to remote host functionality and data imaginable - regardless of application. Moreover, because FullAuto proxy connections are lightweight, proxy hosts in DMZ environments can do double duty as "honey pots" - which themselves can be stood up, fully configured and fully managed automatically by FullAuto. (L<See the 'proxy' configuration element - below|/Proxy>).

FullAuto can be run by a user in a Menu driven, interactive mode (using the L<Term::Menus|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm> module - also written by Brian Kelly), or via UNIX or Linux C<cron> or Windows Scheduler or Cygwin C<cron> in a fully automated fashion.

Example: A user needs to pull data from a database, put it in a text file, zip and encrypt it, and then transfer that file to another computer on the other side of the world via the internet - in one-step.

Assume FullAuto is installed on computer one, the database is on computer two, and the remote computer in Japan is computer three. When the user starts the script using C<Net::FullAuto>, FullAuto will connect via C<ssh> and C<sftp> (simultaneously) to computer two, and via C<sftp> to computer three. Using a sql command utility on computer two, data can be extracted and piped to a text file on computer two. Then, FullAuto will run the command for a C<zip> utility over C<ssh> on computer two to compress the file. Next (assume the encryption software is on computer one) FullAuto will transfer this file to computer one, where it can be encrypted with licensed encryption software, and then finally, the encrypted file can be transferred to computer three via C<sftp>. Email and pager software can be used for automated notification as well.

Example: The same process above needs to run at 2:00am unattended.

A script using FullAuto can be run via C<cron> (or any other scheduler) to perform the same actions above without user involvement.

Each individual command run on a remote computer returns to FullAuto STDOUT (output) and STDERR (error messages) and command exit codes. With these features, users and programmers can write code to essentially trap remote errors "locally" and respond with any number of error recovery approaches. Everything from sending an e-mail, to re-running the command, to switching remote computers and much more is available as error handling options. The only limits are the skills and ingenuity of the programmers and administrators using FullAuto. If FullAuto loses a connection to a remote host, automatic attempts will be made to re-connect seamlessly - with errors reported when the configured maximum numbers of attempts fail.

Connecting to a remote host is as simple as:

 ------------------------------------------------------------------------

 use Net::FullAuto;

 my $remote_host_info={

      Label => 'Remote Host',
      Hostname => $ip_or_hostname,
      Login => $username,
      IdentityFile => $identity_file,  # can leave out if password or
                                       # or key-based login is used
      # Password => $password,         # can leave out if identity file
                                       # or key-based login is used
 };

 my $remote_host_handle=connect_ssh($remote_host_info);

 ------------------------------------------------------------------------

Commands also are easy:

 ------------------------------------------------------------------------

 my ($stdout,$stderr,$exitcode)=$remote_host_handle->cmd('ls -l');

 ------------------------------------------------------------------------

In addition, no cleanup is necessary - FullAuto handles cleanup I<automatically>.

FullAuto uses C<ssh> and C<sftp> for communication across hosts and devices. FullAuto connections can be configured to use password-less key exchange.

=head1 Reasons to Use this Module

To do everything you could do with other workload automation packages like Chef, Puppet, Anisble and Salt without the cost, overhead and resource requirements of those solutions. To go beyond those packages and set up real-time ssh proxy-chained interactive command channels and data feeds. To do L<Managed File Transfers|/"Managed File Transfers"> via sftp or insecure ftp without having to impose requirements on owners of remote host servers. To have an entire workload automation encapsulated in a single L<Instruction Set|/Instruction Sets> that often is so tiny; it can easily be attached to an email. You need a solution that is as easy to install as C<install Net::FullAuto>. You want the entire CPAN available for use in your L<Instruction Sets|/Instruction Sets>. You want the true strengths of Perl and the Perl Community and features like Perl's unsurpassed regular expression functionality readily available. You want the flexibility of a serial scripting language, and the option to use modern OO programming with Moose. A solution that can work equally well on both UNIX/Linux and Windows operating systems (FullAuto works on Windows within the Cygwin Linux layer for Windows environment).

FullAuto is the SIMPLEST and most direct path to Full Automation (hence the name). That path is to make full use of trusted connectivity components already in widespread use on billions of devices the world over. SSH and SFTP are literally on every UNIX and Linux host in the world - and are both easily added to MS Windows. SSH and SFTP are used to connect to multiple network devices such as routers and switches. SSH and SFTP are a widely available means to connect to the Mainframe. All we EVER needed was an automation solution that simply utilized this widespread access architecture already in place - AS IS, without requiring any special features or configuration. That solution is now a reality - and its name is B<FullAuto>.

=head1 Connect Methods

=head2 B<%connection_info> - hash to pass connection information to the following connect_<type> methods.

=over 4

=item

   %connection_info=(

      Label    => '<label_to_identify>',
      Hostname => '<hostname>', # Optional - need Hostname -or- IP Address
      IP       => '<ip address>',
      Login    => '<login id>',
      Use      => '<hostname or ip>, # When both Hostname and IP are listed,
                                     # use the specified first
      IdentityFile => '<path to file>', # Optional - RECOMMENDED (most secure)
      Password => '<password>', # Optional - *NOT* Recommended
      Log      => 1 | 0,     # Optional - Log output to FullAuto log
      Debug    => 1 | 0,     # Optional - Display debug info in output
      Quiet    => 1 | 0,     # Optional - Suppress output
      Timeout  => <seconds>, # Optional - Default is 90 seconds. Use to extend
                             # time allowed to establish a connection
      Proxy    => <\%proxy_connection_info>, # Optional - use other host as a
                                             # Proxy
 
   );

=back

=head3 Label

=over 4

=item

C<Label =E<gt> E<lt>labelE<gt>,>

This element contains the label to identify the host.

=back

=head3 Hostname

=over 4

=item

C<Hostname =E<gt> E<lt>hostnameE<gt>,>

This element contains the hostname of the host. It can also be encoded with an ip address as no validation is done.

=back

=head3 IP

=over 4

=item

C<IP =E<gt> E<lt>ip addressE<gt>,>

This element contains the ip address of the host. It can also be encoded with a hostname as no validation is done.

=back

=head3 Use

=over 4

=item

C<Use =E<gt> E<lt>hostname|ipE<gt>,>

This element is used when both a hostname and ip address are included in C<%connection_info>. It is used to indicate which to "use" first - hostname or ip address. FullAuto will use try the hostname first, if both hostname and ip address are configured, and C<Use> is not used.

=back

=head3 Password

=over 4

=item

C<Password =E<gt> E<lt>passwordE<gt>,>

This element contains the password to use when logging in. You are strongly advised NOT to use this element, as clear text passwords are VERY insecure! Rather, use keys or identityfiles to authenticate against remote ssh/sftp servers.

=back

=head3 IdentityFile

=over 4

=item

C<IdentityFile =E<gt> E<lt>path to identityfileE<gt>,>

This element contains the path to the identityfile used to login to the remote host. If you are not already authenticating with this approach, you are STRONGLY encouraged to consider doing so. Clear text passwords are notoriously unsafe.

=back

=head3 Log

=over 4

=item

C<Log =E<gt> E<lt>1|0|path_to_logfileE<gt>,>

FullAuto has built in logging, but in order to use it, it must be explicitly turned on. It can be turned on and off in C<%connection_info> using this element. A custom logfile and location can be indicated rather than a '1' which simply turns it on. The default location for FullAuto logs is C</home/E<lt>userE<gt>/.fullauto/logs>. FullAuto does NOT have one big log, but rather creates an entirely new log for each script/Instruction Set invocation. This is a typical example: C<FA9320d031716h14m13s19.log> The naming convention of the file is as follows.

 FA        -> identifies this as a FullAuto log file
 9320      -> PID (Process ID) of the FullAuto process to which this log belongs
 d031716   -> Date of the log: March 17, 2016
 h14m13s19 -> h: hour 14 (2pm) m: 13 minutes s: 19 seconds

FullAuto logging is turned on by default when using the FullAuto Framework (C<fa> commandline executable). In addition to the log just described, a stdout file C<OUTPUT.txt> is also created in the same folder as the log. Each process overwrites this file.

Both files are placed in a zip file (C<fa_logs.zip>) in the current directory. Each process overwrites this file as well.

To turn off this behavior set the C<$save_fa_logs_dot_zip_in_current_directory> variable to zero '0' in the C<fa_conf.pm> configuration file. Use C<fa -V> to find the location.

=back

=begin html

<P CLASS="indented">
The <code>Log</code> element is used to dynamically turn on and off logging:<br><br>Turn on logging: <code>Log =&gt; 1,</code><br><br>Turn off logging: <code>Log =&gt; 0,</code><br><br>Turn on logging with custom name and path location: <code>Log =&gt; &lt;path_to_logfile&gt;,</code>
<P>

=end html

=head3 LogCount

=over 4

=item

C<Log =E<gt> E<lt>numberE<gt>,>

This element indicates how many logs to store. When the number is reached, FullAuto will delete the oldest.

=back

=head3 Debug

=over 4

=item

C<Debug =E<gt> E<lt>1|0E<gt>,>

This element instructs FullAuto to print all debug output to the screen.

=back

=head3 Quiet

=over 4

=item

C<Quiet =E<gt> E<lt>1|0E<gt>,>

This element instructs FullAuto suppress all output except Fatal Errors.

=back

=head3 Timeout

=over 4

=item

C<Timeout =E<gt> E<lt>1|0E<gt>,>

This element changes the default timeout value for any command that has no output. As long as a command has output, there is no timeout. The default timeout value is 90 seconds. It is advised that a stream of continuous output be provided if possible. Examine the options of commands you will be using, and use verbose or debug options if output is ordinarily light. When calling custom scripts - make sure those scripts provide output that comes continuously or at least within the 90-second timeout.

=back

=head3 Proxy

=over 4

=item

C<Proxy =E<gt> E<lt>\%proxy_connection_infoE<gt>,>



=back

=head2 connect_secure() - connect to remote host via ssh and sftp

=over 4

=item

C<($ssh_host_object,$error) = connect_secure(\%connection_info);>

C<$ssh_host_object = connect_secure(\%connection_info);>

=back

=begin html

<STYLE TYPE="text/css">
<!--
.indented
   {
   padding-left: 50pt;
   padding-right: 50pt;
   }
-->
</STYLE>
<P CLASS="indented">
Any connection errors will result in complete termination of
the process.</P>

<P CLASS="indented">
The <CODE>$secure_host_object</CODE> represents both ssh AND sftp connections
together in ONE<br>object.</P>
</P>
<P CLASS="indented">
The important thing to understand is that there is no other code
needed to connect to remote<br>hosts. <code>Net::FullAuto</code> handles all
connection details, such as dynamic remote-prompt discovery,<br>
AUTOMATICALLY. No need to define <i>or even know</i> what the remote
prompt is. This feature<br>'alone' is a major departure from most
other scriptable remote command and file transfer utilities.</P>

=end html

=head2 connect_ssh() - connect to remote host via ssh

=over 4

=item

C<($ssh_host_object,$error) = connect_ssh(\%connection_info);>

C<$ssh_host_object = connect_ssh(\%connection_info);>

=back

=begin html

<P CLASS="indented">
This method returns a ssh connection <i>only</i> - any attempt to
use file-transfer features with this object<br>will throw an error.
</P><P CLASS="indented">
Use this method if you do not need file-transfer capability in
your process.
</P>

=end html

=head2 connect_sftp() - connect to remote host via sftp

=over 4

=item

C<($sftp_host_object,$error) = connect_sftp(\%connection_info);>

C<$sftp_host_object = connect_sftp(\%connection_info);>

=back

=begin html

<P CLASS="indented">
This method returns a sftp connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you do not need
remote command-line capability in your process.</P>

=end html

=head2 connect_insecure() - connect to remote host via telnet & ftp

=over 4

=item

C<($insecure_host_object,$error) = connect_insecure(\%connection_info);>

=back

=begin html

<P CLASS="indented">
All Connect Methods return a <i>host object</i> if connection
is successful, or error message(s)<br>
in the error variable if the method is requested to return a list.
Otherwise, if the method is<br>requested to only return a scalar:
</P>

=end html

=over 4

=item

C<$insecure_host_object = connect_insecure(\%connection_info);>

=back

=begin html

<P CLASS="indented">
Any connection errors will result in complete termination of
the process.</P>

<P CLASS="indented">
The <CODE>$insecure_host_object</CODE> represents both telnet AND ftp 
connections together in ONE<br>object. 
</P>

=end html

=over 4

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING - 
use C<connect_secure()> whenever possible.

=back

=head2 connect_telnet() - connect to remote host via telnet

=over 4

=item

C<($ssh_host_object,$error) = connect_telnet(\%connection_info);>

C<$ssh_host_object = connect_telnet(\%connection_info);>

=back

=begin html

<P CLASS="indented">
This method returns a telnet connection <i>only</i> - any attempt to
use file-transfer features with this object<br>will throw an error.
</P><P CLASS="indented">
Use this method if you do not need file-transfer capability in
your process.
</P>

=end html

=over 4

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_ssh()> whenever possible.

=back

=head2 connect_ftp() - connect to remote host via ftp

=over 4

=item

C<($ftp_host_object,$error) = connect_ftp(\%connection_info);>

C<$ftp_host_object = connect_ftp(\%connection_info);>

=back

=begin html

<P CLASS="indented">
This method returns an ftp connection <i>only</i> - any attempt to
use remote command-line features with this object<br>will throw
an error.</P><P CLASS="indented">Use this method if you do not need
remote command-line capability in your process.</P>

=end html

=over 4

=item

THIS METHOD IS *NOT* RECOMMENDED for CONNECTING -
use C<connect_sftp()> whenever possible.

=back

=head2 connect_shell() - connect to local shell

=over 4

=item

C<($shell_localhost_object,$error) = connect_shell();>

C<($shell_localhost_object,$error) = connect_shell(\%connection_info);>

C<$shell_localhost_object = connect_shell();>

C<$shell_localhost_object = connect_shell(\%connection_info);>

=back

=begin html

<P CLASS="indented">
This method returns a local shell handle. When this connect method is
used, a separate process is forked in memory and a local shell (currently
only BASH is supported) is spawned within it. In this way, you can have
any number of local shell processes running that each emulate a command
line environment precisely as if it were a remote host handle. This is an
extremely useful feature and allows you to run a number of local processes
in their own protected environments in parallel. The one difference of note
between a local process and a remote one, is that the <code>\%connection_info
</code> hash is <i>optional</i>. With <code>connect_shell(\%connection_info)
</code> the only elements of <code>\%connection_info</code> that are
available are <code> debug</code>, <code> quiet</code>, and <code> log</code>.

=end html

=head1 Host Object Elements

A Host Object is in fact an ordinary Perl object in that is contains both elements and methods. The elements contain either one or two process handles, and descriptive metadata about the handle(s).

=head2 _hostlabel

=over 4

=item

C<$connect_secure_object-E<gt>{_hostlabel} = [ 'Label','' ];>

=back

=begin html

<P CLASS="indented">
The <code>_hostlabel</code> element contains the label you assigned in the <code>\%connection_info</code> hash passed to the <code>connect_&lt;type&gt;()</code> method. Each object must have a unique label. If FullAuto detects that you are attempting to create a new object with a label already in use by another object, it will terminate with an error. The <code>_hostlabel</code> element is an array, and you may assign more than one label to an object.<br><br><code>$connect_secure_object-E<gt>{_hostlabel} = [ 'Label','Label Two' ];</code>.<br><br>You can access the primary label at any time with the following syntax:<br><br><code>$connect_secure_object-&gt;{_hostlabel}-&gt;[0];</code>
</P>

=end html

=head2 _cmd_handle

=over 4

=item

C<$connect_secure_object-E<gt>{_cmd_handle} = Net::Telnet=GLOB(0x8006c330);>

C<$connect_ssh_object-E<gt>{_cmd_handle} = Net::Telnet=GLOB(0x8006c330);>

=back

=begin html

<P CLASS="indented">
The <code>_cmd_handle</code> element contains the process handle GLOB. This is a Net::Telnet handle as the <a href="http://search.cpan.org/~jrogers/Net-Telnet-3.04/lib/Net/Telnet.pm">Net::Telnet</a> module from CPAN is used to actually connect to a spawned local shell (bash) process, that is then used to launch SSH and SFTP sessions. Don't let the name "Net::Telnet" confuse you - when <code>connect_secure()</code> and other FullAuto secure connect methods are used, the actual clear text and insecure <i>'telnet'</i> protocol is <b>*NOT*</b> being used! SSH and SFTP are being used instead. Net::Telnet can be used as a lightweight "Expect" and that is precisely how it is used in the internals of Net::FullAuto. As such, all the features and methods of Net::Telnet are available within this handle. There are times when it is very useful to access some of Net::Telnet's methods directly and bypass FullAuto's input and output manipulations. When doing so, you will have to account for the output artifacts that FullAuto handles for you, but there are occasions where this is desirable - especially when front-ending and automating interactive command line programs that prompt the user. Examples of this are provided later in the documentation. So just what does FullAuto provide that Net::Telnet does not? For starters, Net::Telnet requires you to know the prompt of each remote host you want to connect and interact with. This sounds like a simple requirement, but in actual practice, this requirement is a MAJOR headache. The truth is, prompts are very dynamic artifacts that change from host to host, shell to shell, user to user, and can and do change without notice. Prompt changes are one of the most common reasons automated workloads break! FullAuto dynamically discovers the prompt for you on login, eliminating this requirement altogether - and making your job of automating processes significantly easier. FullAuto enables you to access correct output, error output from STDERR, and command exit codes with each command sent. Net::Telnet alone does not provide this kind of advanced functionality. FullAuto automatically handles echoed prompts and other telnet protocol line noise, relieving the user of having to deal with any of it. Many users over the years have attempted to use Net::Telnet the way they <b>CAN</b> use FullAuto, without understanding and appreciating Net::Telnet's limitations and the actual knowledge and skill needed to use Net::Telnet successfully. The goal of the FullAuto project was to essentially remove nearly all of Net::Telnet's limitations, and allow users to automate workloads as they would intuitively expect they should be able to - like they would do it manually in PuTTY for instance, but <i>programmatically </i> instead. A user can successfully use FullAuto without needing a deep dive into the documentation, and without a big learning curve - unlike when trying to use Net::Telnet alone. FullAuto also provides process locking - a necessary feature when automating large and complex workloads.<br><br>Net::Telnet methods can be accessed in the following manner:<br><br><code>$connect_secure_object-&gt;{_cmd_handle}-&gt;print();</code>
</P>

=end html

=over 4

=item

C<$connect_sftp_object-E<gt>{_cmd_handle} = Net::Telnet=GLOB(0x8006c330);>

=back

=begin html

<P CLASS="indented">
When connecting via the <code>connect_sftp()</code> method, the resulting <code>_cmd_handle</code> element contains the command environment of the local sftp program only. This environment is very limited, with the command set comprising ls, put, get, cd, lcd, etc. One important feature of note however, is the escape to local command line feature that is accomplished with the exclamation point or 'bang' character. This does work as expected with this handle. For example, to get the hostname of the local host, this will work as expected:<br><br><code>$connect_sftp_object->cmd('!hostname');</code>
</P>

=end html

=head2 _ftp_handle

=over 4

=item

C<$connect_secure_object-E<gt>{_ftp_handle} = Net::Telnet=GLOB(0x8006c330);>

=back

=begin html

<P CLASS="indented">
This element exists only when connecting via the <code>connect_secure()</code> and <code>connect_insecure()</code> methods. It's needed with these methods because the <code>_cmd_handle</code> element contains an ssh or telnet or shell command environment. Otherwise, for the <code>connect_sftp()</code> and <code>connect_ftp()</code> methods, the ftp handle is accessed through the <code>_cmd_handle</code> element. An example of usage is the following:<br><br><code>$connect_secure_object->{_ftp_handle}->cmd('!hostname');</code><br><br>Also available is a Host Object Method called ftpcmd(). It can be used instead:<br><br><code>$connect_secure_object->ftpcmd('!hostname');</code>
<P>

=end html

=head2 _cmd_type

=over 4

=item

C<$connect_secure_object-E<gt>{_cmd_type} = 'type'>;

=back

=begin html

<P CLASS="indented">
This element indicates what type of command connection exists in the connect_object. The possible values are <code>'ssh'</code>, <code>'telnet'</code> and <code>'shell'</code>.
<P>

=end html

=head2 _ftp_type

=over 4

=item

C<$connect_secure_object-E<gt>{_ftp_type} = 'sftp|ftp'>;

=back

=begin html

<P CLASS="indented">
This element indicates what type of file transfer connection (or method) exists in the connect_object. The possible values are <code>'ftp'</code> and <code>'sftp'</code>.
<P>

=end html

=head2 _connect

=over 4

=item

C<$connect_secure_object-E<gt>{_connect} = 'connect_E<lt>typeE<gt>'>;

=back

=begin html

<P CLASS="indented">
This element indicates which <code>connect_&lt;type&gt;()</code> method was used to create the host object.
<P>

=end html

=head2 _work_dirs

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs} = \%work_dirs;>

=back

=begin html

<P CLASS="indented">
This element is used heavily by the FullAuto <code>cwd()</code> method. It is listed here for informational purposes, but it is NOT recommended that anyone modify these values directly.
<P>

=end html

=head3 _work_dirs -> _cwd

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_cwd} = cwd (current working directory in Unix format)>

=back

=begin html

<P CLASS="indented">
This element stores the current working directory in Unix format.
<P>

=end html

=head3 _work_dirs -> _pre

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_pre} = (previous working directory in Unix format)>

=back

=begin html

<P CLASS="indented">
This element stores the previous working directory in Unix format.
<P>

=end html

=head3 _work_dirs -> _tmp

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_tmp} = /tmp directory>

=back

=begin html

<P CLASS="indented">
This element stores the /tmp directory in Unix format.
<P>

=end html

=head3 _work_dirs -> _cwd_mswin

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_cwd_mswin} = cwd - current working directory>

=back

=begin html

<P CLASS="indented">
This element stores the current working directory in MS Windows format.
<P>

=end html

=head3 _work_dirs -> _pre_mswin

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_pre_mswin} = previous working directory>

=back

=begin html

<P CLASS="indented">
This element stores the previous working directory in MS Windows format.
<P>

=end html

=head3 _work_dirs -> _tmp_mswin

=over 4

=item

C<$connect_secure_object-E<gt>{_work_dirs}-E<gt>{_tmp_mswin} = temp directory>

=back

=begin html

<P CLASS="indented">
This element stores the temp directory in MS Windows format.
<P>

=end html

=head2 _hostname

=over 4

=item

C<$connect_secure_object-E<gt>{_hostname} = hostname>

=back

=begin html

<P CLASS="indented">
This element indicates hostname of the remote host encapsulated in 
the host object. When <code>connect_shell()</code> is used, the 
hostname is the local host.
<P>

=end html

=head2 _ip

=over 4

=item

C<$connect_secure_object-E<gt>{_ip} = ip address>

=back

=begin html

<P CLASS="indented">
This element indicates the ip address of the remote host 
encapsulated in the host object. When <code>connect_shell()</code> 
is used, the ip address is the local host.
<P>

=end html

=head2 _uname

=over 4

=item

C<$connect_secure_object-E<gt>{_uname} = uname of remote host>

=back

=begin html

<P CLASS="indented">
This element indicates uname of the remote host encapsulated 
in the host object. When <code>connect_shell()</code> is used, 
the uname is from the local host.
<P>

=end html

=head2 _luname

=over 4

=item

C<$connect_secure_object-E<gt>{_luname} = uname of local host>

=back

=begin html

<P CLASS="indented">
This element indicates uname of the local host encapsulated in 
the host object. When <code>connect_shell()</code> is used, 
the luname is the same as uname.
<P>

=end html

=head2 _cmd_pid

=over 4

=item

C<$connect_secure_object-E<gt>{_cmd_pid} = process id of forked ssh or telnet program>

=back

=begin html

<P CLASS="indented">
This element indicates the process id of the forked ssh or 
telnet program encapsulated in the host object. When 
<code>connect_shell()</code> is used, the _cmd_pid is the 
same as _sh_pid.
<P>

=end html

=head2 _sh_pid

=over 4

=item

C<$connect_secure_object-E<gt>{_sh_pid} = process id of the shell within the ssh or telnet connection>

=back

=begin html

<P CLASS="indented">
This element indicates the process id of the shell within the 
ssh or telnet connection encapsulated in the host object. When
<code>connect_shell()</code> is used, the _sh_pid is the
same as _cmd_pid.
<P>

=end html

=head2 _shell

=over 4

=item

C<$connect_secure_object-E<gt>{_shell} = remote shell>

=back

=begin html

<P CLASS="indented">
This element indicates which shell is being used within
the ssh or telnet connection encapsulated in the host object.
<P>

=end html

=head2 _homedir

=over 4

=item

C<$connect_secure_object-E<gt>{_homedir} = home directory on remote host>

=back

=begin html

<P CLASS="indented">
This element indicates the home directory on the remote host. 
<P>

=end html

=head2 _cygdrive

=over 4

=item

C<$connect_secure_object-E<gt>{_cygdrive} = cygdrive value when remote environment is Cygwin>

=back

=begin html

<P CLASS="indented">
This element contains the cygdrive value when remote environment is <a href="http://cygwin.com">Cygwin</a>.
<P>

=end html

=head2 _cygdrive_regex

=over 4

=item

C<$connect_secure_object-E<gt>{_cygdrive_regex} = regular expression to test for Cygwin paths>

=back

=begin html

<P CLASS="indented">
This element contains a regular expression to test output for Cygwin style path construction.
<P>

=end html

=head1 Host Object Methods

=head2 cmd() - run ssh, telnet or local shell command line commands on the targeted (remote or local) host

=over 4

=item

C<($cmd_output,$error,$exitcode) = $connect_secure_object-E<gt>cmd('<commandE<gt>');>

=back

=begin html

<P CLASS="indented">
There is a <code>cmd</code> method available with every connect_object.
For all objects that contain both remote command-line and file-transfer
connections, the <code>cmd</code> method gives access ONLY to the 
remote command-line feature. To access the (s)ftp cmd options, use the
following syntax:
</P>

=end html

=over 4

=item

C<($sftp_cmd_output,$error) = $connect_secure_object-E<gt>{_ftp_handle}-E<gt>cmd('<sftp commandE<gt>');>

or for older insecure ftp:

C<($ftp_cmd_output,$error) = $connect_secure_object-E<gt>{_ftp_handle}-E<gt>cmd('<ftp commandE<gt>');>

=back 

=begin html

<P CLASS="indented">
For all objects that contain only an sftp or ftp
connection, the <code>cmd</code> method gives access ONLY to the
sftp and ftp command-line feature<br><br><code>($sftp_cmd_output,$error,$exitcode) = $connect_sftp_object->cmd('&lt;ftp command&gt;')</code>.
</P>

=end html

=over 4

=item

=================================================================

=back
 
=begin html

<P CLASS="indented">
The <b>cmd()</b> method is the "centerpiece" of FullAuto. This is the one method you will use at least 80% of the time. It is as close to a full "command environment" encapsulated in one handle as could be imagined. Just about anything you could do manually with a shell terminal or program like PuTTY, you can do just as easily with this method. The most important attribute of this method, and of FullAuto itself, is its use of a <b>*PERSISTENT*</b> connection to the remote host. Because of this approach, STATE is persisted among invocations of this method throughout the life cycle of the Instruction Set. In simpler terms, if you change a directory IT STAYS CHANGED. If you add or modify an environment variable, IT STAYS MODIFIED for the next call of the <code>cmd()</code> method. If you do a <code>su</code> or <code>sudo su</code>, the session will remain persistent until you exit. (One caveat - <code>su</code> usage is the one time you will have to account for the prompt and set it yourself). It is this single attribute (persistent connection) that suddenly makes workload automation <b>EASY</b>.<br><br>NOTE: While this does work:<br><br><code>($ssh_cmd_output,$error,$exitcode) = $connect_secure_object->cmd('cd /etc')</code><br><br>It is better to use the FullAuto <code>cwd()</code> method for all file system navigation. This is because it will keep track of history for both command and (s)ftp environments, and keep both environments synchronized.<br><br><code>($ssh_cmd_output,$error,$exitcode) = $connect_secure_object->cwd('/etc')</code><br><br><b>NOTE:</b> When exporting variables that you wish to persist for an entire session - export them with <b>cmd_raw():</b><br><br><code>$connect_secure_object->cmd_raw('export hello=hello')<br>($ssh_cmd_output,$error,$exitcode) = $connect_secure_object->cmd('echo $hello');
</P>

=end html

The B<cmd()> method has two other optional arguments

=head3 timeout

=begin html

<P CLASS="indented">
The default timeout value for the <code>cmd()</code> method is 90 seconds. You can change this
by specifying a timeout value parameter in seconds:<br><br>
The timeout setting is important only with long running commands that do not produce output. As long as a command produces output, the timeout value will not come into play. The command can run literally forever - as long as there is continuous output. It is advised that if you have any control over the output of the command, to enable a sufficient amount of output to avoid having to use the timeout argument. If the command has a "verbose" option, consider activating it. The tradeoff is that supplying output rather than a timeout value increases reliability, and allows the <code>cmd('&lt;command&gt;')</code> to end whenever it needs to - regardless of how long it takes. However, output is "expensive" and to get the quickest return time, using a timeout might produce faster results. But know that you are intentionally choosing speed over reliability, and speed always carries an increased risk.<br><br>
<code>($cmd_output,$error,$exitcode) = $connect_secure_object->cmd('&lt;command&gt;',&lt;seconds&gt;)</code>
</P>

=end html

=head3 __display__

=begin html

<P CLASS="indented">
This parameter turns on sending all STDOUT to the screen in real time as the <code>&lt;command&gt;</code> runs. Without setting this, all STDOUT is sent only to the <code>$cmd_output</code> variable (when set). <code>'__display__'</code> is not position dependent after the <code>&lt;command&gt;</code> parameter (which needs to be the first parameter.) It can appear before any timeout value, or after. <code>'__display__'</code> is a very useful feature for debugging, as well as for processes that human eyes will be anxiously watching closely. Output is "comforting", heals "blank screen anxiety" and allows stakeholders to relax and know that things are working. However, printing output to the screen has costs and slows down processing - significantly. Therefore, unless you really need to see output, it's best not to set this.<br><br>
<code>($cmd_output,$error,$exitcode) = $connect_secure_object->cmd('&lt;command&gt;','__display__')</code>
</P>

=end html

=head2 cmd_raw() - run ssh or telnet or local shell command without input validation and output parsing.

=over 4

=item

C<$cmd_output = $connect_secure_object-E<gt>cmd_raw('<commandE<gt>');>

=back

=begin html

<P CLASS="indented">
There are occasions where a command simply has too many special symbols, quotes, escapes, etc; where no amount of manipulation can get it through FullAuto's input validation correctly. In these cases, sending it through the <code>cmd_raw()</code> method and bypassing all of FullAuto's special handling logic can occasionally produce the desired result. Usually this will work when there is no output, or the output can be discarded. For the most reliable and robust processing, always try to use <code>cmd()</code> as much as possible, saving <code>cmd_raw()</code> as a method of last resort. Example of actual command that only works through <code>cmd_raw()</code>:<br><br><code>$connect_secure_object->cmd_raw("sed -i 's/\\(^Session$\\\)/    \\1/' $file_to_modify");</code>
</P>

=end html

=head2 print() - convenience method for invoking Net::Telnet's C<print()> method.

=over 4

=item

C<$connect_secure_object-E<gt>print('<commandE<gt>');>

=back

=begin html

<P CLASS="indented">
Used in combination with the <code>fetch()</code> method (see fetch() below), it becomes easy to automate interactive command utilities. <code>print()</code> sends commands straight to the socket unmodified and unverified via the <a href="http://search.cpan.org/~jrogers/Net-Telnet-3.04/lib/Net/Telnet.pm">Net::Telnet</a> handle that FullAuto uses internally. This is a convenience method that saves from having to invoke it like this instead:<br><br><code>$connect_secure_object->{_cmd_handle}->print(&lt;command&gt;);</code> 
</P>

=end html

=head2 sftpcmd() - run sftp commands on the targeted (remote or local) host

=begin html

<P CLASS="indented">
This method is useful when Host Object contains both a ssh (or telnet) and (s)ftp connection.<br><br>
<code>($sftp_cmd_output,$error) = $connect_secure_object->sftpcmd('&lt;sftp command&gt;')</code><br><br>
Uses same <code>timeout</code> and <code>__display__</code> parameters as the <code>cmd()</code> method.
</P>

=end html

=head2 sftp() - run sftp commands on the targeted (remote or local) host

=begin html

<P CLASS="indented">
Same as sftpcmd above, but a little shorter (and less descriptive) method name.<br><br>
<code>($sftp_cmd_output,$error) = $connect_secure_object->sftp('&lt;sftp command&gt;')</code><br><br>
Uses same <code>timeout</code> and <code>__display__</code> parameters as the <code>cmd()</code> method.
</P>

=end html

=head2 ftpcmd() - run ftp commands on the targeted (remote or local) host

=begin html

<P CLASS="indented">
Same as sftpcmd above, but for ftp.<br><br>
<code>($ftp_cmd_output,$error) = $connect_secure_object->ftpcmd('&lt;ftp command&gt;')</code><br><br>
Uses same <code>timeout</code> and <code>__display__</code> parameters as the <code>cmd()</code> method.
</P>

=end html

=head2 ftp() - run ftp commands on the targeted (remote or local) host

=begin html

<P CLASS="indented">
Same as ftpcmd above, but a little shorter (and less descriptive) method name.<br><br>
<code>($ftp_cmd_output,$error) = $connect_secure_object->ftp('&lt;ftp command&gt;')</code><br><br>
Uses same <code>timeout</code> and <code>__display__</code> parameters as the <code>cmd()</code> method.
</P>

=end html

=head2 cwd() - change working directory for both command (ssh or telnet) and (s)ftp connections simultaneously

=over 4

=item

C<($sftp_cmd_output,$error) = $connect_secure_object-E<gt>cwd('<pathE<gt>');>

C<($sftp_cmd_output,$error) = $connect_secure_object-E<gt>cwd('-');>

C<($sftp_cmd_output,$error) = $connect_secure_object-E<gt>cwd('~');>

C<($sftp_cmd_output,$error) = $connect_secure_object-E<gt>cwd('../..');>

=back

=begin html

<P CLASS="indented">
Unlike most other workload automation packages, persistent connection is the one feature that truly sets FullAuto apart. One of the biggest problems there is when a connection is not persistent, is maintaining "state" between commands. When the connection is not persistent, the environment must be updated along with each command sent. This is huge burden on developers, is resource intensive, and makes workload automation extraordinarily complex and fragile. This is precisely why most workload automation packages like 'Chef', 'Puppet', 'Salt' and others are Client-Server architecture - requiring agents on all remote hosts/nodes. 'Ansible' is dependent on the "ControlPersist" feature of OpenSSH. The problem with the "ControlPersist" feature is that not all SSH servers are OpenSSH, or a recent version of OpenSSH. FullAuto has NO such dependency and will work with ANY SSH server or version of SSH server known to the author. Also, (s)ftp servers <code>cwd</code> and <code>lcd</code> commands do not support common Unix/Linux shell navigation syntax such as '<code>~</code>' for one button access to the user's home directory. However, when using the <code>cwd()</code> method supplied with FullAuto, this syntax is fully supported for both the command and (s)ftp environments. The importance of this becomes apparent when you start coding up large and complex  L<Instruction Sets|/Instruction Sets> . The ability to use one single method to change the path location in both environments simultaneously, and to navigate PRECISELY as you would as if you were using a manual terminal like PuTTY, or within any Unix/Linux shell environment, makes it easy for ANYONE who works with these tools regularly to use FullAuto successfully without needing advanced programming language skills or any significant learning curve.
<br><br><code>($cmd_output,$error,$exitcode) = $connect_secure_object->cwd('src')</code><br><code>($cmd_output,$error,$exitcode) = $connect_secure_object->cmd('make install','__display__')</code><br><code>($cmd_output,$error,$exitcode) = $connect_secure_object->cwd('-')</code></P>

=end html

=head2 lcd()

=over 4

=item

C<$connect_secure_object-E<gt>lcd('E<lt>pathE<gt>')>;

=back

=begin html

<P CLASS="indented">
The <code>lcd()</code> method is a convenience method to perform local change directory on the (s)ftp handle without having to do this:<br><br><code>($cmd_output,$error) = $connect_secure_object->{_ftp_handle}->cmd('lcd path')</code><br><br>Also, it supports Unix navigation syntax like '~' for navigating to the home directory, etc.
<P>

=end html

=head2 put()

=over 4

=item

C<$connect_secure_object-E<gt>put('E<lt>fileE<gt>')>;

=back

=begin html

<P CLASS="indented">
The <code>put()</code> method is a convenience method to perform (s)ftp put on the (s)ftp handle without having to do this:<br><br><code>($cmd_output,$error) = $connect_secure_object->{_ftp_handle}->cmd('put file')</code>
<P>

=end html

=head2 get()

=over 4

=item

C<$connect_secure_object-E<gt>get('E<lt>fileE<gt>')>;

=back

=begin html

<P CLASS="indented">
The <code>get()</code> method is a convenience method to perform (s)ftp get on the (s)ftp handle without having to do this:<br><br><code>($cmd_output,$error) = $connect_secure_object->{_ftp_handle}->cmd('get file')</code>
<P>

=end html

=head2 prompt() - convenience method for invoking Net::Telnet's C<prompt()> method.

=over 4

=item

C<$connect_secure_object-E<gt>prompt();>

=back

=begin html

<P CLASS="indented">
This is convenience method for accessing the <a href="http://search.cpan.org/~jrogers/Net-Telnet-3.04/lib/Net/Telnet.pm#METHODS">Net::Telnet</a> <code>prompt()</code> method. It saves from having to invoke it like this instead:<br><br><code>$connect_secure_object->{_cmd_handle}->prompt();</code>
</P>

=end html

=head1 FullAuto Methods

=head2 fetch()

=over 4

=item

C<$output = fetch($connect_secure_object);>;

=back

=begin html

<P CLASS="indented">
The <code>fetch()</code> method is used to retrieve raw output straight from the socket when a command is sent via <a href="http://search.cpan.org/~jrogers/Net-Telnet-3.04/lib/Net/Telnet.pm">Net::Telnet</a>'s <code>print()</code> method.<br><br>The following is typical usage of <code>fetch()</code>. In this example, responses to installation options are sent automatically to an interactive <a href="http://www.mysql.com">MySQL</a> command line utility used to perform a secure install of a MySQL database:
<P>

=end html

=over 4

=item

   $connect_secure_object->print('sudo mysql_secure_installation');
         # Using Net::Telnet's print() method
   my $prompt=substr($connect_secure_object->prompt(),1,-1);
         # Using Net::Telnet's prompt() method to retrieve shell prompt
   while (1==1) {
      my $output=fetch($connect_secure_object);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'root (enter for none):') {
         $connect_secure_object->print();
         next;
      } elsif (-1<index $output,'Set root password? [Y/n]') {
         $connect_secure_object->print('n');
         next;
      } elsif (-1<index $output,'Remove anonymous users? [Y/n]') {
         $connect_secure_object->print('Y');
         next;
      } elsif (-1<index $output,'Disallow root login remotely? [Y/n]') {
         $connect_secure_object->print('Y');
         next;
      } elsif (-1<index $output,
            'Remove test database and access to it? [Y/n]') {
         $connect_secure_object->print('Y');
         next;
      } elsif (-1<index $output,'Reload privilege tables now? [Y/n]') {
         $connect_secure_object->print('Y');
         next;
      }
   }

=back

=head2 log()

=over 4

=item

C<log('E<lt>1|0|path_to_logfileE<gt>')>;

FullAuto has built in logging, but in order to use it, it must be explicitly turned on. It can be turned on and off anywhere in the script/Instruction Set using this method. A custom logfile and location can be indicated rather than a '1' which simply turns it on. The default location for FullAuto logs is C</home/E<lt>userE<gt>/.fullauto/logs>. FullAuto does NOT have one big log, but rather creates an entirely new log for each script/Instruction Set invocation. This is a typical example: C<FA9320d031716h14m13s19.log> The naming convention of the file is as follows.

 FA        -> identifies this as a FullAuto log file
 9320      -> PID (Process ID) of the FullAuto process for which this log belongs
 d031716   -> Date of the log: March 17, 2016
 h14m13s19 -> h: hour 14 (2pm) m: 13 minutes s: 19 seconds

=back

=begin html

<P CLASS="indented">
The <code>log()</code> method is used to dynamically turn on and off logging:<br><br>Turn on logging: <code>log(1);</code><br><br>Turn off logging: <code>log(0);</code><br><br>Turn on logging with custom name and path location: <code>log(&lt;path_to_logfile&gt;);</code>
<P>

=end html

=head2 ls_parse()

=over 4

=item

C<($size,$timestamp,$file_or_dir)=ls_parse($line);>;

=back

=begin html

<P CLASS="indented">
The <code>ls_parse()</code> method was created because of the frequent need to derive size, timestamp and file and directory names from <code>ls -l</code> output from remote hosts.<br><br>The following is typical output from the <code>ls -l</code> command; followed by an example of how <code>ls_parse()</code> can be used:
<P>

=end html

=over 4

=item

 ($stdout,$stderr)=$connect_secure_object->cmd('ls -l')

 ---------------------------------------------------------------------------
 total 166
 drwxrwxrwx+ 1 KB06606       Domain Users     0 Mar 10 10:26 FullAuto
 -rw-r--r--  1 KB06606-admin Domain Users 53383 Mar 14 08:35 FullAuto.html
 -rwxr-xr-x  1 KB06606       Domain Users 47560 Mar 13 18:47 FullAuto.pm
 -rwxr-xr-x  1 KB06606-admin Domain Users 46742 Mar 13 12:22 FullAuto.pm.bak
 -rw-r--r--  1 KB06606-admin Domain Users     3 Mar 22  2015 pod2htmd.tmp
 -rw-r--r--  1 KB06606-admin Domain Users     3 Mar 22  2015 pod2htmi.tmp
 -rw-r--r--  1 KB06606-admin Domain Users  1784 Jun 14  2015 test.pl
 -rwxrwxrwx  1 KB06606-admin Domain Users  1327 Jul 18  2015 tsftp.pl
 ---------------------------------------------------------------------------

 my ($size,$timestamp,$file_or_dir)=('','','');
 foreach my $line (split /\n/, $stdout) {

    ($size,$timestamp,$file_or_dir)=ls_parse($line);

 }

=back

=begin html

<P CLASS="indented">

<P>

=end html

=head2 acquire_fa_lock() - acquire a FullAuto lock.

=over 4

=item

C<acquire_fa_lock(\%lock_config);>

=back

=begin html

<P CLASS="indented">
Workload automation of any complexity will quickly introduce the need for a powerful locking mechanism. FullAuto uses locking internally, and provides that same mechanism for customized use in scripts and L<Instruction Sets|/Instruction Sets>. Here is a short list of occasions when a locking mechanism is needed:<br><br>* When a script using FullAuto runs on a scheduler. Occasionally a new instance starts before the old instance has completed.<br><br>* When an Instruction Set is written to run in parallel, but you have a need to limit the number of FullAuto processes running in memory at any one time.<br><br>* When you want to do <a HREF="#Managed-File-Transfers">Managed File Transfers</a>, and have a number of FullAuto worker processes emptying an outbound folder of files on a remote SFTP host. When you want only one process working on any particular file.<br><br>* You need multiple processes to append to a file on a remote server, and because it's remote, local file locking mechanisms are not available.<br><br>* You want to insure only one FullAuto process connects to a particular remote host at any given time.<br><br>* Other scenarios too numerous to list.<br><br>FullAuto uses <a href="http://www.oracle.com/technetwork/database/database-technologies/berkeleydb/overview/index.html">Oracle BerkeleyDB</a> as its internal locking store, because of its speed, portability, and maturity. BerkeleyDB has very robust deadlock protection that is critically important for workload automation of any complexity and sensitivity.<br><br>A workload of any complexity will likely require more than one kind of lock. Within a single workload, there may be a need for 3, 4 or more different kinds of locks for different needs. In the EXAMPLES section is a sample Managed File Transfer workload that uses 3 different types of locks.
</P>

=end html

=head3 %lock_config - hash to pass config information to C<acquire_fa_lock();>

=over 4

=item

 my %lock_config = (

     # Optional User Defined

     FullAuto_Lock_ID => "$filename",
     Lock_Description => "File Lock",
     MaxNumberAllowed => 1,
     KillAfterSeconds => 1600,
     Enable_This_Lock => 1,
     Wait_For_NewLock => 0,
     PollingMilliSecs => 500,
     Return_If_Locked => 1,

     # AUTO POPULATED

     UserName         => 'username',
     Logfile          => 'logfile if activated',
     FullAuto_Proc_ID => 'fullauto process id',
     FA_Proc_Launched => [time fullauto launched],
     TimeLockAcquired => 'time this lock was acquired',

 );

=back

=begin html

<P CLASS="indented">
</P>

=end html

=head4 FullAuto_Lock_ID

=over 4

=item

C<FullAuto_Lock_ID =E<gt> '<idE<gt>',>

=back

=begin html

<P CLASS="indented">
This is the name of a FullAuto lock. The <code>FullAuto_Lock_ID</code> is how FullAuto identifies a lock, and uses this name to lookup the lock in the BerkeleyDB database.
</P>

=end html

=head4 Lock_Description

=over 4

=item

C<Lock_Description =E<gt> '<descriptionE<gt>',>

=back

=begin html

<P CLASS="indented">
This is an element where an optional lock description would be placed.
</P>

=end html

=head4 MaxNumberAllowed

=over 4

=item

C<MaxNumberAllowed =E<gt> '<numberE<gt>',>

=back

=begin html

<P CLASS="indented">
This element defines the maximum number of locks that can be created by all FullAuto processes configured to use locks sharing the same <code>FullAuto_Lock_ID</code>. 
</P>

=end html

=head4 KillAfterSeconds

=over 4

=item

C<KillAfterSeconds =E<gt> '<secondsE<gt>',>

=back

=begin html

<P CLASS="indented">
In a perfect world, this feature would not be needed. However, in this world, "hangs" happen. For long-running workloads that are spawned by a scheduler or recurrent event of some sort, hung or orphaned processes can built up in memory, and eventually impair the performance of the host. To insure this does not happen, the <code>KillAfterSeconds</code> element can be used. It is recommended that the number of seconds be something in the order of 10 times the expected duration of a successfully completed workload. The notion being that a workload that is 10 times older than expected is "dead" and needs to terminated. This element instructs FullAuto to both delete the lock, and kill the process group associated with it. Use this feature with caution.
</P>

=end html

=head4 Enable_This_Lock

=over 4

=item

C<Enable_This_Lock =E<gt> '0|1',>

=back

=begin html

<P CLASS="indented">
This element is a simple binary that tells FullAuto whether the lock is enabled or not. This is useful for temporarily disabling a particular lock with only a simple toggle. '1' is enabled, and '0' is not.
</P>

=end html

=head4 Wait_For_NewLock

=over 4

=item

C<Wait_For_NewLock =E<gt> '<secondsE<gt>',> '0' means do not wait at all. The default is '60' seconds.

=back

=begin html

<P CLASS="indented">
This element defines how long a FullAuto process that encounters a lock, and cannot get a new one because no locks are available (defined with <code>MaxNumberAllowed</code>), should wait to get a new one, before it terminates. This is important for long-running processes because of potentially long and resource intensive startup and initialization. Performance is improved if a process that takes 2 minutes to start and initialize, can instead wait up to the 2 minutes to get a lock from a process that no longer needs it, rather than start from scratch. '0' instructs FullAuto not to wait at all. The default is '60' seconds.
</P>

=end html

=head4 PollingMilliSecs

=over 4

=item

C<PollingMilliSecs =E<gt> '<milliseconds<gt>',>

=back

=begin html

<P CLASS="indented">
When a FullAuto process encounters a lock, it polls the BerkeleyDB database for the availability of a particular lock at a configured interval. The default interval is '500' milliseconds.
</P>

=end html

=head4 Return_If_Locked

=over 4

=item

C<Return_If_Locked =E<gt> '<0|1E<gt>',>

=back

=begin html

<P CLASS="indented">
This element instructs FullAuto to either terminate when it encounters a lock, or return to the script or Instruction Set. '1' means return, '0' means terminate. The default is to terminate any FullAuto processes that encounter the lock, and exceed the <code>Wait_For_Newlock</code> setting - if any. This is particularly useful when locking files that will be removed by other processes upon completion of a transfer or other operation. In these cases, when a FullAuto process encounters a lock on a file, it can return from the <code>acquire_fa_lock()</code> method and loop and attempt to work with another file that is not locked by another FullAuto process.
</P>

=end html

=head4 AUTO POPULATED

=over 4

=item

 UserName         => 'username',
 Logfile          => 'logfile if activated',
 FullAuto_Proc_ID => 'fullauto process id',
 FA_Proc_Launched => [time fullauto launched],
 TimeLockAcquired => 'time this lock was acquired',

=back

=begin html

<P CLASS="indented">
The elements above are "auto populated" - meaning FullAuto adds them automatically to the lock_config. These are listed for informational purposes, and should NOT be defined by the user.
</P>

=end html

=head2 release_fa_lock() - release a FullAuto lock.

=over 4

=item

C<release_fa_lock('<FullAuto_Lock_IDE<gt>');>

=back

=begin html

<P CLASS="indented">
</P>

=end html

=head1 Instruction Sets

A FullAuto Instruction Set is actually a Perl module that utilizes FullAuto to perform a very specific type of operation. There is very little difference between a "script" that uses FullAuto, and an Instruction Set. An Instruction Set is simply a way of packaging a FullAuto script for distribution within the under development FullAuto Framework. The goal is that someday there will be a vast library of Instruction Set modules that can be downloaded and used to provide specific and tailored automated solutions for a wide spectrum of use cases and applications. The Instruction Set framework is something that can also be used to package proprietary instructions that can be even be sold for profit within a planned "FullAuto Marketplace". Soon, with the upcoming launch of the FullAuto Web Service API, FullAuto Instruction Sets can be written in I<any> programming or scripting language that can utilize RESTful Web Services. Currently there are 5 Instruction Sets bundled with FullAuto (and which will be released as stand-alone Perl modules in the near future):

=begin html

<table><tr>
<td style="width:35%">
<a href="http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/Catalyst_is.pm">Net::FullAuto::ISets::Amazon::Catalyst_is</a></td><td>Builds and Stands up a Catalyst Perl MVC Web Framework</td></tr><tr>
<td style="width:35%">
<a href="http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/Hadoop_is.pm">Net::FullAuto::ISets::Amazon::Hadoop_is</a></td><td>Builds and Stands up a Hadoop 4 node Cluster</td></tr><tr>
<td style="width:35%">
<a href="http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/KaliLinux_is.pm">Net::FullAuto::ISets::Amazon::KaliLinux_is</a></td><td>Builds and Stands up a KaliLinux Security Tools Host</td></tr><tr>
<td style="width:35%">
<a href="http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/Liferay_is.pm">Net::FullAuto::ISets::Amazon::Liferay_is</a></td><td>Builds and Stands up a Liferay Portal App Server with MySQL and Apache on different hosts</td></tr><tr>
<td style="width:35%">
<a href="http://cpansearch.perl.org/src/REEDFISH/Net-FullAuto-1.0000465/lib/Net/FullAuto/ISets/Amazon/OpenLDAP_is.pm">Net::FullAuto::ISets::Amazon::OpenLDAP_is</a></td><td>Builds and Stands up an OpenLDAP Server with phpLDAPAdmin</td>
</tr></table>

=end html

Currently, the included Instruction Sets only work on Amazon EC2, but will be extended to work on other public clouds and even private environments in the near future. You can run these Instruction Sets yourself with the Windows "Self Service Demonstration" helper app at L<http://sourceforge.net/projects/fullauto> or from Linux with the FullAuto Framework. Be sure to stand up a micro server in EC2 first, and install FullAuto with cpan. Full instructions for setting up EC2 are in the YouTube video L<https://youtu.be/gRwa1QoOS7M>. Then from the command line of the Linux FullAuto micro server, run the following command:

   fa --iset-amazon

Be sure to follow the onscreen instructions.

=head1 Installation

=head2 Linux/Unix and Cygwin (for Windows) command line installation

FullAuto is installed with Perl's C<cpan> command line utility. At C<cpan> prompt, type: C<install Net::FullAuto>

The FullAuto install is a bit different than other CPAN module installations. Normally C<cpan> will NOT update a dependency module if it already exists on the system - even if it is an older version. It also will NOT remove the same module found in more than one location, even if the old one has precedence in @INC - meaning it will always load the old one. FullAuto does not work with "local::lib" - so this install will update all dependencies (over 100 of them) and remove any duplicates. If this is not acceptable, then do not install FullAuto on hosts, or in a Perl installation, where module updates can be an issue. A highly recommended approach, is to install/build a separate Perl on these hosts, and install FullAuto there.

=head2 FullAuto Windows Installer

FullAuto for Microsoft Windows has a dependency on L<Cygwin|http://cygwin.com>. Since Cygwin setup and configuration can be complex, a turn-key FullAuto Windows Installer was created that installs Cygwin and all other dependencies needed to run FullAuto on a Windows host. The FullAuto Windows Installer can be downloaded here:

L<https://sourceforge.net/projects/fullauto/files/latest/download|https://sourceforge.net/projects/fullauto/files/latest/download>

Download the executable, double click, and follow the onscreen instructions. Be sure to use an account with full Administrative privileges.

=head3 Install minimal Cygwin and OpenSSH Server on Microsoft Windows

The FullAuto Windows Installer contains an option to install a minimal Cygwin installation along with a fully configured OpenSSH service. This is useful for installing a full featured SSH and SFTP service on any Windows host. Such a host can then be accessed by FullAuto via SSH and SFTP and participate in any FullAuto automated workload. When this option is used, FullAuto itself will NOT be installed. Be sure to use an account with full Administrative privileges.

=head1 Examples

The best workload automation examples are the included L<Instruction Sets|/Instruction Sets> (discussed above). Within the bundled modules listed above are code examples to accomplish just about any basic operation one would need to automate just about any workload imaginable. Please review them for assistance and inspiration.

=head2 Managed File Transfers

=over 4

=item

According to Wikipedia, L<Managed File Transfers|https://en.wikipedia.org/wiki/Managed_file_transfer> (MFT) I<"Typically, ... offers a higher level of security and control than FTP. Features include reporting (e.g., notification of successful file transfers), non-repudiation, auditability, global visibility, automation of file transfer-related activities and processes, end-to-end security, and performance metrics/monitoring."> All of these features can be included in a FullAuto implementation of MFT. All transfer output can be optionally logged, including transfer speeds and ETA's. Files can be verified on the remote host with C<ls -l>. The code below is designed to be launched by cron, The number of active processes can be controlled through FullAuto's locking feature. Individual files being actively transferred are locked, and so are writes to the transfer report - even when that report is on a different host and operating system locking mechanisms are not available.

=back

=over 4

=item

   use Net::FullAuto qw[ls_parse connect_sftp acquire_fa_lock
                        release_fa_lock cleanup log];

   my $identity_file = '/path/to/file/identity_file.key';
   my %remote_host_connection_info=(

      Label   => 'Remote Host',
      IP      => '000.00.00.000',
      Login   => 'User',
      IdentityFile => $identity_file,
      #debug => 1,
      #quiet => 1,
      logcount => 300,
      log => 1,

   );

   my %config_max_locks=(

      FullAuto_Lock_ID => 'MaxLocks',
      Lock_Description => 'Number of Processes Allowed',
      MaxNumberAllowed => 2,
      KillAfterSeconds => 1600,
      Wait_For_NewLock => 60

   );
   Net::FullAuto::FA_Core::log(1);
   Net::FullAuto::FA_Core::acquire_fa_lock(\%config_max_locks);

   my ($remote_host_handle,$error)=connect_sftp(\%remote_host_connection_info);
   die "Connect_SFTP ERROR!: $error\n" if $error;

   my ($stdout,$stderr)=$remote_host_handle->cmd('cd /path/to_remote_dir');

   ($stdout,$stderr)=$remote_host_handle->cmd('pwd');
   die $stderr if $stderr;

   print "REMOTE DIRECTORY IS: $stdout\n";

   ($stdout,$stderr)=$remote_host_handle->cmd('lcd /opt/SFTP/outbound');
   die $stderr if $stderr;

   ($stdout,$stderr)=$remote_host_handle->cmd('!ls -lh');

   foreach my $line (split "\n", $stdout) {
      next unless $line=~/^-/;
      my ($size,$timestamp,$filename)=ls_parse($line);
      next unless -e '/opt/FTP/outbound/'.$filename;
      my $config_file_lock={

         FullAuto_Lock_ID => "$filename",
         Lock_Description => "File Lock",
         MaxNumberAllowed => 1,
         KillAfterSeconds => 1600,
         Wait_For_NewLock => 0,
         Return_If_Locked => 1

      };
      next unless acquire_fa_lock($config_file_lock);
      ($stdout,$stderr)=$remote_host_handle->cmd('lcd /opt/FTP/outbound');
      ($stdout,$stderr)=$remote_host_handle->cmd('cd /path/to_remote_dir');
      ($stdout,$stderr)=$remote_host_handle->put($filename,'__display__');
      if (-1<index $stdout,'100%') {
         ($stdout,$stderr)=$remote_host_handle->cmd("!rm -fv $filename",
            '__display__');
         $filename=sprintf "%-32s", $filename;
         my $date=sprintf "%-30s", scalar localtime($timestamp);
         acquire_fa_lock('report_lock');
         my $report_dir='/path/to/file/';
         open(my $rfile, ">>", "$report_dir/files_transferred.txt")
            or die "Can't open $report_dir/files_transferred.txt: $!";
         chmod 0777, "$dir/files_transferred.txt";
         print $rfile $filename,$date,$size,"\n";
         close($rfile);
         release_fa_lock('report_lock');
         print "Filename=$filename<== and TIMESTAMP=",
            scalar localtime($timestamp)," and SIZE=$size\n";
      } else {
         print "TRANSFER of $filename FAILED. Leaving file in Que ",
               "and Releasing Lock";
      }
      release_fa_lock($filename);
   }
   close $rfile;

   release_fa_lock('MaxLocks');

   #$remote_host_handle->close(); # Use this -OR- cleanup method
   cleanup(); # Use this routine for faster cleanup

=back

=head2 Automated Builds, Deployments, DevOps and Term::Menus

=over 4

=item

The FullAuto project was started in 2000 in an effort to create a better way to do software builds and deployments. This was back before the word "L<DevOps|https://en.wikipedia.org/wiki/DevOps>" (I<a clipped compound of "development" and "operations">) was even coined. Back then, as it is today, security and domain (or turf) protection was far and away the biggest obstacle to productivity. As necessary as it is, security and departmental boundaries come with a cost. That cost is the compartmentalization of access to an organization's IT infrastructure. It's this compartmentalization and the effort needed to work within it to accomplish project goals that ends up killing more time and productivity than any other single factor. The result is a never-ending "access" tug-of-war where solution producers (developers) vie and lobby for as much as access as possible, while operations tries to limit access to the greatest extent possible. FullAuto was conceived as the ultimate tool to make maximum efficient use of very limited access to organizational infrastructure. Such a tool would have to be "free" because procuring expensive software is difficult. It needed to be "agent-less" because of the politics and difficulty of getting permission to install anything on hosts you did not own or control. It needed to be centralized for efficiency, yet utilize ubiquitous distributed components to the greatest extend possible. Finally, it needed to be "easy" to use so that more traditional system administrators can use it without having to rely on developers or be developers themselves. That is why FullAuto is written in Perl, because even today, system administrators are familiar with it. FullAuto was built to take the workflow of a system administrator's typical task and be able to execute it in an almost identical fashion, with the same shell commands and utilities used manually.

The L<Instruction Sets|/Instruction Sets> listed above are in fact the best examples of DevOps there is. They encompass both automated builds and deployment. They demonstrate the level of true automation that can applied to any workload - especially those that cross departmental boundaries.

There is however, one more element to a successful workload strategy, and that is the need for some kind of I<minimal>, I<lightweight>, yet powerful user interface. FullAuto has a sister module - L<Term::Menus|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm>, also written by Brian Kelly. Originally part of the FullAuto Framework, it was later separated out into its own stand-alone module. No matter how automated a workload is, there is almost always going to be the need for some kind of human input. Today that input comes predominantly in the form of command line parameters and configuration files. It's the customized, poorly documented and non-intuitive nature of these inputs that often makes workloads fragile and error-prone. L<Term::Menus|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm> is a solution to this need. Used within FullAuto scripts and L<Instruction Sets|/Instruction Sets>, Term::Menus enables embedded documentation, user selection and validation that command line parameters and config files do not provide. Term::Menus even provides the kind of powerful <Lforms|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm#FORMS> most would expect to find only in a cumbersome web interface (cumbersome because of the overhead and complexity of putting a web interface in front of anything). Term::Menus is lightweight, easy to program, and even easier to use. Menus built with Term::Menus can hold 2 items or 2 million items - and are searchable. They can be inserted anywhere in any workload - especially long running ones, where human input would otherwise require complete interruption and/or decoupling. This can significantly reduce the need for complex and cumbersome command line parameter and config file based metadata conveyance between disconnected workloads; workloads that can now be unified. With FullAuto and L<Term::Menus|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm> - the number of workloads can be reduced, and the remaining ones simplified to a remarkable degree. With Term::Menus, you can now build powerful command environment user interfaces with search capabilities that rival (and in some ways exceed) anything you can do in a web interface.

To see the just some of the capabilities of L<Term::Menus|http://search.cpan.org/dist/Term-Menus/lib/Term/Menus.pm>, check out the FullAuto Figlet utility:

fa --figlet

---------------------------------------------------------------------------

    ___ ___ ___ _     _       ___        _
   | __|_ _/ __| |___| |_    | __|__ _ _| |_ ___
   | _| | | (_ | / -_)  _|   | _/ _ \ ' \  _(_-<
   |_| |___\___|_\___|\__|   |_|\___/_||_\__/__/

   Choose a FIGlet Font (by number) to preview with text "Example"
   -OR- continuously scroll and view by repeatedly pressing ENTER

   HINT: Typing  !figlet -f<fontname> YOUR TEXT

         is another way to preview the font of your choice.

   >   1      1943____
       2      1row
       3      3-d
       4      3d_diagonal
       5      3x5
       6      4max
       7      4x4_offr
       8      5lineoblique

   528 Total Choices   [v][^] Scroll with ARROW keys   [F1] for HELP

   ([ESC] to Quit)   PLEASE ENTER A CHOICE:

---------------------------------------------------------------------------

   '########:'##::::'##::::'###::::'##::::'##:'########::'##:::::::'########:
    ##.....::. ##::'##::::'## ##::: ###::'###: ##.... ##: ##::::::: ##.....::
    ##::::::::. ##'##::::'##:. ##:: ####'####: ##:::: ##: ##::::::: ##:::::::
    ######:::::. ###::::'##:::. ##: ## ### ##: ########:: ##::::::: ######:::
    ##...:::::: ## ##::: #########: ##. #: ##: ##.....::: ##::::::: ##...::::
    ##:::::::: ##:. ##:: ##.... ##: ##:.:: ##: ##:::::::: ##::::::: ##:::::::
    ########: ##:::. ##: ##:::: ##: ##:::: ##: ##:::::::: ########: ########:
   ........::..:::::..::..:::::..::..:::::..::..:::::::::........::........::

   ========================================
   [ EXAMPLE                              ]  banner3-D  font
   ========================================

   The box above is an input box. The [DEL] key will clear the contents.
   Type anything you like, and it will appear in the banner3-D FIGlet font!

   (Press [F1] for HELP)

   ([ESC] to Quit)   Press ENTER when finished

---------------------------------------------------------------------------

The FullAuto Figlet utility is useful for making headlines and banners for menus and important
events in a long running workload.

=back

=head1 Coming Soon

=head2 FullAuto Web Service API

Nearing completion is the FullAuto Web Service API that will enable anyone in any programming or scripting language to access and use the full power and functionality of FullAuto without having to know Perl at all.

=head2 FullAuto Framework Environment

FullAuto will soon have a "Framework" environment accessed with the C<fa> executable. Using this environment, passwords can be stored encrypted in the Berkeley DB database. The FullAuto Framework is an interactive lifecycle environment that will make using FullAuto easier for teams and multiple users. The FullAuto Framework Environment can be previewed now (just follow the onscreen instructions):

 fa --new-user

For greater security and workload isolation, FullAuto will soon have the option for C<setuid> installs on UNIX and Linux based hosts. (Windows/Cygwin does not support "setuid" - so this feature will not be available on Windows computers. This is the only Windows FullAuto limitation.) With FullAuto setup to use C<setuid>, users can be configured to run complex distributed processes without the permissions actually needed by the remote (or even local) resources. This setup can allow users to run FullAuto processes without having access to the passwords controlling remote access, or for that matter, the code running those processes.

=head2 The FullAuto MarketPlace

FullAuto L<Instruction Sets|/Instruction Sets> can be created to satisfy big ambitions and small ones. Some of of those solutions can be shared as Open Source, and others will have market value, and can potentially be quite valuable (as well as sensitive). The FullAuto MarketPlace will be an online location where users can shop, preview, research and download and/or purchase FullAuto L<Instruction Sets|/Instruction Sets>. It is anticipated there will someday be Instruction Sets customized for different public clouds and private clouds, different operating systems, infrastructure setup, security monitoring and penetration testing, automated build and deployment tools, as well highly specialized Instruction Sets for different engineering, profiling, data analytics, testing and industrial applications. The possibilities are almost limitless.

=head1 Author

Brian M. Kelly

L<Brian.Kelly@FullAuto.com|mailto:Brian.Kelly@FullAuto.com>

=head1 Copyright

Copyright (C) 2000-2019

by Brian M. Kelly.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Affero General Public License
as published by the Free Software Foundation, either version 3 of 
the License, or (at your option) any later version.
(L<http://www.gnu.org/licenses/agpl.html|http://www.gnu.org/licenses/agpl.html>).
