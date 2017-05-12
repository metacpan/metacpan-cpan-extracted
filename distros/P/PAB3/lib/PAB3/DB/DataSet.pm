package PAB3::DB::DataSet;
# =============================================================================
# Perl Application Builder
# Module: PAB3::DB::DataSet (Alpha)
# Represents data retrieved using PAB3::DB.
# Use "perldoc PAB3::DB::DataSet" for documentation
# =============================================================================
use strict;
no strict 'subs';
use warnings;

use Carp ();
use PAB3::DB ();

use vars qw($VERSION);

BEGIN {
	$VERSION = '1.0.0';

	*append = \&insert;
	*append_record = \&insert_record;
}

use constant {
	# CommandType constants
	ctQuery					=> 1,
	ctTable					=> 2,
	ctStoredProcedure		=> 3,
	# State constants
	dsSetKey				=> 4,
	dsInsert				=> 3,
	dsEdit					=> 2,
	dsBrowse				=> 1,
};

# using variables instead of constants because it needs less of memory
# (perl/5.8.8)
our $IDA_DB				= 0;
our $IDA_CMD_TEXT		= 1;
our $IDA_CMD_TYPE		= 2;
our $IDA_LIMIT			= 3;
our $IDA_OFFSET			= 4;
our $IDA_STATE			= 5;
our $IDA_ROWCOUNT		= 6;
our $IDA_ROWMAX			= 7;
our $IDA_ERROR			= 8;
our $IDA_RESULT			= 9;
our $IDA_FILTER			= 10;
our $IDA_POINTER		= 11;
our $IDA_SAFEFIELDS		= 12;
our $IDA_NAMES			= 13;
our $IDA_OPTIONS		= 14;
our $IDA_LAST_CMD		= 15;
our $IDA_TABLE_INFO		= 16;
our $IDA_SAVEPOINTER	= 17;
our $IDA_PAB			= 18;
our $IDA_OBJECTNAME		= 19;
our $IDA_ENUMPOINTER	= 20;
our $IDA_INITOFFSET		= 21;
our $IDA_SEARCH			= 22;
our $IDA_KEY_INFO		= 23;
our $IDA_CMD_TEXT_PLAIN	= 24;

our $IDA_LASTINDEX 		= 24;

our $IDA_OPT_CALCLIMIT	= 1;
our $IDA_OPT_CALCROWS	= 2;

our $DATA_MAX_SIZE		= 128 * 1024;

our $LastError = '';

our @EXPORT_CT = qw(ctQuery ctTable ctStoredProcedure);
our @EXPORT_DS = qw(dsInsert dsEdit dsBrowse);
our @EXPORT_OK = ( @EXPORT_DS, @EXPORT_CT );
our %EXPORT_TAGS = (
	'ct' => \@EXPORT_CT,
	'ds' => \@EXPORT_DS,
	'all' => \@EXPORT_OK,
);
require Exporter;
*import = \&Exporter::import;

1;

sub new {
	my $proto = shift;
	my $class = ref( $proto ) || $proto;
	my $this  = {
		'__I#D#A__' => []
	};
	my %arg = @_;
	if( ! $arg{'db'} || ref( $arg{'db'} ) !~ /PAB3::DB/ ) {
		$LastError = 'Cannot create DataSet without a valid "PAB3::DB" handle';
		return undef;
	}
	bless( $this, $class );
	my $ida = $this->{'__I#D#A__'};
	$ida->[$IDA_DB] = $arg{'db'};
	$ida->[$IDA_PAB] = $arg{'pab'};
	$ida->[$IDA_OBJECTNAME] = $arg{'object_name'};
	$ida->[$IDA_STATE] = dsBrowse;
	$ida->[$IDA_ROWCOUNT] = 0;
	$ida->[$IDA_ROWMAX] = 0;
	$ida->[$IDA_INITOFFSET] = 0;
	$ida->[$IDA_OFFSET] = 0;
	$ida->[$IDA_POINTER] = -1;
	$ida->[$IDA_ENUMPOINTER] = -1;
	$ida->[$IDA_SAFEFIELDS] = {};
	$ida->[$IDA_LAST_CMD] = '';
	if( $arg{'limit'} ) {
		$ida->[$IDA_LIMIT] = $arg{'limit'};
		$ida->[$IDA_OPTIONS] = 0;
	}
	else {
		$ida->[$IDA_LIMIT] = 1;
		$ida->[$IDA_OPTIONS] = $IDA_OPT_CALCLIMIT;
	}
	if( $arg{'filter'} ) {
		$ida->[$IDA_FILTER] = $this->_format_sql( $arg{'filter'} );
	}
	$this->command_type( $arg{'command_type'} ) if $arg{'command_type'};
	$this->command_text( $arg{'command_text'} ) if $arg{'command_text'};
	return $this;
}

#sub DESTROY {
#	my $this = shift or return;
#	&close( $this );
#}

sub open {
	my( $this ) = @_;
	my( $ida, $sql, $sqlrows, $db, $res, @row );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	return 1 if $ida->[$IDA_POINTER] >= $ida->[$IDA_OFFSET] && $ida->[$IDA_RESULT];
	$ida->[$IDA_OFFSET] = $ida->[$IDA_INITOFFSET];
	$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS;
	( $sqlrows, $sql ) = $this->_prepare_query() or return 0;
	$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS;
	$db = $ida->[$IDA_DB];
	$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
	$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
	$ida->[$IDA_NAMES] = [ $ida->[$IDA_RESULT]->fetch_names() ];
	if( $sqlrows ) {
		$res = $db->query( $sqlrows ) or return 0;
		( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
	}
	else {
		$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
	}
	@row = $ida->[$IDA_RESULT]->fetch_row() or return 0;
	$this->_apply( \@row );
	$ida->[$IDA_POINTER] = $ida->[$IDA_OFFSET];
	# calculate buffer
	if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) != 0 ) {
		my @l = $ida->[$IDA_RESULT]->fetch_lengths();
		my $len = 0;
		$len += $_ foreach @l;
		$ida->[$IDA_LIMIT] = int( $DATA_MAX_SIZE / ( $len * 2 ) );
		$ida->[$IDA_LIMIT] = 1 if $ida->[$IDA_LIMIT] < 1;
	}
	return 1;
}

