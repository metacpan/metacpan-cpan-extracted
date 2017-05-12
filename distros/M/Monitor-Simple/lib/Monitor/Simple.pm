#-----------------------------------------------------------------
# Monitor::Simple
# Author: Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer se below.
#
# ABSTRACT: Simple monitoring of applications and services
# PODNAME: Monitor::Simple
#-----------------------------------------------------------------

package Monitor::Simple;

use warnings;
use strict;

our $VERSION = '0.2.8'; # VERSION

# values returned by plugins (compatible with Nagios'
use constant {
    RETURN_OK       => 0,
    RETURN_WARNING  => 1,
    RETURN_CRITICAL => 2,
    RETURN_UNKNOWN  => 3,

    # ...and this is returned if the plugin cannot be started
    RETURN_FATAL    => -1,
};

# values used in configuration file for notifiers (in attribute "on")
use constant {
    NOTIFY_OK       => 'ok',
    NOTIFY_WARNING  => 'w',
    NOTIFY_CRITICAL => 'c',
    NOTIFY_UNKNOWN  => 'u',
    NOTIFY_ALL      => 'all',
    NOTIFY_ERRORS   => 'err',
    NOTIFY_NONE     => 'none',
};

use Monitor::Simple::Log;
use Monitor::Simple::Config;
use Monitor::Simple::UserAgent;
use Monitor::Simple::Utils;
use Monitor::Simple::Output;
use Monitor::Simple::Notifier;

use Carp;
use Log::Log4perl qw(:easy);
use Parallel::ForkManager;
use IO::CaptureOutput qw(capture_exec);
use File::Spec;
use Time::HiRes qw(time);


my $default_npp = 10; # maximum number of child processes in parallel

# -----------------------------------------------------------------
# The main loop checking all services as defined in the given
# configuration.
#
# Recognized arguments:
#    { config_file => $config_file,
#      npp         => <integer>,
#      outputter   => instance of Monitor::Simple::Output,
#      filter      => hashref (keys are service IDS) or
#                     arrayref with service IDs, or
#                     scalar with just one service ID
#      nonotif     => boolean
#    }
# -----------------------------------------------------------------
sub check_services {
    my ($self, $args) = @_;

    # recognized arguments
    my $config;
    my $config_file;
    if ($args->{config_file}) {
        $config_file = $args->{config_file};
        $config = Monitor::Simple::Config->get_config ($config_file);
    } else {
        LOGDIE ("check_services: Missing argument 'config_file'. Cannot do anything.\n");
    }
    my $npp = ($args->{npp} || $default_npp);
    if ($npp < 1) {
        LOGWARN ("check_services: Argument 'npp' must be positive. Replaced by default value $default_npp.\n");
        $npp = $default_npp;
    }
    my $outputter = ($args->{outputter} || Monitor::Simple::Output->new (config   => $config));

    # optional filter tells which only services to check; filter can be
    # hashref or arrayref or scalar (all with service name(s) we wish
    # to check)
    my $filter = $args->{filter};
    if ($filter) {
        if (ref ($filter) eq 'ARRAY') {
            $filter = { map { $_ => 1 } @$filter };
        } elsif (ref ($filter) eq 'HASH') {
            # already done
        } else {
            $filter = { $filter => 1 };
        }
    }
    $filter = undef unless keys %$filter > 0;

    # before the main checking loop starts
    $outputter->header();
    my $notifier = Monitor::Simple::Notifier->new (config  => $config,
                                                   cfgfile => $config_file);

    # main loop
    INFO ('--- Checking started ---');
    my $start_time = time();
    my $pm = new Parallel::ForkManager ($npp);
    foreach my $service (@{ $config->{services} }) {

        # filtering of services
        next if $filter and not exists $filter->{ $service->{id} };

        # this does the fork and for the parent branch and continues the foreach loop
        $pm->start and next;

        # this is the child branch: execute an external plugin...
        my $command = $service->{plugin}->{command};
        unless (File::Spec->file_name_is_absolute ($command)) {
            my $plugins_dir = $config->{general}->{'plugins-dir'};
            if ($plugins_dir) {
                $command = File::Spec->catfile ($plugins_dir, $command);
            }
        }
        my @command = ($command,
                       Monitor::Simple::Config->create_plugin_args ($config_file,
                                                                    $config,
                                                                    $service->{id}));
        DEBUG ("Started: " . join (' ', @command));
        my ($stdout, $stderr, $success, $exit_code) = capture_exec (@command);

        # ...and make the result report
        print STDERR "$stderr\n" if $stderr;  # do not hide standard errors, if any
        my ($code, $msg) = Monitor::Simple::Utils->process_exit ($command, $exit_code, $stdout);
        $outputter->out ($service->{id}, $code, $msg);
        unless (exists $args->{nonotif} and $args->{nonotif}) {
            $notifier->notify ( { service => $service->{id},
                                  code    => $code,
                                  msg     => $msg } );
        }
        $pm->finish;
    }

    # here the parent branch continue when all child process have been
    # started; we need to wait untill all these processes finish -
    # otherwise we would create a "zombie" process in out operating
    # system
    $pm->wait_all_children();
    $outputter->footer();

    INFO ('--- Checking finished [' . (time() - $start_time) . ' s] ---');
}


