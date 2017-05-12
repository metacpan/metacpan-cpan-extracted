package Pod::Tests;

=pod

=head1 NAME

Pod::Tests - Extracts embedded tests and code examples from POD

=head1 SYNOPSIS

  use Pod::Tests;
  $p = Pod::Tests->new;

  $p->parse_file($file);
  $p->parse_fh($fh);
  $p->parse(@code);

  my @examples = $p->examples;
  my @tests    = $p->tests;

  foreach my $example (@examples) {
      print "The example:  '$example->{code}' was on line ".
            "$example->{line}\n";
  }

  my @test_code         = $p->build_tests(@tests);
  my @example_test_code = $p->build_examples(@examples);

=head1 DESCRIPTION

This is a specialized POD viewer to extract embedded tests and code
examples from POD.  It doesn't do much more than that.  pod2test does
the useful work.

=head2 Parsing

After creating a Pod::Tests object, you parse the POD by calling one
of the available parsing methods documented below.  You can call parse
as many times as you'd like, all examples and tests found will stack
up inside the object.

=head2 Testing

Once extracted, the tests can be built into stand-alone testing code
using the build_tests() and build_examples() methods.  However, it is
recommended that you first look at the pod2test program before
embarking on this.

=head2 Methods

=cut

use 5.005;
use strict;
use vars qw($VERSION);
BEGIN {
	$VERSION = '1.19';
}





#####################################################################
# Constructor

=pod

=head2 new

  $parser = Pod::Tests->new;

Returns a new Pod::Tests object which lets you read tests and examples
out of a POD document.

=cut

sub new {
	my ($proto) = shift;
	my ($class) = ref $proto || $proto;

	my $self = bless {}, $class;
	$self->_init;
	$self->{example} = [];
	$self->{testing} = [];

	return $self;
}





#####################################################################
# Pod::Tests Methods

=pod

=head2 parse

  $parser->parse(@code);

Finds the examples and tests in a bunch of lines of Perl @code.  Once
run they're available via examples() and testing().

=cut

sub parse {
	my ($self) = shift;

	$self->_init;
	foreach (@_) {
		if ( /^=(\w.*)/ and $self->{_sawblank} and !$self->{_inblock}) {
			$self->{_inpod} = 1;

			my ($tag, $for, $pod) = split /\s+/, $1, 3;

			if ( $tag eq 'also' ) {
				$tag = $for;
				($for, $pod) = split /\s+/, $pod, 2;
			}

			if ( $tag eq 'for' ) {
				$self->_beginfor($for, $pod);
			} elsif ( $tag eq 'begin' ) {
				$self->_beginblock($for);
			} elsif ( $tag eq 'cut' ) {
				$self->{_inpod} = 0;
			}

			$self->{_sawblank} = 0;
		} elsif ( $self->{_inpod} ) {
			if (
			(/^=(?:also )?end (\S+)/ or /^=for (\S+) end\b/)
			and
			$self->{_inblock} eq $1
			) {
				$self->_endblock;
				$self->{_sawblank} = 0;
			} else {
				if ( /^\s*$/ ) {
					$self->_endfor() if $self->{_infor};
					$self->{_sawblank} = 1;
				} elsif ( !$self->{_inblock} and !$self->{_infor} ) {
					$self->_sawsomethingelse;
					$self->{_sawblank} = 0;
				}
				$self->{_currpod} .= $_;
			}
		} else {
			if ( /^\s*$/ ) {
				$self->{_sawblank} = 1;
			} else {
				$self->_sawsomethingelse;
			}
		}

		$self->{_linenum}++;
	}

	$self->_endfor;

	push @{$self->{example}}, @{$self->{_for}{example}};
	push @{$self->{testing}}, @{$self->{_for}{testing}};
	push @{$self->{example_testing}}, @{$self->{_for}{example_testing}};
}

#=head2 _init
#
#  $parser->_init;
#
#Initializes the state of the parser, but not the rest of the object.
#Should be called before each parse of new POD.
sub _init {
	my ($self) = shift;
	$self->{_sawblank} = 1;
	$self->{_inblock}  = 0;
	$self->{_infor}    = 0;
	$self->{_inpod}    = 0;
	$self->{_linenum}  = 1;
	$self->{_for}      = {
		example         => [],
		testing         => [],
		example_testing => [],
	};
}