sub close {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	my $db = $ida->[$IDA_DB];
	$ida->[$IDA_RESULT] = undef;
	$ida->[$IDA_POINTER] = -1;
	$ida->[$IDA_ENUMPOINTER] = -1;
	$ida->[$IDA_NAMES] = undef;
	$ida->[$IDA_ROWCOUNT] = 0;
	$ida->[$IDA_INITOFFSET] = 0;
	$ida->[$IDA_OFFSET] = 0;
	return 1;
}

sub first {
	my( $this ) = @_;
	my( $ida, $sql, $db, $resid, @row );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data in dataset' );
	}
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	return 1 if $ida->[$IDA_POINTER] == 0;
	$db = $ida->[$IDA_DB];
	if( $ida->[$IDA_POINTER] > 0 ) {
		if( $ida->[$IDA_POINTER] < $ida->[$IDA_ROWCOUNT] ) {
			$ida->[$IDA_RESULT]->row_seek( 0 ) or return 0;
		}
		else {
			$ida->[$IDA_OFFSET] = 0;
			$sql = $this->_prepare_query() or return 0;
			$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
			$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		}
	}
	@row = $ida->[$IDA_RESULT]->fetch_row() or return 0;
	$this->_apply( \@row );
	$ida->[$IDA_POINTER] = 0;
	return 1;
}

sub last {
	my( $this ) = @_;
	my( $ida, $sql, $db, $resid, @row );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data in dataset' );
	}
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	return 1 if $ida->[$IDA_POINTER] == $ida->[$IDA_ROWMAX] - 1;
	$db = $ida->[$IDA_DB];
	if( $ida->[$IDA_POINTER] < $ida->[$IDA_ROWMAX] - $ida->[$IDA_ROWCOUNT] - 1 ) {
		$ida->[$IDA_OFFSET] = $ida->[$IDA_ROWMAX] - $ida->[$IDA_LIMIT] - 1;
		$sql = $this->_prepare_query() or return 0;
		$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
	}
	$ida->[$IDA_RESULT]->row_seek( $ida->[$IDA_ROWCOUNT] - 1 ) or return 0;
	@row = $ida->[$IDA_RESULT]->fetch_row();
	$this->_apply( \@row );
	$ida->[$IDA_POINTER] = $ida->[$IDA_ROWMAX] - 1;
	return 1;
}

sub next {
	my( $this ) = @_;
	my( @row, $ida, $sql, $db );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data in dataset' );
	}
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	return 0 if $this->eof();
	if( $ida->[$IDA_POINTER] == $ida->[$IDA_OFFSET] + $ida->[$IDA_ROWCOUNT] - 1 ) {
		if( $ida->[$IDA_POINTER] == $ida->[$IDA_ROWMAX] - 1 ) {
			return -1;
		}
		$db = $ida->[$IDA_DB];
		$ida->[$IDA_OFFSET] += $ida->[$IDA_ROWCOUNT];
		$sql = $this->_prepare_query() or return 0;
		$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
	}
	@row = $ida->[$IDA_RESULT]->fetch_row()
		or return 0;
	$ida->[$IDA_POINTER] ++;
	$this->_apply( \@row );
	return 1;
}

sub prior {
	my( $this ) = @_;
	my( @row, $ida, $sql, $db );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data in dataset' );
	}
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	$db = $ida->[$IDA_DB];
	if( $ida->[$IDA_POINTER] == $ida->[$IDA_OFFSET] ) {
		if( $ida->[$IDA_POINTER] == 0 ) {
			return -1;
		}
		$ida->[$IDA_OFFSET] -= $ida->[$IDA_LIMIT];
		$ida->[$IDA_OFFSET] = 0 if $ida->[$IDA_OFFSET] < 0;
		$sql = $this->_prepare_query() or return 0;
		$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
	}
	else {
		$db->row_seek(
			$ida->[$IDA_RESULT],
			$ida->[$IDA_POINTER] - $ida->[$IDA_OFFSET] - 1
		) or return 0;
	}
	@row = $ida->[$IDA_RESULT]->fetch_row()
		or return 0;
	$ida->[$IDA_POINTER] --;
	$this->_apply( \@row );
	return 1;
}

sub move_by {
	my( $this, $offset ) = @_;
	my( $ida, $db, $sql );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data in dataset' );
	}
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	$db = $ida->[$IDA_DB];
	$offset = $ida->[$IDA_POINTER] + $offset;
	$offset = 0 if $offset < 0;
	$offset = $ida->[$IDA_ROWMAX] - 1 if $offset >= $ida->[$IDA_ROWMAX];
	return 1 if $offset == $ida->[$IDA_POINTER];
	if( $offset < $ida->[$IDA_OFFSET]
		|| $offset >= $ida->[$IDA_OFFSET] + $ida->[$IDA_LIMIT]
	) {
		$ida->[$IDA_OFFSET] = $offset - ( $offset % $ida->[$IDA_LIMIT] );
		$ida->[$IDA_OFFSET] = 0 if $ida->[$IDA_OFFSET] < 0;
		$sql = $this->_prepare_query() or return 0;
		$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		if( $offset != $ida->[$IDA_OFFSET] ) {
			$ida->[$IDA_RESULT]->row_seek( $offset - $ida->[$IDA_OFFSET] )
				or return 0;
		}
	}
	else {
		$ida->[$IDA_RESULT]->row_seek( $offset - $ida->[$IDA_OFFSET] )
			or return 0;
	}
	$ida->[$IDA_POINTER] = $offset;
	return 1;
}

