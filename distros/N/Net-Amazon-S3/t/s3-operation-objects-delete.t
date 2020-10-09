#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

# plan tests => 4;

expect_operation_objects_delete (
	'API'     => \& api_objects_delete,
	'Client'  => \& client_objects_delete,
);

had_no_warnings;

done_testing;

sub api_objects_delete {
	my (%args) = @_;

	build_default_api_bucket (%args)
		->delete_multi_object (@{ $args{keys} })
		;
}

sub client_objects_delete {
	my (%args) = @_;

	build_default_client_bucket (%args)
		->delete_multi_object (@{ $args{keys} })
		;
}

sub expect_operation_objects_delete {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Objects::Delete',
		plan => {
			"delete multiple objects" => {
				act_arguments => [
					bucket => 'bucket-name',
					keys   => [ 'key-1', 'key-2', 'key-3' ],
				],
			},
		}
}
