package Module::Build::TestReporter;

use strict;
use warnings;

use vars '$VERSION';

$VERSION = '1.00';

use base 'Module::Build';
use Scalar::Util          'reftype';
use File::Spec::Functions qw( devnull catdir );

# if these subs had real names, they'd confuse caller() in SUPER.pm
# making them anonymous and assigning to *__ANON__ fixes that
# this is the "You don't have all of MBTR's dependencies installed" constructor
sub fake_new
{
	return sub
	{
		local *__ANON__    = 'new';
		my ($class, %args) = @_;

		my $requires                 = $args{build_requires} ||= {};
		$requires->{'SUPER'}                                 ||= '1.10';
		$requires->{'IPC::Open3'}                            ||= '';
		$requires->{'Class::Roles'}                          ||= '';
		$requires->{'Test::Harness'}                         ||= '2.47';

		Module::Build->new( %args );
	};
}

# this is the "Everything looks good!" constructor
sub new
{
	my ($class, %args) = @_;
	my $report_file    = delete $args{report_file}   || 'test_failures.txt';
	my $report_address = delete $args{report_address}|| '';
	my $self           = $class->SUPER( %args );
	
	$self->notes( report_file    => $report_file    );
	$self->notes( report_address => $report_address ) if $report_address;

	return $self;
}

BEGIN
{
	eval
	{
		require SUPER;
		require IPC::Open3;

		require Test::Harness::Straps;
		require Class::Roles;

		IPC::Open3->import();
		Class::Roles->import(
			role => [qw(
				new ACTION_test find_test_files save_failure_details
				report_failures write_report
			)]
		);
	};

	if ($@)
	{
		no strict 'refs';
		no warnings 'redefine';
		*{ 'new' } = fake_new();
	}
}

sub ACTION_test
{
	my $self    = shift;

	# don't let Module::Build::Base whine about missing tests
	open( my $fh, '>' . devnull() );
	
	my $oldfh = select( $fh );
	unless (reftype( $oldfh ))
	{
		no strict 'refs';
		$oldfh = \*$oldfh;
	}
	$self->notes( 'test_oldfh' => $oldfh );

	$self->SUPER( @_ );

	# now let it whine
	select( $self->notes( 'test_oldfh' ) );
}

sub find_test_files
{
	my $self  = shift;
	my $strap = Test::Harness::Straps->new();
	my $outfh = $self->notes( 'test_oldfh' );

	$self->notes( test_failures => [] );

	# XXX: this doesn't work
	my $p = $self->{properties};
	local @INC =
	(
		 ( map { catdir( $p->{base_dir}, $self->blib(), $_ ) } qw( lib arch ) ),
          @INC
	);

	# this does
	local $ENV{HARNESS_PERL_SWITCHES} = '-Mblib';

	# actually run the tests, collecting diagnostics
	for my $file (@{ $self->SUPER( @_ ) })
	{
		my ($in, $out);

		my $pid     = open3( $in, $out, $out, $strap->_command_line( $file ));
		my %results = $strap->analyze_fh( $file, $out );

		if ($results{passing})
		{
			print $outfh "$file...ok\n" if $ENV{TEST_VERBOSE};
			next;
		}
		$self->save_failure_details( $file, \%results );
	}

	$self->report_failures();

	# don't let the tests leak out
	return [];
}

sub save_failure_details
{
	my ($self, $file, $results) = @_;
	my $failures                = $self->notes( 'test_failures' );

	my @failures;

	for my $number ( 1 .. @{ $results->{details} } )
	{
		my $test = $results->{details}[$number - 1];

		next if $test->{actual_ok};

		push @failures,
		{
			number      => $number,
			description => $test->{name}        || '',
			diagnostics => $test->{diagnostics} || '',
		};
	}

	delete $results->{details}; 
	$results->{file}     = $file;
	$results->{failures} = \@failures;
	push @$failures, $results;
}

sub report_failures
{
	my $self     = shift;
	my $failures = $self->notes( 'test_failures' );
	my $report   = '';

	for my $test ( @$failures )
	{
		my $failed  = $test->{seen} - $test->{ok};
		next unless $failed;

		$report    .= sprintf( 
			"Test failures in '%s' (%d/%d):\n",
			$test->{file}, $failed, $test->{seen}
		);

		for my $failure (@{ $test->{failures} })
		{
			$report .= sprintf( 
				"  %d: %s\n\t%s",
				@{$failure}{qw( number description diagnostics )}
			);
		}
	}

	return $self->write_success_results() unless $report;

	my $version_fh;

	my $version = "\n\n" .
		( open( $version_fh, $^X . ' -V |' ) ?
			join( '', <$version_fh> ) :
			"Could not find version information for $^X on $^O: $!\n" );

	$self->write_report( $report, $version );
	$self->write_failure_results( $report );
}

