package Salus::Command;
use strict; use warnings;
use Salus;
use Rope;
use Rope::Autoload;
use Term::Table;
use Term::Size;
use JSON qw//;
use ANSI::Palette qw/bold_16 reset/;

prototyped (
	info => [qw/
		title options_title header_title header_description diff_title diff_desc 
		read_title read_desc add_title add_desc all_title all_desc get_title 
		get_desc get_col_title get_col_desc set_title set_desc set_col_title 
		set_col_desc delete_title delete_desc delete_col_title delete_col_desc 
		write_title write_desc sort_title sort_desc search_title search_desc 
		find_title find_desc agg_title agg_desc exit_title exit_desc help_title 
		help_desc
	/],
	title => qq|Welcome to the command line interface for Salus\n|, 
	options_title => qq|The following are commands that can be used to manipulate a Salus CSV\n|,
	header_title => q|+ Headers|,
	header_description => [
		qq|\tprint the headers of the csv - |,
		qq|headers|,
	],
	diff_title => qq|+ Diff Files|,
	diff_desc => [
		qq|\tdiff two salus csv files - |,
		qq|diff \$filepath1 \$filepath2|
	],
	read_title => qq|+ Read File|,
	read_desc => [
		qq|\tread a salus csv file - |,
		qq|read \$filepath \$unprotected|,
	],
	add_title => qq|+ Add Row|,
	add_desc => [
		qq|\tadd a new row, the delimeter is a space not wrapped in quotations - |,
		qq|add \$one \$two \$three|,
	],
	all_title => qq|+ All|,
	all_desc => [
		qq|\tprint all rows - |,
		qq|all \$include_index|
	],
	get_title => qq|+ Get Row|,
	get_desc => [
		qq|\tretrieve a row by index and print it to the terminal - |,
		qq|get \$index|,
	],
	get_col_title => qq|+ Get Row Column|,
	get_col_desc => [
		qq|\tretrieve a column by row and column index and print it to the terminal - |,
		qq|get_col \$row \$col|
	],
	set_title => qq|+ Set Row|,
	set_desc => [
		qq|\tset an existing row by index or name - |,
		q|set \$index|,
	],
	set_col_title => qq|+ Set Row Column|,
	set_col_desc => [
		qq|\tset a columns value by row and column index or name - |,
		qq|set_col \$row \$col|,
	],
	delete_title => qq|+ Delete Row|,
	delete_desc => [
		qq|\tdelete a row by index - |,
		qq|delete \$row|
	],
	delete_col_title => qq|+ Delete Row|,
	delete_col_desc => [
		qq|\tdelete a column by row index and column index or name - |,
		qq|delete \$row \$col|
	],
	write_title => qq|+ Write File|,
	write_desc => [
		qq|\twrite data to a file - |,
		qq|write \$filepath|
	],
	sort_title => qq|+ Sort|,
	sort_desc => [
		qq|\treorder the rows by column index or name - |,
		qq|sort \$col \$dir|
	],
	search_title => qq|+ Search|,
	search_desc => [
		qq|\tsearch all rows by column value and print any matches to the terminal - |,
		qq|search \$col \$search \$include_index|
	],
	find_title => qq|+ Find|,
	find_desc => [
		qq|\tfind a row index by column value and print it to the terminal - |,
		qq|find \$col \$search|
	],
	exit_title => qq|+ Exit|,
	exit_desc => [
		qq|\tto exit you can either use - CTRL C - or type - |,
		qq|exit|,
	],
	help_title => qq|+ Help|,
	help_desc => [
		qq|\tprint all available commands - |,
		qq|help|
	],
	agg_title => qq|+ Aggregations|,
	agg_desc => [
		qq|\tthe following aggregations are available - count - min - max - sum - mean - median - mode - |,
		qq|min \$column \$table|
	],
	salus => undef
);

function INITIALISED => sub {
	my ($self, $params) = @_;	
	
	push @INC, $params->{lib} if $params->{lib};
	
	my $class = $params->{class};
	
	if ($class) {
		eval "require $class";
		$self->class = $class = $class->new();
	} else {
		if (!$params->{headers}) {
			self->say("No class or headers passed while starting the salus script");
			exit;
		}

		if (!ref $params->{headers}) {
			$params->{headers} = JSON->new->decode($params->{headers});
		}

		$self->class = $class = Salus->new({
			headers => $params->{headers}
		});
	}

	$self->salus = $class;
};

