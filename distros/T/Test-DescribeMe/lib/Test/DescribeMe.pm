package Test::DescribeMe;
{
  $Test::DescribeMe::VERSION = '0.004';
}

use strict;
use warnings;

use Test::Settings qw(:all);

my %types = (
	'smoke'       => \&want_smoke,
	'interactive' => sub { ! want_non_interactive, },
	'extended'    => \&want_extended,
	'author'      => \&want_author,
	'release'     => \&want_release,
);

sub import {
	my ($pkg, @arg) = @_;

	for my $type (@arg) {
		unless ($types{$type}) {
			require Carp;
			Carp::croak("Test type '$type' not known");
		}

		unless ($types{$type}->()) {
			require Test::More;
			Test::More::plan(skip_all => "Not running $type tests");
		}
	}
}

1;
__END__

=head1 NAME

Test::DescribeMe - Tell test runners what kind of test you are

=head1 VERSION

version 0.004

=head1 SYNOPSIS

Maybe you're an author test and users shouldn't run you:

  use Test::DescribeMe qw(author);

Or maybe you are a really slow test you don't want to bother most people with:

  use Test::DescribeMe qw(extended);

Or perhaps you only want to run on smokers

  use Test::DescribeMe qw(smoke);

Or a combination there of

  use Test::DescribeMe qw(smoke extended);

Or you require user input

  use Test::DescribeMe qw(interactive);

=head1 DESCRIPTION

Sometimes you want to run (or not run) tests under certain conditions. This 
module provides a way to identify what kind of test a test is and will skip the 
test if the matching conditions aren't met. See L</BACKGROUND> below for a 
longer description.

=head2 Usage

To describe what kind of test you are, you C<use()> this module and pass test 
types to the import list. This B<SHOULD> be done before importing L<Test::More> 
if you set explicit plans or tests will break!

Example:

  use Test::DescribeMe qw(smoke);
  use Test::More tests => 5;

(Although you probably want L<Test::More/done_testing> without explicit plans).

The available test descriptions and effects are:

=over 4

=item *

B<smoke> - This test only wants to run on smoke boxes.

=item *

B<interactive> - This test requires user interaction and should not be run 
in cases where this isn't wanted or available

=item *

B<extended> - This test should only be run if someone really wants to - as it 
may take a long time or use lots of resources.

=item *

B<author> - This is an author test and should only be run during development 
time.

=item *

B<release> - This is a release test and should onyl be run pre-release to 
ensure a build is insane.

=back

=head2 More Control

If this doesn't provide the control you're looking for - for example, NOT 
running a test if on a smoker, see L<Test::Settings>.

=head1 BACKGROUND

With the Lancaster Consensus at the Perl QA Hackathon 2013, a 'new' system has 
been defined which provides two new test environment variables and reaffirms an 
existing one.

B<AUTOMATED_TESTING> was meant to be used by smokers, but has been abused to say 
things like "Only run this test on smokers since it takes a long time." The 
problem with this is install tools want to say "Run all tests but don't prompt 
the user" and the only way to do that is with B<AUTOMATED_TESTING>, and so they 
end up running the long running tests and wasting time.

In order to support the other behaviors, B<AUTOMATED_TESTING> will once again mean 
"I am a smoker running these tests" and two new environmental variables 
B<EXTENDED_TESTING> and B<NONINTERACTIVE_TESTING> will handle the two other cases.

B<EXTENDED_TESTING> is for tests that may take a long time or require special 
configuration that is too complex for typical intalls - like requiring other 
software for testing or internet connections.

B<NONINTERACTIVE_TESTING> can be used by a build system like L<App::cpanminus> to say 
don't run tests that require user interaction.

=head1 SEE ALSO

L<Test::Settings> - Ask or tell when certain types of tests should be run 

L<Test::Is> - Skip test in a declarative way, following the Lancaster Consensus

L<https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/lancaster-consensus.md> -
The Annotated Lancaster Consensus

=head1 AUTHOR

Matthew Horsfall (alh) - <wolfsage@gmail.com>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
