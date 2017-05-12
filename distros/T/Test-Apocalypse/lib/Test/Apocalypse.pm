#
# This file is part of Test-Apocalypse
#
# This software is copyright (c) 2014 by Apocalypse.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict; use warnings;
package Test::Apocalypse;
# git description: release-1.005-0-g6408495
$Test::Apocalypse::VERSION = '1.006';
BEGIN {
  $Test::Apocalypse::AUTHORITY = 'cpan:APOCAL';
}

# ABSTRACT: Apocalypse's favorite tests bundled into a simple interface

# setup our tests and etc
use Test::More 0.96;
use Module::Pluggable 3.9 search_path => [ __PACKAGE__ ];

# auto-export the only sub we have
use parent 'Exporter';
our @EXPORT = qw( is_apocalypse_here );

sub is_apocalypse_here {
	# should we even run those tests?
	unless ( $ENV{RELEASE_TESTING} or $ENV{AUTOMATED_TESTING} ) {
		plan skip_all => 'Author test. Please set $ENV{RELEASE_TESTING} to a true value to run.';
	} else {
		require Test::FailWarnings;
	}

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( ( @_ & 1 ) and ref $_[0] and ref( $_[0] ) eq 'HASH' ) { ## no critic (Bangs::ProhibitBitwiseOperators)
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ & 1 ) { ## no critic (Bangs::ProhibitBitwiseOperators)
			die 'The sub is_apocalypse_here() requires an even number of options';
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	# setup the "allow/deny" tests
	if ( exists $opt{'allow'} and exists $opt{'deny'} ) {
		die 'Unable to use "allow" and "deny" at the same time!';
	}
	foreach my $type ( qw( allow deny ) ) {
		if ( ! exists $opt{ $type } or ! defined $opt{ $type } ) {
			# Don't set anything
			delete $opt{ $type } if exists $opt{ $type };
		} else {
			if ( ! ref $opt{ $type } ) {
				# convert it to a qr// regex?
				eval { $opt{ $type } = qr/$opt{ $type }/i };
				if ( $@ ) {
					die "Unable to compile the '$type' regex: $@";
				}
			} elsif ( ref( $opt{ $type } ) ne 'Regexp' ) {
				die "The '$type' option is not a regexp!";
			}
		}
	}

	# Print some basic debugging info, thanks POE::Test::Loops::00_info!
	diag(
		"Testing with Test::Apocalypse v$Test::Apocalypse::VERSION, ",
		"Perl $], ",
		"$^X on $^O",
	);

	# loop through our plugins ( in alphabetical order! )
	foreach my $t ( sort { $a cmp $b } __PACKAGE__->plugins() ) {
		my $plugin = $t;
		$plugin =~ s/^Test::Apocalypse:://;

		# Do we want this test?
		# PERL_APOCALYPSE=1 means run all tests, =0 means default behavior
		if ( ! exists $ENV{PERL_APOCALYPSE} or ! $ENV{PERL_APOCALYPSE} ) {
			if ( exists $opt{'allow'} ) {
				if ( $t =~ /^Test::Apocalypse::(.+)$/ ) {
					if ( $1 !~ $opt{'allow'} ) {
						diag( "Skipping $plugin ( via allow policy )..." );
						next;
					}
				}
			} elsif ( exists $opt{'deny'} ) {
				if ( $t =~ /^Test::Apocalypse::(.+)$/ ) {
					if ( $1 =~ $opt{'deny'} ) {
						diag( "Skipping $plugin ( via deny policy )..." );
						next;
					}
				}
			}
		}

		# Load it, and look for errors
		eval "use $t";
		if ( $@ ) {
			# TODO smarter error detection - missing module, bla bla
			my $error = "Unable to load $plugin -> $@";

			if ( $ENV{RELEASE_TESTING} or $ENV{PERL_APOCALYPSE} ) {
				die $error;
			} else {
				diag( $error );
			}

			next;
		}

		# Is this plugin disabled?
		if ( $t->can( '_is_disabled' ) and ! $ENV{PERL_APOCALYPSE} ) {
			my $ret = $t->_is_disabled;
			if ( $ret ) {
				diag( "Skipping $plugin => $ret" );
				next;
			}
		}

		# Check for AUTOMATED_TESTING
		if ( $ENV{AUTOMATED_TESTING} and ! $ENV{PERL_APOCALYPSE} and $t->can( '_do_automated' ) and ! $t->_do_automated() ) {
			diag( "Skipping $plugin ( for RELEASE_TESTING only )..." );
			next;
		}

		# run it!
		subtest $plugin => sub {
			eval {
				# TODO ignore annoying gpg warnings like 'WARNING: This key is not certified with a trusted signature!' at /usr/local/share/perl/5.18.2/Module/Signature.pm line 265.
				no warnings qw(once);
				local @Test::FailWarnings::ALLOW_FROM = ( 'Module::Signature' );

				local $SIG{__WARN__} = \&Test::FailWarnings::handler;
				$t->do_test();
			};
			if ( $@ ) {
				# Sometimes we get a plain string, sometimes we get
				# Error running Kwalitee: Test::Builder::Exception=HASH(0x3fa6078)
				my $err = $@;
				if ( $err->isa( 'Test::Builder::Exception' ) ) {
					# TODO reach into T::B to get the actual skip reason
					$err = Test::Builder->new->{Skip_All};
				}

				if ( $ENV{RELEASE_TESTING} or $ENV{PERL_APOCALYPSE} ) {
					die "Error running $plugin: $err";
				} else {
					diag( "Error running $plugin: $err" );
				}

				# we need to manually intervene or we'll get this:
				# Running DOSnewline...
				# Running Dependencies...
					# Child (Dependencies) exited without calling finalize()
					#   Failed test 'Dependencies'
					#   at /usr/local/share/perl/5.18.2/Test/Apocalypse.pm line 134.
					# Error running Dependencies: Can't locate object method "new" via package "Version::Requirements" (perhaps you forgot to load "Version::Requirements"?) at /usr/local/share/perl/5.18.2/Test/Apocalypse/Dependencies.pm line 59.
				# Running DirChecks...
				# Error running DirChecks: You already have a child named (Dependencies) running at /usr/local/share/perl/5.18.2/Test/More.pm line 771.
				done_testing();
			}
		};
	}

	done_testing();
	return 1;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Apocalypse Niebur Ryan cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan apocal CPAN
AUTHORs al backend debian distro distros dists env hackish plugins
testsuite yml pm yay unicode blog precompiled =for stopwords ap cyclomatic
cal dist homebrew imo internet perltidy prefs prereq testrun

=head1 NAME

Test::Apocalypse - Apocalypse's favorite tests bundled into a simple interface

=head1 VERSION

  This document describes v1.006 of Test::Apocalypse - released October 25, 2014 as part of Test-Apocalypse.

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;

	use Test::More;
	eval "use Test::Apocalypse";
	if ( $@ ) {
		plan skip_all => 'Test::Apocalypse required for validating the distribution';
	} else {
		is_apocalypse_here();
	}

=head1 DESCRIPTION

This module greatly simplifies common author tests for modules heading towards CPAN. I was sick of copy/pasting
the tons of t/foo.t scripts + managing them in every distro. I thought it would be nice to bundle all of it into
one module and toss it on CPAN :) That way, every time I update this module all of my dists would be magically
updated!

This module respects the RELEASE_TESTING/AUTOMATED_TESTING env variable, if it is not set it will skip the entire
testsuite. Normally end-users should not run it; but you can if you want to see how bad my dists are, ha! The scheme
is exactly the same as the one Alias proposed in L<Test::XT> and in his blog post, L<http://use.perl.org/use.perl.org/_Alias/journal/38822.html>.

This module uses L<Module::Pluggable> to have custom "backends" that process various tests. We wrap them in a hackish
L<Test::Block> block per-plugin and it seems to work nicely. If you want to write your own, it should be a breeze
once you look at some of my plugins and see how it works. ( more documentation to come )

=head2 Usage

In order to use this, you would need to be familiar with the "standard" steps in order to fully exercise the testsuite.
There are a few steps we require, because our plugins need stuff to be prepared for them. For starters, you would need
a test file in your distribution similar to the one in SYNOPSIS. Once that is done and added to your MANIFEST and etc,
you can do this:

	perl Build.PL			# sets up the dist ( duh, hah )
	./Build dist			# makes the tarball ( so certain plugins can process it )
	RELEASE_TESTING=1 ./Build test	# runs the testsuite!

=head1 Methods

=head2 is_apocalypse_here()

This is the main entry point for this testsuite. By default, it runs every plugin in the testsuite. You can enable/disable
specific plugins if you desire. It accepts a single argument: a hashref or a hash. It can contain various options, but as of
now it only supports two options. If you try to use allow and deny at the same time, this module will throw an exception.

=head3 allow

Setting "allow" to a string or a precompiled regex will run only the plugins that match the regex. If passed a string, this module
will compile it via C<qr/$str/i>.

	# run only the EOL test and disable all other tests
	is_apocalypse_here( {
		allow	=> qr/^EOL$/,
	} );

	# run all "dist" tests
	is_apocalypse_here( {
		allow	=> 'dist',
	} );

=head3 deny

Setting "deny" to a string or a precompiled regex will not run the plugins that match the regex. If passed a string, this module
will compile it via C<qr/$str/i>.

	# disable Pod_Coverage test and enable all other tests
	is_apocalypse_here( {
		deny	=> qr/^Pod_Coverage$/,
	} );

	# disable all pod tests
	is_apocalypse_here( {
		deny	=> 'pod',
	} );

=head2 plugins()

Since this module uses L<Module::Pluggable> you can use this method on the package to find out what plugins are available. Handy if you need
to know what plugins to skip, for example.

	my @tests = Test::Apocalypse->plugins;

=head1 EXPORT

Automatically exports the "is_apocalypse_here" sub.

=head1 MORE IDEAS

=over 4

=item * Test::NoSmartComments

I don't use Smart::Comments but it might be useful? I LOVE BLOAT! :)

=item * Better POD spelling checker?

Test::Spelling is ancient, and often blows up. There's a Test::Pod::Spelling on CPAN but it is flaky too :(

=item * Document the way we do plugins so others can add to this testsuite :)

