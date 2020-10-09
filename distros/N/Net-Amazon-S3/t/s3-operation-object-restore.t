#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-operation.pl" }

expect_operation_object_restore (
	'Client'    => \& client_object_restore,
);

had_no_warnings;

done_testing;

sub client_object_restore {
	my (%args) = @_;

	build_default_client_object (%args)
		->restore (%args)
		;
}

sub expect_operation_object_restore {
	expect_operation_plan
		implementations => +{ @_ },
		expect_operation => 'Net::Amazon::S3::Operation::Object::Restore',
		plan => {
			"abort restore" => {
				act_arguments => [
					bucket      => 'bucket-name',
					key         => 'some-key',
					days        => 'args-days',
					tier        => 'args-tier',
				],
			},
		}
}