sub write_success_results
{
	my $self  = shift;
	my $oldfh = $self->notes( 'test_oldfh' );
	print $oldfh "All tests passed...\n";
}

sub write_report
{
	my ($self, $report, $version) = @_;
	my $file                      = $self->notes( 'report_file' );
	my $outfh                     = $self->notes( 'test_oldfh'  );

	open( my $out, '>', $file ) or die "Can't write $file: $!\n";
	print $out   $report, $version;
}

sub write_failure_results
{
	my ($self, $report) = @_;
	my $outfh           = $self->notes( 'test_oldfh'     );
	my $contact         = $self->notes( 'report_address' );
	my $report_file     = $self->notes( 'report_file'    );

	my $header          = "Tests failed!\n";
	$header .= "Please e-mail '$report_file' to $contact.\n" if $contact;

	print $outfh $header;
	print $outfh $report if $ENV{TEST_VERBOSE};
}

1;
__END__

=head1 NAME

Module::Build::TestReporter - help users report test failures

=head1 SYNOPSIS

  use Module::Build::TestReporter;
  my $build = Module::Build::TestReporter->new(
	# normal Module::Build code here
  );

  # or, in your own M::B subclass

  package My::Module::Build;

  use Class::Roles does => 'Module::Build::TestReporter';

  # your code as usual

=head1 DESCRIPTION

Shipping test suites with your code is a good thing, as it helps your users
know that your code works as you expect on your systems and it allows you
better debugging information if things break in environments where you haven't
yet tested your code.  However, it can be tedious and tricky to convince your
users to send you the appropriate failure information.

Module::Build::TestReporter extends and enhances Module::Build to collect
information on test failures and the Perl environment for users to send to you.
Rather than walking them through running tests in verbose mode on the phone, in
IRC, or via e-mail, use this module alongside your usual Module::Build build
process and it will gather this information in case of failure.

=head1 USAGE

There are three ways to use this module.  You can use it directly in place of
Module::Build, if you don't subclass it to add your own customizations.  You
can inherit from it if you do subclass Module::Build to add your own behavior.
Finally, you can use it as a role with L<Class::Roles>.  The correct approach
depends on your desire and what you do with it.

Module::Build::TestReporter only overrides the behavior of Module::Build's
C<ACTION_test>.  If you don't touch this process, you'll probably be fine no
matter what your code does.

However you use it, there are two additional arguments passed to its C<new()>
(in your F<Build.PL> file) that must be present for the module to do its work:

=over 4

=item * C<report_file =E<gt> 'filename.txt'>

C<report_file> is the name of the file to which to write the failure report.

=item * C<report_address =E<gt> 'you@example.com'>

C<report_address> is the e-mail address to which to send failure reports.

=back

At the end of the test run, the module writes any failures to the file
specified in C<report_file>.  If you've specified a C<report_address>, it also
prints a message to inform the users to e-mail that file to the appropriate
address.  The report contains information on all of the failed test files, all
of the failing tests (including their diagnostics), and the characteristics of
the Perl environment (as found by calling C<perl -V>).

Hopefully this will improve your debugging.

=head1 DISTRIBUTION

As Stig Brautaset pointed out, there's a bit of a bootstrapping problem.  How
can you rely on users having this module available if you use it to mark
dependencies?  The easiest approach is to bundle this module with the code that
uses it; I tend to store mine in a F<build_lib> directory.  Then modify C<@INC>
in your F<Build.PL> file.

Note that you should mark the dependencies for this module in your F<Build.PL>
file as if they were build dependencies of your module.  I recommend:

	build_requires =>
	{
		'IO::String'    =>     '',
		'IPC::Open3'    =>     '',
		'Class::Roles'  =>     '',
		'SUPER'         => '1.02',
		'Test::Simple'  => '0.48',
		'Test::Harness' => '2.47',
	}

This module does go through some hoops to mark dependencies if you forget, but
be careful.

=head1 AUTHOR

chromatic, E<lt>chromatic at wgz dot orgE<gt>

=head1 BUGS

No known bugs.  The C<SUPER()> calls in role mode may be a little weird, but I
feel a little paranoid as I've not had much feedback on either module coming
into play here.

I have heard rumors that C<IPC::Open3> both works and does not work on non-Unix
platforms.  I don't have access to these platforms to test, so I appreciate any
advice and test results.

=head1 COPYRIGHT

Copyright (c) 2005, chromatic.  Some rights reserved.

This module is free software; you can use, redistribute, and modify it under
the same terms as Perl 5.8.
