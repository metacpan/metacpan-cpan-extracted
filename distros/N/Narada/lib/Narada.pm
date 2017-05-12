package Narada;

use warnings;
use strict;
use Carp;

our $VERSION = 'v2.3.7';


# Possible types of current directory:
# - narada-1
#       config/patch/
#       config/version
#       var/backup/
#       var/patch/
# - narada
#       VERSION (except when migrating from 0.0.0)
#       .backup/
# - narada-1 and narada
#       config/backup/
#       config/log/
#       var/log/
sub detect {
    my %need = map {$_=>1} @_ ? @_ : qw( narada narada-1 );
    my $type
      = -d 'config/backup'  && -d '.backup'     ? 'narada'
      : -d 'config/backup'  && -d 'var/backup'  ? 'narada-1'
      :                                           undef
      ;
    return $type if $type && $need{$type};
    die 'This is not '.join(' or ', keys %need)." directory\n";
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Narada - framework for ease deploy and support microservice projects


=head1 VERSION

This document describes Narada version v2.3.7


=head1 SYNOPSIS

    #--- Create new project
    ~ $ narada-new my_proj
    ... New project will be created using template (from git repo).

    #--- Develop project as usually, until it's ready to run
    ~ $ cd my_proj
    ~/my_proj $
    ... Now you in project's source dir with git repo.
    ... You can develop this project in any way and language.

    #--- Make release and deploy it to check how it works
    ... NOTE: This operation is usually automated by script(s) provided
    ... by "project template" used while creating new project.
    ... Create file 0.1.0.migrate with instructions how to migrate between
    ... empty directory and version 0.1.0 of your project plus any related
    ... 0.1.0.{patch,tgz,etc.} files if you need them.
    ... Copy these files into .release/ subdirectory of directory where
    ... you want to deploy this version of project, for ex. in _live/.
    ~/my_proj $ cp 0.1.0.* _live/.release/
    ~/my_proj $ cd _live
    ~/my_proj/_live $ narada-install 0.1.0
    ... Now you in project's deploy directory, with config files, logs,
    ... running services, data files, etc. and you can check how it works.

    #--- Upgrade or downgrade project
    ... Repeat same steps to prepare 0.2.0.migrate and save into .release/.
    ~/my_proj/_live $ narada-install 0.2.0
    ... You can downgrade if something goes wrong.
    ~/my_proj/_live $ narada-install 0.1.0

    #--- You may need to update project's external configuration/data
    ~/my_proj/_live $ narada-setup-cron
    ~/my_proj/_live $ narada-setup-mysql
    ~/my_proj/_live $ narada-setup-qmail
    ~/my_proj/_live $ narada-start-services

    #--- You may need to backup this version and restore another one
    ~/my_proj/_live $ narada-backup
    ~/my_proj/_live $ cp .backup/full.tar .backup/full-0.2.0.tar
    ~/my_proj/_live $ narada-restore .backup/full-0.1.0.tar

    #--- You may need to lock project while manual maintenance
    ~/my_proj/_live $ narada-lock-exclusive
    [LOCKED] ~/my_proj/_live $
    ... Now all project applications will be blocked on next attempt
    ... to read/write any file or database, so you can safely change
    ... project files or databases, etc.
    [LOCKED] ~/my_proj/_live $ exit
    ~/my_proj/_live $
    ... Now project applications will be unblocked and continue to work.

    #--- Manage project
    ... View/monitor project's log.
    ~/my_proj/_live $ narada-viewlog
    ... Get console access to project's database.
    ~/my_proj/_live $ narada-mysql

    #--- Stop and uninstall this project.
    ... Cleanup related external configurations.
    ~/my_proj/_live $ narada-setup-cron --clean
    ~/my_proj/_live $ narada-setup-mysql --clean
    ~/my_proj/_live $ narada-setup-qmail --clean
    ... Kill all related background processes.
    ~/my_proj/_live $ narada-shutdown-services
    ~/my_proj/_live $ narada-bg-killall
    ... Then just remove it.
    ~/my_proj/_live $ cd ..
    ~/my_proj $ rm -rf _live/


=head1 DESCRIPTION

Narada was designed for ease development, deploy and support for medium/big
server-side project or large amount of small projects (used in microservice
architecture). It's a framework which define B<the way to manage> your
project (which doesn't really depend on your project's nature), and
doesn't restrict your project's implementation in any way. With Narada you
can create any projects using any programming languages as long as your
project conform to Narada interface and work in *NIX.

Typical example of project which wins a lot when managed by Narada is web
site backend or network service, which consists of several applications
(even written in different programming languages) with different entry
points (HTTP, RPC, cron, email), which all should have common runtime
environment, logs, etc.

In short, Narada dictates where your project should keep and how it should
work with: config files, logs, locks, temporary and persistent data files,
required external configuration for cron, qmail, databases. All of this is
called "Narada interface", and if your project conform to it then you can
also use a lot of handy command-line tools provided by Narada to deploy,
backup and manage your project.

There are few helper Narada::* modules for Perl which helps you to conform
Narada interface in your Perl modules/scripts; for other languages you may
want to create similar helpers, but this isn't required - Narada interface
is simple and can be easily conformed without using special helpers (it
was designed that way to make it ease to conform to Narada interface even
in shell scripts).

To use Narada you'll also need to learn format of C<.migrate> files used
to describe project's upgrade/downgrade operations (see
L<App::migrate/"SYNTAX">) and choose which "project template" to use for
your new project (for ex. see default template
L<narada-base|https://github.com/powerman/narada-base>; you can modify it
with plugins or develop your own template from scratch).

