#!/usr/bin/env perl

=head1 NAME

C<App::pickle::OptArgs> - Defines the command line arguments to be parsed.

=cut

package App::pickle::OptArgs;

use OptArgs2;
 
cmd 'App::pickle' => (
	comment => 'An electronic component pick list utility',
	optargs => sub {
		arg 'file' => (
			comment  => 'PickLE file to be parsed',
			isa      => 'Str',
			required => 1,
		);
	},
);

subcmd 'App::pickle::import' => (
	comment => 'Converts another file into a PickLE pick list',
	optargs => sub {
		arg 'type' => (
			comment  => 'File type. Supported formats: eagle (Eagle BOM CSV)',
			isa      => 'Str',
			required => 1,
		);

		arg 'file' => (
			comment  => 'File to be imported',
			isa      => 'Str',
			required => 1,
		);
	},
);

subcmd 'App::pickle::export' => (
	comment => 'Exports a PickLE pick list in another format',
	optargs => sub {
		arg 'type' => (
			comment  => 'File type. Supported formats: html, json',
			isa      => 'Str',
			required => 1,
		);

		arg 'file' => (
			comment  => 'PickLE pick list to be exported',
			isa      => 'Str',
			required => 1,
		);
	},
);

1;

__END__

=head1 AUTHOR

Nathan Campos <nathan@innoveworkshop.com>

=head1 COPYRIGHT

Copyright (c) 2022- Nathan Campos.

=cut