1; # End of Monitor::Simple

__END__
=pod

=head1 NAME

Monitor::Simple - Simple monitoring of applications and services

=head1 VERSION

version 0.2.8

=head1 SYNOPSIS

   # check services defined in 'my.cfg' and report to the STDOUT
   use Monitor::Simple;
   my $args = { config_file => 'my.cfg' };
   Monitor::Simple->check_services ($args);

   It displays something like this:

   DATE                           SERVICE           STATUS  MESSAGE
   Tue Sep 20 12:15:00 2011       Memory Check           1  Memory WARNING - 70.7% (1064960 kB) used
   Tue Sep 20 12:15:01 2011       NCBI PubMed page       0  OK

   --- or using a ready-to-use script:

   smonitor -cfg my.cfg

=head1 DESCRIPTION

The B<Monitor::Simple> allows simple monitoring of applications and
services of your IT infrastructure. There are many such tools, some of
them very complex and sophisticated. For example, one widely used is
I<Nagios> (L<http://www.nagios.org/>). The I<Monitor::Simple> does not
aim, as its name indicates, for all features provided by those
tools. It allows, however, to check whether your applications and
services are running correctly. Its simple command-line interface can
be used in cron jobs and reports can be viewed as a single HTML or
text page.

Regarding B<what> it checks, it uses the same concept as I<Nagios>:
all checking is done by B<plugins>, standalone scripts. And more to
it: these plugins are fully compatible with the Nagios plugins. Which
means that you either write your own plugins and use them either with
I<Monitor::Simple> or with I<Nagios>, or you can use many existing
Nagios plugins and use them directly with the I<Monitor::Simple>. For
example, the "Memory check" in the synopsis above is an unchanged
Nagios plugin.

Another concept used by I<Monitor::Simple> are B<notifiers>. These are
again standalone scripts that are called whenever a
service/application check is done and there is a notifier (or
notifiers) defined to be used. The notification can be sent (or
ignored) for every possible check result (errors, OK, all,
etc.). Because these I<notifiers> are just standalone scripts, one can
easily wrapped many existing notifying tools (pagers, SMS senders,
etc.); again, many of them are known to Nagios and similar programs.

Finally, the last "concept" in I<Monitor::Simple> is the
configuration. The Monitor::Simple uses an B<XML configuration file>
defining what services should be checked, how to check them (meaning,
what plugins to use) and whom to notify (meaning, what notifiers to
use). You can use Monitor::Simple without any Perl programming, just
by creating a configuration file (because only you know what services
you wish to check) and use it with the provided ready-to-use script
B<smonitor>, providing that the few plugins and notifiers distributed
with Monitor::Simple are good enough (at least as a starting
point). The I<smonitor> has its own documentation describing its
command-line parameters in details:

   smonitor -man

However, either way (using I<smonitor> or embedding I<Monitor::Simple>
into your Perl code), you need to write a configuration file. So,
let's start with it:

=head2 Configuration file

The simplest configuration file is:

   <smon/>

It does nothing but also it does not complain. Even the root tag
C<smon> can be anything. But let's talk about more useful
configuration files. They have a C<general> section and a list of
services to be checked in C<services> section:

   <smon>
     <general></general>
     <services></services>
   </smon>

However, it still does nothing. We need to add some services. Each
service must have its C<id> attribute and a C<plugin> section where
must be a C<command> attribute:

   <smon>
     <services>
       <service id="service1">
         <plugin command="get-date.pl" />
       </service>
     </services>
   </smon>

This configuration file, finally, does something. It invokes the
plugin script C<get-date.pl>. The script only returns the current date
(so it does not do much of the checking) but it returns it in
compatible way with all other plugins (also with Nagios plugins). It
is good for testing. Here is how it reports (assuming that we named
our configuration file C<my.cfg>):

   $> smonitor -cfg my.cfg
   DATE                           SERVICE   STATUS  MESSAGE
   Tue Sep 20 14:05:29 2011       service1       0  Tue Sep 20 14:05:29 2011

The C<service> tag can also have a C<name> attribute for a more human
readable display name and a C<description> tag (used in the HTML format
of reports). The C<plugin> tag can also have (and usually it has) more
sub-tags. They varies depending on the plugin's command. Generally,
all additional arguments for a plugin can be defined by the C<args>
and C<arg> tags. They simply specify what will get the plugin on its
command-line. For example, the Nagios plugin for checking available
memory accepts these arguments:

   <smon>
     <services>
       <service id="memory" name="Memory Check">
         <plugin command="check_mem.pl">
           <args>
             <arg>-u</arg> <!-- check USED memory -->
             <arg>-w</arg> <!-- -w PERCENT   Percent free/used when to warn -->
             <arg>55</arg>
             <arg>-c</arg> <!-- -c PERCENT   Percent free/used when critical -->
             <arg>80</arg>
           </args>
         </plugin>
       </service>
     </services>
   </smon>

   $> smonitor -cfg my.cfg
   DATE                       SERVICE       STATUS  MESSAGE
   Tue Sep 20 14:23:09 2011   Memory Check       1  Memory WARNING - 66.5% (893584 kB) used

Read more about specific tags for plugins distributed with
I<Monitor::Simple> in the L<"Plugins"> section.

Each service can also have one or more notifiers. Each notifier (see
L<"Notifiers">) is an external script defined by the C<command>
attribute. The script will be executed if the attribute C<on> is
satisfied. The C<on> attribute contains a code or a comma-separated
list of codes representing the result of the service check. If the
result matches the attribute value (or, in case of a list, any of the
values), the notifier is invoked. If you need to use the codes in your
Perl programming, they are available as constants
I<Monitor::Simple::NOTIFY_*>. The code values in the configuration
files are these:

    NOTIFY_OK       => 'ok',
    NOTIFY_WARNING  => 'w',
    NOTIFY_CRITICAL => 'c',
    NOTIFY_UNKNOWN  => 'u',
    NOTIFY_ALL      => 'all',
    NOTIFY_ERRORS   => 'err',
    NOTIFY_NONE     => 'none',

There are few other attributes and sub-tags for notifiers, such as
I<whom> the notification should be sent to. They depend on the type of
the notifier - read more about specific attributes and tags for
notifiers distributed with I<Monitor::Simple> in the L<"Notifiers">
section. Here is an example of a service with two configured
notifiers:

   <smon>
     <services>
       <service id="date">
         <plugin command="get-date.pl" />
         <notifier command="send-email"   on="err" email="senger@localhost" />
         <notifier command="copy-to-file" on="all">
           <args>
             <arg>-file</arg> <arg>report.txt</arg>
           </args>
         </notifier>
       </service>
     </services>
   </smon>

Each notifier can also have an attribute C<format> specifying the
format of the notification. The formats are "tsv" (TAB-separated
values), "html" and "human" (plain text). But read about pitfalls of
some of these formats in the L<"Notifiers"> section.

Finally, the notifiers can be also specified in the C<general> section
of the configuration file. These notifiers are then used for every
service (additionally to the notifiers defined in individual
services):

   <smon>
     <general>
       <notifier command="copy-to-file" on="all" format="tsv">
         <args>
           <arg>-file</arg> <arg>report.tsv</arg>
         </args>
       </notifier>
     </general>
     ...
   </smon>

Sometimes, you have a service for which you wish to exclude (to
ignore) the general notifiers (those defined in the C<general>
tag). In such case use the C<ignore-general-notifiers> tag:

   <service id="ping-git" name="Ping Git Repository">
     <ignore-general-notifiers />
     <plugin command="check-ping">
       <args>
          ...
       </args>
     </plugin>
   </service>

For exploring configuration, the I<Monitor::Simple> distribution has
directory F<Monitor/Simple/configs> with few examples of configuration
files.

=head2 Plugins

The plugins are external scripts that are invoked to do the real
service checking. Each service has its plugin defined in the
configuration file:

   <service id="service1">
      <plugin command="check-my-service.pl" />
   </service>

The plugins usually take some parameters - which are also specified in
the configuration files (examples below).

Because plugins are just external scripts they can be anywhere on your
machine. For such cases, you can use the full (absolute) path in the
"command" attribute of the plugin. But usually, all (or most)
plugins are in a single directory which you can specify in the
"general" section of the configuration file:

   <general>
      <plugins-dir>/some/directory/on/my/computer</plugins-dir>
   </general>

Default location for all plugins is a directory "plugins" in the
directory where sub-modules of Monitor::Simple are installed. Which
means "...somewhere/Monitor/Simple/plugins/".

There are several rather general plugins distributed with the
I<Monitor::Simple>:

=head3 Plugin: B<check-url.pl>

A general plugin for checking availability of a single URL, using the
I<HTTP HEAD> method. You can use this plugin to check if the URL of
your service or application is not broken, or/and if it returns within
a specified timeout period. The configuration is the following:

   <plugin command="check-url.pl">
     <head-test>
       <url>http://you.server.org/home/applications.php</url>
       <timeout>5</timeout>
     </head-test>
     ... more <head-test>s can be here...
   </plugin>

The C<url> tag is mandatory, the C<timeout> tag is only
optional. There may be more C<head-test> sections if you wish to check
more URLs by the same plugin call.

The plugin script is very simple; all the work is actually done by the
method C<Monitor::Simple::UserAgent-E<gt>head_or_exit()>.

=head3 Plugin: B<check-post.pl>

This is a slightly generalized L<check-url.pl|"Plugin:_check-url.pl">
plugin. It can do also the C<head-test>s (as the C<check-url.pl> does)
but its main purpose is to send data to the service using the I<HTTP
POST> method. It allows you to check whether your service returns
expected data. The full configuration is the following:

   <plugin command="check-post.pl">
     <head-test>
       <url>...</url>
     </head-test>
     <post-test>
       <timeout>5</timeout>
       <url>...</url>
       <data><![CDATA[name=brca1&namespace=geneid&format=html]]></data>
       <response>
         <content-type>text/json</content-type>
         <contains>BRCA1</contains>
       </response>
     </post-test>
     <post-test>
       <url></url>
       <data><![CDATA[namespace=geneid&action=table]]></data>
       <response>
         <content-type>text/json</content-type>
         <contains>Alternate_name</contains>
         <contains>Gene_Symbol</contains>
         <equal>...</equal>
       </response>
     </post-test>
   </plugin>

At least one C<post-test> section is mandatory, and it has to have a
C<url> and C<data>. The response can be checked for the returned
I<HTTP Content type> or for text anywhere within the response body, or
for equality (after trimming heading and trailing white-spaces). More
C<contains> tags means that all such texts must be found in the
response body.

The plugin script is also simple; all the work is actually done by the
method C<Monitor::Simple::UserAgent-E<gt>post_or_exit()>.

=head3 Plugin: B<check-get.pl>

This is very similar to L<check-post.pl|"Plugin:_check-post.pl"> plugin,
except it uses I<HTTP GET> method. And, therefore, it does not use
C<data> tag in the configuration file (because all input data are
already part of the C<url> tag). It does not use I<HTTP HEAD> method.

Again, it allows you to check whether your service returns expected
data. The full configuration is the following:

   <plugin command="check-get.pl">
     <get-test>
       <timeout>5</timeout>
       <url>![CDATA[...]]></url>
       <response>
         <content-type>text/json</content-type>
         <contains>...</contains>
         <equal>...</equal>
       </response>
     </get-test>
     <get-test>
        ...
     </get-test>
   </plugin>

At least one C<get-test> section is mandatory, and it has to have a
C<url>. The response can be checked for the returned I<HTTP Content
type> or for text anywhere within the response body, or for equality
(after trimming heading and trailing white-spaces). More C<contains>
tags means that all such texts must be found in the response body.

The plugin script is also simple; all the work is actually done by the
method C<Monitor::Simple::UserAgent-E<gt>get_or_exit()>.

=head3 Plugin: B<check-prg.pl>

A general plugin that executes any command-line program with the given
arguments and then it reports warning if there was any STDERR and it
checks the STDOUT for expected values. The full configuration is the
following:

   <plugin command="check-prg.pl">
     <prg-test>
       <program>...</program>
       <timeout>...</timeout>
       <args>
         <arg>...</arg>
         <arg>...</arg>
       </args>
       <stdout>
         <contains>...</contains>
         <contains>...</contains>
       </stdout>
     </prg-test>
     <prg-test>
       <program>...</program>
       <timeout>...</timeout>
       <args>
         <arg>...</arg>
       </args>
       <stdout>
         <is-integer/>
       </stdout>
     </prg-test>
   </plugin>

At least one C<prg-test> section is mandatory, and it has to have a
C<program> tag (a program that will be invoked). The STDOUT of the
invoked program can be checked that it contains given text. More
C<contains> tags means that all such texts must be present. It can
also make a test that the produced STDOUT is nothing than white-spaces
and an integer.

The C<timeout> tag may specify how many seconds to wait for the
program completion before it reports timeout warning.

Again, the plugin script is simple; all the work is actually done by the
method C<Monitor::Simple::Utils-E<gt>exec_or_exit()>.

=head2 Creating your own plugins

Plugins are executed from inside of the main method
C<Monitor::Simple-E<gt>check_services()>. The method creates one of
the two possible types of command-line. One is used for native
I<Monitor::Simple> plugins. This type is created if there are no
C<arg> tags in the plugin configuration:

   <plugin-command> -service <id>              \
                    -cfg <config-file>         \
                    -logfile <logfile>         \
                    -loglevel <level>          \
                    -logformat <format>

The C<service id> identifies what service this plugin was invoked
for. The C<-cfg config-file> contains a filename with the XML
configuration. From this file, you can get the full configuration by
using:

   my $config = Monitor::Simple::Config->get_config ($config_file);

All command-line arguments can be parsed by calling
C<Monitor::Simple::Utils-E<gt>parse_plugin_args()>. Therefore, the
I<Monitor::Simple> native plugin scripts usually start with:

   use Monitor::Simple;
   use Log::Log4perl qw(:easy);

   # read command-line arguments and configuration
   my ($config_file, $service_id) = Monitor::Simple::Utils->parse_plugin_args ('', @ARGV);
   LOGDIE ("Unknown service (missing parameter '-service <id>')\n")
      unless $service_id;
   my $config = Monitor::Simple::Config->get_config ($config_file);

As you see in this example, you can use the logging system by calling
C<Log::Log4perl> so-called "easy" methods: DEBUG(), INFO(), WARN(),
ERROR(), LOGDIE() and LOGWARN(), without doing anything with the
log-related arguments.

If the plugin configuration contains C<arg> tags, then the plugin will
be invoked with the command-line exactly as defined by these C<args>
tags. This is how to use plugins written without I<Monitor::Simple>
support. An example is the Nagios plugin "check-mem.pl". Its
configuration looks like this:

   <plugin command="check_mem.pl">
      <args>
         <arg>-u</arg>
         <arg>-w</arg> <arg>75</arg>
         <arg>-c</arg> <arg>80</arg>
      </args>
   </plugin>

and it will be called with this command-line:

   check_mem.pl -u -w 75 -c 80

Regarding the results, each plugin is expected to comply with the
Nagios plugins standard
L<http://nagios.sourceforge.net/docs/3_0/pluginapi.html> which means:

=over

=item B<Exit code>

The exit code should be zero for success and 1, 2 or 3 when the
checking failed:

   Exit code   Service State
      0           OK
      1           WARNING
      2           CRITICAL
      3           UNKNOWN

In your programming you may use the predefined constants in
I<Monitor::Simple> module:

   use constant {
      RETURN_OK       => 0,
      RETURN_WARNING  => 1,
      RETURN_CRITICAL => 2,
      RETURN_UNKNOWN  => 3,
   }

=item B<STDOUT>

The output can be a single line of text (which is mandatory), or it can be more lines (they are optional).

   TEXT OUTPUT
   LONG TEXT LINE 1
   LONG TEXT LINE 2
   ...
   LONG TEXT LINE N

Additionally, the first and the last line can be extended by
"performance data" separated by a bar ("|") character:

   TEXT OUTPUT | OPTIONAL PERFDATA
   LONG TEXT LINE 1
   LONG TEXT LINE 2
   ...
   LONG TEXT LINE N | PERFDATA LINE 2
   PERFDATA LINE 3
   ...
   PERFDATA LINE N

The I<Monitor::Simple> does not do anything special with the
performance data, it just leaves them in the report. But you should be
aware of it and not to use bar characters in the output of your
plugins.

=back

The I<Monitor::Simple> provides few methods that can be useful in your
plugins. For example, for checking availability of a URL or for
checking contents of a checked web page. See the distributed plugins
(and their documentation above) for more details.

=head2 Notifiers

The notifiers are external scripts that are called whenever a need for
a notification occurs. The notifiers can be specified for individual
services, or for all services (see examples in L<"Configuration
file">).

Each notifier is used independently on other notifiers; there is no
mechanism collecting them together and sending all notifications in
one go. If you need a "collective report" (which you often do) for all
services, use rather STDOUT produced by the
C<Monitor::Simple-E<gt>check_services()> method. This method can be
used in a program (do not forget the ready-to-use such program
C<smonitor>) that is called in a cron job - and the cron job itself
takes care about sending an email with the full result, without any
notifier. Sending email notifications by using notifiers is more
fine-grained: with the notifiers you can send notifications to
different email addresses for each service or a group of services.

Because of the independence of notifiers, some notification formats
may be less convenient. You can use without problems the "tsv"
(TAB-separated values) format because this format does not produce any
header or footer lines. All such notifications can be, therefore,
conveniently, appended to a single file keeping the full history of
all checking. Other formats, such as "html", are better used for
not-so-frequent notifications, such as sending an email if a service
failed.

A notifier is invoked only if the result of a service check matches
the code in the C<on> attribute of this notifier (again, see the
L<"Configuration file">).

Because notifiers are just external scripts they can be anywhere on
your machine. For such cases, you can use the full (absolute) path in
the C<command> attribute of the notifier. But usually, all (or most)
notifiers are in a single directory which you can specify in the
C<general> section of the configuration file:

   <general>
      <notifiers-dir>/some/directory/on/my/computer</notifiers-dir>
   </general>

Default location for all notifiers is a directory C<notifiers> in the
directory where sub-modules of I<Monitor::Simple> are installed. Which
means C<...somewhere/Monitor/Simple/notifiers/>. This is also the
place where you can find the ready-to-use notifiers coming with the
I<Monitor::Simple> distribution. Each of them has slightly different
needs for the configuration:

=head3 Notifier: B<copy-to-file>

A notifier appending its notification to a file.  Here is how to
configure this notifier (either within the C<service> tag or within
the C<general> tag):

   <notifier command="copy-to-file" on="all" format="tsv">
      <args>
         <arg>-file</arg>  <arg>report.tsv</arg>
         <arg>-login</arg> <arg>senger@allele</arg>
      </args>
   </notifier>

The mandatory C<-file> argument specifies the name of a file (usually
with the full path) where the notification will be appended. The
argument C<-login> allows to use a file on a remote machine, providing
the SSH login name. This notifier does not have any provision for
specifying a password. Therefore, the user from the C<-login> argument
must have its public key already installed on the remote machine.

=head3 Notifier: B<send-email>

A notifier sending notification to one or more email addresses. Be
aware that this could work only if your computer B<can> send
emails. If not check the following notifier "send-email-via-ssh".

Configuration of this notifier uses either attribute C<email> or
C<email-group> or both. Each of this attributes can have one or more,
comma-separated, values. Examples are:

   <notifier command="send-email" on="err" email="senger@localhost" />
   <notifier command="send-email" on="err" email="senger@localhost,kim@localhost" />
   <notifier command="send-email" on="err" email-group="watch-dogs" />
   <notifier command="send-email" on="err" email-group="watch-dogs, others" />
   <notifier command="send-email" on="err" email-group="secrets" email="senger@localhost"/>

If you use the C<email-group> attribute, you need also to tell what
addresses this group contains. It is done in the C<general>
section. For example:

   <general>
      <email-group id="others">
         <email>jitka@localhost</email>
         <email>guest@localhost</email>
      </email-group>
      <email-group id="secrets">
         <email>top.secret@elsewhere.com</email>
      </email-group>
   </general>

=head3 Notifier: B<send-email-via-ssh>

This notifier does the same as the previous I<send-email> except that
it first logs-in to a remote machine using SSH and executes the
C<mail> command there. It is useful when your computer cannot directly
send emails - but it requires that you have an SSH account somewhere
and that machine has your SSH public key installed (there is no
provision for specifying a password in this notifier configuration).

The configuration attributes for this notifier are the same as for
C<send-email> (except the different name of the command) and
additionally it has the C<-login> argument:

   <notifier command="send-email-via-ssh" on="err" email="martin.senger@gmail.com">
      <args>
         <arg>-login</arg>
         <arg>senger@open-bio.org</arg>
      </args>
   </notifier>

=head2 Creating your own notifiers

The notifiers are invoked - whenever necessary - from inside of the
main method C<Monitor::Simple-E<gt>check_services()>. The method
creates the following command-line:

   <notifier-command> -service <id>              \
                      -msg <file>                \
                      -emails email1 [email2...] \
                      -logfile <logfile>         \
                      -loglevel <level>          \
                      -logformat <format>        \
                      <additional arguments>

where additional arguments comes from the configuration file from the
C<arg> tags specified for this notifier. The C<service id> identifies
what service this notifier was invoked for. The C<-msg file> is a
filename with already formatted notification message. Read this file
but do not destroy it - other notifiers may want to read it, too. The
C<-emails...> may not be relevant to your notifier but if there were
attributes C<email> and/or C<email-group> in the notifier
configuration they are passed here.

All basic (not additional) arguments can be parsed by calling
C<Monitor::Simple::Utils-E<gt>parse_notifier_args()>. Therefore, the
notifier script usually starts with:

   use Monitor::Simple;
   use Log::Log4perl qw(:easy);

   # read command-line arguments
   my ($service_id, $msgfile, $emails) = Monitor::Simple::Utils->parse_notifier_args (\@ARGV);

You can continue by parsing the additional arguments (if any). Here is
an example from C<send-email-via-ssh> notifier:

   # read more command-line arguments specific for this notifier
   my ($login_name);
   Getopt::Long::Configure ('no_ignore_case', 'pass_through');
   GetOptionsFromArray (\@ARGV,
                        'login=s' => \$login_name,
                       );
   LOGDIE ("Missing parameter '-login' with hostname or user\@hostname\n")
           unless $login_name;

And then you do whatever your notifier needs to do. You can use the
logging system by calling C<Log::Log4perl> so-called "easy" methods:
DEBUG(), INFO(), WARN(), ERROR(), LOGDIE() and LOGWARN().

=head1 MODULES and METHODS

The best way to explore modules, methods and how to use them is to
look the I<smonitor> script. Here is a short summary what methods are
available. The main focus is on methods helping to write your own
plugins and notifiers.

=head2 Monitor::Simple

This module is a wrapper for all other modules and has only one, but
important, method (it is a class method):

=head3 check_services ($args)

It loops over all services and checks them (by invoking their
plugins). If necessary, it invokes their notifiers. And it produces a
summary report about all checks. The $args is a hashref with the
following keys and values:

=over

=item config_file -> $file

A mandatory argument. It specifies what configuration to use.

=item outputter => an instance of I<Monitor::Simple::Output>

This outputter will be responsible for creating the summary report of
all checks. If not given, a default outputter is used.

=item filter => hashref or arrayref or scalar

If any filter given then it contains IDs of services that will be
checked (and only them will be checked). Of course, it can still be
only services that are defined in the configuration file.

The scalar is use if you need to check only one service. The arrayref
points to a list of service IDs. The hashref has service IDs as keys
(values are ignored).

=item nonotif => boolean

If set to true all notifications (for all services) will be
disabled. Default is false.

=item npp => integer

Maximum number of service checks done in parallel. Default is 10.

=back

=head2 Monitor::Simple::Config

This module helps to find and explore the configuration file (that
defines what should be monitored). There are no instances of this
module (no C<new> or similar method), all methods are class methods
(but still methods - so use "Monitor::Simple::Config->" to call them).

=head3 resolve_config_file ($filename)

It tries to locate given $filename and return its full path:

=over

=item a) as it is - if such file exists

=item b) as $ENV{MONITOR_SIMPLE_CFG_DIR}/$filename