=head2 Main features

=over

=item Templates and plugins for project source.

You can choose one of existing templates when starting new project, and
even modify some of them using plugins - or made your own templates or
plugins if you often develop similar projects. Both templates and plugins
are implemented by merging remote repositories, so if they will change
after you've started your project you can easily update it by fetching and
merging them again.

=item You can continue using your favorite workflow.

While L<narada-new> tool and existing project templates/plugins use Git,
you may opt out and don't use them. This is only Narada tool which do
something with your B<project's source directory> (all other tools work
only with B<project's deploy directory>) and it's completely optional. You
can create new project using Mercurial or even without using any VCS, and
use any workflow you like. All you need is produce C<.migrate> and related
files as result of releasing every version of your project, including
ephemeral development versions which you may release many times per day.

=item Provide file/directory structure for deployed project.

Some choices are already made for you: where and how to store project
configuration, temporary and persistent data files, logs, locks, backups,
current version number. This file/directory structure was designed to make
it ease to use from any programming language (including shell scripts) and
provide several valuable features like reliable upgrades and backups.

=item Reliable project upgrade and downgrade.

Narada use C<.migrate> files to describe operations needed to upgrade and
(required!) downgrade project. While usual development process you'll run
these operations each time you wanna check how your changes work, i.e.
this will happens dozens (if not hundreds) of times while you're
developing next version, so both upgrade and downgrade operations are
usually guaranteed to be well-tested before releasing each next version.

=item Different project installations have different configurations.

Changes in your local configuration won't be occasionally sent with next
update to production server. And you won't have any issues because of
config files added into your repo with project sources because in Narada
projects config files exists only in B<project's deploy directory>.

=item Ease project setup after installation/update.

Narada provide tools to update project's external setup (cron tasks, qmail
handlers for incoming emails, MySQL scheme) according to current project's
configuration.

=item Reliable services.

Run your FastCGI or RPC daemons with guaranteed restart after crash.
Narada project may have own services, always running in background.
By default we use L<runit|http://smarden.org/runit/> for supervising
project's services, but other similar supervisors like daemontools or s6
also can be used.

=item All project's applications have common log(s).

