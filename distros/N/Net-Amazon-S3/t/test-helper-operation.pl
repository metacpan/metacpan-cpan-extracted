#!perl

use strict;
use warnings;

use FindBin;

BEGIN { require "$FindBin::Bin/test-helper-common.pl" }

use Sub::Override;

use Shared::Examples::Net::Amazon::S3 ();
use Shared::Examples::Net::Amazon::S3::API ();
use Shared::Examples::Net::Amazon::S3::Client ();

sub build_default_api {
	Shared::Examples::Net::Amazon::S3::API->_default_with_api({});
}

sub build_default_api_bucket (\%) {
	my ($args) = @_;

	build_default_api->bucket (delete $args->{bucket});
}

sub build_default_client  {
	Shared::Examples::Net::Amazon::S3::Client->_default_with_api({});
}

sub build_default_client_bucket (\%) {
	my ($args) = @_;

	build_default_client->bucket (name => delete $args->{bucket});
}

sub build_default_client_object (\%) {
	my ($args) = @_;

	build_default_client_bucket (%$args)->object (key => delete $args->{key});
}

sub expect_operation {
	my ($title, %plan) = @_;

	my $guard = Sub::Override->new (
		'Net::Amazon::S3::_perform_operation',
		sub {
			my ($self, $operation, %args) = @_;

			delete $args{error_handler};

			my ($ok, $stack);
			($ok, $stack) = Test::Deep::cmp_details ($operation, $plan{expect_operation});
			($ok, $stack) = Test::Deep::cmp_details (\%args,     $plan{expect_arguments})
				if $ok;

			diag Test::Deep::deep_diag ($stack)
				unless ok $title, got => $ok;

			die bless {}, 'expect_operation';
		}
	);

	my $lives = eval { $plan{act}->(); 1 };
	my $error = $@;
	$error = undef if Scalar::Util::blessed ($error) && ref ($error) eq 'expect_operation';

	if ($lives) {
		fail $title;
		diag "_perform_operation() not called";
		return;
	}

	if ($error) {
		fail $title;
		diag "unexpected_error: $@";
		return;
	}

	return 1;
}

sub expect_operation_plan {
	my (%args) = @_;

	for my $implementation (sort keys %{ $args{implementations} }) {
		my $act = $args{implementations}{$implementation};

		for my $title (sort keys %{ $args{plan} }) {
			my $plan =  $args{plan}{$title};

			my @act_arguments = @{ $plan->{act_arguments} || [] };
			my $expect_arguments = $plan->{expect_arguments};
			$expect_arguments = { @act_arguments } unless $expect_arguments;

			if (exists $expect_arguments->{bucket}) {
				my $bucket_name = delete $expect_arguments->{bucket};
				$expect_arguments->{bucket} = any (
					obj_isa ('Net::Amazon::S3::Bucket') & methods (bucket => $bucket_name),
					$bucket_name,
				);
			}

			expect_operation "$implementation / $title" =>
				act => sub { $act->(@act_arguments) },
				expect_operation => $args{expect_operation},,
				expect_arguments => $expect_arguments,
				;
		}
	}
}

sub _api_expand_headers {
	my (%args) = @_;

	%args = (%args, %{ $args{headers} });
	delete $args{headers};

	%args;
}

sub _api_expand_metadata {
	my (%args) = @_;

	%args = (
		%args,
		map +( "x_amz_meta_$_" => $args{metadata}{$_} ), keys %{ $args{metadata} }
	);

	delete $args{metadata};

	%args;
}

sub _api_expand_header_arguments {
	_api_expand_headers _api_expand_metadata @_;
}

1;
