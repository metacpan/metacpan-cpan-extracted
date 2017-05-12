#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Gearman;

use strict;
use warnings;

our $VERSION = "0.32.0";

1;

=head1 Rex::Gearman - Distributed Rex

Distibuted Rex is a addition to Rex for distributed Task execution with the help of gearman. So it is possible to scale rex.

Distributed Rex is setup of two components. One (or more) Worker and one Client. As more worker you run as more parallel tasks you are able to execute.

=head1 INSTALLATION

To install Distributed Rex you have to follow these steps.


=head2 On the Client

First you have to add the Rex repository to your package manager. To do this read L<http://rexify.org/get/>.

Now you can install Distributed Rex via your package manager. On Debian or Ubuntu you can use I<apt>.

 apt-get install rex-gearman

If you want to install it via CPAN you can do this easily with cpanm.

 cpanm Rex::Gearman

or

 curl -L get.rexify.org | perl - --sudo -n Rex::Gearman

=head2 On the server (worker)

First you have to install gearman, configure it to listen not only on the loopback device and start it. 

Than you can install Distributed Rex. On Debian or Ubuntu you can use I<apt>.

 apt-get install rex-gearman

If you want to install it via CPAN you can do this easily with cpanm.

 cpanm Rex::Gearman

or

 curl -L get.rexify.org | perl - --sudo -n Rex::Gearman


After that you have to distribute your Rexfile (and all associated files (like templates, the "lib" directory, ssh keys, ...) to your worker machines. We recommend to name the directory where you put the Rexfile the same as on your client machine.

Example directory structure on the client:

 /home/user/projects/frontend
                        |-- Rexfile
                        |-- client.conf
                        +-- lib
                        |   +-- Rex
                        |       +-- Webserver
                        |       +-- Apache.pm
                        |           +-- templates
                        |               +-- httpd.conf
                        +-- worker.conf

Example directory structure on the server/worker machine:

 /opt/rex/frontend
             |-- Rexfile
             |-- client.conf
             +-- lib
             |   +-- Rex
             |       +-- Webserver
             |       +-- Apache.pm
             |           +-- templates
             |               +-- httpd.conf
             +-- worker.conf

Now change into the directory where your I<Rexfile> is located and create a file I<worker.conf>.

Here you have to configure all your gearmand servers so that the Worker module can register its functions to them.

 {
    job_servers => [
      "127.0.0.1:4730",
      "192.168.7.10:4730",
      "192.168.7.11:4730",
    ],
 };

Now you are able to start the workerprocess.

 rex-gearman-worker -d

=head1 RUNNING A TASK

Switch back to your workstation / the client.

Change to the directory where your I<Rexfile> lives and create a file called I<client.conf>. In this file you have to configure your gearmand servers.

 {
    job_servers => [
      "127.0.0.1:4730",
      "192.168.7.10:4730",
      "192.168.7.11:4730",
    ],
 };


Now you're able to run your tasks as known. But you have to replace the I<rex> command with I<rex-gearman-client>. The CLI parameter are the same. So you can use I<rex-gearman-client> the same way as you used I<rex>.

For example:

 rex-gearman-client -h
 rex-gearman-client -Tv
 rex-gearman-client prepare


=head1 REPORTING BUGS

Please report the bugs in the Issue-Tracker.

=head1 GETTING HELP

If you need help, you can join us on irc on irc.freenode.net channel #rex.