When your project consists of many applications/scripts or run many
processes of same application it's important to have single common log for
all of them. To implement this each Narada project usually run own log
service. By default we use L<socklog|http://smarden.org/socklog/>
(syslog-compatible daemon) to receive logs from all project's applications
and C<svlogd> tool from L<runit|http://smarden.org/runit/> to manage logs
(rotate, filter, group records in separate files, etc.).

=item All project's applications have common lock.

This guarantee live project's consistency while backup, update or manual
maintenance. NOTE: While Narada provide and use this lock file in it's own
tools B<it's your responsibility to always get shared lock on that lock
file before doing read/write of any project's files or databases> - if you
won't do this you'll break mentioned above consistency guarantee.

=item Consistent and fast project backup.

Narada interface include shared/exclusive project locking, which let us
guarantee backup consistency between project files and databases.

Narada backup tool support incremental backups both for files and
database, which makes it possible to backup most projects in few seconds -
your website visitors won't even notice your daily/hourly backup!

=item Backward compatibility.

Whenever possible, projects created using previous Narada versions will be
supported by latest Narada (but newly added tools may not work with such
an old projects).

=back

=head2 Important changes since previous versions

=head3 Narada 1.x

Narada 1 was created when Git and Mercurial wasn't exists yet, so it
doesn't use repository for project sources. Also it doesn't separate
project's source vs deploy directories and run project's applications in
directory with it sources - this was perfectly fine for projects developed
in script languages like Perl without using VCS. The C<narada-new> tool
used to create Narada 1 projects is still available but it was renamed to
L<narada-new-1>.

Also Narada 1 provide several tools used to generate, email/upload and
apply patches for project's directory - this was the way to both deploy
new version to server and distribute changes to other developers in team.
These tools has no use in current Narada, but they still exists for
compatibility with Narada 1 projects: L<narada-diff>, L<narada-release>,
L<narada-patch-remote>, L<narada-patch-send>, L<narada-patch-pull>,
L<narada-patch>.

Files&directories structure also was changed since Narada 1.x, see
L<Changes|https://metacpan.org/changes/distribution/Narada> in version
2.0.0 for more details.

This documentation describe current Narada, check documentation for
L<latest Narada 1|https://metacpan.org/pod/release/POWERMAN/Narada-v1.4.5/lib/Narada.pm>
if you're still using Narada 1 projects.


=head1 EXAMPLE

Create new project:

    ~ $ narada-new hello_world
    ... a lot of Git output skipped
    ~ $ cd hello_world/
    ~/hello_world $ ls -AF
    build*  deploy*  doc/  .git/  .gitignore  migrate  release*  t/

This is B<project's source directory> initialized using default template.
It provide basic C<migrate> files with all commands needed to create all
files/directories needed by every deployed Narada project plus few
scripts: C<./release> for releasing new versions (both development
ephemeral versions and tagged final versions) and C<./deploy> for
installing them into C<_live/> subdirectory.

Cool, we already can release something!

    ~/hello_world $ ./release
    t/build/migrate.t .. 1/1 # Checking migrate
    t/build/migrate.t .. ok
    All tests successful.
    Files=1, Tests=1,  0 wallclock secs ( ... )
    Result: PASS
    ~/hello_world $ ls -AF
    build*  deploy*  doc/  .git/  .gitignore  migrate  release*  .release/
    t/  VERSION
    ~/hello_world $ ls -AF .release/
    0.0.0+b4ff31c.migrate  0.0.0+b4ff31c.patch
    ~/hello_world $ cat VERSION
    0.0.0+b4ff31c

As you see, your project get unique ephemeral version number in file
C<VERSION> and this version was released as two files in C<.release/>.
Now, let's deploy it!

    ~/hello_world $ ./deploy
    Loading .release/0.0.0+b4ff31c.migrate
    ... a lot of executed commands output skipped
    Migration to 0.0.0+b4ff31c completed
    ~/hello_world $ ls -AF
    build*  deploy*  doc/  .git/  .gitignore  _live/  migrate  release*
    .release/  t/  VERSION
    ~/hello_world $ ls -AF _live/
    .backup/  config/  doc/  .lock  .release/  t/  tmp/  var/  VERSION

