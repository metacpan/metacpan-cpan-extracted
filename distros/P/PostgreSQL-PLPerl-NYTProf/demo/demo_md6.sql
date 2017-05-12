
CREATE OR REPLACE FUNCTION md6_add(text) returns text language plperl
as $$
	use Digest::MD6;  # document dependency explicitly
	my $md6 = $_SHARED{md6} ||= Digest::MD6->new;
	$md6->add(@_);
	return 1;
$$;

CREATE OR REPLACE FUNCTION md6_hex() returns text language plperl
as $$
	my $md6 = $_SHARED{md6} or die "md6_add has not been called";
	return $md6->hexdigest;
$$;

SELECT count(md6_add(v::text)) from generate_series(1,100000) v;
SELECT md6_hex();

DO 'DB::enable_profile()' language plperl;

CREATE OR REPLACE FUNCTION call_via_spi() returns void language plperl
as $$
	$sql = "select count(md6_add(v::text)) from generate_series(1,100000) v";
	spi_exec_query($sql);
$$;

SELECT call_via_spi();

