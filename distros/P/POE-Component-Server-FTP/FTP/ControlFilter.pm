package POE::Component::Server::FTP::ControlFilter;

###########################################################################
### POE::Component::Server::FTP::ControlFilter
### L.M.Orchard (deus_x@pobox.com)
### David Davis (xantus@cpan.org)
###
### TODO:
### --
###
### Copyright (c) 2001 Leslie Michael Orchard.  All Rights Reserved.
### This module is free software; you can redistribute it and/or
### modify it under the same terms as Perl itself.#
###
### Changes Copyright (c) 2003-2004 David Davis and Teknikill Software
###########################################################################

use strict;

sub DEBUG { 0 }

sub new {
	my $class = shift;
	my %args = @_;

	bless({}, $class);
}

sub get {
	my ($self, $raw) = @_;
	my @events = ();

	foreach my $input (@$raw) {
		$input =~ s/\n//g;
		$input =~ s/\r//g;
		DEBUG && print STDERR "<<< $input\n";
		my ($cmd, @args) = split(/ /, $input);

		push(@events, { cmd => uc $cmd, args =>\@args });
	}

	return \@events;
}

sub put {
	my ($self, $in) = @_;
	my @out = ();

	foreach (@$in) {
		DEBUG && print STDERR ">>> $_\n";
		push(@out, "$_\n");
	}

	return \@out;
}

sub get_pending {
	my ($self) = @_;
	warn ref($self)." does not support the get_pending() method\n";
	return;
}

1;