The C<_live/> is B<project's deploy directory>. There are may be many of
them, even on same development machine in case you develop in several
branches and wanna have each branch deployed to separate directory, or
just wanna install simultaneously old and new versions of project and
compare how they work.

Okay, we get Narada files&directories structure in C<_live/>, but it
doesn't have much use for now. Let's add something to our project.

    ~/hello_world $ cat >hello <<EOF
    > #!/usr/bin/perl
    > print "Hello, World!\n";
    > EOF
    ~/hello_world $ chmod +x hello
    ~/hello_world $ git add hello
    ~/hello_world $ ./release && ./deploy
    t/build/migrate.t .. 1/1 # Checking migrate
    t/build/migrate.t .. ok
    All tests successful.
    Files=1, Tests=1,  0 wallclock secs ( ... )
    Result: PASS
    Loading .release/0.0.0+b4ff31c.dirty-1428492362.migrate
    Loading .release/0.0.0+b4ff31c.migrate
    Backuping to .backup/full-0.0.0+b4ff31c.tar
    ...
    Migration to 0.0.0 completed
    ...
    Migration to 0.0.0+b4ff31c.dirty-1428492362 completed

What just happens? New ephemeral version "0.0.0+b4ff31c.dirty-1428492362"
was released (it have such a name because we didn't committed our changes
to the repo yet); then previous version "0.0.0+b4ff31c" installed in
C<_live/> was saved in the backup and downgraded to version "0.0.0" (which
is initial version meaning "empty directory"); then that empty directory
was upgraded to current version "0.0.0+b4ff31c.dirty-1428492362". Look:

    ~/hello_world $ cat VERSION
    0.0.0+b4ff31c.dirty-1428492362
    ~/hello_world $ ls -AF .release/
    0.0.0+b4ff31c.dirty-1428492362.migrate  0.0.0+b4ff31c.migrate
    0.0.0+b4ff31c.dirty-1428492362.patch    0.0.0+b4ff31c.patch
    ~/hello_world $ ls -AF _live/
    .backup/  config/  doc/  hello*  .lock  .release/  t/  tmp/  var/
    VERSION
    ~/hello_world $ cd _live/
    ~/hello_world/_live $ ./hello
    Hello, World!
    ~/hello_world/_live $ cd -
    ~/hello_world $

Next, let's start using some Narada features, like config files.
We'll also add migration operation to C<migrate> file to create new config
file on upgrading to this version and remove it on downgrading from this
version.

    ~/hello_world $ echo 'add_config my_name Powerman' >> migrate
    ~/hello_world $ cat >hello <<EOF
    > #!/usr/bin/perl
    > use Narada::Config qw( get_config_line );
    > printf "Hello, %s!\n", get_config_line('my_name');
    > EOF
    ~/hello_world $ ./release && ./deploy
    ...
    Loading .release/0.0.0+b4ff31c.dirty-1428493197.migrate
    Loading .release/0.0.0+b4ff31c.dirty-1428492362.migrate
    Backuping to .backup/full-0.0.0+b4ff31c.dirty-1428492362.tar
    ...
    Migration to 0.0.0 completed
    ...
    Migration to 0.0.0+b4ff31c.dirty-1428493197 completed
    ~/hello_world $ cd _live/
    ~/hello_world/_live $ ./hello
    Hello, Powerman!

In deploy directory we can safely modify config or data files - these
changes will affect only project deployed in this directory.

    ~/hello_world/_live $ ls -AF config/
    backup/  crontab/  log/  my_name  mysql/  qmail/
    ~/hello_world/_live $ echo Anonymous > config/my_name
    ~/hello_world/_live $ ./hello
    Hello, Anonymous!
    ~/hello_world/_live $ cd -
    ~/hello_world $