=item c) in the directory where the main invoker (e.g. your program)
is located

=item d) in one of the @INC directories

=item e) return undef

=back

=head3 get_config ([$filename])

It reads configuration from a file and returns it as a hashref. The
configuration is looked for in the given $filename or in a default
configuration file name. The path to both given and default
configuration file is resolved by rules defined in
L<resolve_config_file()|"resolve_config_file_($filename)">. The default
configuration file name is in
C<$Monitor::Simple::DEFAULT_CONFIG_FILE>.

=head3 extract_service_config ($service_id, $config)

Return a hashref with configuration for a given service (identified by
its $service_id). If such configuration cannot be found, a warning is
issued and undef is returned. The service configuration is looked for
in the given hashref $config containing the full configuration
(usually obtained by L<get_config()|"get_config_([$filename])">).

=head2 Monitor::Simple::UserAgent

This module deals with the Web communication. It uses
I<LWP::UserAgent> module to do the communication. It uses only class
methods.

=head3 head_or_exit ($service_id, $config)

It makes the I<HTTP HEAD> test described in
L<check_url.pl|"Plugin:_check-url.pl"> plugin. If everything okay it
just returns. Otherwise, it exits with the Nagios-compliant reporting
(see more about it in
L<report_and_exit()|"report_and_exit_($service_id,_$config,_$exit_code,_$return_msg)">).

