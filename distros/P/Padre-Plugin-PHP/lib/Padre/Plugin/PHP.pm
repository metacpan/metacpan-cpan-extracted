package Padre::Plugin::PHP;

use warnings;
use strict;
use 5.008;

our $VERSION = '0.05';

use base 'Padre::Plugin';
use Padre::Wx ();
use Padre::Wx::Dialog::Preferences();

sub padre_interfaces {
	'Padre::Plugin' => 0.50,
	'Padre::Document' => 0.21;
}

sub registered_documents {
	'application/x-php' => 'Padre::Document::PHP',;
}

sub plugin_enable {
	my $self = shift;

	$self->_config_settings;

	$Padre::Wx::Dialog::Preferences::PANELS{'Padre::Wx::Dialog::Preferences::PHP'} = 'PHP';
}

sub menu_plugins_simple {
	my $self = shift;

	return (
		'PHP' => [
			'About', sub { $self->about },
		]
	);
}

sub about {
	my ($main) = @_;

	my $about = Wx::AboutDialogInfo->new;
	$about->SetName(__PACKAGE__);
	$about->SetDescription("This plugin currently provides naive syntax highlighting for PHP files\n");
	$about->SetVersion($VERSION);
	Wx::AboutBox($about);
	return;
}

###############################################################################
# Internal functions

sub _config_settings {
	my $self = shift;

	my $config = Padre->ide->config;

	$config->setting(
		name    => 'php_cmd',
		type    => Padre::Constant::ASCII,
		store   => Padre::Constant::HOST,
		default => '',
	);

	$config->setting(
		name    => 'php_interpreter_args_default',
		type    => Padre::Constant::ASCII,
		store   => Padre::Constant::HOST,
		default => '',
	);

}


1;
__END__

=head1 NAME

Padre::Plugin::PHP - L<Padre> and PHP

=head1 AUTHOR

Gabor Szabo, C<< <szabgab at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