Now, let's release current version tagged with own version number.

    ~/hello_world $ git add migrate
    ~/hello_world $ git commit -m 'add hello'
    ~/hello_world $ ./release --minor
    t/build/migrate.t .. 1/1 # Checking migrate
    t/build/migrate.t .. ok
    All tests successful.
    Files=1, Tests=1,  0 wallclock secs ( ... )
    Result: PASS
    [master 8338faa] Release 0.1.0
     1 file changed, 4 insertions(+)
    ~/hello_world $ cat VERSION
    0.1.0
    ~/hello_world $ ls -AF .release/
    0.0.0+b4ff31c.dirty-1428492362.migrate  0.0.0+b4ff31c.migrate
    0.0.0+b4ff31c.dirty-1428492362.patch    0.0.0+b4ff31c.patch
    0.0.0+b4ff31c.dirty-1428493197.migrate  0.1.0.migrate
    0.0.0+b4ff31c.dirty-1428493197.patch    0.1.0.patch
    ~/hello_world $

And deploy it on server:

    ~/hello_world $ ssh localhost 'mkdir -p hello_project/.release'
    ~/hello_world $ scp .release/0.1.0.* localhost:hello_project/.release/
    0.1.0.migrate        100% 7105     6.9KB/s   6.9KB/s   00:00
    0.1.0.patch          100% 5223     5.1KB/s   6.9KB/s   00:00
    ~/hello_world $ ssh localhost
    ~ $ cd hello_project/
    ~/hello_project $ ls -AF
    .release/
    ~/hello_project $ ls -AF .release/
    0.1.0.migrate  0.1.0.patch
    ~/hello_project $ narada-install 0.1.0
    Loading .release/0.1.0.migrate
    ...
    Migration to 0.1.0 completed
    ~/hello_project $ ls -AF
    .backup/  config/  doc/  hello*  .lock  .release/  t/  tmp/  var/
    VERSION
    ~/hello_project $ ./hello
    Hello, Powerman!
    ~/hello_project $

Finally, let's cleanup and uninstall all projects.

Template used to create this project include some basic cron configuration
to make daily project backups. And these settings was already added to
your user's crontab while installing the project. So, before removing
project directories we should remove this cron setup.

    ~/hello_project $ narada-setup-cron --clean
    ~/hello_project $ cd ..
    ~ $ rm -rf hello_project/
    ~ $ exit
    ~/hello_world $ cd _live/
    ~/hello_world/_live $ narada-setup-cron --clean
    ~/hello_world/_live $ cd ../..
    ~ $ rm -rf hello_world/


=head1 INTERFACE

The "Narada interface" is described here files&directories structure for
B<project's deploy directory> and some conventions about how they should
be used. Your project must conform to this interface.

=over

For example, let's review part of Narada interface related to
L</"Consistent and fast project backup."> feature.

"Consistent" require using shared/exclusive file locking on file
C<.lock>. All Narada does is create that file while installing new
project and acquire exclusive lock on it while executing L<narada-backup>.
But to really have consistent backups B<you> must acquire shared lock on
that file when accessing any project files or database in any of your
applications! In Perl scripts you can use helper module L<Narada::Lock>, and
it's not a big deal to manually use flock(2) in any other language. If you
fail to do this, you backups won't be guaranteed to be consistent anymore!

"Fast" consists of two parts: files and database. To backup project files
fast you should keep large junk files according to Narada's interface -
in directories listed in C<config/backup/exclude>, for ex. in C<tmp/>.
To backup MySQL database fast you should try hard to store large amount of
data in append-only tables with "auto_increment primary key", and add
names of these tables to C<config/mysql/dump/incremental>.

