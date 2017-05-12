
package MyConText::TableString;
use vars qw! @ISA !;
@ISA = qw! MyConText::String MyConText::Table !;

sub index_document {
	my ($self, $id) = @_;
	my $data = $self->get_the_data_from_table($id);
	$self->SUPER::index_document($id, $data);
	}

package MyConText::TableNum;
use vars qw! @ISA !;
@ISA = qw! MyConText::Table !;

sub index_document {
	my ($self, $id) = @_;
	my $data = $self->get_the_data_from_table($id);
	$self->SUPER::index_document($id, $data);
	}


package MyConText::Table;
use MyConText;
use strict;
use vars qw! @ISA !;
@ISA = qw! MyConText !;

sub _open_tables {
	my $self = shift;
	if (defined $self->{'doc_id_table'}) {
		eval 'use MyConText::String';
		bless $self, 'MyConText::TableString';
		}
	else {
		bless $self, 'MyConText::TableNum';
		}
	}

# we do not create any new tables, we just check that the parameters are
# OK (the table and columns exist, etc.)
sub _create_tables {
	my $ctx = shift;
	my ($table, $column, $id) = @{$ctx}{ qw! table_name column_name
		column_id_name ! };
	if (not defined $table and $column =~ /\./) {
		($table, $column) =~ ($column =~ /^(.*)\.(.*)$/s);
		}
	my $id_type;

	if (not defined $table) {
		return "The parameter table_name has to be specified with the table frontend.";
		}
	if (not defined $column) {
		return "The parameter column_name has to be specified with the table frontend.";
		}
	my $dbh = $ctx->{'dbh'};
	my $sth = $dbh->prepare("show columns from $table");
	$sth->{'PrintError'} = 0;
	$sth->{'RaiseError'} = 0;
	$sth->execute or return "The table `$table' doesn't exist.";

	my $info = $dbh->selectall_arrayref($sth,
			{ 'PrintError' => 0, 'RaiseError' => 0 });
	if (not defined $info) {
		return "The table `$table' doesn't exist.";
		}

### use Data::Dumper; print Dumper $info;

	if (not defined $id) {
		# search for column with primary key
		my $pri_num = 0;
		for my $i (0 .. $#$info) {
			if ($info->[$i][3] eq 'PRI') {
				$pri_num++;
				$id = $info->[$i][0];
				$id_type = $info->[$i][1];
				}
			}
		if ($pri_num > 1) {
			return 'The primary key has to be one-column.';
			}	
		if ($pri_num == 0) {
			return "No primary key found in the table `$table'.";
			}
		}


	my $testcol = $dbh->prepare("select $column from $table where 1 = 0");
	$testcol->execute or
		return "Column `$column' doesn't exist in table `$table'.";
	$testcol->finish;

	$ctx->{'column_id_name'} = $id;

	if ($id_type =~ /^\w*int\((\d+)\)$/) {
		$ctx->{'doc_id_bits'} = $MyConText::PRECISION_TO_BITS{$1};
		bless $ctx, 'MyConText::TableNum';
		}
	else {
		my ($length) = ($id_type =~ /^\w+\((\d+)\)$/);
		$ctx->{'name_length'} = $1;
		eval 'use MyConText::String';
		bless $ctx, 'MyConText::TableString';
		$ctx->MyConText::String::_create_tables($ctx);
		}
### use Data::Dumper; print Dumper $ctx;
	return;
	}

sub get_the_data_from_table {
	my ($self, $id) = @_;
	my $dbh = $self->{'dbh'};
	my $get_data = ( defined $self->{'get_data_sth'}
		? $self->{'get_data_sth'}
		: $self->{'get_data_sth'} = $dbh->prepare("
			select $self->{'column_name'} from $self->{'table_name'}
			where $self->{'column_id_name'} = ?
			") );

	my ($data) = $dbh->selectrow_array($get_data, {}, $id);
	$data;
	}

1;

