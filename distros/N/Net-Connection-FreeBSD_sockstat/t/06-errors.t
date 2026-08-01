#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Net::Connection::FreeBSD_sockstat;

subtest 'undecodable JSON' => sub {
	foreach my $garbage ( '', 'not json at all', '{"sockstat":', '<xml/>' ) {
		my @objects;
		eval { @objects = &sockstat_to_nc_objects( { string => $garbage, ports => 0, ptrs => 0 } ); };

		like(
			$@,
			qr/Failed to decode the JSON from sockstat/,
			'dies on ' . ( $garbage eq '' ? 'an empty string' : $garbage )
		);
	} ## end foreach my $garbage ( '', 'not json at all', '{"sockstat":'...})
}; ## end 'undecodable JSON' => sub

subtest 'JSON that decodes but is the wrong shape' => sub {
	my @bad_shapes = (
		[ '[]',                               'a top level array' ],
		[ '"a string"',                       'a top level string' ],
		[ '{}',                               'a hash with no sockstat key' ],
		[ '{"sockstat": "nope"}',             'sockstat not being a hash' ],
		[ '{"sockstat": []}',                 'sockstat being an array' ],
		[ '{"sockstat": {}}',                 'sockstat with no socket key' ],
		[ '{"sockstat": {"socket": {}}}',     'socket being a hash' ],
		[ '{"sockstat": {"socket": "nope"}}', 'socket being a string' ],
	);

	foreach my $bad_shape (@bad_shapes) {
		my ( $json, $description ) = @{$bad_shape};

		my @objects;
		eval { @objects = &sockstat_to_nc_objects( { string => $json, ports => 0, ptrs => 0 } ); };

		like( $@, qr/does not contain the array \.sockstat\.socket/, "dies on $description" );
	}
}; ## end 'JSON that decodes but is the wrong shape' => sub

subtest 'not being on FreeBSD' => sub {
	plan skip_all => 'this is FreeBSD, so sockstat would actually be called' if $^O =~ /freebsd/;

	my @objects;
	eval { @objects = &sockstat_to_nc_objects( { ports => 0, ptrs => 0 } ); };

	like( $@, qr/this is not FreeBSD/, 'calling it without a string off of FreeBSD dies' );
};

done_testing();