sub _sawsomethingelse {
	my ($self) = shift;
	$self->{_lasttype} = 0;
}

#=head2 _beginfor
#
#  $parser->_beginfor($format, $pod);
#
#Indicates that a =for tag has been seen.  $format (what immediately
#follows '=for'), and $pod is the rest of the POD on that line.
sub _beginfor {
	my ($self, $for, $pod) = @_;
	
	if ( $for eq 'example' and defined $pod ) { 
		if ( $pod eq 'begin' ) {
			return $self->_beginblock($for);
		} elsif ( $pod eq 'end' ) {
			return $self->_endlblock;
		}
	}
	
	$self->{_infor}    = $for;
	$self->{_currpod}  = $pod;
	$self->{_forstart} = $self->{_linenum};
}

#=head2 _endfor
#
#  $parser->endfor;
#
#Indicates that the current =for block has ended.
sub _endfor {
	my ($self) = shift;

	my $pod = {
		code => $self->{_currpod},
		# Skip over the "=for" line
		line => $self->{_forstart} + 1,
	};

	if ( $self->{_infor} ) {
		if ( $self->{_infor} eq 'example_testing' ) {
			$self->_example_testing($pod);
		}

		if ( $self->{_infor} eq $self->{_lasttype}) {
			my $last_for = ${$self->{_for}{$self->{_infor}}}[-1];
			$last_for->{code} .= "\n" x ($pod->{line} - 
				($last_for->{line} + 
				$last_for->{code} =~ tr/\n//)
				);
			$last_for->{code} .= $self->{_currpod};
		
		} else {
			push @{$self->{_for}{$self->{_infor}}}, $pod;
		}
	}
	
	$self->{_lasttype} = $self->{_infor};
	$self->{_infor} = 0;
}

#=head2 _beginblock
#
#  $parser->_beginblock($format);
#
#Indicates that the parser saw a =begin tag.  $format is the word
#immediately following =begin.
sub _beginblock {
	my ($self, $for) = @_;

	$self->{_inblock}    = $for;
	$self->{_currpod}    = '';
	$self->{_blockstart} = $self->{_linenum};
}

#=head2 _endblock
#
#  $parser->_endblock
#
#Indicates that the parser saw an =end tag for the current block.
sub _endblock {
	my ($self) = shift;

	my $pod = {
		code => $self->{_currpod},
		# Skip over the "=begin"
		line => $self->{_blockstart} + 1,
	};

	if ( $self->{_inblock} ) {
		if ( $self->{_inblock} eq 'example_testing' ) {
			$self->_example_testing($self->{_currpod});
		}

		if ( $self->{_inblock} eq $self->{_lasttype}) {
			my $last_for = ${$self->{_for}{$self->{_inblock}}}[-1];
			$last_for->{code} .= "\n" x ($pod->{line} - 
				($last_for->{line} + 
				$last_for->{code} =~ tr/\n//)
				);
			$last_for->{code} .= $self->{_currpod};
		
		} else {
			push @{$self->{_for}{$self->{_inblock}}}, $pod;
		}
	}

	$self->{_lasttype} = $self->{_inblock};
	$self->{_inblock}  = 0;
}

sub _example_testing {
	my ($self, $test) = @_;

	my $last_example = ${$self->{_for}{example}}[-1];
	$last_example->{code} .= "\n" x ($test->{line} - 
		($last_example->{line} + 
		$last_example->{code} =~ tr/\n//)
		);

	$last_example->{testing} = $test->{code};
}

=pod

=head2 parse_file $file

  $parser->parse_file($filename);

Just like parse() except it works on a file.

=cut

sub parse_file {
	my ($self, $file) = @_;

	unless( open(POD, $file) ) {
		warn "Couldn't open POD file $file:  $!\n";
		return;
	}

	return $self->parse_fh(\*POD);
}

=pod

=head2 parse_fh $fh

  $parser->parse_fh($fh);

Just like parse() except it works on a filehandle.

=cut

sub parse_fh {
	my ($self, $fh) = @_;

	# Yeah, this is inefficient.  Sue me.
	return $self->parse(<$fh>);
}

=pod

=head2 tests

  @testing  = $parser->tests;

Returns the tests found in the parsed POD documents.  Each element of
@testing is a hash representing an individual testing block and contains
information about that block.

  $test->{code}         actual testing code
  $test->{line}         line from where the test was taken

=cut

sub tests {
	my ($self) = shift;
	return @{$self->{testing}};
}

=pod

=head2 examples

  @examples = $parser->examples;

Returns the examples found in the parsed POD documents.  Each element of
@examples is a hash representing an individual testing block and contains
information about that block.

  $test->{code}         actual testing code
  $test->{line}         line from where the test was taken

=cut

sub examples {
	my ($self) = shift;
	return @{$self->{example}};
}

=pod

=head2 build_tests

  my @code = $p->build_tests(@tests);

Returns a code fragment based on the given embedded @tests.  This
fragment is expected to print the usual "ok/not ok" (or something
Test::Harness can read) or nothing at all.

Typical usage might be:

    my @code = $p->build_tests($p->tests);

This fragment is suitable for placing into a larger test script.

B<NOTE> Look at pod2test before embarking on your own test building.

=cut

sub build_tests {
	my ($self, @tests) = @_;

	my @code = ();

	foreach my $test (@tests) {
		my $file = $self->{file} || '';
		push @code, <<CODE;
{
    undef \$main::_STDOUT_;
    undef \$main::_STDERR_;
#line $test->{line} $file
$test->{code}
    undef \$main::_STDOUT_;
    undef \$main::_STDERR_;
}
CODE

	}

	return @code;
}

=pod

=head2 build_examples

  my @code = $p->build_examples(@examples);

Similar to build_tests(), it creates a code fragment which tests the
basic validity of your example code.  Essentially, it just makes sure
it compiles.

If your example has an "example testing" block associated with it it
will run the the example code and the example testing block.

=cut

sub build_examples {
	my ($self, @examples) = @_;

	my @code = ();
	foreach my $example (@examples) {
		my $file = $self->{file} || '';
		push @code, <<CODE;
    undef \$main::_STDOUT_;
    undef \$main::_STDERR_;
eval q{
  my \$example = sub {
    local \$^W = 0;

#line $example->{line} $file
$example->{code};

  }
};
is(\$@, '', "example from line $example->{line}");
CODE

		if ( $example->{testing} ) {
			$example->{code} .= $example->{testing};
			push @code, $self->build_tests($example);
		}

		push @code, <<CODE;
    undef \$main::_STDOUT_;
    undef \$main::_STDERR_;
CODE
	}

	return @code;
}

1;

=pod

=head1 EXAMPLES

Here's the simplest example, just finding the tests and examples in a
single module.

  my $p = Pod::Tests->new;
  $p->parse_file("path/to/Some.pm");

And one to find all the tests and examples in a directory of files.  This
illustrates building a set of examples and tests through multiple calls
to parse_file().

  my $p = Pod::Tests->new;
  opendir(PODS, "path/to/some/lib/") || die $!;
  while( my $file = readdir PODS ) {
      $p->parse_file($file);
  }
  printf "Found %d examples and %d tests in path/to/some/lib\n",
         scalar $p->examples, scalar $p->tests;

Finally, an example of parsing your own POD using the DATA filehandle.

  use Fcntl qw(:seek);
  my $p = Pod::Tests->new;

  # Seek to the beginning of the current code.
  seek(DATA, 0, SEEK_SET) || die $!;
  $p->parse_fh(\*DATA);

=head2 SUPPORT

This module has been replaced by the newer L<Test::Inline> 2. Most testing
code that currently works with C<pod2test> should continue to work with
the new version. The most notable exceptions are C<=for begin> and
C<=for end>, which are deprecated.

After upgrading, Pod::Tests and C<pod2test> were split out to provide
a compatibility package for legacy code.

C<pod2test> will stay in CPAN, but should remain unchanged indefinately,
with the exception of any minor bugs that will require squishing.

Bugs in this dist should be reported via the following URL. Feature requests
should not be submitted, as further development is now occuring in
L<Test::Inline>.

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Tests>

=head1 AUTHOR

Michael G Schwern E<lt>schwern@pobox.comE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Test::Inline>

L<pod2test>, Perl 6 RFC 183  http://dev.perl.org/rfc183.pod

Short set of slides on Pod::Tests
http://www.pobox.com/~schwern/talks/Embedded_Testing/

Similar schemes can be found in L<SelfTest> and L<Test::Unit>.

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

Copyright 2001 - 2003 Michael G Schwern.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