This method uses C<head-test> portion of this service configuration.

=head3 post_or_exit ($service_id, $config)

It makes the I<HTTP POST> test described in
L<check_post.pl|"Plugin:_check-post.pl"> plugin. If everything okay it
just returns. Otherwise, it exits with the Nagios-compliant reporting
(see more about it in
L<report_and_exit()|"report_and_exit_($service_id,_$config,_$exit_code,_$return_msg)">).

This method uses C<post-test> portion of this service configuration.

=head2 Monitor::Simple::Output

This module is responsible for outputting the results of service
checks in several different formats. It is also used by notifiers to
format their notification messages. The main method is C<out()> that
prints the given message in the given format to the given target, both
as defined in the C<new()> constructor method.

=head3 new (%args)

It creates an instance (an I<outputter>) with the given arguments. The
recognized keys are:

=over

=item config => $config

A configuration - the only mandatory argument.

=item outfile => $file

A destination of the messages.

=item onlyerr => 1 | 0

It influences where the method C<out()> prints its messages. If
C<onlyerr> is set to 1 (default is 0) only the erroneous messages will
be sent to STDOUT. Here are various combinations of C<outfile> and
C<onlyerr> arguments:

   outfile    onlyerr    what will be done
   --------------------------------------------
   yes        no         all output to file

   yes        yes        all output to file
                         + errors also on STDOUT

   no         no         all output to STDOUT

   no         yes        only errors to STDOUT
   ---------------------------------------------

