
package MyConText::Phrase;
use strict;
use MyConText::Column;
use vars qw! @ISA !;
@ISA = qw! MyConText::Column !;

# Open in the backend just sets the object
sub open {
	my ($class, $ctx) = @_;
	return bless { 'ctx' => $ctx }, $class;
	}
# Create creates the table(s) according to the parameters
sub _create_tables {
	my ($class, $ctx) = @_;
	my $COUNT_FIELD = '';
	my $CREATE_DATA = <<EOF;
		create table $ctx->{'data_table'} (
			word_id $MyConText::BITS_TO_INT{$ctx->{'word_id_bits'}} unsigned not null,
			doc_id $MyConText::BITS_TO_INT{$ctx->{'doc_id_bits'}} unsigned not null,
			idx longblob default '' not null,
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
		# here the value in the %$words hash is an array of word
		# positions
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
		: $self->{'insert_worddoc_sth'} = 
			$dbh->prepare("
				insert into $data_table
				select id, ?, ? from $word_id_table
					where word = ?")
			);
        
	my $packstring = $MyConText::BITS_TO_PACK{$ctx->{'position_bits'}};

	my $num_words = 0;
	for my $word ( keys %$words ) {
		$insert_wordid_sth->execute($word);
		my $values = pack $packstring.'*', @{$words->{$word}};
		$insert_worddoc_sth->execute($id, $values, $word);
		$num_words++;
		}
	return $num_words;
	}
sub update_document {
	my ($self, $id, $words) = @_;
	my $ctx = $self->{'ctx'};
	my $dbh = $ctx->{'dbh'};
	my $data_table = $ctx->{'data_table'};
	$dbh->do("delete from $data_table where doc_id = ?", {}, $id);

	$self->add_document($id, $words);
	}
sub contains_hashref {
	my $self = shift;
	my $ctx = $self->{'ctx'};
	my $dbh = $ctx->{'dbh'};
	my $data_table = $ctx->{'data_table'};
	my $word_id_table = $ctx->{'word_id_table'};

	my $packstring = $MyConText::BITS_TO_PACK{$ctx->{'position_bits'}};


	my $SQL = <<"EOF";
		select doc_id, idx
		from $data_table, $word_id_table
		where word like ?
			and id = word_id
		order by doc_id
EOF
	my @sths;
	for (my $i = 0; $i < @_; $i++) {
		$sths[$i] = $dbh->prepare($SQL);
		$sths[$i]->execute($_[$i]);
		}

	my (@overflow, @finished) = ((), ());
	my $finished_count = 0;

	my $out = {};

	my $i = 0;
	my $actdoc;
	my (%word_out, %doc_out) = ((), ());

	# budeme cyklit; promenna $i rika, ktere slovo prave
	# zpracovavame
	while ($finished_count < @_) {
		my ($doc, $data);
		# pokud mame neco ulozeno z predchoziho behu, nasosneme
		if (defined $overflow[$i]) {
			($doc, $data) = @{$overflow[$i]};
			$overflow[$i] = undef;
			}
		# jinak nacteme z databaze
		else {
			($doc, $data) = $sths[$i]->fetchrow_array;
			if (not defined $doc) {
				$finished_count++ unless defined $finished[$i];
				$finished[$i] = 1;
				}
			}

		# bud jde o dalsi data pro ten samy dokument, nebo jde o
		# data pro dalsi dokument, nebo pro toto slovo uz zadna
		# data pro zadny dokument nejsou
		if (not defined $doc or (defined $actdoc and $doc != $actdoc)) {
			# pokud jde o data dalsiho dokumentu, ulozime si je
			$overflow[$i] = [ $doc, $data ];
			if ($i == 0) { %doc_out = %word_out; }
			else {
				# protoze prechazime na dalsi slovo,
				# zjistime, co z doc_out zbylo
				my %tmp;
				for (keys %doc_out) {
					if (not exists $word_out{$_+$i}) {
						$tmp{$_} = 1;
						}
					}
				for (keys %tmp) { delete $doc_out{$_}; }
				}
			
			# kazdopadne prejdeme na dalsi slovo (pro ten
			# samy dokument)
			$i++;
			%word_out = ();
			if ($i >= @_) {
				# pokud uz jsme pro dany dokument prosli
				# vsechna slova
				$i = 0;
				$out->{$actdoc} = scalar(keys %doc_out)
							if keys %doc_out;
				%doc_out = ();
				$actdoc = undef;
				}

			next;	
			}

		$actdoc = $doc;
		my @values = unpack $packstring.'*', $data;
		%word_out = (%word_out, map { ( $_ => 1 ) } @values);
		}
	
	for (my $i = 0; $i < @_; $i++) {
		$sths[$i]->finish;
		}
        
	$out;
	}

*parse_and_index_data = \&MyConText::parse_and_index_data_list;

1;