=item * POD standards check

Do we have SYNOPSIS, ABSTRACT, SUPPORT, etc sections? ( PerlCritic can do that! Need to investigate more... )

=item * Integrate Test::UniqueTestNames into the testsuite

This would be nice, but I'm not sure if I can actually force this on other tests. Otherwise I'll be just making
sure that the Test::Apocalypse tests is unique, which is worthless to $dist trying to clean itself up...

=item * META.yml checks

We should make sure that the META.yml includes the "repository", "license", and other useful keys!

=item * Other AUTHORs

As always, we should keep up on the "latest" in the perl world and look at other authors for what they are doing.

=item * indirect syntax

We should figure out how to use indirect.pm to detect this deprecated method of coding. There's a L<Perl::Critic> plugin for this, yay!

=item * Test::PPPort

Already implemented as PPPort.pm but it's less invasive than my version, ha!

=item * Test::DependentModules

This is a crazy test, but would help tremendously in finding regressions in your code!

=item * Test::CleanNamespaces

I don't exclusively code in Moose, but this could be useful...

=item * no internet?

It would be nice to signal INTERNET_TESTING=0 or something zany like that so this testsuite will skip the tests that need internet access...

	<Apocalypse> Is there a convention that signals no internet access? Similar to RELEASE_TESTING, AUTOMATED_TESTING, and etc?
	<@rjbs> No.
	<Apocalypse> mmm I ain't in the mood to invent it so I'll just bench it for now :(
	<Apocalypse> however, if I was to invent it I would call it something like INTERNET_TESTING=0
	<Apocalypse> Also, why does ILYAZ keep re-inventing the stuff? Use of uninitialized value $ENV{"PERL_RL_TEST_PROMPT_MINLEN"} in bitwise or (|) at test.pl line 33.
	<@Alias> use LWP::Online ':skip_all';
	<@Alias> Whack that in the relevant test scripts
	<Apocalypse> Alias: Hmm, how can I control that at a distance? i.e. disabling inet if I had inet access?
	<@Alias> You can't
	<@Alias> It's a pragmatic test, tries to pull some huge site front pages and looks for copyright statements
	<Apocalypse> At least it's a good start - thanks!
	<@Alias> So it deals with proxies and airport wireless hijacking etc properly
	<Apocalypse> Hah yeah I had to do the same thing at $work in the past, we put up a "special" page then had our software try to read it and if the content didn't match it complained :)
	<@Alias> right
	<@Alias> So yeah, it automates that
	<@Alias> I wrote it while in an airport annoyed that something I wrote wasn't falling back on a minicpan properly
	<Apocalypse> At least it'll be an improvement, but I still need to force no inet for testing... ohwell
	<Apocalypse> Heh, it seems like us perl hackers do a lot of work while stranded at airports :)
	<@Alias> If you can break LWP from the environment, that would work
	<@Alias> Setting a proxy ENVthat is illegal etc
	<Apocalypse> ah good thinking, I'll read up on the fine points of LWP env vars and try to screw it up

