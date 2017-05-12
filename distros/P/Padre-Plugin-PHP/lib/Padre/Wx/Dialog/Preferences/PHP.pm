package Padre::Wx::Dialog::Preferences::PHP;

use 5.008;
use warnings;
use strict;

use Padre::Wx::Dialog::Preferences ();

our $VERSION = '0.05';
our @ISA     = 'Padre::Wx::Dialog::Preferences';

sub panel {
	my $self     = shift;
	my $treebook = shift;
	my $parent   = shift;

	my $config = Padre->ide->config;

	my $table = [

		#		[   [   'Wx::CheckBox', 'editor_wordwrap', ( $config->editor_wordwrap ? 1 : 0 ),
		#				Wx::gettext('Default word wrap on for each file')
		#			],
		#			[]
		#		],
		[   [ 'Wx::StaticText', undef,     Wx::gettext('PHP interpreter:') ],
			[ 'Wx::TextCtrl',   'php_cmd', $config->php_cmd ]
		],
		[   [ 'Wx::StaticText', undef,                          Wx::gettext('PHP interpreter arguments:') ],
			[ 'Wx::TextCtrl',   'php_interpreter_args_default', $config->php_interpreter_args_default ]
		],
	];

	my $panel = $self->_new_panel($treebook);
	$parent->fill_panel_by_table( $panel, $table );

	return $panel;
}

sub save {
	my $self = shift;
	my $data = shift;

	my $config = Padre->ide->config;

	$config->set(
		'php_cmd',
		$data->{php_cmd}
	);

	$config->set(
		'php_interpreter_args_default',
		$data->{php_interpreter_args_default}
	);

}



1;
__END__

=head1 NAME

Padre::Plugin::PHP - L<Padre> and PHP

=head1 DESCRIPTION

This modules provides preference options for the Padre::Plugin::PHP - module.

It uses the Padre preferences panel.

=head1 AUTHOR

Sebastian Willing

=head1 COPYRIGHT & LICENSE

Copyright 2009 Gabor Szabo, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