=item format => tsv | human | html

How to format output messages. Default is C<human>. The list of
actually supported formats can be obtained by calling a class method
C<Monitor::Simple::Output-E<gt>list_formats()>.

=item cssurl => $url

Used only for C<html> format . It points to a URL with the
CSS-stylesheet for the output. By default, it uses stylesheet similar
to the one shown in the distribution in file
F<Monitor/Simple/configs/monitor-default.css>.

=back

=head3 list_formats

A class method. It returns a hashref with a list of actually supported
formats (keys) and their description (values). At the time of writing
this document, it returns:

   { tsv    => 'TAB-separated (good for machines)',
     human  => 'Easier readable by humans',
     html   => 'Formatted as an HTML document' }

=head3 out ($service_id, $code, $message)

It formats and outputs one message about a just finished service check
(with an additional date field). $service_id defines what service is
the report about, $code indicates what kind of message is being
outputted (see $Monitor::Simple::RETURN* constants) and $msg is the
real message.

This method outputs one message, nothing before and nothing after
it. Because some formats needs also a header and possible a footer,
there are also methods C<header> and C<footer>.

=head3 header ([$header])

It outputs a header line (in the format specified in the C<new()>
constructor). The content of the header is either taken from the
$header argument or a default one is used.

=head3 footer ([$footer])