function run => sub {
	my ($self, $params) = @_;

	$self->help();

	while (1) {
		$self->say("cmd: ", 1);
		my $input = <STDIN>;
		chomp($input);
		if ($input eq 'exit') {
			exit;
		}
		my ($cmd, @args) = $self->extract_line_args($input);
		$self->$cmd(@args);		
	}
};

function help => sub {
	my $self = shift;
	for (@{ $self->info }) {
		$self->say($self->$_);
	}
};

function diff => sub {
	my ($self, $file1, $file2) = @_;
	my $diff = eval { $self->salus->diff_files($file1, $file2); };
	$self->say($@ ? $@ : $diff);
};

function read => sub {
	my ($self, $file, $unprotected) = @_;
	$self->unprotected_read = $unprotected if $unprotected;
	$self->salus->file = $file;
	eval { $self->salus->read(); };
	$self->say($@ ? $@ : "read file");
	$self->unprotected_read = 0;
};

function combine => sub {
	my ($self, $file, $unprotected) = @_;
	$self->unprotected_read = $unprotected if $unprotected;
	$self->salus->file = $file;
	eval { $self->salus->combine() };
	$self->say($@ ? $@ : "combined file");
	$self->unprotected_read = 0;
};

function write => sub {
	my ($self, $file) = @_;
	$self->salus->file = $file if $file;
	eval { $self->salus->write(); };
	$self->say($@ ? $@ : "wrote file");	
};

function add => sub {
	my ($self, @row) = @_;
	eval { $self->salus->add_row(\@row); };
	$self->say($@ ? $@ : "created row");	
};

function all => sub {
	my ($self, $include_index) = @_;
	my ($index, @rows) = (0);
	for (@{$self->salus->rows}) {
		my $row = $_->as_array();
		push @rows, ($include_index ? [ $index++, @{$row} ] : $row);
	}
	$self->print_table(\@rows, $include_index);
};

function get => sub {
	my ($self, $index) = @_;
	my $row = eval { $self->salus->get_row($index) };
	unless ($row) {
		$self->say($@ ? $@ : "no row available for index ${index}");
	 	return;
	}
	$self->print_table($row->as_array);
};

function get_col => sub {
	my ($self, $r, $c) = @_;
	my $col = eval { $self->salus->get_row_col($r, $c) };
	unless ($col) {
		$self->say($@ ? $@ : "no column available for index ${r} ${c}");
	 	return;
	}
	$self->say(($col->header->label || $col->header->name) . " value " . $col->value);
};

function set => sub {
	my ($self, $r, @row) = @_;
	eval { $self->salus->set_row($r, \@row) };
	$self->say($@ ? $@ : "set row");	
};

function set_col => sub {
	my ($self, $r, $c, $v) = @_;
	eval { $self->salus->set_row_col($r, $c, $v) };
	$self->say($@ ? $@ : "set column");	
};

function delete => sub {
	my ($self, $row) = @_;
	eval { $self->salus->delete_row($row) };
	$self->say($@ ? $@ : "deleted row");	
};

function delete_col => sub {
	my ($self, $r, $c) = @_;
	eval { $self->salus->delete_row_col($r, $c) };
	$self->say($@ ? $@ : "deleted column");	
};

