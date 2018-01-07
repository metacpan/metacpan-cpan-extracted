package Test::ClassAPI; # git description: 7ff3c00
# ABSTRACT: Provides basic first-pass API testing for large class trees

# Allows us to test class APIs in a simplified manner.
# Implemented as a wrapper around Test::More, Class::Inspector and Config::Tiny.

use 5.006;
use strict;
use File::Spec       0.83 ();
use Test::More       0.47 ();
use Config::Tiny     2.00 ();
use Class::Inspector 1.12 ();
use Params::Util     1.00 '_INSTANCE';

our $VERSION = '1.07';

use vars qw{$CONFIG $SCHEDULE $EXECUTED %IGNORE *DATA};
BEGIN {
	# Config starts empty
	$CONFIG   = undef;
	$SCHEDULE = undef;

	# We only execute once
	$EXECUTED = '';

	# When looking for method that arn't described in the class
	# description, we ignore anything from UNIVERSAL.
	%IGNORE = map { $_, 1 } qw{isa can};
}

# Get the super path ( not including UNIVERSAL )
# Rather than using Class::ISA, we'll use an inlined version
# that implements the same basic algorithm, but faster.
sub _super_path($) {
	my $class = shift;
	my @path  = ();
	my @queue = ( $class );
	my %seen  = ( $class => 1 );
	while ( my $cl = shift @queue ) {
		no strict 'refs';
		push @path, $cl;
		unshift @queue, grep { ! $seen{$_}++ }
			map { s/^::/main::/; s/\'/::/g; $_ }
			( @{"${cl}::ISA"} );
	}

	@path;
}





#####################################################################
# Main Methods

# Initialise the Configuration
sub init {
	my $class = shift;

	# Use the script's DATA handle or one passed
	*DATA = ref($_[0]) eq 'GLOB' ? shift : *main::DATA;
 
	# Read in all the data, and create the config object
	local $/ = undef;
	$CONFIG = Config::Tiny->read_string( <DATA> )
		or die 'Failed to load test configuration: '
			. Config::Tiny->errstr;
	$SCHEDULE = delete $CONFIG->{_}
		or die 'Config does not have a schedule defined';

	# Add implied schedule entries
	foreach my $tclass ( keys %$CONFIG ) {
		$SCHEDULE->{$tclass} ||= 'class';
		foreach my $test ( keys %{$CONFIG->{$tclass}} ) {
			next unless $CONFIG->{$tclass}->{$test} eq 'implements';
			$SCHEDULE->{$test} ||= 'interface';
		}
	}
	

	# Check the schedule information
	foreach my $tclass ( keys %$SCHEDULE ) {
		my $value = $SCHEDULE->{$tclass};
		unless ( $value =~ /^(?:class|abstract|interface)$/ ) {
			die "Invalid schedule option '$value' for class '$tclass'";
		}
		unless ( $CONFIG->{$tclass} ) {
			die "No section '[$tclass]' defined for schedule class";
		}
	}

	1;
}

# Find and execute the tests
sub execute {
	my $class = shift;
	if ( $EXECUTED ) {
		die 'You can only execute once, use another test script';
	}
	$class->init unless $CONFIG;

	# Handle options
	my @options = map { lc $_ } @_;
	my $CHECK_UNKNOWN_METHODS     = !! grep { $_ eq 'complete'   } @options;
	my $CHECK_FUNCTION_COLLISIONS = !! grep { $_ eq 'collisions' } @options;

	# Set the plan of no plan if we don't have a plan
	unless ( Test::More->builder->has_plan ) {
		Test::More::plan( 'no_plan' );
	}

	# Determine the list of classes to test
	my @classes = sort keys %$SCHEDULE;
	@classes = grep { $SCHEDULE->{$_} ne 'interface' } @classes;

	# Check that all the classes/abstracts are loaded
	foreach my $class ( @classes ) {
		Test::More::ok( Class::Inspector->loaded( $class ), "Class '$class' is loaded" );
	}

	# Check that all the full classes match all the required interfaces
	@classes = grep { $SCHEDULE->{$_} eq 'class' } @classes;
	foreach my $class ( @classes ) {
		# Find all testable parents
		my @path = grep { $SCHEDULE->{$_} } _super_path($class);

		# Iterate over the testable entries
		my %known_methods = ();
		my @implements = ();
		foreach my $parent ( @path ) {
			foreach my $test ( sort keys %{$CONFIG->{$parent}} ) {
				my $type = $CONFIG->{$parent}->{$test};

				# Does the class have a named method
				if ( $type eq 'method' ) {
					$known_methods{$test}++;
					Test::More::can_ok( $class, $test );
					next;
				}

				# Does the class inherit from a named parent
				if ( $type eq 'isa' ) {
					Test::More::ok( $class->isa($test), "$class isa $test" );
					next;
				}

				unless ( $type eq 'implements' ) {
					print "# Warning: Unknown test type '$type'";
					next;
				}
				
				# When we 'implement' a class or interface,
				# we need to check the 'method' tests within
				# it, but not anything else. So we will add
				# the class name to a seperate queue to be
				# processed afterwards, ONLY if it is not
				# already in the normal @path, or already
				# on the seperate queue.
				next if grep { $_ eq $test } @path;
				next if grep { $_ eq $test } @implements;
				push @implements, $test;
			}
		}

		# Now, if it had any, go through and check the classes added
		# because of any 'implements' tests
		foreach my $parent ( @implements ) {
			foreach my $test ( keys %{$CONFIG->{$parent}} ) {
				my $type = $CONFIG->{$parent}->{$test};
				if ( $type eq 'method' ) {
					# Does the class have a method
					$known_methods{$test}++;
					Test::More::can_ok( $class, $test );
				}
			}
		}

		if ( $CHECK_UNKNOWN_METHODS ) {
			# Check for unknown public methods
			my $methods = Class::Inspector->methods( $class, 'public', 'expanded' )
				or die "Failed to find public methods for class '$class'";
			@$methods = grep { $_->[2] !~ /^[A-Z_]+$/ } # Internals stuff
				grep { $_->[1] ne 'Exporter' } # Ignore Exporter methods we don't overload
				grep { ! ($known_methods{$_->[2]} or $IGNORE{$_->[2]}) } @$methods;
			if ( @$methods ) {
				print STDERR join '', map { "# Found undocumented method '$_->[2]' defined at '$_->[0]'\n" } @$methods;
			}
			Test::More::is( scalar(@$methods), 0, "No unknown public methods in '$class'" );
		}

		if ( $CHECK_FUNCTION_COLLISIONS ) {
			# Check for methods collisions.
			# A method collision is where
			#
			#     Foo::Bar->method
			#
			# is actually interpreted as
			#
			#     &Foo::Bar()->method
			#
			no strict 'refs';
			my @collisions = ();
			foreach my $symbol ( sort keys %{"${class}::"} ) {
				next unless $symbol =~ s/::$//;
				next unless defined *{"${class}::${symbol}"}{CODE};
				print STDERR "Found function collision: ${class}->${symbol} clashes with ${class}::${symbol}\n";
				push @collisions, $symbol;
			}
			Test::More::is( scalar(@collisions), 0, "No function/class collisions in '$class'" );
		}
	}

	1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::ClassAPI - Provides basic first-pass API testing for large class trees

=head1 VERSION

version 1.07

=head1 DESCRIPTION

For many APIs with large numbers of classes, it can be very useful to be able
to do a quick once-over to make sure that classes, methods, and inheritance
is correct, before doing more comprehensive testing. This module aims to
provide such a capability.

=head2 Using Test::ClassAPI

Test::ClassAPI is used with a fairly standard looking test script, with the
API description contained in a __DATA__ section at the end of the script.

  #!/usr/bin/perl
  
  # Test the API for Foo::Bar
  use strict;
  use Test::More 'tests' => 123; # Optional
  use Test::ClassAPI;
  
  # Load the API to test
  use Foo::Bar;
  
  # Execute the tests
  Test::ClassAPI->execute;
  
  __DATA__
  
  Foo::Bar::Thing=interface
  Foo::Bar::Object=abstract
  Foo::Bar::Planet=class
  
  [Foo::Bar::Thing]
  foo=method
  
  [Foo::Bar::Object]
  bar=method
  whatsit=method
  
  [Foo::Bar::Planet]
  Foo::Bar::Object=isa
  Foo::Bar::Thing=isa
  blow_up=method
  freeze=method
  thaw=method

Looking at the test script, the code itself is fairly simple. We first load
Test::More and Test::ClassAPI. The loading and specification of a test plan
is optional, Test::ClassAPI will provide a plan automatically if needed.

This is followed by a compulsory __DATA__ section, containing the API
description. This description is in provided in the general form of a Windows
style .ini file and is structured as follows.

=head2 Class Manifest

At the beginning of the file, in the root section of the config file, is a
list of entries where the key represents a class name, and the value is one
of either 'class', 'abstract', or 'interface'.

The 'class' entry indicates a fully fledged class. That is, the class is
tested to ensure it has been loaded, and the existance of every method listed
in the section ( and its superclasses ) is tested for.

The 'abstract' entry indicates an abstract class, one which is part of our
class tree, and needs to exist, but is never instantiated directly, and thus
does not have to itself implement all of the methods listed for it. Generally,
many individual 'class' entries will inherit from an 'abstract', and thus a
method listed in the abstract's section will be tested for in all the 
subclasses of it.

The 'interface' entry indicates an external interface that is not part of
our class tree, but is inherited from by one or more of our classes, and thus
the methods listed in the interface's section are tested for in all the 
classes that inherit from it. For example, if a class inherits from, and
implements, the File::Handle interface, a C<File::Handle=interface> entry
could be added, with the C<[File::Handle]> section listing all the methods
in File::Handle that our class tree actually cares about. No tests, for class
or method existance, are done on the interface itself.

=head2 Class Sections

Every class listed in the class manifest B<MUST> have an individual section,
indicated by C<[Class::Name]> and containing a set of entries where the key
is the name of something to test, and the value is the type of test for it.

The 'isa' test checks inheritance, to make sure that the class the section is
for is (by some path) a sub-class of something else. This does not have to be
an immediate sub-class. Any class refered to (recursively) in a 'isa' test
will have its 'method' test entries applied to the class as well.

The 'method' test is a simple method existance test, using C<UNIVERSAL::can>
to make sure that the method exists in the class.

=head1 METHODS

=head2 execute

The C<Test::ClassAPI> has a single method, C<execute> which is used to start
the testing process. It accepts a single option argument, 'complete', which
indicates to the testing process that the API listed should be considered a
complete list of the entire API. This enables an additional test for each
class to ensure that B<every> public method in the class is detailed in the
API description, and that nothing has been "missed".

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Test-ClassAPI>
(or L<bug-Test-ClassAPI@rt.cpan.org|mailto:bug-Test-ClassAPI@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Adam Kennedy Karen Etheridge

=over 4

=item *

Adam Kennedy <adam@ali.as>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