sub edit {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	$this->_verify_dataset( 1 ) or return 0;
	return 1 if $ida->[$IDA_STATE] != dsBrowse;
	if( $ida->[$IDA_ROWCOUNT] <= 0 ) {
		return $this->_set_error( 'No data to edit' );
	}
	$ida->[$IDA_STATE] = dsEdit;
	return 1;
}

sub insert {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	$this->_verify_dataset( 1 ) or return 0;
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	$ida->[$IDA_SAVEPOINTER] = $ida->[$IDA_POINTER];
	$ida->[$IDA_POINTER] = $ida->[$IDA_ROWMAX];
	$ida->[$IDA_STATE] = dsInsert;
	foreach ( @{$ida->[$IDA_NAMES]} ) {
		delete $this->{ $_ };
	}
	$ida->[$IDA_SAFEFIELDS] = {};
	return 1;
}

sub insert_record {
	my( $this, $ida, $i, $names, $sfields );
	$this = shift;
	$ida = $this->{'__I#D#A__'};
	$this->_verify_dataset( 1 ) or return 0;
	if( $ida->[$IDA_STATE] != dsBrowse ) {
		$this->post() or return 0;
	}
	$this->_table_info() or return 0;
	$ida->[$IDA_SAVEPOINTER] = $ida->[$IDA_POINTER];
	$ida->[$IDA_POINTER] = $ida->[$IDA_ROWMAX];
	$ida->[$IDA_STATE] = dsInsert;
	$ida->[$IDA_SAFEFIELDS] = {};
	$names = $ida->[$IDA_NAMES];
	$sfields = $ida->[$IDA_SAFEFIELDS];
	for $i( 0 .. $#{$names} ) {
		$sfields->{$names->{$i}} = $this->{$names->{$i}} = $_[$i];
	}
	return $this->post();
}

sub post {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	return 1 if $ida->[$IDA_STATE] == dsBrowse;
	$this->_verify_dataset( 1 ) or return 0;
	$this->_table_info() or return 0;
	if( $ida->[$IDA_STATE] == dsEdit ) {
		# update data
		$this->_do_update() or return 0;
	}
	elsif( $ida->[$IDA_STATE] == dsInsert ) {
		# insert data
		$this->_do_insert() or return 0;
	}
	$ida->[$IDA_STATE] = dsBrowse;
	return 1;
}

sub cancel {
	my $this = shift;
	my( $ida, $sfields, $num_fields, $i, $key );
	$ida = $this->{'__I#D#A__'};
	return 1 if $ida->[$IDA_STATE] == dsBrowse;
	$this->_verify_dataset( 1 ) or return 0;
	if( $ida->[$IDA_STATE] == dsInsert ) {
		$ida->[$IDA_POINTER] = $ida->[$IDA_SAVEPOINTER];
	}
	$sfields = $ida->[$IDA_SAFEFIELDS];
	$num_fields = scalar @{ $ida->[$IDA_NAMES] };
	for $i( 0 .. $num_fields - 1 ) {
		$key = $ida->[$IDA_NAMES][$i];
		$this->{$key} = $sfields->{$key};
	}
	return 1;
}

sub delete {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	$this->_verify_dataset( 1 ) or return 0;
	$this->_table_info() or return 0;
	if( $ida->[$IDA_POINTER] > $ida->[$IDA_ROWMAX] ) {
		return $this->setError( 'Nothing to delete from here' );
	}
	$this->_do_delete() or return 0;
	$ida->[$IDA_ROWCOUNT] --;
	$ida->[$IDA_ROWMAX] --;
	$ida->[$IDA_STATE] = dsBrowse;
	$this->next() or return 0;
	$ida->[$IDA_POINTER] --;
	return 1;
}

sub bof {
	my( $this ) = @_;
	my $ida = $this->{'__I#D#A__'};
	return $ida->[$IDA_POINTER] <= $ida->[$IDA_INITOFFSET];
}

sub eof {
	my( $this ) = @_;
	my $ida = $this->{'__I#D#A__'};
	if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) == 0 ) {
		# using hard limit
		return $ida->[$IDA_POINTER] - $ida->[$IDA_OFFSET] >= $ida->[$IDA_ROWCOUNT] - 1;
	}
	return $ida->[$IDA_POINTER] >= $ida->[$IDA_ROWMAX] - 1;
}

sub fill {
	my $this = shift;
	my( $ida, $i, $field, $ref );
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_STATE] == dsBrowse ) {
		return $this->setError( 'Cannot use "fill" in BrowseMode' );
	}
	$ref = ref( $_[0] );
	if( $ref eq 'HASH' ) {
		foreach( keys %{$_[0]} ) {
			$this->{$_} = $_[0]->{$_};
		}
	}
	elsif( $ref eq 'ARRAY' ) {
		$i = 0;
		foreach( @{ $_[0] } ) {
			$field = $ida->[$IDA_NAMES][$i ++];
			$this->{$field} = $_;
		}
	}
	else {
		$i = 0;
		foreach( @_ ) {
			$field = $ida->[$IDA_NAMES][$i ++];
			$this->{$field} = $_;
		}
	}
	#$ida->[$IDA_STATUS] = 0;
	return 1;
}

sub refresh {
	my( $this ) = @_;
	return $this->_resync();
}

sub command_type {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		if( $ida->[$IDA_STATE] != dsBrowse ) {
			$this->post() or return 0;
		}
		$ida->[$IDA_CMD_TYPE] = $_[0] >= 1 && $_[0] <= 3 ? $_[0] : 1;
		if( $ida->[$IDA_ROWCOUNT] ) {
			$this->open() or return 0;
		}
	}
	return $ida->[$IDA_CMD_TYPE];
}

