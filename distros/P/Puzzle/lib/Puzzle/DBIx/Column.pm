package Puzzle::DBIx::Column;


our $VERSION = '0.02';

use base 'Class::DBI::Column';
use Puzzle::DBIx::sysMetaschema;

sub label {
	my $self = shift;
	return $self->{label} if ($self->{label});
	$self->_retrive_label;
	return $self->{label};
}

sub _retrive_label {
	$self						= shift;
	my $rec					= Puzzle::DBIx::sysMetaschema->retrieve($self->name);
	if ($rec) {
		$self->{label}	= $rec->txt_label;
	} else {
		my $name = $self->name;
		# lo so che non e' cosa buona questa ma funziona
		$self->{label} = qq|<a title="Aggiungi la descrizione corretta a questo campo" href="/gestione/metaschema/crud.mpl?mode=c&columnname=$name">$name</a>|;
	}
}

1;