All of this will let L<narada-backup> to hold exclusive lock (and thus
freeze your project while backup) shortest possible time, complete safe
part of backup task after releasing the lock, and use incremental backups
to save both time and disk space.

=back

=head2 Directory types

There are two types of "root" directories in your project:
B<source directory> and B<deploy directory>.

The B<project's source directory> isn't part of Narada interface.
Only tool which work with it is L<narada-new> (which helps you to create
new project), but you're not required to use it, and even if you use it no
Narada tools will touch your B<project's source directory> after it will
be created.

The B<project's deploy directory> is the one where all files&directories
defined by Narada interface should exists. Also B<it's the directory where
you should run all Narada tools and your project's applications> - this is
required to allow them to find all Narada files&directories using paths 
relative to current directory.

It's ok to have many source directories (as repo clones for your team) and
to have many deploy directories (as different installations on same or
different computers) - for ex. it may be very useful to deploy different
versions from different Git branches to different deploy directories on
same development machine.

=head2 Overview of deploy directory structure

Project templates often include typical directories like C<doc/> or C<t/>
but they isn't part of Narada interface and thus you're free to rename or
remove them if you like.

=over

=item C<.release/>

Contain C<.migrate> and related files used to upgrade and downgrade
project while migrating to another version.

=item C<.backup/>

Contain project backups. You can create and manage them yourself, but they
also will be automatically created before migrating to another version and
may be automatically used when only way to downgrade project is restore
previous version from backup. In general it's safe to remove backups when
you like, but absence of some backups may make it impossible to downgrade
to some previous version.

=item C<VERSION>

Contain current project version. Required for upgrade and downgrade, and
will be automatically updated after migration or restoring from backup.
May be useful for your applications (read-only).

=item C<.lock*>

Several lock files used mostly internally by Narada tools, except for
the C<.lock> file which should be shared-locked by all your applications
while they read or write any project's files or databases.

=item C<config/>

Project's configuration (both defined by Narada interface and custom
settings of your project). May differ in different project's deploy
directories. While it's possible to modify configuration in all deploy
directories while project migration, usually most of config files modified
either manually or by your applications in one deploy directory.

=item C<service/>

Used to setup project's services (daemons) and run them using service
supervisor (runit, daemontools, etc.). Most projects usually have just one
(log) or a couple (log and fastcgi/http/rpc) services.

=item C<tmp/>

Used for temporary data files. Contents of this directory won't be
included in backups.

=item C<var/>

Used for persistent data files.

=back

=head2 Deploy

In L</EXAMPLE> above you've seen scripts C<./release>, C<./deploy>, files
C<migrate> and C<VERSION>, directories C<.release/> and C<_live/> while
working with Narada, but all of them was in B<project's source directory>
and isn't part of Narada interface! All of them was provided by used
project template, and different templates may implement these tasks in
different ways - read documentation for chosen project template. Also
you're free to modify these paths and scripts in any way - template
provide only starting point, but it's your project's sources and you have
freedom to do anything you like.

What is actually part of Narada interface is result of running these
C<./release && ./deploy> scripts: file C<< .release/<version>.migrate >>
and optional related files (usually named C<< .release/<version>.patch >>
or C<< .release/<version>.tgz >>) in B<project's deploy directory>.
No matter how you develop, build, compile, release and copy/upload new
version to deploy directory, the final result should be such file/files.

=over

=item C<< .release/<version>.migrate >>

These files must contain upgrade and downgrade operations between version
previous to C<< <version> >> and C<< <version> >>, but usually they also
contain operations for all previous versions up to initial version "0.0.0"
(meaning "empty directory").

It's recommended to use L<semantic versions|http://semver.org/>, but
except for predefined initial version "0.0.0" you're free to use for your
project any version numbering scheme you like.

Files&directories structure conforming to Narada interface must be created
using upgrade operations in this file when describing upgrade from version
"0.0.0".