sub command_text {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		if( $ida->[$IDA_STATE] != dsBrowse ) {
			$this->post() or return 0;
		}
		$ida->[$IDA_CMD_TEXT_PLAIN] = $_[0];
		$ida->[$IDA_CMD_TEXT] = $this->_format_sql( $_[0] );
		if( $ida->[$IDA_ROWCOUNT] ) {
			$this->open() or return 0;
		}
	}
	return $ida->[$IDA_CMD_TEXT];
}

sub record_count {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	return $ida->[$IDA_ROWMAX];
}

sub current_record {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	return $ida->[$IDA_POINTER];
}

sub fields {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		return $ida->[$IDA_NAMES]->[$_[0]];
	}
	return @{$ida->[$IDA_NAMES]};
}

sub field_count {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	return scalar @{$ida->[$IDA_NAMES]};
}

sub filter {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		if( $ida->[$IDA_STATE] != dsBrowse ) {
			$this->post() or return 0;
		}
		$ida->[$IDA_FILTER] = $this->_format_sql( $_[0] );
#		if( $ida->[$IDA_ROWCOUNT] ) {
#			$this->open() or return 0;
#		}
	}
	return $ida->[$IDA_FILTER];
}

sub limit {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		if( $ida->[$IDA_STATE] != dsBrowse ) {
			$this->post() or return 0;
		}
#		return $ida->[$IDA_LIMIT] if $ida->[$IDA_LIMIT] == $_[0];
		$ida->[$IDA_LIMIT] = $_[0] > 0 ? $_[0] : 1;
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) != 0 ) {
			$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCLIMIT;
		}
#		if( $ida->[$IDA_ROWCOUNT] ) {
#			$this->open() or return 0;
#		}
	}
	return $ida->[$IDA_LIMIT];
}

sub offset {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( defined $_[0] ) {
		if( $ida->[$IDA_STATE] != dsBrowse ) {
			$this->post() or return 0;
		}
#		return $ida->[$IDA_OFFSET] if $ida->[$IDA_OFFSET] == $_[0];
		$ida->[$IDA_INITOFFSET] = $_[0];
#		$ida->[$IDA_OFFSET] = $_[0];
#		if( $ida->[$IDA_ROWCOUNT] ) {
#			$this->open() or return 0;
#		}
	}
	return $ida->[$IDA_OFFSET];
}

