package ODS;

use strict; use warnings;

our $VERSION = '0.04';

use ODS::Table;
use Blessed::Merge;
use YAOO;

sub import {
	my $package = shift;
	no strict 'refs';
	my $called = caller();
	my $table = ODS::Table->new();
	my $bm = Blessed::Merge->new(
		blessed => 0,
		same => 0
	);
	YAOO::make_keyword($called, "true", sub { 1; });
	YAOO::make_keyword($called, "false", sub { 0; });
	YAOO::make_keyword($called, "name", sub {
		my (@args) = @_;
		$table->name(@args);
	});
	YAOO::make_keyword($called, "options", sub {
		my (%args) = @_;
		$table->options($bm->merge($table->options, \%args));
	});
	YAOO::make_keyword($called, "column",  sub {
		my (@args) = @_;
		if (!$table->name) {
			$table->name([split "\:\:", $called]->[-1]);
		}
		$table->add_column(@args);
	});
	YAOO::make_keyword($called, "item",  sub {
		my (@args) = @_;
		if (!$table->name) {
			$table->name([split "\:\:", $called]->[-1]);
		}
		$table->add_item(@args);
	});
	YAOO::make_keyword($called, "storage_class",  sub {
		my (@args) = @_;
		$table->storage_class(pop @args);
	});
	YAOO::make_keyword($called, "connect", sub {
		return $table->connect(@_);
	});
	YAOO::make_keyword($called, "instantiate", sub {
		return $table->instantiate(@_);
	});
}

=head1 NAME

ODS - Object Data Store

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	package Table::Court;

	use ODS;

	name "user";

	options (
		custom => 1
	);

	column id => (
		type => "integer",
		auto_increment => true,
		mandatory => true,
		filterable => true,
		sortable => true,
		no_render => true
	);

	column first_name => (
		type => "string",
		mandatory => true,
		filterable => true,
		sortable => true,
	);

	column last_name => (
		type => "string",
		mandatory => true,
		filterable => true,
		sortable => true,
	);

	column diagnosis => (
		type => "string",
		mandatory => true,
		filterable => true,
		sortable => true,
	);

	1;

	...

	package ResultSet::Court;

	use YAOO;

	extends 'ODS::Table::ResultSet";

	has people => isa(string);

	has miss_diagnosis => isa(object);

	sub licenced_doctors {
		my ($self, %name) = @_;

		$self->miss_diagnosis($self->find(
			%name
		));
	}

	...

	package Row::Court;

	use YAOO;

	extends 'ODS::Table::Row';

	has barrister => isa(string);

	...

	my $data = Table::Court->connect('File::YAML', {
		file => 't/filedb/patients'
	});

	my $all = $data->all();

	my $misdiagnosis = $data->licenced_doctors({ first_name => 'Anonymous', last_name => 'Object' });

	$miss_diagnosis->update(
		diagnosis => 'psychosis'
	);

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ods at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=ODS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc ODS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=ODS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/ODS>

=item * Search CPAN

L<https://metacpan.org/release/ODS>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of ODS