Narada uses L<App::migrate> to implement project migrations, format of
C<.migrate> files is documented in L<App::migrate/"SYNTAX">.

=over

B<When you need to convert some data in files or database when installing
new version you should use> C<.migrate> B<file to run scripts which will
do this.>

You should not try to do these data migrations automatically on first time
new version of your project's application starts - both because this will
make impossible to downgrade quickly and without losing data (if you'll
provide script which does backward data conversion, of course) and you'll
have to restore from backup instead, and because project migration may
include many upgrades at once and your application as it was at one of
intermediate versions wasn't get a chance to run at all.

=back

=back

=head2 Backup

=over

=item C<config/backup/exclude>

Shell patterns (one per line) for files/dirs which shouldn't be included
in backup. Must contain at least these lines:

    ./.backup/*         to avoid recursively including old backups in new
    ./.lock*            to avoid unlocking while restoring from backup
    ./tmp/*             to conform to Narada interface and not include
                        temporary files in backups

=item C<config/mysql/dump/incremental>

List of database tables (one per line) which can be dumped incrementally
(according to their "auto_increment primary key" field). C<narada-backup>
will dump only new records in these tables (dumps for older records will
be available in existing files in C<.backup/> or C<var/mysql/>).

=item C<config/mysql/dump/empty>

List of database tables (one per line) which records shouldn't be included in
backup, only scheme.

=item C<config/mysql/dump/ignore>

List of database tables (one per line) which shouldn't be included in
backup at all (even scheme).

=item C<var/mysql/>

Contain files with last database dump (usually made while last backup).

=item C<var/use/>

Keeps current used/unused state recorded by last run of C<narada-setup-*>
and C<narada-*-services> tools. It will be used by L<narada-restore> to
setup project after full restore.

=item C<.backup/full.tar>

=item C<.backup/incr.tar>

Latest full and incremental backups. To force full backup next time just
remove C<.backup/full.tar>. See L<narada-backup> for more details.

=back

=head2 Logging

=over

=item C<config/log/type>

Define type of logging: C<syslog> (default if this file not exists) or
C<file>. If set to C<syslog> then C<config/log/output> should contain path
to syslog's UNIX socket (like C<var/log.sock> or C</dev/log>).

It's recommended to use C<syslog> type and run syslog-compatible log
service for each project, because it's very hard to correctly implement
concurrent writes to common log file.

If set to C<file> then each application in your project must open this
file in append-only mode, avoid writing single log record using more than
one write syscall (may happens because of buffered I/O), don't use NFS for
C<var/log/>… and you anyway may have some issues. One possible issue is
performance: if you'll conform to Narada interface and acquire shared lock
on C<.lock> before writing each one line to log this may result in
noticeable slowdown. Another possible issue happens if you avoid locking
because of performance issue, but without locks it may be impossible to
ensure log consistency in backups or reliably implement log rotation.

=item C<config/log/output>

File name where project applications should write their logs: either UNIX
socket (to syslog-compatible daemon) or usual file (or C</dev/stdout>).

=item C<config/log/level>

Current log level, should be one of these strings:

    ERR WARN NOTICE INFO DEBUG DUMP

=item C<var/log/>

This directory contains project log files.

=back

=head2 Cron tasks

=over

=item C<config/crontab/*>

Settings for project's cron tasks, in crontab format.

When these settings will be installed to system's cron, each command will
be automatically prefixed by:

    cd /path/to/project/deploy/dir || exit;

C<narada-setup-cron> update system's cron using settings from these files.

=back

=head2 Processing incoming emails

Only qmail supported at this time.

=over

=item C<config/qmail/*>

Files with qmail configuration (in .qmail format).
Commands listed in these files (lines beginning with C<|>) will be
executed in B<project's deploy directory> instead of user's home directory
(qmail's default behaviour).

=item C<var/qmail/*>

Internally used by C<narada-setup-qmail>.

=back

=head2 Database

Only MySQL supported at this time.

=over

=item C<config/mysql/db>

Contains one line - name of MySQL database. If this file doesn't exists or
empty - Narada won't use database.

=item C<config/mysql/login>

=item C<config/mysql/pass>

Login/pass for database.

=item C<config/mysql/host>

Host name of database server. if this file doesn't exists or empty then
usual UNIX socket will be used to connect to MySQL server.

=item C<config/mysql/port>

TCP port of database server.

=back

=head2 Locking

=over

=item C<.lock>

This file should be shared-locked using flock(2) or L<Narada::Lock> or
L<narada-lock> before accessing any project's files or database by usual
applications, and exclusive-locked while project's backup, update or
manual maintenance.

=item C<.lock.new>

This file will be created before trying to acquire exclusive lock on
C<.lock>. All applications wanted to acquire shared lock on C<.lock> must
check before that is C<.lock.new> exists and if yes then delay/avoid
locking C<.lock>. This is needed to guarantee exclusive lock will be
acquired as soon as possible.

After exclusive lock will be acquired and critical operations requiring it
will be completed - C<.lock.new> will be removed.

If server will be rebooted while waiting for exclusive lock or in the
middle of critical operations requiring it then file C<.lock.new>
won't be removed and project applications won't continue to work after
server reboot until this file will be removed manually or another
operation requiring exclusive lock will be started and successfully
finished.

=item C<.lock.bg>

Each project's background process (running as service, or started by cron,
qmail, etc.) should acquire shared lock on this file. This can be easily
done using L<narada-bg> tool. This will make possible to reliably detect
and kill all project's background processes while upgrade or downgrade
using L<narada-bg-killall> tool.

=back

=head2 Services

There are several ways to start project's services: manually by running
L<narada-start-services> - this way they wasn't start automatically after
server reboot, try to start them every 1 minute from cron if they wasn't
running yet (usually using C<config/crontab/service> but this file isn't
part of Narada interface) - this way it may took about 1 minute before
project services will be started after deploy or server reboot, run them
as one of system-wide service based on similar (runit/daemontools/s6/etc.)
supervisor - fastest and most reliable way but require root permissions to
add new system-wide service.

=over

=item C<config/service/type>

Type of used service supervisor. For now only supported type is C<runit>.

=item C<.lock.service>

This lock file is used by L<narada-start-services> to check is services
already running.

=back


=head1 TOOLS

All tools (except L<narada-new>) must be executed in
B<project's deploy directory>. Read man pages of these tools for details.

=head2 Create new project

=over

=item L<narada-new>

=back

=head2 Deploy & uninstall

=over

=item L<narada-install>

=item L<narada-setup-cron>

=item L<narada-setup-mysql>

=item L<narada-setup-qmail>

=item L<narada-shutdown-services>

=item L<narada-start-services>

=back

=head2 Backup & restore

=over

=item L<narada-backup>

=item L<narada-mysqldump>

=item L<narada-restore>

=back

=head2 Background processes

=over

=item L<narada-bg>

=item L<narada-bg-killall>

=item L<narada-lock>

=item L<narada-lock-exclusive>

=back

=head2 Misc tools

=over

=item L<narada-viewlog>

=item L<narada-mysql>

=item L<narada-emu>

=back

=head2 SSH tools

These tools make it easier to copy files between local and remote
project's deploy directories. If you're doing things in right way - you
won't need these tools.

=over

=item L<narada-remote>

=item L<narada-upload>

=item L<narada-download>

=back

=head2 Perl modules

=over

=item L<Narada::Config>

=item L<Narada::Lock>

=item L<Narada::Log>

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/Narada/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/Narada>

    git clone https://github.com/powerman/Narada.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Narada>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Narada>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Narada>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Narada>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Narada>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 CONTRIBUTORS

Nikita Savin E<lt>asdfgroup@gmail.comE<gt>

Nick Levchenko E<lt>project129@yandex.ruE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