sub locate {
	my( $this, $ida, $db, $i, $tmp, $res, $sqlrows, $oo );
	$this = shift;
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	if( ! ref( $_[0] ) ) {
		$ida->[$IDA_SEARCH] = $db->quote_id( $_[0] )
			. ( defined $_[1] ? ' = ' . $db->quote( $_[1] ) : ' IS NULL' );
	}
	else {
		$tmp = '';
		$_[1] ||= [];
		for $i( 0 .. $#{$_[0]} ) {
			$tmp .= ' AND ' if $i;
			$tmp .= $db->quote_id( $_[0]->[$i] )
			. ( defined $_[1]->[$i] ? ' = ' . $db->quote( $_[1]->[$i] ) : ' IS NULL' );
		}
		$ida->[$IDA_SEARCH] = $tmp;
	}
	$oo = $ida->[$IDA_OFFSET];
	$ida->[$IDA_OFFSET] = 0;
	$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS;
	( $sqlrows, $tmp ) = $this->_prepare_query() or return 0;
	$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS;
	$res = $db->query( $tmp ) or return 0;
	if( $res->num_rows() ) {
		$ida->[$IDA_RESULT] = $res;
		$ida->[$IDA_ROWCOUNT] = $res->num_rows();
		$ida->[$IDA_NAMES] = [ $res->fetch_names() ];
		if( $sqlrows ) {
			$res = $db->query( $sqlrows ) or return 0;
			( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
		}
		else {
			$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
		}
		my @row = $ida->[$IDA_RESULT]->fetch_row() or return 0;
		$this->_apply( \@row );
		$ida->[$IDA_POINTER] = $ida->[$IDA_OFFSET];
	}
	else {
		$ida->[$IDA_OFFSET] = $oo;
		return 0;
	}
	return 1;
}

sub find_key {
	my( $this, $ida, $db, $i, $num_fields, $field, @pk, @uk, $tmp, $oo, $res,
		$sqlrows );
	$this = shift;
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$this->_table_info() or return 0;
	$num_fields = scalar @{ $ida->[$IDA_TABLE_INFO] };
	for $i( 0 .. $num_fields - 1 ) {
		$field = $ida->[$IDA_TABLE_INFO][$i];
		if( $field->[$PAB3::DB::DB_FIELD_PRIKEY] ) {
			push @pk, $field->[$PAB3::DB::DB_FIELD_NAME];
		}
		elsif( $field->[$PAB3::DB::DB_FIELD_UNIKEY] ) {
			push @uk, $field->[$PAB3::DB::DB_FIELD_NAME];
		}
	}
	if( @pk ) {
		for $i( 0 .. $#pk ) {
			$tmp .= ' AND ' if $i;
			$tmp .= $db->quote_id( $pk[$i] )
				. ( defined $_[$i] ? ' = ' . $db->quote( $_[$i] ) : ' IS NULL' );
		}
		$ida->[$IDA_SEARCH] = $tmp;
	}
	elsif( @uk ) {
		for $i( 0 .. $#uk ) {
			$tmp .= ' AND ' if $i;
			$tmp .= $db->quote_id( $uk[$i] )
				. ( defined $_[$i] ? ' = ' . $db->quote( $_[$i] ) : ' IS NULL' );
		}
		$ida->[$IDA_SEARCH] = $tmp;
	}
	else {
		return 0;
	}
	$oo = $ida->[$IDA_OFFSET];
	$ida->[$IDA_OFFSET] = 0;
	$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS;
	( $sqlrows, $tmp ) = $this->_prepare_query() or return 0;
	$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS;
	$res = $db->query( $tmp ) or return 0;
	if( $res->num_rows() ) {
		$ida->[$IDA_RESULT] = $res;
		$ida->[$IDA_ROWCOUNT] = $res->num_rows();
		$ida->[$IDA_NAMES] = [ $res->fetch_names() ];
		if( $sqlrows ) {
			$res = $db->query( $sqlrows ) or return 0;
			( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
		}
		else {
			$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
		}
		my @row = $ida->[$IDA_RESULT]->fetch_row() or return 0;
		$this->_apply( \@row );
		$ida->[$IDA_POINTER] = $ida->[$IDA_OFFSET];
	}
	else {
		$ida->[$IDA_OFFSET] = $oo;
		return 0;
	}
	return 1;
}

sub index_defs {
	my( $this, $ida, $db, %index, $key, @index );
	$this = shift;
	$ida = $this->{'__I#D#A__'};
	if( $ida->[$IDA_CMD_TYPE] != ctTable ) {
		return $this->_set_error( 'Not available on a non TABLE dataset' );
	}
	$db = $ida->[$IDA_DB];
	return $ida->[$IDA_KEY_INFO] if $ida->[$IDA_KEY_INFO];
	foreach( $db->show_index( $ida->[$IDA_CMD_TEXT_PLAIN] ) ) {
		$key = $_->[$PAB3::DB::DB_INDEX_NAME];
		if( ! $index{$key} ) {
			$index{$key} = {
				'name' => $key,
				'fields' => $_->[$PAB3::DB::DB_INDEX_COLUMN],
				'type' => $_->[$PAB3::DB::DB_INDEX_TYPE]
			};
			push @index, $index{$key};
		}
		else {
			$index{$key}->{'fields'} .= ';' . $_->[$PAB3::DB::DB_INDEX_COLUMN];
		}
	}
	$ida->[$IDA_KEY_INFO] = \@index;
	return $ida->[$IDA_KEY_INFO];
}

sub register_loop {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	# my( $loopid [, $objectname [, $clspab]] )
	my $object = $_[1] || $ida->[$IDA_OBJECTNAME];
	my $pab = $_[2] || $ida->[$IDA_PAB];
	if( ! $_[0] || ! $object || ! $pab || ref( $pab ) !~ /PAB/ ) {
		&Carp::croak( 'Usage: register_loop( $loopid [, $objectname [, $clspab]] )' );
	}
	$pab->register_loop( $_[0], 'next', PAB3::FUNC, undef, undef, $object )
		or return $this->_set_error( $pab->error() );
	return 1;
}

sub register_loop_enum {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	# my( $loopid [, $record_name [, $objectname [, $clspab]]] )
	my $object = $_[2] || $ida->[$IDA_OBJECTNAME];
	my $pab = $_[3] || $ida->[$IDA_PAB];
	if( ! $_[0] || ! $object || ! $pab || ref( $pab ) !~ /PAB/ ) {
		&Carp::croak(
			'Usage: register_loop_enum( $loopid [ $recordname [, $objectname [, $clspab]]] )'
		);
	}
	$pab->register_loop( $_[0], '_enum', PAB3::FUNC, $_[1], PAB3::SCALAR, $object )
		or return $this->_set_error( $pab->error() );
	return 1;
}

sub register_loop_mapped {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	# my( $loopid [, $record_name [, $objectname [, $clspab]]] )
	my $object = $_[2] || $ida->[$IDA_OBJECTNAME];
	my $pab = $_[3] || $ida->[$IDA_PAB];
	if( ! $_[0] || ! $object || ! $pab || ref( $pab ) !~ /PAB/ ) {
		&Carp::croak(
			'Usage: register_loop_mapped( $loopid [, $record_name [, $objectname [, $clspab]]] )'
		);
	}
	$pab->register_loop( $_[0], '_enum_mapped', PAB3::FUNC, $_[1], PAB3::SCALAR, $object )
		or return $this->_set_error( $pab->error() );
	$pab->add_hashmap( $_[0], $_[1], $ida->[$IDA_NAMES] )
		or return $this->_set_error( $pab->error() );
	return 1;
}

sub _enum {
	my $this = shift;
	my( $ida, $sql, $sqlrows, $db, $res, %row );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	if( $ida->[$IDA_ENUMPOINTER] < $ida->[$IDA_OFFSET] ) {
		if( $ida->[$IDA_OFFSET] == $ida->[$IDA_INITOFFSET] && $ida->[$IDA_RESULT] ) {
			$ida->[$IDA_RESULT]->row_seek( 0 )
				or return $this->_set_error( $db->error() );
			%row = $ida->[$IDA_RESULT]->fetch_hash()
				or return $this->_set_error( $db->error() );
			$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_OFFSET];
			return \%row;
		}
		$ida->[$IDA_OFFSET] = $ida->[$IDA_INITOFFSET];
		$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS;
		( $sqlrows, $sql ) = $this->_prepare_query() or return 0;
		$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS;
		$ida->[$IDA_RESULT] = $db->query( $sql )
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		$ida->[$IDA_NAMES] = [ $ida->[$IDA_RESULT]->fetch_names() ];
		if( $sqlrows ) {
			$res = $db->query( $sqlrows )
				or return $this->_set_error( $db->error() );
			( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
		}
		else {
			$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
		}
		%row = $ida->[$IDA_RESULT]->fetch_hash()
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_OFFSET];
		# calculate buffer
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) != 0 ) {
			my @l = $ida->[$IDA_RESULT]->fetch_lengths();
			my $len = 0;
			$len += $_ foreach @l;
			$ida->[$IDA_LIMIT] = int( $DATA_MAX_SIZE / ( $len * 2 ) );
			$ida->[$IDA_LIMIT] = 1 if $ida->[$IDA_LIMIT] < 1;
		}
		return \%row;
	}
	else {
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) == 0 ) {
			goto resetenum
				if $ida->[$IDA_ENUMPOINTER] - $ida->[$IDA_OFFSET] >= $ida->[$IDA_ROWCOUNT] - 1;
		}
		if( $ida->[$IDA_ENUMPOINTER] == $ida->[$IDA_OFFSET] + $ida->[$IDA_ROWCOUNT] - 1 ) {
			goto resetenum
				if $ida->[$IDA_ENUMPOINTER] >= $ida->[$IDA_ROWMAX] - 1;
			$ida->[$IDA_OFFSET] += $ida->[$IDA_ROWCOUNT];
			$sql = $this->_prepare_query() or return 0;
			$ida->[$IDA_RESULT] = $db->query( $sql )
				or return $this->_set_error( $db->error() );
			$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		}
		%row = $ida->[$IDA_RESULT]->fetch_hash()
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ENUMPOINTER] ++;
		return \%row;
	}
