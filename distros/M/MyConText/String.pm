
package MyConText::String;
use MyConText;
use strict;
use vars qw! @ISA !;
@ISA = qw! MyConText !;

# Create creates the conversion table that converts string names of
# documents to numbers
sub _create_tables {
	my $ctx = shift;
	$ctx->{'doc_id_table'} = $ctx->{'table'} . '_docid'
			unless defined $ctx->{'doc_id_table'};

	my $CREATE_DOCID = <<EOF;
		create table $ctx->{'doc_id_table'} (
			name varchar($ctx->{'name_length'}) binary not null,
			id $MyConText::BITS_TO_INT{$ctx->{'doc_id_bits'}} unsigned not null auto_increment,
			primary key (id),
			unique (name)
			)
EOF
	my $dbh = $ctx->{'dbh'};
	$dbh->do($CREATE_DOCID) or return $dbh->errstr;
	push @{$ctx->{'created_tables'}}, $ctx->{'doc_id_table'};
	return;
	}

sub get_id_for_name {
	my ($self, $string) = @_;
	my $dbh = $self->{'dbh'};
	my $doc_id_table = $self->{'doc_id_table'};

	my $name_to_id_sth = ( defined $self->{'name_to_id_sth'}
		? $self->{'name_to_id_sth'}
		: $self->{'name_to_id_sth'} = $dbh->prepare("select id from $doc_id_table where name = ?") or die $dbh->errstr);
	my $id = $dbh->selectrow_array($name_to_id_sth, {}, $string);
	if (not defined $id) {
		my $new_name_sth = (defined $self->{'new_name_sth'}
			? $self->{'new_name_sth'}
			: $self->{'new_name_sth'} =
			$dbh->prepare("insert into $doc_id_table values (?, null)") or die $dbh->errstr );
		$new_name_sth->execute($string) or die $new_name_sth->errstr;
		$id = $new_name_sth->{'mysql_insertid'};
		}
	$id;
	}
sub index_document {
	my ($self, $string, $data) = @_;
	my $id = $self->get_id_for_name($string);
	$self->SUPER::index_document($id, $data);
	}

sub contains_hashref {
	my $self = shift;
	my $res = $self->SUPER::contains_hashref(@_);
	return unless keys %$res;

	my $doc_id_table = $self->{'doc_id_table'};

	my $data = $self->{'dbh'}->selectall_arrayref("select name, id from $doc_id_table where " . join(' or ', ('id = ?') x keys %$res), {}, keys %$res);
	return { map { ( $_->[0], $res->{$_->[1]} ) } @$data };
	}


1;

