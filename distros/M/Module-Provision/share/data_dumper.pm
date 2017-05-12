use Data::Dumper; $Data::Dumper::Terse = 1; $Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = sub { [ sort keys %{ $_[ 0 ] } ] };
warn Dumper( $var );
