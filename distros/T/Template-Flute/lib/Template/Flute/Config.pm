package Template::Flute::Config;

use strict;
use warnings;

use Config::Any;

=head1 NAME

Template::Flute::Config - Configuration file handling for Template::Flute

=head1 FUNCTIONS

=head2 load FILE

Loads configuration file FILE with L<Config::Any>.

=cut

sub load {
	my ($file) = @_;
	my ($cf_any, $cf_file, $cf_struct);

	$cf_any = Config::Any->load_files({files => [$file], use_ext => 1});

	for (@$cf_any) {
		($cf_file, $cf_struct) = %$_;
	}

	return $cf_struct;
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
