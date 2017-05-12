# Perl I/O Layer for Logging
#
# Author: Adam J Kaplan
# Email: akaplan@cpan.org
# 
# This script is distributed under the same license as Perl itself.
#
package PerlIO::via::Logger;

$VERSION = '1.01';
use strict;
use warnings;
use POSIX qw(strftime);

# Set default format

# Format for strftime(3)
my $timestr = '[%b %d, %Y %H:%M:%S] ';
# I prefer the string below, but it is not as portable as the one above
#my $timestr = '%b %d, %Y %r: ';

# Satisfy require
1;

#-----------------------------------------------------------------------
# Class methods
#-----------------------------------------------------------------------

#-----------------------------------------------------------------------
#  IN: 1 class (ignored)
#      2 new value for time format string
# OUT: 1 current default time format string

sub format {

		# Set new default format if one specified
		# Return current default format

		$timestr = $_[1] if defined $_[1];
		return $timestr;
} #format

#-----------------------------------------------------------------------
# Subroutines for standard Perl features
#-----------------------------------------------------------------------
#  IN: 1 class to bless with
#      2 mode string (ignored)
#      3 file handle of PerlIO layer below (ignored)
# OUT: 1 blessed object

sub PUSHED { 

	# Die now if strange mode
	# Create the object with the right fields

	bless {timestr => $timestr },$_[0];
} #PUSHED

#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 handle to read from
# OUT: 1 processed string

sub FILL {

		# Obtain local copy of the formatting variables
		# If there is a line to be read from the handle
		#  Append the generated string
		#  Return the result
		# Return indicating end reached

    my ($timeformat) = @{$_[0]}{qw(timestr)};
    
		my $now_string = strftime $timeformat, localtime;
    if (defined( my $line = readline( $_[1] ) )) {
				return $now_string . $line;
    }
    undef;
} #FILL

#-----------------------------------------------------------------------
#  IN: 1 Valid file handle GLOB
#			 2 Optional output. Default is to insert the io layer in place
# OUT: 1 undef

sub logify {
		my $fh = shift||return;
		binmode($fh, ":via(Logger)");
		undef;
}