=back

=head2 Modules that I considered but decided against using

=over 4

=item * L<Test::Distribution>

This module was a plugin in this testsuite but I don't need it. All the functionality in it is already replicated in the plugins :)

=item * L<Test::Module::Used> and L<Test::Dependencies>

They were plugins in this testsuite but since I started coding with L<Moose>, they don't work! I've switched to my homebrew solution
utilizing L<Perl::PrereqScanner> which works nicely for me.

=item * L<Test::MyDeps>

Superseded by L<Test::DependentModules>. Also, I don't want to waste a lot of time on each testrun testing other modules!

=item * L<Test::NoTabs>

I always use tabs! :(

=item * L<Test::CheckManifest>

This was a buggy module that I dropped and is now using L<Test::DistManifest>

=item * L<Test::Dist>

This is pretty much the same thing as this dist ;)

=item * L<Test::PureASCII>

This rocks, as I don't care about unicode in my perl! ;)

=item * L<Test::LatestPrereqs>

This looks cool but we need to fiddle with config files? My OutdatedPrereqs test already covers it pretty well...

=item * L<Test::Pod::Content>

This is useful, but not everyone has the same POD layout. It would be too much work to try and generalize this...

=item * L<Test::GreaterVersion>

Since I never use CPAN, this is non-functional for me. However, it might be useful for someone?

