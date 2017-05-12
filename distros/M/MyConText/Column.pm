
package MyConText::Column;
use strict;

# Open in the backend just sets the object
sub open {
	my ($class, $ctx) = @_;
	return bless { 'ctx' => $ctx }, $class;
	}
# Create creates the table(s) according to the parameters
sub _create_tables {
	my ($class, $ctx) = @_;
	my $COUNT_FIELD = '';
	if ($ctx->{'count_bits'}) {
		$COUNT_FIELD = "count $MyConText::BITS_TO_INT{$ctx->{'count_bits'}} unsigned,"
		}
	my $CREATE_DATA = <<EOF;
		create table $ctx->{'data_table'} (
			word_id $MyConText::BITS_TO_INT{$ctx->{'word_id_bits'}} unsigned not null,
			doc_id $MyConText::BITS_TO_INT{$ctx->{'doc_id_bits'}} unsigned not null,
			$COUNT_FIELD
			index (word_id),
			index (doc_id)
		)
EOF

	$ctx->{'word_id_table'} = $ctx->{'table'}.'_words'
				unless defined $ctx->{'word_id_table'};
	
	
	my $CREATE_WORD_ID = <<EOF;
		create table $ctx->{'word_id_table'} (
			word varchar($ctx->{'word_length'}) binary
				default '' not null,
			id $MyConText::BITS_TO_INT{$ctx->{'word_id_bits'}} unsigned not null auto_increment,
			primary key (id),
			unique (word)
			)
EOF

	my $dbh = $ctx->{'dbh'};
        $dbh->do($CREATE_DATA) or return $dbh->errstr;
	push @{$ctx->{'created_tables'}}, $ctx->{'data_table'};
        $dbh->do($CREATE_WORD_ID) or return $dbh->errstr;
	push @{$ctx->{'created_tables'}}, $ctx->{'word_id_table'};
	return;
	}
sub add_document {
	my ($self, $id, $words) = @_;
	my $ctx = $self->{'ctx'};
	my $dbh = $ctx->{'dbh'};
	my $data_table = $ctx->{'data_table'};
	my $word_id_table = $ctx->{'word_id_table'};
	if (not defined $self->{'insert_wordid_sth'}) {
		$self->{'insert_wordid_sth'} = $dbh->prepare("
			insert into $word_id_table (word) values (?)
			");
		$self->{'insert_wordid_sth'}->{'PrintError'} = 0;
		$self->{'insert_wordid_sth'}->{'RaiseError'} = 0;
		}
	my $insert_wordid_sth = $self->{'insert_wordid_sth'};

	my $count_bits = $ctx->{'count_bits'};
	my $insert_worddoc_sth = ( defined $self->{'insert_worddoc_sth'}
		? $self->{'insert_worddoc_sth'}
		: $self->{'insert_worddoc_sth'} = (
			$count_bits
			? $dbh->prepare("
				insert into $data_table
				select id, ?, ? from $word_id_table
					where word = ?")
			: $dbh->prepare("
				insert into $data_table
				select id, ?, from $word_id_table
					where word = ?")
			) );
	my $num_words = 0;
	for my $word ( keys %$words ) {
		$insert_wordid_sth->execute($word);
		if ($count_bits) {
			$insert_worddoc_sth->execute($id, $words->{$word}, $word);
			}
		else {
			$insert_worddoc_sth->execute($id, $word);
			}
		$num_words += $words->{$word};
		}
	return $num_words;
	}
sub delete_document {
	my $self = shift;
	my $ctx = $self->{'ctx'};
	my $dbh = $ctx->{'dbh'};
	my $data_table = $ctx->{'data_table'};
	my $sth = $dbh->prepare("delete from $data_table where doc_id = ?");
	for my $id (@_) { $sth->execute($id); }
	}
sub update_document {
	my ($self, $id, $words) = @_;
	$self->delete_document($id);
	$self->add_document($id, $words);
	}
sub contains_hashref {
	my $self = shift;
	my $ctx = $self->{'ctx'};
	my $dbh = $ctx->{'dbh'};
	my $data_table = $ctx->{'data_table'};
	my $word_id_table = $ctx->{'word_id_table'};

	my $count_bits = $ctx->{'count_bits'};
	my $sth = ( defined $self->{'get_data_sth'}
		? $self->{'get_data_sth'}
		: ( $count_bits
		? $self->{'get_data_sth'} = $dbh->prepare(
			"select doc_id, count
			from $data_table, $word_id_table
			where word like ?
				and id = word_id" )
		: $self->{'get_data_sth'} = $dbh->prepare(
			"select doc_id, 1
			from $data_table, $word_id_table
			where word like ?
				and id = word_id" )
			) );

	my $out = {};
	for my $word (@_) {
		$sth->execute($word);
		while (my ($doc, $count) = $sth->fetchrow_array) {
			$out->{$doc} += $count;
			}
		$sth->finish;
		}
        $out;
	}

*parse_and_index_data = \&MyConText::parse_and_index_data_count;

1;

