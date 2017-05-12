
CREATE OR REPLACE FUNCTION powerset(text) returns setof text language plperl
as $$
	my @elements = split /,/, shift;

	use Data::PowerSet;  # document dependency explicitly

	my $d = Data::PowerSet->new(@elements);

	while (my $r = $d->next) {
		return_next join ",", @$r;
	}
	return undef;
$$;

SELECT powerset('red,green,blue');
SELECT count(*) from powerset('a,b,c,d,e,f,g,h,i,j,k,l,m,n');

CREATE OR REPLACE FUNCTION call_powerset_via_spi() returns text language plperl
as $$
	$sql = "SELECT count(*) from powerset('a,b,c,d,e,f,g,h,i,j,k,l,m,n')";
	return spi_exec_query($sql)->{rows}[0]{count};
$$;

SELECT call_powerset_via_spi();