function extract_line_args => sub {
	my ($self, $line) = @_;
	my @array = map {
		my $m = $_;
		if ($m ne "") {
			$m =~ s/^("|')|("|')$//g;
			$m;
		} else {
			()
		}
	} split /\s*("[^"]+"|[^\s]+)/, $line;
	return @array;
};

function headers => sub {
	my ($self) = @_;
	$self->print_table();
};

function sort => sub {
	my ($self, $col, $order) = @_;
	eval { $self->salus->sort($col, $order); };
	$self->say($@ ? $@ : "sorted rows");
};

function search => sub {
	my ($self, $col, $search, $include_index) = @_;
	my ($rows, $indexes) = eval { $self->salus->search($col, $search) };
	my @rows;
	for (my $i = 0; $i < @{$rows}; $i++) {
		my $row = $rows->[$i]->as_array();
		push @rows, ($include_index ? [ $indexes->[$i], @{$row} ] : $row);
	}
	$self->print_table(\@rows, $include_index);
};

function find => sub {
	my ($self, $col, $search) = @_;
	my $index = eval { $self->salus->find($col, $search) };
	$self->say(defined $index 
		? qq|Found row matching search query (${search}) with index: ${index}|
		: qq|Cannot find row matching search (${search})|
	);
};

function count => sub {
	my ($self) = @_;
	my $count = eval { $self->salus->count() };
	$self->say($@ ? $@ : qq|Count for csv is ${count}|);
};

function sum => sub {
	my ($self, $col) = @_;
	my $sum = eval { $self->salus->sum($col) };
	$self->say($@ ? $@ : qq|Sum for column ${col} is ${sum}|);
};

function mean => sub {
	my ($self, $col) = @_;
	my $mean = eval { $self->salus->mean($col) };
	$self->say($@ ? $@ : qq|Mean for column ${col} is ${mean}|);
};

function median => sub {
	my ($self, $col, $table) = @_;
	my $median = eval { $self->salus->median($col, $table) };
	$table 
		? $self->print_table($median->as_array)
		: $self->say($@ ? $@ : qq|Median for column ${col} is ${median}|);
};

function mode => sub {
	my ($self, $col) = @_;
	my ($key, $mode) = eval { $self->salus->mode($col) };
	$self->say($@ ? $@ : qq|Mode for column ${col} is key ${key} with ${mode} occurences.|);
};

function min => sub {
	my ($self, $col, $table) = @_;
	my $min = eval { $self->salus->min($col, $table) };
	$table 
		? $self->print_table($min->as_array)
		: $self->say($@ ? $@ : qq|Min for column ${col} is ${min}|);
};

function max => sub {
	my ($self, $col, $table) = @_;
	my $max = eval { $self->salus->max($col, $table) };
	$table 
		? $self->print_table($max->as_array)
		: $self->say($@ ? $@ : qq|Max for column ${col} is ${max}|);
};

function print_table => sub {
	my ($self, $rows, $include_indexes) = @_;
	my ($columns, $r) = Term::Size::chars *STDOUT{IO};
	my $headers = $self->salus->headers_stringify;
	unshift @{$headers}, 'INDEX' if ($include_indexes);
	my $table = Term::Table->new(
		max_width      => $columns,
		pad            => 4,
		allow_overflow => 0,
		collapse       => 1,
		($rows && scalar @{$rows} ? (
			header => $headers,
			rows   => ref $rows->[0] ? $rows : [
				$rows
			]
		) : (
			rows => [
				$headers
			]
		))
	);
	print "$_\n" for $table->render;
};

function say => sub {
	my ($self, $string, $no, $colour) = @_;
	
	if (ref $string) {
		$self->say($string->[0], 1);
		$self->say($string->[1], 0, 1);
		return;
	}
	
	my %colours;
	%colours = (
		colour => sub { return "\e[$_[0];1;1m" . $_[1]; },
		custom => sub { $colours{colour}->(@_) . "\e[0m" . $colours{base}->(''); },
		header => sub { $colours{colour}->(@_) . "\e[0m" . $colours{colour}->('34', ''); },
		'-' => sub { $colours{custom}->(31, @_); },
		'+' => sub { $colours{header}->(32, @_); },
		'$' => sub { $colours{custom}->(35, @_); },
		'key' => sub { $colours{custom}->(36, @_); },
		'cmd:' => sub { $colours{custom}->(32, @_); },
		'base' => sub { $colours{colour}->(33, @_) },
	);
	
	$string =~ s/(-|\+|cmd\:)/$colours{$1}->($1)/eg;

	if ($colour) {
		$string =~ s/((\$)[^\s]+|[^\s]+)/$colours{$2||'key'}->($1)/eg;
	} else {
		$string = $colours{base}->($string);
	}

	print $string;
	print "\e[0m\n" unless $no;
};

1;
