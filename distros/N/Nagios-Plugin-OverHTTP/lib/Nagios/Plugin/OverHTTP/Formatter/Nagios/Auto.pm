package Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto;

use 5.008001;
use strict;
use warnings 'all';

###########################################################################
# METADATA
our $AUTHORITY = 'cpan:DOUGDUDE';
our $VERSION   = '0.16';

###########################################################################
# MODULE IMPORTS
use Carp qw(croak);
use Const::Fast qw(const);
use English qw(-no_match_vars);
use Env::Path 0.04;
use IPC::System::Simple 0.13;
use Regexp::Common 2.119;
use Try::Tiny;

###########################################################################
# ALL IMPORTS BEFORE THIS WILL BE ERASED
use namespace::clean 0.04 -except => [qw(meta)];

###########################################################################
# PRIVATE CONSTANTS
const my $NAGIOS_FORMATTER_PRE => 'Nagios::Plugin::OverHTTP::Formatter::Nagios';
const my $DEFAULT_FORMATTER    => join q{::}, $NAGIOS_FORMATTER_PRE, q{Version3};
const my $NAGIOS_EXECUTABLE    => 'nagios';
const my $VERSION_RE           => $RE{num}{int}{-sep => q{.}}{-group => q{1,3}};

###########################################################################
# CONSTRUCTOR
sub new {
	my ($class, @args) = @_;

	# Find all Nagios executables
	my @nagios_executables = Env::Path->PATH->Whence($NAGIOS_EXECUTABLE);

	# Get a list of version numbers
	my @nagios_versions =
		grep { defined $_ }
		map { _get_nagios_version($_) }
		@nagios_executables;

	# The module to use
	my $formatter = $DEFAULT_FORMATTER;

	# Look for the formatter
	VERSION:
	foreach my $version (@nagios_versions) {
		# Split the version into the different dot parts
		my @parts = split m{\.}msx, $version;

		VERSION_PART:
		while (@parts) {
			# Construct version to check for
			my $check_for_version = join q{.}, @parts;
			my $module_name = join q{::Version},
				$NAGIOS_FORMATTER_PRE,
				$check_for_version;

			if (eval "require $module_name; 1;") {
				# The module exists, so use this
				$formatter = $module_name;
				last VERSION;
			}

			# Remove last version part for next check
			pop @parts;
		}
	}

	# Make sure the formatter is loaded
	if (!eval "require $formatter; 1;") {
		# Module failed to load
		croak $EVAL_ERROR;
	}

	# Return a new formatter instance
	return $formatter->new(@args);
}

###########################################################################
# PRIVATE FUNCTIONS
sub _get_nagios_version {
	my ($nagios_executable) = @_;

	# Get the output from using the -v switch
	my $version_info = try {
		# Capture output
		IPC::System::Simple::capturex($nagios_executable, q{-v});
	}
	catch {
		# If error thrown, return empty string
		q{};
	};

	# Parse out the version number
	my ($version) = $version_info =~ m{^nagios \s+ (?:core \s+)? ($VERSION_RE)}imsx;

	# Return the version (or undef)
	return $version;
}

1;

__END__

=head1 NAME

Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto - Detect installed Nagios
version and format accordingly

=head1 VERSION

This documentation refers to L<Nagios::Plugin::OverHTTP::Formatter::Nagios::Auto>
version 0.16

=head1 SYNOPSIS

  #TODO: Write this

=head1 DESCRIPTION

This formatter for L<Nagios::Plugin::OverHTTP> will attempt to detect the
installed Nagios version and load the appropriate formatter for the version.

=head1 CONSTRUCTOR

This is fully object-oriented, and as such before any method can be used, the
constructor needs to be called to create an object to work with.

=head2 new

This will construct a new plugin object.

=over

=item B<< new(%attributes) >>

C<< %attributes >> is a HASH where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=item B<< new($attributes) >>

C<< $attributes >> is a HASHREF where the keys are attributes (specified in the
L</ATTRIBUTES> section).

=back

=head1 ATTRIBUTES

  # Set an attribute
  $object->attribute_name($new_value);

  # Get an attribute
  my $value = $object->attribute_name;

=head2 response

B<Required>. This is the L<Nagios::Plugin::OverHTTP::Response> object to
format.

=head1 METHODS

=head2 parse

This takes a L<HTTP::Response> object and parses it and will return a
L<Nagios::Plugin::OverHTTP::Response> object.

=head1 DIAGNOSTICS

=over 4

=item C<< Status header %s is in valid >>

The status header that was provided did not contain any known status format.

=back

=head1 DEPENDENCIES

This module is dependent on the following modules:

=over 4

=item * L<Carp>

=item * L<Const::Fast>

=item * L<English>

=item * L<Env::Path> 0.04

=item * L<IPC::System::Simple> 0.13

=item * L<Regexp::Common> 2.119

=item * L<Try::Tiny>

=item * L<namespace::clean> 0.04

=back

=head1 AUTHOR

Douglas Christopher Wilson, C<< <doug at somethingdoug.com> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-nagios-plugin-overhttp at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-OverHTTP>. I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2012 Douglas Christopher Wilson, all rights reserved.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back
