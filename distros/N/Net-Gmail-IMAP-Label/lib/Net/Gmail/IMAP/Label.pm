package Net::Gmail::IMAP::Label;
# ABSTRACT: IMAP proxy for Google's Gmail that retrieves message labels
$Net::Gmail::IMAP::Label::VERSION = '0.008';
use strict;
use warnings;
use Net::Gmail::IMAP::Label::Proxy;
use Getopt::Long::Descriptive;

sub import {
	my ($class, @opts) = @_;
	return unless (@opts == 1 && $opts[0] eq 'run');
	$class->run;
}

sub run {
	my ($opts, $usage) = describe_options(
		"$0 %o",
		[ 'port|p=i',   "local port to connect to (default: @{[Net::Gmail::IMAP::Label::Proxy::DEFAULT_LOCALPORT]})", { default => Net::Gmail::IMAP::Label::Proxy::DEFAULT_LOCALPORT } ],
		[ 'verbose|v+', "increase verbosity (multiple flags for more verbosity)" , { default => 0 } ],
		[ 'help|h|?',   "print usage message and exit" ],
	);

	if($opts->help) {
		print($usage->text);
		return 1;
	}

	Net::Gmail::IMAP::Label::Proxy->new(localport => $opts->port, verbose => $opts->verbose)->run();
}

1;


# vim:ts=4:sw=4

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Gmail::IMAP::Label - IMAP proxy for Google's Gmail that retrieves message labels

=head1 VERSION

version 0.008

=head1 SYNOPSIS

    gmail-imap-label [OPTION]...

=head1 DESCRIPTION

This module provides a proxy that sits between an IMAP client and Gmail's IMAPS
server and adds GMail labels to the X-Label header. This proxy uses the
L<Gmail IMAP extensions|https://developers.google.com/gmail/imap/imap-extensions#access_to_gmail_labels_x-gm-labels>.

To use this proxy, your e-mail client will need to connect to the proxy using
the IMAP protocol (without SSL).

=head1 EXAMPLES

The simplest way of starting is to run the proxy on the default port of 10143:

    gmail-imap-label

An alternative port can be specified using the B<--port> option

    gmail-imap-label --port 993

The proxy has been tested with both mutt (v1.5.21) and offlineimap (v6.3.4).
Example configuration files for these are available in the C<doc> directory.

With mutt, you may have to clear the header cache every so often so that any
updated labels are available inside the UI.

=head1 INSTALLATION

You can either install the package from L<CPAN|http://p3rl.org/Net::Gmail::IMAP::Label>
or from your package manager.

To install the L<Debian package|https://packages.debian.org/libnet-gmail-imap-label-perl>,
run

    apt-get install libnet-gmail-imap-label-perl

=head1 SEE ALSO

See L<gmail-imap-label> for a complete listing of options.

=head1 BUGS

Report bugs and submit patches to the repository on L<Github|https://github.com/zmughal/gmail-imap-label>.

=head1 COPYRIGHT

Copyright 2011 Zakariyya Mughal.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the ISC license, or

=item * the Artistic License version 2.0.

=back

=head1 ACKNOWLEDGMENTS

Thanks to L<Paul DeCarlo|http://pjdecarlo.com/> for pointing out the
Gmail IMAP extensions that made this a whole lot easier than what I had
originally planned on doing.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Zakariyya Mughal <zmughal@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