resetenum:
	$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_INITOFFSET];
	return 0;
}

sub _enum_mapped {
	my $this = shift;
	my( $ida, $sql, $sqlrows, $db, $res, @row );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	if( $ida->[$IDA_ENUMPOINTER] < $ida->[$IDA_OFFSET] ) {
		if( $ida->[$IDA_OFFSET] == $ida->[$IDA_INITOFFSET] && $ida->[$IDA_RESULT] ) {
			$ida->[$IDA_RESULT]->row_seek( 0 )
				or return $this->_set_error( $db->error() );
			@row = $ida->[$IDA_RESULT]->fetch_row()
				or return $this->_set_error( $db->error() );
			$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_OFFSET];
			return \@row;
		}
		$ida->[$IDA_OFFSET] = $ida->[$IDA_INITOFFSET];
		$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS;
		( $sqlrows, $sql ) = $this->_prepare_query() or return 0;
		$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS;
		$ida->[$IDA_RESULT] = $db->query( $sql )
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		$ida->[$IDA_NAMES] = [ $ida->[$IDA_RESULT]->fetch_names() ];
		if( $sqlrows ) {
			$res = $db->query( $sqlrows )
				or return $this->_set_error( $db->error() );
			( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
		}
		else {
			$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
		}
		@row = $ida->[$IDA_RESULT]->fetch_row()
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_OFFSET];
		# calculate buffer
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) != 0 ) {
			my @l = $ida->[$IDA_RESULT]->fetch_lengths();
			my $len = 0;
			$len += $_ foreach @l;
			$ida->[$IDA_LIMIT] = int( $DATA_MAX_SIZE / ( $len * 2 ) );
			$ida->[$IDA_LIMIT] = 1 if $ida->[$IDA_LIMIT] < 1;
		}
		return \@row;
	}
	else {
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCLIMIT ) == 0 ) {
			goto resetenum
				if $ida->[$IDA_ENUMPOINTER] - $ida->[$IDA_OFFSET] >= $ida->[$IDA_ROWCOUNT] - 1;
		}
		if( $ida->[$IDA_ENUMPOINTER] == $ida->[$IDA_OFFSET] + $ida->[$IDA_ROWCOUNT] - 1 ) {
			goto resetenum
				if $ida->[$IDA_ENUMPOINTER] >= $ida->[$IDA_ROWMAX] - 1;
			$ida->[$IDA_OFFSET] += $ida->[$IDA_ROWCOUNT];
			$sql = $this->_prepare_query() or return 0;
			$ida->[$IDA_RESULT] = $db->query( $sql )
				or return $this->_set_error( $db->error() );
			$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
		}
		@row = $ida->[$IDA_RESULT]->fetch_row()
			or return $this->_set_error( $db->error() );
		$ida->[$IDA_ENUMPOINTER] ++;
		return \@row;
	}
resetenum:
	$ida->[$IDA_ENUMPOINTER] = $ida->[$IDA_INITOFFSET];
	return 0;
}

sub error {
	my $this = shift;
	return $LastError if ! ref( $this );
	my $ida = $this->{'__I#D#A__'};
	return $ida->[$IDA_ERROR] if $ida->[$IDA_ERROR];
	return $ida->[$IDA_DB]->error();
}

sub _set_error {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	$ida->[$IDA_ERROR] = $_[0];
	&Carp::croak( $_[0] );
	return 0;
}

sub _apply {
	my $this = shift;
	my( $ida, $sfields, $i, $field, $ref );
	$ida = $this->{'__I#D#A__'};
	$sfields = $ida->[$IDA_SAFEFIELDS];
	$ref = ref( $_[0] );
	if( $ref eq 'HASH' ) {
		foreach( keys %{$_[0]} ) {
			$this->{$_} = $_[0]->{$_};
			$sfields->{$_} = $_[0]->{$_};
		}
	}
	elsif( $ref eq 'ARRAY' ) {
		$i = 0;
		foreach( @{ $_[0] } ) {
			$field = $ida->[$IDA_NAMES][$i ++];
			$this->{$field} = $_;
			$sfields->{$field} = $_;
		}
	}
	else {
		$i = 0;
		foreach( @_ ) {
			$field = $ida->[$IDA_NAMES][$i ++];
			$this->{$field} = $_;
			$sfields->{$field} = $_;
		}
	}
	return 1;
}

