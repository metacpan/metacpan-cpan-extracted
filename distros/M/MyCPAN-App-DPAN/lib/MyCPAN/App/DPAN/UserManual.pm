package MyCPAN::App::DPAN::UserManual;
use strict;
use warnings;
use utf8;

use vars qw($VERSION);
$VERSION = '1.281';

=encoding utf8

=head1 NAME

MyCPAN::App::DPAN::UserManual - How to manage a DPAN

=head1 DESCRIPTION

DPAN, short for D{ark|istributed|ecentralized} Perl Archive Network,
helps you create your own Perl distributions repository that you can
use with standard CPAN tools. You can put any distributions with any
versions that you like in your own repository since you completely
control it. These can be distributions from the real CPAN, private
distributions that you create yourself, or older versions of
distributions from BackPAN (the historical CPAN archive).

The DPAN stuff takes a bunch of distributions that you specify and
organizes them into a CPAN-like repository. The simplest process is to
dump all of your distributions in a single directory and run the
C<dpan> command in the same repository:

	% cd my_dist_directory
	% dpan

By default, C<dpan> finds and organizes all of the distributions in
the directory into the appropriate CPAN-like structure. Behind the
scenes, C<MyCPAN::Indexer> looks at each distribution and creates a
report from it. You should see a directory that contains a reports for
each distribution:

	indexer_reports/
		error_reports/
		success_reports/

From the list of reports, C<dpan> creates the right index files,
including:

	authors/00whois.xml
	authors/01mailrc.txt.gz
	modules/02packages.details.txt.gz
	modules/03modlist.data.gz

After everything is done, you can use your new repository as your CPAN
source. You can use it as a local directory, serve it through a
webserver, or put it behind an FTP server.

=head2 Deciding on which modules to add

So far, it's up to you to decide which distributions that you want in
your repository, but we'd like to create a tool that can take a single
distribution and tell you everything else it needs.

For a more general solution, you can start with a MiniCPAN which
either filters the distributions from the real CPAN or just includes
all of them.

You can keep a separate directory of your private distributions that
C<dpan> can merge for you.

=head2 Running C<dpan> for the first time

Running C<dpan> for the first time over a large repository can take
quite a bit of time. Running it over all of a MiniCPAN, about 20,000
distributions taking up about 1 GB, can take a couple of hours.
Fortunately, on subsequent runs C<dpan> only needs to analyze the
distributions it hasn't succesfully analyzed yet and the run should be
much faster.

To play with C<dpan>, start with a directory that only has a couple of
modules in it. Once you work out how everything works and setup
everything to your satisfaction, you can run C<dpan> against a full
repository.

=head2 Running your own CPAN Search

Once you have your DPAN, you can run C<minicpan-webserver> from
C<CPAN::Mini::Webserver>. You'll have a basic website that allows you
to search for modules and read documentation just for the
distributions in your DPAN.

=head1 ADVANCED USE

=head2 Configuring C<dpan>

C<dpan> can take two different configuration files: one for its setup
and one for C<Log::Log4perl>:

	% dpan -f dpan.conf -l dpan.log4perl

See the L<LOGGING> section for more details about the logging setup.

The C<dpan> configuration directives are listed in the C<dpan>
documentation. The format is a simple, line-oriented list of
key-value pairs:

	organize_dists 1
	retry_errors   0
	merge_dirs     my_local_modules/foo/bar

To see the configuration for any setup, you can use the C<-c> switch:

	% dpan -c
	alarm   15
	author_map
	collator_class   MyCPAN::App::DPAN::Reporter::Minimal
	copy_bad_dists   0
	dispatcher_class   MyCPAN::Indexer::Dispatcher::Serial
	dpan_dir   /Users/brian/DEv/mycpan--app--dpan
	error_report_subdir   /Users/brian/DEv/mycpan--app--dpan/indexer_reports/error
	extra_reports_dir
	fresh_start   0
	i_ignore_errors_at_my_peril   0
	ignore_missing_dists   0
	ignore_packages   main MY MM DB bytes DynaLoader
	indexer_class   MyCPAN::App::DPAN::Indexer
	indexer_id   Joe Example <joe@example.com>
	interface_class   MyCPAN::Indexer::Interface::Text
	log_file_watch_time   30
	organize_dists   1
	parallel_jobs   1
	pause_full_name   DPAN user <CENSORED>
	pause_id   DPAN
	prefer_bin   0
	queue_class   MyCPAN::App::DPAN::SkipQueue
	relative_paths_in_report   1
	report_dir   /Users/brian/DEv/mycpan--app--dpan/indexer_reports
	reporter_class   MyCPAN::App::DPAN::Reporter::Minimal
	retry_errors   1
	skip_perl   0
	success_report_subdir   /Users/brian/DEv/mycpan--app--dpan/indexer_reports/success
	system_id   an unnamed system
	use_real_whois   0
	worker_class   MyCPAN::Indexer::Worker

There are some directives that you'll probably want to set right away because
they are specific to your setup:

	dpan_dir   /path/to/my/dpan/repository
	indexer_id   Joe Example <joe@example.com>
	pause_full_name   DPAN user <CENSORED>
	pause_id   DPAN
	system_id   an unnamed system

You are probably safe with the remaining defaults which configure
C<dpan> for the most common situation.

=head2 Dealing with indexing failures

If there's an error, you'll see some error output and C<dpan> will
dump the error into a file for that distribution under
F<indexer_reports/error_reports/>.

There are two common reasons for an index failure: either the analysis
could not complete in the alloted time (by default 15 seconds) or
C<dpan> could not unpack the distribution. Although rare, the next
most frequent problem comes from an unexpected distribution structure.

