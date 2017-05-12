package Padre::Plugin::ClassSniff;
BEGIN {
  $Padre::Plugin::ClassSniff::VERSION = '0.30';
}

# ABSTRACT: Simple Class::Sniff interface for Padre

use 5.008;
use warnings;
use strict;

use Padre::Config ();
use Padre::Wx     ();
use Padre::Plugin ();

our @ISA = 'Padre::Plugin';

sub padre_interfaces {
	'Padre::Plugin' => 0.47,;
}

sub plugin_name {
	Wx::gettext('Class Sniffer');
}

sub menu_plugins_simple {
	my $self = shift;
	return $self->plugin_name => [
		Wx::gettext('Print Report') => sub { $self->print_report },
		Wx::gettext('About')        => sub { $self->show_about },
	];
}

sub print_report {
	my $self = shift;
	require Padre::Task::ClassSniff;
	Padre::Task::ClassSniff->new(
		mode => 'print_report',
	)->schedule();
}



sub show_about {
	my $self = shift;

	# Generate the About dialog
	my $about = Wx::AboutDialogInfo->new;
	$about->SetName("Padre::Plugin::ClassSniff");
	$about->SetDescription( <<"END_MESSAGE" );
Initial Class::Sniff support for Padre
END_MESSAGE
	$about->SetVersion($Padre::Plugin::ClassSniff::VERSION);

	# Show the About dialog
	Wx::AboutBox($about);

	return;
}

1;



=pod

=head1 NAME

Padre::Plugin::ClassSniff - Simple Class::Sniff interface for Padre

=head1 VERSION

version 0.30

=head1 SYNOPSIS

Use this like any other Padre plugin. To install
Padre::Plugin::ClassSniff for your user only, you can
type the following in the extracted F<Padre-Plugin-ClassSniff-...>
directory:

  perl Makefile.PL
  make
  make test
  make installplugin

Afterwards, you can enable the plugin from within Padre
via the menu I<Plugins-E<gt>Plugin Manager> and there click
I<enable> for I<Class::Sniff>.

=head1 DESCRIPTION

This module adds very, very basic support for running Class::Sniff
with the default settings against the document (assumed to be a class)
in the current editor tab.

The output will go to the Padre output window.

TODO: Configuration

=head1 BUGS

Please report any bugs or feature requests to L<http://padre.perlide.org/>

=head1 COPYRIGHT & LICENSE

Copyright 2009 The Padre development team as listed in Padre.pm.
all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHORS

=over 4

=item *

Steffen Mueller <smueller@cpan.org>

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Steffen Mueller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