#-----------------------------------------------------------------------
#  IN: 1 instantiated object
#      2 buffer to be written
#      3 handle to write to
# OUT: 1 number of bytes written
sub WRITE {

		# Obtain local copies of format vars
		# For all of the lines in this bunch (includes delimiter at end)
		#  Return with error if print failed
		# Return total number of octets handled

    my ($timeformat) = @{$_[0]}{qw(timestr)};
    
		my $now_string = strftime $timeformat, localtime;
    foreach (split( m#(?<=$/)#,$_[1] )) {
				return -1 unless print {$_[2]} $now_string . $_;
    }
    length( $_[1] );
} #WRITE

#-----------------------------------------------------------------------
#  IN: 1 class for which to import
#      2..N parameters passed with -use-

sub import {

# Obtain the parameters
# Loop for all the value pairs specified

    my ($class,%param) = @_;
    $class->$_( $param{$_} ) foreach keys %param;
} #import

#-----------------------------------------------------------------------

__END__

=head1 NAME

PerlIO::via::Logger - PerlIO layer for prefixing current time to log output

=head1 SYNOPSIS

 use PerlIO::via::Logger;
 PerlIO::via::Logger->format( '[%b %d, %Y %r] ' );

 use PerlIO::via::Logger format => '[%b %d, %Y %r] ';

 open( my $in,'<:via(Logger)','filein' )
  or die "Can't open file.ln for reading: $!\n";
 
 open( my $out,'>:via(Logger)','fileout' )
  or die "Can't open file.ln for writing: $!\n";

 PerlIO::via::Logger::logify(*STDOUT);  # redirect stdout in one line!

 PerlIO::via::Logger::logify(*openhandle);  # or any other handle

=head1 DESCRIPTION

This module implements a PerlIO layer that prefixes the current time to each
line of output or input.  This module was created because I frequently need to
use file logging systems in daemon-style Perl systems.  This module was created 
to fulfill three requirements:

=over 4

=item 1. Must be low overhead/fast

=item 2. Must be simple to use (i.e. print "something to log\n")

=item 3. Must be able to add a prefix to each line (times in my case)

=back

I<Note: the format string accepts the format specification of strftime(3) on your system.  You may use the command "man 3 strftime" to view the 
behavior of strftime on your system. Or see this page: 
L<http://www.hmug.org/man/3/strftime.php>>
 
=head1 CLASS METHODS

The following two class methods allow you to alter the prefix formatting string
used by the I/O layer and to redirect existing filehandles with (almost) no
effort.

For convienance, class methods can also be called as key-value pairs in the 
C<use> statement.  This allows you to use this module in an "import and forget
it" fashion.

Please note that the new value of the class methods that are specified, only
apply to the file handles that are opened (or to which the layer is assigned
using C<binmode()>) B<after> they have been changed.

=head2 format

 use PerlIO::via::Logger format => '[%b %d, %Y %r] ';
 
 PerlIO::via::Logger->format( '[%b %d, %Y %r] ' );
 my $format = PerlIO::via::Logger->format;

The class method C<format> returns the format that will be used for adding
the time to lines.  The optional input parameter specifies the format that will
be used for any files that are opened in the future.  You should use only the 
conversion specifiers defined by the ANSI C standard (C89, to play safe). These 
are aAbBcdHIjmMpSUwWxXyYZ% .  The default is C<'[%b %d, %Y %H:%M:%S] '>, though
the examples throughout this document use a more elegant - but less portable -
format.

=head2 logify

 PerlIO::via::Logger::logify( $filehandle );
 PerlIO::via::Logger::logify( *WRITEFH );
 PerlIO::via::Logger::logify( *STDOUT );

The class method C<logify> exists purely for convenience and my personal use.
B<I do not recommend using it unless your systems are for development only, or
you understand how it works.> In short it will reopen the given filehandle 
through the Logger I/O layer.

=head2 FILL 

 PerlIO::via::Logger->FILL()

I<This method is required for PerlIO modules.  Do NOT use it unless you know
what you are doing.>

=head2 PUSHED

 PerlIO::via::Logger->PUSHED()

I<This method is required for PerlIO modules.  Do NOT use it unless you know
what you are doing.>

=head1 EXAMPLES

Here are some examples for your reading pleasure:

=head2 Sending STDOUT to a log file

The following code redirects STDOUT through the Logger without using logify()
Note the use of >&: instead of >: because this is a filehandle glob.

 #!/usr/bin/perl
 use PerlIO::via::Logger;
 open my $stdout, ">&STDOUT";
 close STDOUT;
 open (STDOUT, ">&:via(Logger)", $stdout)
   or die "Unable to logify standard output: $!\n";
 print "Something that needs a time!\n";

Goes to STDOUT as:

 [Jan 01, 2007 01:23:45] Something that needs a time!

=head2 Using an file-based log and silly custom prefix

This would probably be the most common use:

 #!/usr/bin/perl
 use PerlIO::via::Logger format => 'Logtastic: ';
 open (OUT, ">:via(Logger)", 'foo.log')
   or die "Unable to open foo.log: $!\n";
 print OUT "The format string does not need any time variables.";

Would output the following into the file 'foo.log'

 Logtastic: The format string does not need any time variables.

=head1 DEPENDANCIES

This module is free of any dependancies beyond what is included by default
with the version of Perl I used to create and test it, version 5.8.6.

=head2 Required Modules

L<POSIX>

=head2 Optional Testing Dependancies

L<Pod::Simple>
L<Test::Pod::Coverage>

The Pod tests that are included with this distribution require the two
modules listed above. However, running the test suite is optional, and the 
test scripts will not break if these modules are missing.

=head1 BUGS, LIMITATIONS AND FEATURE REQUESTS

=head2 Known Bugs and Limitations

None at this time.

=head2 Reporting Bugs

Please report any bugs and/or feature requests to
C<bug-PerlIO-via-Logger at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PerlIO-via-Logger>.
Be as detailed as possible when describing problems.  The RT system will
notify me automatically and keep you updated as we work to resolve your
issue.

=head1 SEE ALSO

L<PerlIO::via> and any other PerlIO::via modules on CPAN.
L<POSIX> and C<man 3 strftime> on your system.

=head1 AUTHOR

Adam J. Kaplan <akaplan at cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 B<Adam J Kaplan>. All rights reserved.
Based on snippets of code from Elizabeth Mattijsen's PerlIO::via modules.
This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

