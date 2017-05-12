package PSGI::Hector::Log;

=pod

=head1 NAME

PSGI::Hector::Log - Logging class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

use strict;
use warnings;
#########################################################

=pod

#head2 new($options)

	$log = PSGI::Hector::Log->new({
		'debug' => 1
	});

Creates a new instance of the logging class

=cut

#########################################################
sub new{
	my($class, $options) = @_;
	my $self = {
		'__debug' => $options->{'debug'}
	};
	bless $self, $class;
	return $self;
}
#########################################################

=pod

=head2 log($message, $severity)

	$log->log('Just testing', 'info');

Logs the provided string to STDERR with a prefixed severity.

=cut

###########################################################
sub log{	#a simple way to log a message to the apache error log
	my($self, $message, $severity) = @_;
	$severity = "" unless $severity;
	return if !$self->{'__debug'} and $severity eq 'debug';	#ignore debug messages when not in debug mode
	print STDERR uc($severity) . " - " . $message . "\n";
}
#################################################

=head1 Notes

=head1 Author

MacGyveR <dumb@cpan.org>

Development questions, bug reports, and patches are welcome to the above address.

=head1 See Also

=head1 Copyright

Copyright (c) 2017 MacGyveR. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

###############################################
return 1;
