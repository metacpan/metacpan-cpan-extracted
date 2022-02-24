package ODS::Table::Generate::Data;
use strict;
use warnings;
use YAOO;

auto_build;

use ODS::Utils qw/load/;

use Term::ProgressSpinner;

has table_class => isa(string);

has table_class_type => isa(string);

has table_class_connect => isa(hash);

has total => isa(integer);

# Acme::MetaSyntactic class or one that follows the same standard
has data_class => isa(string('Acme::MetaSyntactic')), build_order(1);

has data_class_theme => isa(string), build_order(2);

has data_class_total => isa(integer(10));

has auto_increment => isa(integer), default(0);

has default_strings => isa(array), delay, coerce(sub {
	my ($self, $data) = @_;

	if ($self->data_class_theme) {
		load $self->data_class;
		my $meta = $self->data_class->new($self->data_class_theme);
		my @syntactic = $meta->name( $self->data_class_total );
		return \@syntactic;
	}
	return [
		"Barbarians",
		"Gunga Din",
		"Fame and Fortune",
		"Anthem For Doomed Youth",
		"You're My Waterloo",
		"Belly of the Beast",
		"Iceman",
		"Heart of the Matter",
		"The Milkman's Horse",
		"Ruling Force",
		"Worlds on Fire",
		"Ninja",
		"Open Eyes",
		"Dollars and Dimes",
		"Saturday",
		"More Fire",
		"Ghetto Long Time",
		"Liberate",
		"Today",
		"Ave Adore",
		"House I Built",
		"Catch a Vibe",
		"Chasing Cars",
		"Gleaming Auction",
		"Made of Stone",
		"Bounce",
		"Forest",
		"Sweet Disposition",
		"Science Of Fear",
		"The Motto",
		"Mysterious Ways"
	];
});

has default_integers => isa(array([ 1 .. 100 ]));

has default_floats => isa(array([ (map { sprintf "%.2f", "1.$_" } 0 .. 99) ]));

has default_emails_domains => isa(array([
	"lnation.org",
	"world-wide.world",
	"notifi.site",
	"supervisor.fun",
	"supervisor.guru",
	"autonomous.cyou",
	"notifi.page"
]));

has default_epoch => isa(array([ map { 1645016769 - (300 * $_) } 1 .. 50 ]));

has default_phone => isa(array), delay, coerce(sub {
	my ($self) = @_;
	my @numbers = ();

	my $total = $self->data_class_total;

	for (1 .. $self->data_class_total) {
		push @numbers, '+' . map { int(rand(10)) } 0 .. 12
	}
	return \@numbers;
});

sub generate {
	my ($self) = @_;

	load $self->table_class;

	my $table = $self->table_class->connect($self->table_class_type, $self->table_class_connect);

	$table->table->rows([]);

	my $ps = Term::ProgressSpinner->new(
		text_color => 'black on_bright_black',
		precision => 2,
	);

	$ps->start($self->total);

	my $i = 1;
	while ($ps->advance) {
		my %row = ();
		for my $column ( keys %{ $table->table->columns } ) {
			$column = $table->table->columns->{$column};
			my $callback = 'generate_' . $column->{type};
			$row{$column->name} = $self->$callback($column);
		}
		$table->create(\%row);
	}
}

sub generate_integer {
	my ($self, $row) = @_;

	if ($row->auto_increment) {
		$self->auto_increment($self->auto_increment + 1);
		return $self->auto_increment;
	}

	my $integers = $self->default_integers;

	return $integers->[int(rand(scalar @{$integers}))]
}

sub generate_string {
	my ($self, $row) = @_;

	my $strings = $self->default_strings;


	return $strings->[int(rand(scalar @{$strings}))];
}

sub generate_boolean {
	my ($self, $row) = @_;

	my $boolean = int(rand(2));

	return \$boolean;
}

sub generate_phone {
	my ($self, $row) = @_;

	my $phone = $self->default_phone;

	return $phone->[int(rand(scalar @{$phone}))];
}

sub generate_epoch {
	my ($self, $row) = @_;

	my $epoch = $self->default_epoch;

	return $epoch->[int(rand(scalar @{$epoch}))];
}


1;
