=head1 NAME

String::FormatX - Perl extension for formatting strings and numbers

=head1 Purpose

Formats a string based on pre-defined String::FormatX templates or
user-supplied template patterns.

=head1 Requires

You will need all of the modules below to be installed for the
String::FormatX library to work.

=over 

=item	Exporter

=item	Number::Format

=over

=item Carp

=back

=back 

=head1 Synopsis

	# As a function library...

	use String::FormatX qw(FormatX);

	my $FormattedSSN = FormatX('123456789','999-99-9999');
	print $FormattedSSN; # prints 123-45-6789

	my $GreenMoney = FormatX('123456789','~PRICE');
	print $GreenMoney; # prints $ 1,234,567.89


	# As an object...

	use String::FormatX;
	my $StrObj = new String::FormatX;

	my $FormattedSSN = $StrObj->FormatX('123456789','999-99-9999');
	print $FormattedSSN; # prints 123-45-6789


=head1 Author

Lance P. Cleveland
Charleston Software Associates (www.CharlestonSW.com)
(c) 2005-2006 - Charleston Software Associates, Inc.

=cut
#==============================================================================


#==============================================================================
#
# Package Preparation
# Sets up global variables and invokes required libraries.
#
#==============================================================================

package String::FormatX;										# Define the package name

require Exporter;													# The Export Symbol Table Manipulator
@ISA	= qw(Exporter);											# Inherit the "Export" class

@EXPORT		= qw();												# Default Exports
@EXPORT_OK  = qw(FormatX);										# Export by request only 

use Number::Format qw(:subs :vars);							# Import Number::Format Methods & Namespace

$String::FormatX::VERSION = 0.01;							# Set our version

#==============================================================================

=head1 Public Methods

=over

=item new()

 Create a new String::FormatX object.

 Properties
 ERRMSG	- contains last error message generated during String::FormatX processing
 
=cut
#==============================================================================

#--------------------------------------------------------------------

=item new()

 Create a new FormatX object.

=cut
#----------------------------------------------------------
sub new {
	# Setup Object References/Invocation
	#
	my $invocant 	= shift;
	my $class		= ref($invocant) || $invocant;		# Allows either an object or class name to invoke new

	# New Object Properties (core)
	# Put vars that can be overriden before @_,
	# Vars that ALWAYS are set come @_, or in separate definitions after my $self...
	#
	my $self = { 
						@_ ,
						ERRMSG	=> '',
						
					};

	# Bless The Hash (make it an object) and return it
	#
	return bless $self, $class;
}

#--------------------------------------------------------------------

=item FormatX()

 Return a string formatted as instructed.

 Parameters
 STR 		=> Input string to be formatted
 FORMAT  =>	Format template

=over

=item The FORMAT Parameter 

 FORMAT can be set to a predefined string as in FORMAT=>'~PRICE' or to a
 user-defined output string as in FORMAT=>'999-99-9999'.

 Predefined Strings
 ~PRICE - return a price starting with "$ ", comma separated, and 2 decimal precision

 User Defined Strings
 9 - only a numeric allowed in this position
 X - alphanumeric and '_' allowed in this position 
 All other characters are taken as literal replacements within the text.

 Processing
 When a '9' or 'X' appears in the format string the input string is processed
 scanning for the next numeric or alphanumeric throwing away all interim
 characters during the search.  In other words, if we are looking for digit format
 such as '999.99' and we get 'blah12blah345' you end up with '123.45' because
 we threw away the blah blah.

=back
 Returns 
 STR formatted according to FORMAT setting

=cut
#----------------------------------------------------------
sub FormatX(@) {
	my $self = shift;
	my $funcyKey;
	my $funcyVal;

	# Called As Function vs. Object Method
	#
	if (ref($self) ne 'String::FormatX') {
		unshift (@_ , $self);
#		$funcyKey = $self;
#		$funcyVal = shift;
		$self = new String::FormatX;
	}

	# Setup options hash
	#
	my %options = @_;
#	if ($funcyKey) { 
#		$options{$funcyKey} = $funcyVal; 
#	}
	my $retval;
	foreach (qw(STR FORMAT)) { 
		if (! defined $options{$_}) { 
			$self->{ERRMSG} = "String::FormatX options $_ required.";
			return; 
		} 
	}

	# Check For Reserved Processing
	#
	my $ReservedProc;
	RP: foreach (qw(~PRICE)) {	if ($options{FORMAT} eq $_) { $ReservedProc = 1; last RP; } }

	# Reserved Word Processing
	#
	if ($ReservedProc) {

		RWP: {
			if ($options{FORMAT} eq '~PRICE') {
				$INT_CURR_SYMBOL = '$';
				$retval = format_price($options{STR});
				last RWP;
			}
		}
		

	# Char By Char Processing
	#
	} else {

		# Process each atom of the Format String
		#
		my $fmtch;
		my $inch;
		my $inPos	= 0;
		my $FmtLen 	= length($options{FORMAT});
		FMTCHAR: for (my $i = 0; $i <= $FmtLen; ++$i) {
			$fmtch 	= substr($options{FORMAT},$i,1);

			FMTTYPE: {
	
				# Numerics (9), digits 0-9 only
				#
				if ($fmtch eq '9') {
					until ($inch =~ /\d/) { 
						$inch = substr($options{STR}, $inPos++, 1);
						if ($inch eq '') { last FMTCHAR; }
					}
					$retval .= $inch;
					last FMTTYPE;							
				}
	
				# Chars (X) , alphanumeric and '_'
				#
				if ($fmtch eq 'X') {
					until ($inch =~ /\w/) { 
						$inch = substr($options{STR}, $inPos++, 1);
						if ($inch eq '') { last FMTCHAR; }
					}
					$retval .= $inch;
					last FMTTYPE;
				}

				# If we are not at the end of our input string...
				#
				if (substr($options{STR}, $inPos + 1, 1) ne '') {
					$retval .= $fmtch;
				}
	
			}
	
			# Prep for next char
			#
			$inch = '';
		}
	}

	return $retval;
}

1;
