package Smart::Comments::Log4perl;

use 5.016;
use strict;
use Smart::Comments;
use Log::Log4perl qw(get_logger :levels);
use Scalar::Util qw(openhandle);

=head1 NAME

Smart::Comments::Log4perl - An extension of Smart::Comments to utilize Log::Log4perl for all output

=head1 VERSION

Version 1.002

=cut

our $VERSION = '1.002';
our $INITIALIZED;
our $LAYOUT;
our $CONFIG_FILE = $ENV{'SCL4P_CONFIG'};
our $LOG_LEVEL = 'info';

my %ADDITIONAL_SMART_COMMENT_KEYWORDS = (
     'l4p_config:' => sub { $CONFIG_FILE = $_[3][0]; },
     'l4p_fatal:'  => sub { _log_at_level('fatal', @_); },
     'l4p_warn:'   => sub { _log_at_level('warn',  @_); },
     'l4p_info:'   => sub { _log_at_level('info',  @_); },
     'l4p_debug:'  => sub { _log_at_level('debug', @_); },
     'l4p_trace:'  => sub { _log_at_level('trace', @_); },
     'l4p_level:'  => sub { $LOG_LEVEL = lc $_[3][0]; },
);

my $LOG_HANDLE;

=head1 SYNOPSIS

Smart:Comments is a great module which allows debug to be completely ignored during normal execution, but have debug entries fire when
necessary.  Log4perl turns logging up a notch, allowing easy logging to STDOUT/STDERR or file handles easily.  This seeks to combine the
two in a useful manner.

Here's a brief code snippet.

	use Smart::Comments::Log4perl;

	my $foo = {};
	### Log a variable: $foo;
	...

=head1 CONFIGURATION

Configuration of Log4Perl is very simple by default, with no additional decorations above Smart::Comments, with a to-screen logger that
logs at debug and above.  Wholesale configuration may be done via a Log4perl configuration file, which can be loaded into the system by
either setting the SCL4P_CONFIG environment variable to the location of the file or by placing the following line:
	### l4p_config: 'config/location'
Variables may also be used in this configuration:
	### l4p_config: "/log_root/$log_file"

Please note: Once a single line of logging has occurred, the ### l4p_config lines will be ignored, as there is no way to re-intialize
the Log4perl system at the moment.

=head1 LOGGING

All normal ### smart comments will, by default, be logged as INFO level logs.  The level for regular smart comments may be changed by
calling the meta-command:
	### l4p_level: 'INFO'
(Other valid options are FATAL, WARN, DEBUG, and TRACE)
A single line of logging may be run at a different level by a matching meta-command per level:
	### l4p_trace: 'This is a TRACE level log'
Note that anything after the : must evaluate to a valid Perl string in order to log successfully.  Analog meta-commands exist for all 5
available log levels

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=cut

sub _log_at_level
{
	my ($level, @args) = @_;
	local $LOG_LEVEL = $level;
	$args[1] = q{};
	_l4p_Dump(@args);
}

sub _prep_logging
{
	my ($package) = @_;
	if (!Log::Log4perl->initialized())
	{
		if ($CONFIG_FILE)
		{
			Log::Log4perl->init($CONFIG_FILE);
		}
		else
		{
			my %options = ( 'log4perl.rootLogger'                               => 'DEBUG, Screen',
			                'log4perl.appender.Screen'                          => 'Log::Log4perl::Appender::Screen',
			                'log4perl.appender.Screen.layout'                   => 'PatternLayout',
			                'log4perl.appender.Screen.layout.ConversionPattern' => '%m',
			);
			Log::Log4perl->init( \%options );
		}
	}
	$LOG_HANDLE = get_logger($package);
	return;
}

sub _l4p_Dump
{
	my ($package) = caller;
	if (@_ > 1 && exists $ADDITIONAL_SMART_COMMENT_KEYWORDS{lc $_[1]})
	{
		$ADDITIONAL_SMART_COMMENT_KEYWORDS{lc $_[1]}->(@_);
		return;
	}
	_prep_logging($package);
	local *STDERR = *L4P_OVERRIDE_STDERR;
	_orig_Dump(@_);
	return;
}

sub _l4p_for_progress
{
	my ($package) = caller;
	_prep_logging($package);
	local *STDERR = *L4P_OVERRIDE_STDERR;
	_orig_for_progress(@_);
	return;
}

sub _while_progress
{
	my ($package) = caller;
	_prep_logging($package);
	local *STDERR = *L4P_OVERRIDE_STDERR;
	_orig_while_progress(@_);
	return;
}

#   These are the nasty hacks to hijack Smart::Comments -- I'd love to have a better way to hook into that framework, but this was the
#   most useful method I could come up with.

unless ( $INITIALIZED )
{
	# To avoid double re-defining causing an infinite loop, ensure this only runs once
	*Smart::Comments::Log4perl::_orig_Dump = \&Smart::Comments::_Dump;
	undef *Smart::Comments::_Dump;
	*Smart::Comments::_Dump = \&_l4p_Dump;

	*Smart::Comments::Log4perl::_orig_for_progress = \&Smart::Comments::_for_progress;
	undef *Smart::Comments::_for_progress;
	*Smart::Comments::_for_progress = \&_l4p_for_progress;

	*Smart::Comments::Log4perl::_orig_while_progress = \&Smart::Comments::_while_progress;
	undef *Smart::Comments::_while_progress;
	*Smart::Comments::_while_progress = \&_l4p_while_progress;

	$INITIALIZED=1;
}

tie *L4P_OVERRIDE_STDERR, 'Smart::Comments::Log4perl::IO';

#   A new package we can tie to STDERR temporarily to hijack Smart::Comment's output

package Smart::Comments::Log4perl::IO;
use base qw<Tie::Handle>;
use Symbol qw<geniosym>;

*L4P_ORIGINAL_STDERR = *STDERR;

sub TIEHANDLE { return bless geniosym, __PACKAGE__ }

sub TELL
{
	return tell L4P_ORIGINAL_STDERR;
}

my %LOGGER_DISPATCH = (
     'fatal' => sub { return $LOG_HANDLE->fatal(@_); },
     'warn'  => sub { return $LOG_HANDLE->warn(@_);  },
     'info'  => sub { return $LOG_HANDLE->info(@_);  },
     'debug' => sub { return $LOG_HANDLE->debug(@_); },
     'trace' => sub { return $LOG_HANDLE->trace(@_); },
);

sub PRINT
{
	shift;
	local *STDERR = *L4P_ORIGINAL_STDERR;
	# Kind of a magic number, needed to step back out of these frames deep enough to find where the smart::comment was originally
	#   So, Smart::Comments::Dump, PRINT, LOGGER_DISPATCH, etc.
	local $Log::Log4perl::caller_depth = 4;
	return unless exists $LOGGER_DISPATCH{$LOG_LEVEL};
	return $LOGGER_DISPATCH{$LOG_LEVEL}->(@_);
}

=head1 AUTHOR

Tracy Beck, C<< <tgbeck at acm.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-smart-comments-log4perl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Smart-Comments-Log4perl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Smart::Comments::Log4perl


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Smart-Comments-Log4perl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Smart-Comments-Log4perl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Smart-Comments-Log4perl>

=item * Search CPAN

L<http://search.cpan.org/dist/Smart-Comments-Log4perl/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Tracy Beck.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Smart::Comments::Log4perl