It outputs a footer line (in the format specified in the C<new()>
constructor). The content of the footer is either taken from the
$footer argument or a default one is used.

=head2 Monitor::Simple::Notifier

This module is responsible for deciding whether a notification should
be sent and for sending it. The main method is C<notify()> that
actually does first the decision if the notification should be sent
and then sending it using its own C<outputter>, an instance of
I<Monitor::Simple::Output>.

=head3 new (%args)

It creates an instance (an I<outputter>) with the given arguments. The
recognized keys are:

=over

=item config => $config

A configuration - the only mandatory argument. Actually, so far, the
only argument.

=back

=head3 notify ($result)

Given a $result of a service check, it makes all expected notifications
(as defined in the $config given in the C<new()> constructor). The
$result is a hashref with this content:

   { service => $service_id,
     code    => $code,
     msg     => $msg }

=head2 Monitor::Simple::Log

=head3 log_init ($logging_options)

It initiates logging (using the I<Log::Log4perl>
module). $logging_options is a hashref with the keys C<level>, C<file>
and C<layout> (some or all keys may be missing). The level is a
(case-insensitive) text acceptable by the method
C<Log::Log4perl::Level::to_priority()>: C<debug>, C<info>, C<warn>,
C<error> or C<fatal>. The file is where the log will be created
to. Value STDOUT is also accepted. Finally, the layout is a format of
the log messages as defined by in Log::Log4Perl; default value being

   %d (%r) %p> %m%n

