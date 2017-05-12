package Tangram::Expr::FlatArray;

sub new
{
	my $pkg = shift;
	bless [ @_ ], $pkg;
}

sub quote
  {
	my $item = shift or return 'NULL';
	$item =~ s/'/''/g;
	$item = "'$item'";
	return $item;
  }

sub includes
{
	my ($self, $item) = @_;
	my ($coll, $memdef) = @$self;

	my $schema = $coll->{storage}{schema};

	$item = quote($item)
	  if $memdef->{string_type};

	my $coll_tid = 't' . $coll->root_table;
	my $data_tid = 't' . Tangram::Expr::TableAlias->new;

	return Tangram::Expr::Filter->new
		(
		 expr => "$data_tid.coll = $coll_tid.$schema->{sql}{id_col} AND $data_tid.v = $item",
		 tight => 100,      
		 objects => Set::Object->new($coll, Tangram::Expr::Table->new($memdef->{table}, $data_tid) ),
		 data_tid => $data_tid # for prefetch
		);
}

sub exists
{
	my ($self, $item) = @_;
	my ($coll, $memdef) = @$self;

	my $schema = $coll->{storage}{schema};

	$item = quote($item)
	  if $memdef->{string_type};

	my $coll_tid = 't' . $coll->root_table;

	return Tangram::Expr::Filter->new
		(
		 expr => "EXISTS (SELECT * FROM $memdef->{table} WHERE coll = $coll_tid.$schema->{sql}{id_col} AND v = $item)",
		 objects => Set::Object->new($coll),
		);
}

1;