sub _resync {
	my( $this, $type ) = @_;
	my( $ida, $db, $sql, $sqlrows, $res );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$ida->[$IDA_OPTIONS] |= $IDA_OPT_CALCROWS if $type == 1;
	( $sqlrows, $sql ) = $this->_prepare_query() or return 0;
	$ida->[$IDA_OPTIONS] ^= $IDA_OPT_CALCROWS if $type == 1;
	$ida->[$IDA_RESULT] = $db->query( $sql ) or return 0;
	$ida->[$IDA_ROWCOUNT] = $ida->[$IDA_RESULT]->num_rows();
	if( $type == 1 ) {
		if( $sqlrows ) {
			$res = $db->query( $sqlrows ) or return 0;
			( $ida->[$IDA_ROWMAX] ) = $res->fetch_row();
		}
		else {
			$ida->[$IDA_ROWMAX] = $ida->[$IDA_ROWCOUNT];
		}
	}
	if( $ida->[$IDA_POINTER] >= $ida->[$IDA_ROWMAX] ) {
		$ida->[$IDA_POINTER] = $ida->[$IDA_ROWMAX] - 1;
	}
	return 1;
}

sub _do_update {
	my $this = shift;
	my(
		$ida, $num_fields, $field, $key, $i, @update, @save, $clausel, $db,
		$sfields, $sql, $hr, @pk, @uk
	);
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$sfields = $ida->[$IDA_SAFEFIELDS];
	$num_fields = scalar @{ $ida->[$IDA_TABLE_INFO] };
	for $i( 0 .. $num_fields - 1 ) {
		$field = $ida->[$IDA_TABLE_INFO][$i];
		$key = $field->[$PAB3::DB::DB_FIELD_NAME];
		if( ! defined $this->{$key} ) {
			if( $field->[$PAB3::DB::DB_FIELD_NULLABLE] ) {
				if( defined $sfields->{$key} ) {
					push @update,
						$db->quote_id( $key ) . ' = NULL';
					$save[$i] = undef;
				}
			}
			elsif( ! defined $sfields->{$key} ) {
				push @update,
					$db->quote_id( $key )
						. ' = ' . $db->quote( $field->[$PAB3::DB::DB_FIELD_DEFAULT] );
				$save[$i] = $field->[$PAB3::DB::DB_FIELD_DEFAULT];
			}
		}
		elsif( ! defined $sfields->{$key}
			|| $sfields->{$key} ne $this->{$key}
		) {
			push @update,
				$db->quote_id( $key )
					. ' = ' . $db->quote( $this->{$key} );
			$save[$i] = $this->{$key};
		}
		else {
			$save[$i] = $this->{$key};
		}
		if( $field->[$PAB3::DB::DB_FIELD_PRIKEY] ) {
			push @pk, $key;
		}
		elsif( $field->[$PAB3::DB::DB_FIELD_UNIKEY] ) {
			push @uk, $key;
		}
	}
	return 1 if ! @update;
	@pk = @uk if ! @pk;
	$clausel = '';
	if( @pk ) {
		foreach $key( @pk ) {
			if( exists( $sfields->{$key} ) ) {
				$clausel .= ' AND ' if $clausel;
				$clausel .= $db->quote_id( $key )
					. ' = ' . $db->quote( $sfields->{$key} );
			}
		}
	}
	if( ! $clausel ) {
		foreach $key( keys %$sfields ) {
			if( exists( $sfields->{$key} ) ) {
				$clausel .= ' AND ' if $clausel;
				$clausel .= $db->quote_id( $key )
					. ' = ' . $db->quote( $sfields->{$key} );
			}
		}
	}
	return if ! $clausel;
	$sql =
		'UPDATE ' .
		$ida->[$IDA_CMD_TEXT] .
		' SET ' .
		join( ', ', @update ) .
		' WHERE ' .
		$clausel
	;
	$db->query( $sql ) or return 0;
	for $i( 0 .. $num_fields - 1 ) {
		$ida->[$IDA_SAFEFIELDS]->{ $ida->[$IDA_NAMES][$i] } = $save[$i];
	}
	return 1;
}

sub _do_insert {
	my $this = shift;
	my( $db, $sql, $ida, $num_fields, $field, $key, $i, @ainc, $sfields,
		@key, @insert, @mark, $hr, $stmt
	);
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$sfields = $ida->[$IDA_SAFEFIELDS];
	$num_fields = scalar @{ $ida->[$IDA_NAMES] };
	for $i( 0 .. $num_fields - 1 ) {
		$field = $ida->[$IDA_TABLE_INFO][$i];
		$key = $field->[$PAB3::DB::DB_FIELD_NAME];
		if( $field->[$PAB3::DB::DB_FIELD_IDENTITY] && ! $this->{$key} ) {
			push @ainc, $key;
			next;
		}
		push @key, $db->quote_id( $key );
		push @mark, '?';
		if( ! defined $this->{$key} ) {
			if( $field->[$PAB3::DB::DB_FIELD_NULLABLE] ) {
				push @insert, undef;
			}
			else {
				push @insert, $field->[$PAB3::DB::DB_FIELD_DEFAULT];
			}
		}
		else {
			push @insert, $this->{$key};
		}
		$sfields->{$key} = $this->{$key};
	}
	$sql =
		'INSERT INTO ' .
		$ida->[$IDA_CMD_TEXT] .
		' ( ' . join( ', ', @key ) . ' ) ' .
		'VALUES( ' . join( ', ', @mark ) . ' )';
	$stmt = $db->prepare( $sql ) or return 0;
	$stmt->execute( @insert ) or return 0;
	foreach( @ainc ) {
		$i = $db->insert_id( $_, $ida->[$IDA_CMD_TEXT_PLAIN] );
		if( defined $i && $i > 0 ) {
			$this->{$_} = $sfields->{$_} = $i;
		}
	}
	$ida->[$IDA_OFFSET] = $ida->[$IDA_ROWMAX] - $ida->[$IDA_LIMIT];
	$this->_resync( 1 ) or return 0;
	return 1;
}