When writing a plugin or a notifier, this method is called for you
automatically from the
L<parse_plugin_args()|"parse_plugin_args_($default_service_id,_@args)">
or L<parse_notifier_args()|"parse_notifier_args_(@args)">.

=head3 get_logging_options

It returns currently used logging options - in the same format as the
same options are define in L<log_init()|"log_init_($logging_options)">.

=head2 Monitor::Simple::Utils

This module is a container for various methods that did not fit
elsewhere. There are no instances of this module (no C<new> or similar
method), all methods are class methods (but still methods - so use
"Monitor::Simple::Util->" to call them).

=head3 parse_plugin_args ($default_service_id, @args)

It reads plugin's command-line arguments @args. It returns two-element
array with the configuration file name (may be undef) and service ID
(if the service id is found in @args, it uses $default_service_id). It
uses logging options (if any found in @args) to set the logging
system. Read about possible arguments in @args in L<"Plugins">.

=head3 report_and_exit ($service_id, $config, $exit_code, $return_msg)

It prints $return_msg on the STDOUT and exits with the
$exit_code. $config is not used (at least now) and can be undef. This
method is usually the last call in your plugin.

=head3 exec_or_exit ($service_id, $config)

It executes an external program with the given arguments and
(optionally) checks its STDOUT for the given content. If everything
okay it just returns. Otherwise, it exits with the Nagios-compliant
reporting (see more about it in
L<report_and_exit()|"report_and_exit_($service_id,_$config,_$exit_code,_$return_msg)">).