=item * L<Test::Kwalitee>

This dist rocks, but it doesn't print the info nor utilize the extra metrics. My homebrew solution actually copied
a lot of code from this, so I have to give it props!

=item * L<Test::LoadAllModules>

This is very similar to L<Test::UseAllModules> but looks more complicated. Also, I already have enough tests that do that ;)

=item * L<Test::ModuleReady>

This looks like a nice module, but what it does is already covered by the numerous tests in this dist...

=item * L<Test::PerlTidy>

Br0ken install at this time... ( PerlCritic can do that! Need to investigate more... ) Also, all it does is... run your module
through perltidy and compare the outputs. Not that useful imo because I never could get perltidy to match my prefs :(

=item * L<Test::Install::METArequires>

This looks like a lazy way to do auto_install and potentially dangerous! Better to just use the prereq logic in Build.PL/Makefile.PL

=item * L<Test::Perl::Metrics::Simple>

This just tests your Cyclomatic complexity and was the starting point for my homebrew solution.

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Test::Apocalypse

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Test-Apocalypse>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Test-Apocalypse>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Apocalypse>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Test-Apocalypse>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Test-Apocalypse>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/Test-Apocalypse>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Test-Apocalypse>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Test-Apocalypse>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Test-Apocalypse>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Test::Apocalypse>

=back

=head2 Email

You can email the author of this module at C<APOCAL at cpan.org> asking for help with any problems you have.

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #perl-help then talk to this person for help: Apocalypse.

=item *

irc.freenode.net

You can connect to the server at 'irc.freenode.net' and join this channel: #perl then talk to this person for help: Apocal.

=item *

irc.efnet.org

You can connect to the server at 'irc.efnet.org' and join this channel: #perl then talk to this person for help: Ap0cal.

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-test-apocalypse at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Apocalypse>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/apocalypse/perl-test-apocalypse>

  git clone git://github.com/apocalypse/perl-test-apocalypse.git

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head2 CONTRIBUTORS

=for stopwords Apocalypse Ryan Niebur

=over 4

=item *

Apocalypse <apoc@blackhole.(none)>

=item *

Apocalypse <apoc@satellite.(none)>

=item *

Apocalypse <perl@0ne.us>

=item *

Ryan Niebur <ryanryan52@gmail.com>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to jawnsy@cpan.org for the prodding and help in getting this package ready to be bundled into debian!

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Apocalypse.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=head1 DISCLAIMER OF WARRANTY

THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