sub _do_delete {
	my $this = shift;
	my( $db, $sql, $ida, $key, $field, $num_fields, $i, @pk, @uk, $clausel );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$num_fields = scalar @{ $ida->[$IDA_TABLE_INFO] };
	for $i( 0 .. $num_fields - 1 ) {
		$field = $ida->[$IDA_TABLE_INFO][$i];
		$key = $field->[$PAB3::DB::DB_FIELD_NAME];
		if( $field->[$PAB3::DB::DB_FIELD_PRIKEY] ) {
			push @pk, $key;
		}
		elsif( $field->[$PAB3::DB::DB_FIELD_UNIKEY] ) {
			push @uk, $key;
		}
	}
	@pk = @uk if ! @pk;
	if( @pk ) {
		$clausel = '';
		foreach $key( @pk ) {
			if( defined $this->{$key} ) {
				$clausel .= ' AND ' if $clausel;
				$clausel .= $db->quote_id( $key )
					. ' = ' . $db->quote( $this->{$key} );
			}
		}
	}
	if( ! $clausel ) {
		$clausel = '';
		foreach $key( @{ $ida->[$IDA_NAMES] } ) {
			if( defined $this->{$key} ) {
				$clausel .= ' AND ' if $clausel;
				$clausel .= $db->quote_id( $key )
					. ' = ' . $db->quote( $this->{$key} );
			}
		}
	}
	if( $clausel ) {
		$sql =
			'DELETE FROM '
			. $ida->[$IDA_CMD_TEXT]
			. ' WHERE '
			. $clausel;
		$db->query( $sql ) or return 0;
		return 1;
	}
	return 0;
}

sub _table_info {
	my( $this ) = @_;
	my( $ida, $db, $field, @tabinf );
	$ida = $this->{'__I#D#A__'};
	return 1 if $ida->[$IDA_LAST_CMD] eq $ida->[$IDA_CMD_TEXT];
	$db = $ida->[$IDA_DB];
	@tabinf = ();
	foreach $field( $db->show_fields( $ida->[$IDA_CMD_TEXT] ) ) {
		push @tabinf, $field;
	}
	$ida->[$IDA_TABLE_INFO] = \@tabinf;
	$ida->[$IDA_LAST_CMD] = $ida->[$IDA_CMD_TEXT];
	return 1;
}

sub _prepare_query {
	my( $this ) = @_;
	my( $ida, $db, $sql, $sql2 );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	$this->_verify_dataset() or return 0;
	if( $ida->[$IDA_CMD_TYPE] == ctQuery ) {
		$sql = $ida->[$IDA_CMD_TEXT];
		$sql2 = '';
	}
	elsif( $ida->[$IDA_CMD_TYPE] == ctTable ) {
		$sql = 'SELECT * FROM ' . $db->quote_id( $ida->[$IDA_CMD_TEXT] ) . ' WHERE 1';
		if( $ida->[$IDA_FILTER] ) {
			$sql .= ' AND ( ' . $ida->[$IDA_FILTER] . ' )';
		}
		if( $ida->[$IDA_SEARCH] ) {
			$sql .= ' AND ( ' . $ida->[$IDA_SEARCH] . ' )';
		}
		if( ( $ida->[$IDA_OPTIONS] & $IDA_OPT_CALCROWS ) != 0 ) {
			$sql2 = $db->sql_calc_rows( $sql );
			$sql = $db->sql_pre_calc_rows( $sql );
		}
		else {
			$sql2 = '';
		}
		$sql = $db->sql_limit( $sql, $ida->[$IDA_LIMIT], $ida->[$IDA_OFFSET] );
	}
	elsif( $ida->[$IDA_CMD_TYPE] == ctStoredProcedure ) {
		return $this->_set_error( "CommandType 'ctSoredProcedure' ist not supported yet" );
	}
	return ( $sql2, $sql );
}

sub _verify_dataset {
	my $this = shift;
	my $ida = $this->{'__I#D#A__'};
	if( $_[0] ) {
		# want edit
		if( $ida->[$IDA_CMD_TYPE] != ctTable ) {
			return $this->_set_error( 'Cannot modify a non TABLE dataset' );
		}
	}
	if( ! $ida->[$IDA_CMD_TEXT] ) {
		return $this->_set_error( '"CommandText" is undefined' );
	}
	return 1;
}

sub _format_sql {
	my $this = shift;
	my( $ida, $db, $res, @fs, $step, $lp, $i );
	$ida = $this->{'__I#D#A__'};
	$db = $ida->[$IDA_DB];
	@fs = split( //, $_[0] );
	$res = '';
	$step = 0;
	for $i( 0 .. $#fs ) {
		if( $step == 0 ) {
			if( $fs[$i] eq '\'' ) {
				$step = 1;
			}
			elsif( $fs[$i] eq '[' ) {
				$lp = $i + 1;
				$step = 2;
				next;
			}
			$res .= $fs[$i];
		}
		elsif( $step == 1 ) {
			if( $fs[$i] eq '\'' ) {
				if( $fs[$i + 1] eq '\'' ) {
					$res .= '\'\'';
					$i ++;
					next;
				}
				elsif( $fs[$i - 1] eq '\\' ) {
					$res .= '\'';
					next;
				}
				else {
					$step = 0;
				}
			}
			$res .= $fs[$i];
		}
		elsif( $step == 2 ) {
			if( $fs[$i] eq ']' ) {
				$res .= $db->quote_id( substr( $_[0], $lp, $i - $lp ) );
				$step = 0;
				next;
			}
		}
	}
	return $res;
}


__END__