This method uses C<prg-test> portion of this service configuration.

=head3 parse_notifier_args ($args)

It reads plugin's command-line arguments $args (an arrayref - so the
recognized arguments can be removed from the provided array). It
returns a three-element array with a service ID, a file name with the
notification message and a reference to an array with all email
addresses (may be empty for some notifiers). It uses logging options
(if any found in $args) to set the logging system. Read about possible
arguments in $args in L<"Notifiers">.

=head1 BUGS

Please report any bugs or feature requests to
L<http://github.com/msenger/Monitor-Simple/issues>.

=head2 Known bugs and limitations

=over

=item Locking remote files

The I<copy-to-file> notifier adds notification messages to a file on a
remote machine (if it is configured to use SSH) and it does it without
any concern about the potential need of exclusively locking that file
(it may be accessed in the same time by many notifiers). It is this
way because it uses program "cat" which, as far as I know, does not do
locking.

Similarly, log files are not using any locking.

=back

=head1 ACKNOWLEDGMENT

Thanks to Gisbert W. Selke C<< <gws@cpan.org> >> the tests should be
now working also under Windows. He also provided a new version of the
C<check_mem.pl> - under the name I<check_mem2.pl> - a plugin, that
should work both under Windows and Unix.

=head1 AUTHOR

Martin Senger <martin.senger@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Martin Senger, CBRC-KAUST (Computational Biology Research Center - King Abdullah University of Science and Technology) All Rights Reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