We're developing a bunch of reports that we can distribute separately
so you don't have to do this by hand. If your run into problem
distributions, let us know.

=head3 Time-outs

If you see the error "Alarm rang", it means the analysis timed-out.
You can set a longer time by configuring the alarm time in your
configuration file:

	alarm: 120

Some distributions can take an extremely long time (more than a couple
minutes) to unpack. This time might include the transfer speed over your
network if you have to get the file over NFS, etc), the size of the distribution,
the speed at which you can write files.

=head3 Distribution unpacking

C<MyCPAN::Indexer> relies on C<Archive::Extract> to unpack distributions.
C<Archive::Extract> can try a pure Perl solution through C<Archive::Tar>
or use an external binary.

=head3 Can't find modules

CPAN authors can do almost anything they like with their modules, so
C<MyCPAN::Indexer> might have some trouble indexing some modules.  The
most frequent problems comes from errors unpacking archives.

Although C<MyCPAN::Indexer> is constantly trying to improve its
ability to analyze distributions, DPAN specifically disables
C<MyCPAN::Indexer>'s preferred method of running the build file and
inspecting F<blib/> to see what showed up. C<dpan> tries not to run
any code, so it sometimes can't guess what would have shown up in
F<blib/>. It does its best though.

Aside from improvements in C<MyCPAN::Indexer>'s ability to deal with
odd situations, C<dpan> has another way to handle these problematic
distributions. You can configure the C<extra_reports> directive so the
indexer can use pre-prepared reports in addition to the reports that
it generates. These extra reports can be ones that you create by hand
with information that you know about the module or reports that you
get from a more in-depth index.

=head2 Adding your local distributions

You could just dump the private distributions you want to add into
the DPAN directory, but you can also copy them in from other
directories:

	merge_dirs /repo/foo/bar /repo/baz/quux

This is quite handy when you are using C<CPAN::Mini>, which tries to
remove files it doesn't think belong in the repository. After you
update your MiniCPAN, C<dpan> can copy these additional modules into
your DPAN repository.

=head1 USE CASES

C<dpan> is usually only part of the process to manage your DPAN. The
particular process depends on your needs, and there are several ways
that you could manage it.

=head2 A small private repository

If you prefer a very small repository that contains only the
distributions that your application uses, you have a bit of work to
do. It's on our to-do list to automatically list and download all of
the distributions that a particular application uses, but we're not
that far yet.

	... Magic happens ...

Assuming the magic that gets you all of the distributions that you
need, put all of those distributions in the a single directory and run
C<dpan>.

=head2 Tracking a MiniCPAN

You can base your DPAN on a MiniCPAN. There are a few steps to go
through, so you might create a shell script to handle this for you.

Update your MiniCPAN:

	% minicpan

The F<~/.minicpanrc> configuration file should use your DPAN
directory as the value for C<local>:

	local: /path/to/your/dpan
	remote: some CPAN mirror

The C<minicpan> is going to try to clean up your directory, so your
local modules might disappear. That's not a problem. There is
currently a bug in C<CPAN::Mini> that will also clean up source
control files and other files that might disappear. We're working on
that too. Here's a patch to C<CPAN::Mini>:

	http://github.com/briandfoy/cpan-mini/commit/6cc882cc09b2987ce0f3a4f8087ea751feaa88f1

You can filter distributions from your MiniCPAN with the hooks that
C<CPAN::Mini> provides. See it's documentation for the details.

Once you update with C<minicpan>, your repository is stale. That's
okay. It's time to run C<dpan>:

	% dpan -f dpan.conf

If you have C<merge_dirs> configured, C<dpan> will pull those
distributions and put them into DPAN with the fake CPAN author that
you specified in C<pause_id> ("DPAN" by default). If you don't want to
merge in this way. you can copy the distributions into your MiniCPAN
with rsync or something else. Ensure you keep the originals so
C<minicpan> doesn't delete them.

Once complete, start up C<minicpan_webserver> from
C<CPAN::Mini::Webserver>:

	% minicpan_webserver

 C<minicpan_webserver> uses the C<local> value from F<~/.minicpanrc>.

=head2 Keeping DPAN in source control

DPAN might be most useful when you keep it in source control. At the
end of an indexing run, C<dpan> can commit the changes to source
control. There are some adjustments that you need to make, however.

First, you have to ensure that C<minicpan> won't remove your source
control directories. There's a patch for that:

	http://github.com/briandfoy/cpan-mini/commit/6cc882cc09b2987ce0f3a4f8087ea751feaa88f1

Next, configure a C<postflight_class> for C<dpan>. Start with the
C<MyCPAN::App::DPAN::SVNPostFlight> for an example. At the end of
processing, C<dpan> calls the C<run> method in C<postflight_class>.
In the example, C<MyCPAN::App::DPAN::SVNPostFlight> figures out what
to remove or add to your subversion repository and commits the
result. It's more fully explained in the example, which is intended as
a starting point for your own process.

=head1 LOGGING

C<dpan> uses C<Log::Log4perl>, which you can configure any way that you
like. Each component has its own logging category:

	Coordinator
	Queue
	Dispatcher
	Worker
	Reporter
	Collator
	PostFlight

For more details on the components, see C<MyCPAN::Indexer::Tutorial>. There
are some example Log4perl configurations in the C<MyCPAN::Indexer> and
C<MyCPAN::App::DPAN> distributions.

=head1 GETTING MORE HELP

If you have any other questions, don't hesitate to ask. If you need help
setting up a DPAN, we can also arrange for private help.

=head1 SEE ALSO

MyCPAN::Indexer::Tutorial, dpan

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2010-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
