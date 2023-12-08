#!perl

use strict;
use warnings;

use Mojolicious::Lite;

use JSON::PP;

$ENV{MOJO_LOG_LEVEL} //= 'debug';

app->secrets([ int( rand( 1_000_000 ) ) . time . int( rand( 1_000_000 ) ) ]);

post '/api/oauth/access_token' => sub {
	my ( $c ) = @_;

	my $status_code = $c->param('_status_code') // 200;

	return $c->render(
		status => $status_code,
		json => {
			$status_code == 200
				? ( access_token => 'ACCESS_TOKEN' )
				: (
					error => 'access_denied',
					error_description => 'invalid entity access',
				),
		},
	);
};

get '/api/agency/v1.1/export/beneficiaries' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_export_beneficiaries( $self->req->params->to_hash ),
	);
};

get '/api/agency/v1.1/export/tenants' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_export_tenants(),
	);
};

get '/api/agency/v1.1/entity/payment/:external_id' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_payment({
			path_params => {
				external_id => $self->param("external_id")
			},

			$self->req->params->to_hash->%*,
		}),
	);
};

post '/api/agency/v1.1/entity/payment' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_payment(),
	);
};

put '/api/agency/v1.1/entity/payment/:external_id' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_payment({
			path_params => {
				external_id => $self->param("external_id")
			},
		}),
	);
};

get '/api/agency/v1.1/entity/invoice/:external_id' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_invoice({
			path_params => {
				external_id => $self->param("external_id")
			},

			$self->req->params->to_hash->%*,
		}),
	);
};

post '/api/agency/v1.1/entity/invoice' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_invoice(),
	);
};

put '/api/agency/v1.1/entity/invoice/:external_id' => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_entity_invoice({
			path_params => {
				external_id => $self->param("external_id")
			},
		}),
	);
};

get "/api/agency/v1.1/tags" => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => _get_tags()
	);
};

post "/api/agency/v1.1/tags" => sub {
	my ( $self ) = @_;

	my $name = $self->req->json->{name};

	return $self->render(
		status => 200,
		json => shift @{ [ grep { $_->{name} eq $name } _get_tags()->{items}->@* ] }
	);
};

post "/api/agency/v1.1/tags/entities/:enity_type/:entity_id" => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => { items => [ map { { id => $_->{id}, name => $_->{name} } } _get_tags()->{items}->@* ] }
	);
};

put "/api/agency/v1.1/tags/:external_id" => sub {
	my ( $self ) = @_;

	my $req_content = $self->req->json;
	my $external_id = $self->param('external_id');

	my $response_data = [
		map {
			{
				id => $_->{id},
				name => $_->{name},
				%$req_content,
			}
		} grep { $_->{id} eq $external_id } _get_tags()->{items}->@*
	];

	return $self->render(
		status => 200,
		json => shift $response_data->@*,
	);
};

del "/api/agency/v1.1/tags/:external_id" => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => { message => 'Tag has been successfully deleted.' }
	);
};

del "/api/agency/v1.1/tags/:external_id/entities" => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => { message => 'Tag link successfully removed from entity.' }
	);
};

get "/api/agency/v1.1/tags/:external_id/entities" => sub {
	my ( $self ) = @_;

	return $self->render(
		status => 200,
		json => {
			items => [
				{
					id => "qv1pKQBXdN",
					name => "Fontana Road 51, Lephalale",
					type => "property"
				},
				{
					id => "BRXEKW75ZO",
					name => "Abass Samson",
					type => "tenant"
				}
			],
			pagination => {
				page => 1,
				rows => 2,
				total_pages => 1,
				total_rows => 2
			}
		}
	);
};

# TODO: move to a JSON file
sub _get_tags {

	my @mock_data = (
		{
			"id" => "woRZQl1mA4",
			"links" => {
				"entities" => [
					{
						"count" => 0,
						"type" => "tenant"
					},
					{
						"count" => 0,
						"type" => "property"
					},
					{
						"count" => 0,
						"type" => "beneficiary"
					}
				],
				"total" => 0
			},
			"name" => "New tag1"
		},
		{
			"id" => "oz2JkGJbgm",
			"links" => {
				"entities" => [
					{
						"count" => 0,
						"type" => "tenant"
					},
					{
						"count" => 1,
						"type" => "property"
					},
					{
						"count" => 0,
						"type" => "beneficiary"
					}
				],
				"total" => 1
			},
			"name" => "new_tag2"
		}
	);

	my $mock_results_count = scalar @mock_data;

	return {
		status => 200,
		items => \@mock_data,
		pagination => {
			page => 1,
			total_pages => 1,
			rows => $mock_results_count,
			total_rows => $mock_results_count,
		},
	};
}

# TODO: move to a JSON file
sub _get_export_beneficiaries {
	my ( $params ) = @_;

	my @mock_data = (
		{
			"billing_address" => {
				"city" => "Gonubie",
				"country_code" => "ZA",
				"created" => "2018-09-14T00:00:00",
				"email" => 'z0ey9pbik@webmail.co.za',
				"fax" => "043 829 3128",
				"first_line" => "10 Ketch Street",
				"id" => "7QZGgLxnZ9",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2018-09-14T00:00:00",
				"phone" => "043 780 9789",
				"postal_code" => "5257",
				"second_line" => "",
				"state" => "Eastern Cape",
				"third_line" => "",
				"zip_code" => "5257"
			},
			"business_name" => "",
			"comment" => undef,
			"customer_id" => undef,
			"customer_reference" => "",
			"email_address" => '4rqa2bc@live.com',
			"email_cc_address" => "",
			"first_name" => "Aadila",
			"id" => "8EJAY9P9Jj",
			"id_reg_number" => "STPMSURGVK",
			"id_type_id" => "",
			"is_active_owner" => JSON::PP::false,
			"is_owner" => JSON::PP::false,
			"last_name" => "Hall",
			"mobile_number" => "27840575453",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [
				{
					"account_balance" => 24.34,
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "0G1O8N62ZM",
					"listed_from" => "2018-02-22",
					"listed_until" => undef,
					"monthly_payment_required" => "5586.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "A Double Delight Crescent 63, Somerset West",
					"responsible_agent" => "David Louw",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1
				},
				{
					"account_balance" => 18602.21,
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "B6XKa96VZW",
					"listed_from" => "2017-02-02",
					"listed_until" => undef,
					"monthly_payment_required" => "8000.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Maritz Street 78, Cape Town",
					"responsible_agent" => "Timothy Liesl",
					"responsible_agent_id" => undef,
					"responsible_user" => undef
				}
			],
			"vat_number" => "3534450636"
		},
		{
			"billing_address" => {
				"city" => "Cape Town",
				"country_code" => "ZA",
				"created" => "2021-11-29T00:00:00",
				"email" => 'a2urop58m@gmail.com',
				"fax" => "021 742 4109",
				"first_line" => "45 Nordic Crescent",
				"id" => "B6XKb09pJW",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2021-12-14T00:00:00",
				"phone" => "021 089 4001",
				"postal_code" => "7806",
				"second_line" => "",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7806"
			},
			"business_name" => "",
			"comment" => undef,
			"customer_id" => 'CustomerID',
			"customer_reference" => "",
			"email_address" => 'dvvao2h4mu@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Abeinsa Epc Khi",
			"id" => "GVJj3qMPXE",
			"id_reg_number" => "DQQZUQJYOL",
			"id_type_id" => "",
			"is_active_owner" => JSON::PP::true,
			"is_owner" => JSON::PP::true,
			"last_name" => "Boje",
			"mobile_number" => "27788140634",
			"notify_email" => JSON::PP::false,
			"notify_sms" => JSON::PP::true,
			"properties" => [
				{
					"account_balance" => 0,
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "v2XlAxYy1e",
					"listed_from" => "2021-11-08",
					"listed_until" => undef,
					"monthly_payment_required" => "7000.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Walnut Avenue 65, Lephalale",
					"responsible_agent" => "Jacques Nesi",
					"responsible_agent_id" => "8eJPVdn1G7",
					"responsible_user" => undef
				}
			],
			"vat_number" => "6050029778"
		}
	);

	$params //= {};
	if ( $params->%* ) {
		my ( $filter_by, $filter_value ) = %$params;

		@mock_data = grep { $_->{ $filter_by } // '' eq $filter_value } @mock_data;
	}

	my $mock_results_count = scalar @mock_data;

	return {
		status => 200,
		items => \@mock_data,
		pagination => {
			page => 1,
			total_pages => 1,
			rows => $mock_results_count,
			total_rows => $mock_results_count,
		},
	};
}

# TODO: move to a JSON file
sub _get_export_tenants {

	my @mock_data = (
		{
			"address" => {
				"city" => "Polokwane",
				"country_code" => "ZA",
				"created" => "2020-12-11T00:00:00",
				"email" => 'jsx1cur5r@yahoo.com',
				"fax" => "015 757 7775",
				"first_line" => "23 Lloyd Street",
				"id" => "WzJBgyqaXQ",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2020-12-11T00:00:00",
				"phone" => "015 669 5309",
				"postal_code" => "0700",
				"second_line" => "",
				"state" => "Limpopo",
				"third_line" => "",
				"zip_code" => "0700"
			},
			"business_name" => "Abrahams Miemie",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Abrahams Miemie",
			"email_address" => 'sgmgbv6s9w48@flysaa.com',
			"email_cc_address" => "",
			"first_name" => "Miemie",
			"id" => "GvJDkKOjZz",
			"id_reg_no" => "800900449722",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Abrahams",
			"mobile_number" => "27831413029",
			"notify_email" => JSON::PP::false,
			"notify_sms" => JSON::PP::false,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Klerksdorp",
				"country_code" => "ZA",
				"created" => "2016-10-11T00:00:00",
				"email" => 'dt5y5jsw@yahoo.com',
				"fax" => "018 867 2390",
				"first_line" => "Unit 8",
				"id" => "RV1Rbveo1P",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2016-10-11T00:00:00",
				"phone" => "018 425 0313",
				"postal_code" => "2571",
				"second_line" => "32 Bloe Street",
				"state" => "North West",
				"third_line" => "",
				"zip_code" => "2571"
			},
			"business_name" => "Abrahams Nicole",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Abrahams Nicole",
			"email_address" => 'sd75c6vd@iafrica.com',
			"email_cc_address" => "",
			"first_name" => "Nicole",
			"id" => "EyJ6KOYwXj",
			"id_reg_no" => "925844129108",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Abrahams",
			"mobile_number" => "27810886281",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},

		{
			"address" => {
				"city" => "Nelspruit",
				"country_code" => "ZA",
				"created" => "2017-12-22T00:00:00",
				"email" => 'u4qgtykfuq@mweb.co.za',
				"fax" => "013 347 8214",
				"first_line" => "65 Plettenberg Street",
				"id" => "EyJ68YGO1j",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-12-22T00:00:00",
				"phone" => "013 432 0084",
				"postal_code" => "1202",
				"second_line" => "",
				"state" => "Mpumalanga",
				"third_line" => "",
				"zip_code" => "1202"
			},
			"business_name" => "Abrahamse Elmarie",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Abrahamse Elmarie",
			"email_address" => 'ysulqjup8agf6@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Elmarie",
			"id" => "agXV4lw2Z3",
			"id_reg_no" => "336451774630",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Abrahamse",
			"mobile_number" => "27735504827",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Melkbosstrand",
				"country_code" => "ZA",
				"created" => "2017-11-16T00:00:00",
				"email" => '8qpz4rzu@gmail.com',
				"fax" => "021 067 6731",
				"first_line" => "8 Exeter Court",
				"id" => "90JYbBrkXo",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-11-16T00:00:00",
				"phone" => "021 815 6221",
				"postal_code" => "7441",
				"second_line" => "",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7441"
			},
			"business_name" => "Abrie Ryno",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Abrie Ryno",
			"email_address" => '4c97ux2uv9ulg@mweb.co.za',
			"email_cc_address" => "",
			"first_name" => "Ryno",
			"id" => "5AJ5em0oJM",
			"id_reg_no" => "003872174906",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Abrie",
			"mobile_number" => "27790989094",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Roodepoort",
				"country_code" => "ZA",
				"created" => "2021-03-12T00:00:00",
				"email" => 'rlu782x3g22@sanlam.co.za',
				"fax" => "011 028 7313",
				"first_line" => "76 Main Street",
				"id" => "oRZQePO5Zm",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2021-03-12T00:00:00",
				"phone" => "011 221 5882",
				"postal_code" => "1724",
				"second_line" => "",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "1724"
			},
			"business_name" => "Ackerman Willie",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ackerman Willie",
			"email_address" => 'prb30esh41u@yebo.co.za',
			"email_cc_address" => "",
			"first_name" => "Willie",
			"id" => "RwXx2KbEZA",
			"id_reg_no" => "530126987722",
			"id_type_id" => "",
			"invoice_lead_days" => 0,
			"last_name" => "Ackerman",
			"mobile_number" => "27768984594",
			"notify_email" => JSON::PP::false,
			"notify_sms" => JSON::PP::false,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Boksburg",
				"country_code" => "ZA",
				"created" => "2017-06-22T00:00:00",
				"email" => '7floex77mwa@gmail.com',
				"fax" => "011 316 6261",
				"first_line" => "59 Lambert Avenue",
				"id" => "WzJBmvB2ZQ",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-06-22T00:00:00",
				"phone" => "011 545 7401",
				"postal_code" => "1459",
				"second_line" => "",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "1459"
			},
			"business_name" => "Ackermann Alexandra",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ackermann Alexandra",
			"email_address" => 'm49xrg@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Alexandra",
			"id" => "8eJPGN9RZG",
			"id_reg_no" => "543877096449",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Ackermann",
			"mobile_number" => "27749881851",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Deneysville",
				"country_code" => "ZA",
				"created" => "2016-04-06T00:00:00",
				"email" => '8vq4tp6n@hotmail.com',
				"fax" => "016 641 5438",
				"first_line" => "69 Adler Street",
				"id" => "WzJB7b39XQ",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2016-04-06T00:00:00",
				"phone" => "016 059 4038",
				"postal_code" => "1932",
				"second_line" => "",
				"state" => "Free State",
				"third_line" => "",
				"zip_code" => "1932"
			},
			"business_name" => "Ackermann Waylon",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ackermann Waylon",
			"email_address" => 'kix02bjzt@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Waylon",
			"id" => "rp19wnKBJA",
			"id_reg_no" => "197719603257",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Ackermann",
			"mobile_number" => "27821388563",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Cape Town",
				"country_code" => "ZA",
				"created" => "2019-09-20T00:00:00",
				"email" => 'a7ftjctwjpvg7@global.co.za',
				"fax" => "021 567 3095",
				"first_line" => "Unit 19",
				"id" => "K3Jw34reJE",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2020-11-25T00:00:00",
				"phone" => "021 553 7798",
				"postal_code" => "7504",
				"second_line" => "12 Blueberry Street",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7504"
			},
			"business_name" => "Acton Mohammed",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1989-03-30T00:00:00",
			"display_name" => "Acton Mohammed",
			"email_address" => '3umjeqtt@telkomsa.net',
			"email_cc_address" => 'bosmanleandri@yahoo.co.za',
			"first_name" => "Mohammed",
			"id" => "v2XljLy9Ze",
			"id_reg_no" => "112018430526",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Acton",
			"mobile_number" => "27784638474",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::false,
			"properties" => [
				{
					"account_balance" => 2093.58,
					"address" => {
						"city" => "Kriel",
						"country_code" => "ZA",
						"created" => "2015-06-01T00:00:00",
						"email" => 'yvz1cq8r@yahoo.com',
						"fax" => "017 081 0331",
						"first_line" => "66 On Millennium Boulevard",
						"id" => "EyJ6yOEbZj",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2022-09-29T00:00:00",
						"phone" => "017 597 1161",
						"postal_code" => "2271",
						"second_line" => "",
						"state" => "Mpumalanga",
						"third_line" => "",
						"zip_code" => "2271"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "lwZ75Ma8XD",
					"listed_from" => "2015-06-01",
					"listed_until" => undef,
					"monthly_payment_required" => "9750.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "On Millennium Boulevard 66, Kriel",
					"responsible_agent" => "Willem Hermanus Jansen",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1,
					"tenant" => {
						"deposit_id" => "VW1700",
						"end_date" => "2022-07-31",
						"start_date" => "2019-12-01"
					}
				}
			],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "George",
				"country_code" => "ZA",
				"created" => "2016-08-29T00:00:00",
				"email" => 'a1z5lujuu3yk@yahoo.com',
				"fax" => "044 975 2301",
				"first_line" => "Wemco House",
				"id" => "lwZ7MV99XD",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2016-08-29T00:00:00",
				"phone" => "044 021 2343",
				"postal_code" => "6560",
				"second_line" => "Mooirivier Street",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "6560"
			},
			"business_name" => "Adam Carel",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Adam Carel",
			"email_address" => 'svm2av09t5@yahoo.com',
			"email_cc_address" => "",
			"first_name" => "Carel",
			"id" => "rp19wKOoJA",
			"id_reg_no" => "631694966950",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Adam",
			"mobile_number" => "27749441083",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Hartbeespoort",
				"country_code" => "ZA",
				"created" => "2020-12-11T00:00:00",
				"email" => 'uwiqd2k56l@gmail.com',
				"fax" => "012 721 3956",
				"first_line" => "Windsong House",
				"id" => "RV1RyKG8XP",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2021-04-13T00:00:00",
				"phone" => "012 610 3011",
				"postal_code" => "0216",
				"second_line" => "Silver Oak Street",
				"state" => "North West",
				"third_line" => "",
				"zip_code" => "0216"
			},
			"business_name" => "Adam Kudzanai",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1992-08-03T00:00:00",
			"display_name" => "Adam Kudzanai",
			"email_address" => 'q0odhsq2wugp@dpw.gov.za',
			"email_cc_address" => "",
			"first_name" => "Kudzanai",
			"id" => "mGX0MbOg13",
			"id_reg_no" => "635515898646",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Adam",
			"mobile_number" => "27845110763",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::false,
			"properties" => [
				{
					"account_balance" => 0,
					"address" => {
						"city" => "Cape Town",
						"country_code" => "ZA",
						"created" => "2020-12-11T00:00:00",
						"email" => '2iayjljkmjkq@netactive.co.za',
						"fax" => "021 116 4492",
						"first_line" => "43 Briza Road",
						"id" => "d71exbOlX5",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2022-07-14T00:00:00",
						"phone" => "021 977 7875",
						"postal_code" => "7925",
						"second_line" => "",
						"state" => "Western Cape",
						"third_line" => "",
						"zip_code" => "7925"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "z2JkGKGpJb",
					"listed_from" => "2020-12-11",
					"listed_until" => undef,
					"monthly_payment_required" => "10500.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Briza Road 43, Cape Town",
					"responsible_agent" => "Doret Macintyre",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1,
					"tenant" => {
						"deposit_id" => "VW1890",
						"end_date" => "2022-07-31",
						"start_date" => "2021-02-01"
					}
				}
			],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Cape Town",
				"country_code" => "ZA",
				"created" => "2021-05-03T00:00:00",
				"email" => 'q4aqbwg@telkomsa.net',
				"fax" => "021 921 4558",
				"first_line" => "31 Broadway Complex",
				"id" => "5AJ5vrkoXM",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2021-05-03T00:00:00",
				"phone" => "021 100 5267",
				"postal_code" => "7806",
				"second_line" => "",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7806"
			},
			"business_name" => "Adams Onica",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Adams Onica",
			"email_address" => '8t2198zmt@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Onica",
			"id" => "mLZd0Ez4Zn",
			"id_reg_no" => "908587009375",
			"id_type_id" => "",
			"invoice_lead_days" => 0,
			"last_name" => "Adams",
			"mobile_number" => "27797519591",
			"notify_email" => JSON::PP::false,
			"notify_sms" => JSON::PP::false,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Roodepoort",
				"country_code" => "ZA",
				"created" => "2019-08-26T00:00:00",
				"email" => '8orss52s4qnw4@tigerbrands.com',
				"fax" => "011 910 5469",
				"first_line" => "58 Earlswood Road",
				"id" => "lwZ7Npn81D",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2019-08-26T00:00:00",
				"phone" => "011 265 4595",
				"postal_code" => "1724",
				"second_line" => "",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "1724"
			},
			"business_name" => "Adams Reinhardt",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Adams Reinhardt",
			"email_address" => 'o6repys7gxak8@mweb.co.za',
			"email_cc_address" => "",
			"first_name" => "Reinhardt",
			"id" => "GVJjWQwAXE",
			"id_reg_no" => "440916449147",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Adams",
			"mobile_number" => "27786707289",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Johannesburg",
				"country_code" => "ZA",
				"created" => "2020-09-11T00:00:00",
				"email" => 'uen789ecs@gmail.com',
				"fax" => "011 396 3688",
				"first_line" => "Unit 26",
				"id" => "PzZyVB6KJd",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2020-09-11T00:00:00",
				"phone" => "011 364 7973",
				"postal_code" => "2146",
				"second_line" => "26 Steve Biko Street",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "2146"
			},
			"business_name" => "Adams Rozanne",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1959-07-02T00:00:00",
			"display_name" => "Adams Rozanne",
			"email_address" => 'yqutbty1pjw@dha.gov.za',
			"email_cc_address" => "",
			"first_name" => "Rozanne",
			"id" => "EyJ6Px571j",
			"id_reg_no" => "575022383785",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Adams",
			"mobile_number" => "27797508620",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [
				{
					"account_balance" => 9033.81,
					"address" => {
						"city" => "Germiston",
						"country_code" => "ZA",
						"created" => "2018-05-18T00:00:00",
						"email" => 'y7n136yhbx3r@gmail.com',
						"fax" => "011 140 3740",
						"first_line" => "23 The Boulevards",
						"id" => "RV1Rpn55JP",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2022-04-04T00:00:00",
						"phone" => "011 259 3838",
						"postal_code" => "1610",
						"second_line" => "",
						"state" => "Gauteng",
						"third_line" => "",
						"zip_code" => "1610"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "agXVv7Y2X3",
					"listed_from" => "2018-05-18",
					"listed_until" => undef,
					"monthly_payment_required" => "17500.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "The Boulevards 23, Germiston",
					"responsible_agent" => "Siphosethu Naidoo",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1,
					"tenant" => {
						"deposit_id" => "VW1843",
						"end_date" => undef,
						"start_date" => "2020-09-11"
					}
				}
			],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Pietermaritzburg",
				"country_code" => "ZA",
				"created" => "2018-10-19T00:00:00",
				"email" => 'z7xaq6x@bcx.co.za',
				"fax" => "033 713 1923",
				"first_line" => "Unit 11",
				"id" => "Kd1brqnV1v",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2018-10-19T00:00:00",
				"phone" => "033 244 2556",
				"postal_code" => "3201",
				"second_line" => "17 Carnation Street",
				"state" => "Kwazulu-Natal",
				"third_line" => "",
				"zip_code" => "3201"
			},
			"business_name" => "Adams Wonga",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Adams Wonga",
			"email_address" => 'g7g38j0ld9fd@iafrica.com',
			"email_cc_address" => "",
			"first_name" => "Wonga",
			"id" => "rp19dGwaXA",
			"id_reg_no" => "559500302391",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Adams",
			"mobile_number" => "27792906203",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "George",
				"country_code" => "ZA",
				"created" => "2017-07-28T00:00:00",
				"email" => 'hqug4d9@gmail.com',
				"fax" => "044 959 5136",
				"first_line" => "Unit 22",
				"id" => "oRZQ2Vr5Jm",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-07-28T00:00:00",
				"phone" => "044 274 3502",
				"postal_code" => "6529",
				"second_line" => "77 Old Kent Drive",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "6529"
			},
			"business_name" => "Addison Sydney",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Addison Sydney",
			"email_address" => '8tkwcr4f71zm@yahoo.com',
			"email_cc_address" => "",
			"first_name" => "Sydney",
			"id" => "GVJjBVAOJE",
			"id_reg_no" => "927017760886",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Addison",
			"mobile_number" => "27833465400",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Wolseley",
				"country_code" => "ZA",
				"created" => "2016-09-13T00:00:00",
				"email" => '1fbki7i8bzig@engenoil.com',
				"fax" => "023 803 1282",
				"first_line" => "Apartment 6",
				"id" => "z2JkN5zYZb",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2016-09-13T00:00:00",
				"phone" => "023 309 4835",
				"postal_code" => "6830",
				"second_line" => "35 Eaton Square",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "6830"
			},
			"business_name" => "Adonisi Ilse",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Adonisi Ilse",
			"email_address" => 'thvxr48px6np@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Ilse",
			"id" => "v2XlAvBa1e",
			"id_reg_no" => "678541125403",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Adonisi",
			"mobile_number" => "27793814451",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Cape Town",
				"country_code" => "ZA",
				"created" => "2015-06-12T00:00:00",
				"email" => 'e5pyv6btcr@gmail.com',
				"fax" => "021 118 8448",
				"first_line" => "24 Camilla Street",
				"id" => "7nZ32DyO1N",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2015-06-12T00:00:00",
				"phone" => "021 403 0214",
				"postal_code" => "7800",
				"second_line" => "",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7800"
			},
			"business_name" => "Africa James Michael",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1971-03-15T00:00:00",
			"display_name" => "Africa James Michael",
			"email_address" => '2ewh7i@gmail.com',
			"email_cc_address" => "",
			"first_name" => "James Michael",
			"id" => "WrJvPy0B1l",
			"id_reg_no" => "627996612428",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Africa",
			"mobile_number" => "27826958271",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [
				{
					"account_balance" => 204.8,
					"address" => {
						"city" => "Polokwane",
						"country_code" => "ZA",
						"created" => "2011-02-17T00:00:00",
						"email" => 'i2ictcoal4ty2@gmail.com',
						"fax" => "015 696 7719",
						"first_line" => "Unit 26",
						"id" => "lwZ7a5QmXD",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2022-04-05T00:00:00",
						"phone" => "015 758 9016",
						"postal_code" => "0700",
						"second_line" => "10 Davy Street Block",
						"state" => "Limpopo",
						"third_line" => "",
						"zip_code" => "0700"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "7QZGLGzJ9Y",
					"listed_from" => "2011-02-17",
					"listed_until" => undef,
					"monthly_payment_required" => "7004.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Davy Street Block 10, Unit 26, Polokwane",
					"responsible_agent" => "Gideon Govender",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1,
					"tenant" => {
						"deposit_id" => "VW951",
						"end_date" => "2023-05-31",
						"start_date" => "2015-07-01"
					}
				}
			],
			"reference" => "",
			"status" => "Active",
			"vat_number" => ""
		},
		{
			"address" => {
				"city" => "Ermelo",
				"country_code" => "ZA",
				"created" => "2019-02-20T00:00:00",
				"email" => 'n4qiwbwhr83h1@live.com',
				"fax" => "017 261 2651",
				"first_line" => "55 Louie Street",
				"id" => "agXV327413",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2021-04-22T00:00:00",
				"phone" => "017 209 9295",
				"postal_code" => "2350",
				"second_line" => "",
				"state" => "Mpumalanga",
				"third_line" => "",
				"zip_code" => "2350"
			},
			"business_name" => "Africa Johan",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1979-08-30T00:00:00",
			"display_name" => "Africa Johan",
			"email_address" => 'p8f3rh5@anglogoldashanti.com',
			"email_cc_address" => 'cindykets81@gmail.com',
			"first_name" => "Johan",
			"id" => "B6XK3GWQXW",
			"id_reg_no" => "502998709589",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Africa",
			"mobile_number" => "27844390503",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::false,
			"properties" => [
				{
					"account_balance" => 20162.23,
					"address" => {
						"city" => "Ermelo",
						"country_code" => "ZA",
						"created" => "2018-05-14T00:00:00",
						"email" => '959w01e9z0i1@googlemail.com',
						"fax" => "017 313 5970",
						"first_line" => "Unit 30",
						"id" => "z2JkledlXb",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2021-01-25T00:00:00",
						"phone" => "017 567 1016",
						"postal_code" => "2350",
						"second_line" => "16 Buitengracht Street",
						"state" => "Mpumalanga",
						"third_line" => "",
						"zip_code" => "2350"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::true,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "WzJBj4p9JQ",
					"listed_from" => "2018-05-14",
					"listed_until" => undef,
					"monthly_payment_required" => "9500.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Buitengracht Street 16, Unit 30, Ermelo",
					"responsible_agent" => "Nomalanga Manus",
					"responsible_agent_id" => undef,
					"responsible_user" => undef,
					"tenant" => {
						"deposit_id" => "VW1606",
						"end_date" => "2023-04-30",
						"start_date" => "2019-05-01"
					}
				}
			],
			"reference" => "",
			"status" => "Active",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Ermelo",
				"country_code" => "ZA",
				"created" => "2017-08-07T00:00:00",
				"email" => 'wuu5vp1k1kq9@yahoo.com',
				"fax" => "017 682 6487",
				"first_line" => "67 Beretta Street",
				"id" => "rnXWGnQxXG",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-08-07T00:00:00",
				"phone" => "017 408 1918",
				"postal_code" => "2350",
				"second_line" => "",
				"state" => "Mpumalanga",
				"third_line" => "",
				"zip_code" => "2350"
			},
			"business_name" => "Africa Wayne",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Africa Wayne",
			"email_address" => 'p7x5sxtlqys@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Wayne",
			"id" => "lwZ7jprm1D",
			"id_reg_no" => "382535915116",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Africa",
			"mobile_number" => "27761371447",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Brits",
				"country_code" => "ZA",
				"created" => "2019-02-21T00:00:00",
				"email" => '7uija2blt@dcs.gov.za',
				"fax" => "012 723 1533",
				"first_line" => "33 Wild Olive Street",
				"id" => "d71eYyPg15",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2019-02-21T00:00:00",
				"phone" => "012 885 9053",
				"postal_code" => "0250",
				"second_line" => "",
				"state" => "North West",
				"third_line" => "",
				"zip_code" => "0250"
			},
			"business_name" => "Agbomere Byron",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Agbomere Byron",
			"email_address" => 'exvik8ovhqcbo@vodamail.co.za',
			"email_cc_address" => "",
			"first_name" => "Byron",
			"id" => "WrJv2MOQJl",
			"id_reg_no" => "965593128889",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Agbomere",
			"mobile_number" => "27794179155",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Mokopane",
				"country_code" => "ZA",
				"created" => "2016-03-15T00:00:00",
				"email" => 'p7vgodrnls@gmail.com',
				"fax" => "015 509 1178",
				"first_line" => "65 Acutt Road",
				"id" => "LQZr24aRZN",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2016-03-15T00:00:00",
				"phone" => "015 210 0418",
				"postal_code" => "0600",
				"second_line" => "",
				"state" => "Limpopo",
				"third_line" => "",
				"zip_code" => "0600"
			},
			"business_name" => "Ahmed Lillian",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ahmed Lillian",
			"email_address" => '6fbtqjww@mweb.co.za',
			"email_cc_address" => "",
			"first_name" => "Lillian",
			"id" => "D6JmBwo3Xv",
			"id_reg_no" => "735421801782",
			"id_type_id" => "",
			"invoice_lead_days" => 0,
			"last_name" => "Ahmed",
			"mobile_number" => "27829310963",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Ellisras",
				"country_code" => "ZA",
				"created" => "2020-01-28T00:00:00",
				"email" => 'ifogvc@hotmail.com',
				"fax" => "014 295 3431",
				"first_line" => "72 Ulu Drive",
				"id" => "agXVopp913",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2020-01-28T00:00:00",
				"phone" => "014 697 1489",
				"postal_code" => "0555",
				"second_line" => "",
				"state" => "Limpopo",
				"third_line" => "",
				"zip_code" => "0555"
			},
			"business_name" => "Ahmed Mary",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ahmed Mary",
			"email_address" => '2xg0fyt6ljg@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Mary",
			"id" => "8b1gvW2OXG",
			"id_reg_no" => "463502080313",
			"id_type_id" => "oz2JkGJbgm",
			"invoice_lead_days" => 0,
			"last_name" => "Ahmed",
			"mobile_number" => "27799680143",
			"notify_email" => JSON::PP::false,
			"notify_sms" => JSON::PP::false,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Paarl",
				"country_code" => "ZA",
				"created" => "2015-08-20T00:00:00",
				"email" => 'rp7j9d@sita.co.za',
				"fax" => "021 472 3655",
				"first_line" => "75 Tolstoi Street",
				"id" => "7QZGaBxYX9",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2015-08-20T00:00:00",
				"phone" => "021 616 0046",
				"postal_code" => "7646",
				"second_line" => "",
				"state" => "Western Cape",
				"third_line" => "",
				"zip_code" => "7646"
			},
			"business_name" => "Aitken Yusuf",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Aitken Yusuf",
			"email_address" => 't4fldfbd7ii@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Yusuf",
			"id" => "Kd1bBYLA1v",
			"id_reg_no" => "141247650686",
			"id_type_id" => "",
			"invoice_lead_days" => 0,
			"last_name" => "Aitken",
			"mobile_number" => "27827421307",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Johannesburg",
				"country_code" => "ZA",
				"created" => "2015-07-13T00:00:00",
				"email" => '2gni17pxmbv5@gmail.com',
				"fax" => "011 339 9144",
				"first_line" => "Unit 20",
				"id" => "ge1aWlaVJE",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2015-07-13T00:00:00",
				"phone" => "011 298 6536",
				"postal_code" => "2001",
				"second_line" => "75 Beethoven Street",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "2001"
			},
			"business_name" => "Ajayi Sanda",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => undef,
			"display_name" => "Ajayi Sanda",
			"email_address" => 'kk5hwans@gmail.com',
			"email_cc_address" => "",
			"first_name" => "Sanda",
			"id" => "8b1goQ3y1G",
			"id_reg_no" => "553794956570",
			"id_type_id" => "",
			"invoice_lead_days" => 0,
			"last_name" => "Ajayi",
			"mobile_number" => "27849009082",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => undef
		},
		{
			"address" => {
				"city" => "Roodepoort",
				"country_code" => "ZA",
				"created" => "2017-06-05T00:00:00",
				"email" => 'r2pw86gd@msn.com',
				"fax" => "011 029 1843",
				"first_line" => "19 Cecil Auret Road",
				"id" => "PYZ2opyjJQ",
				"latitude" => undef,
				"longitude" => undef,
				"modified" => "2017-06-05T00:00:00",
				"phone" => "011 645 1997",
				"postal_code" => "2194",
				"second_line" => "",
				"state" => "Gauteng",
				"third_line" => "",
				"zip_code" => "2194"
			},
			"business_name" => "Akbar Palesa",
			"comment" => "",
			"customer_id" => undef,
			"date_of_birth" => "1998-11-06T00:00:00",
			"display_name" => "Akbar Palesa",
			"email_address" => 'dmq2x0764@za.pwc.com',
			"email_cc_address" => 'jacojoubert@mail.co.za',
			"first_name" => "Palesa",
			"id" => "B6XKwvkpXW",
			"id_reg_no" => "513965213359",
			"id_type_id" => "",
			"invoice_lead_days" => 5,
			"last_name" => "Akbar",
			"mobile_number" => "27724261601",
			"notify_email" => JSON::PP::true,
			"notify_sms" => JSON::PP::true,
			"properties" => [
				{
					"account_balance" => 1451.36,
					"address" => {
						"city" => "Port Elizabeth",
						"country_code" => "ZA",
						"created" => "2015-12-03T00:00:00",
						"email" => 'b79iqvk@gmail.com',
						"fax" => "041 949 9378",
						"first_line" => "39 Anthony Crescent",
						"id" => "5AJ5aOPvJM",
						"latitude" => undef,
						"longitude" => undef,
						"modified" => "2022-09-15T00:00:00",
						"phone" => "041 001 4887",
						"postal_code" => "6025",
						"second_line" => "",
						"state" => "Eastern Cape",
						"third_line" => "",
						"zip_code" => "6025"
					},
					"allow_payments" => JSON::PP::true,
					"approval_required" => JSON::PP::false,
					"comment" => "",
					"customer_reference" => undef,
					"hold_all_owner_funds" => JSON::PP::false,
					"id" => "7nZ3g9l8ZN",
					"listed_from" => "2015-12-03",
					"listed_until" => undef,
					"monthly_payment_required" => "7400.00",
					"property_account_minimum_balance" => "0.00",
					"property_name" => "Anthony Crescent 39, Port Elizabeth",
					"responsible_agent" => "Pierre Vusumuzi",
					"responsible_agent_id" => "DWzJBbWJQB",
					"responsible_user" => 1,
					"tenant" => {
						"deposit_id" => "VW1288",
						"end_date" => undef,
						"start_date" => "2017-06-05"
					}
				}
			],
			"reference" => "",
			"status" => "Inactive",
			"vat_number" => ""
		}
	);

	my $mock_results_count = scalar @mock_data;

	return {
		status => 200,
		items => \@mock_data,
		pagination => {
			page => 1,
			total_pages => 1,
			rows => $mock_results_count,
			total_rows => $mock_results_count,
		},
	};
}

# TODO: move to a JSON file
sub _get_entity_payment {
	my ( $params ) = @_;

	$params //= {};
	my $path_params = delete $params->{ path_params } // {};

	my @mock_data = (
		{
			"amount" => 868.41,
			"beneficiary_id" => "B6XK97WwZW",
			"beneficiary_type" => "beneficiary",
			"category_id" => "DWzJBaZQBp",
			"customer_id" => 'PaymentCustomerID',
			"description" => undef,
			"enabled" => JSON::PP::true,
			"end_date" => undef,
			"frequency" => "O",
			"percentage" => 54.36,
			"has_tax" => JSON::PP::false,
			"id" => "nZ3YqdvzXN",
			"maintenance_ticket_id" => undef,
			"no_commission_amount" => undef,
			"payment_day" => 6,
			"property_id" => "Kd1bdGW8Jv",
			"reference" => "distinctio qui quis",
			"start_date" => "2023-10-06",
			"use_money_from" => "property_account",
		},
		{
			"amount" => 505.85,
			"beneficiary_id" => "B6XK97WwZW",
			"beneficiary_type" => "beneficiary",
			"category_id" => "DWzJBaZQBp",
			"customer_id" => undef,
			"description" => undef,
			"enabled" => JSON::PP::true,
			"end_date" => undef,
			"frequency" => "O",
			"percentage" => "45.24",
			"has_tax" => JSON::PP::false,
			"id" => "MZnW5oLYJ7",
			"maintenance_ticket_id" => undef,
			"no_commission_amount" => undef,
			"payment_day" => 6,
			"property_id" => "Kd1bdGW8Jv",
			"reference" => "distinctio qui quis",
			"start_date" => "2023-10-06",
			"use_money_from" => "any_tenant",
		},
	);

	# the query param in this case is "is_customer_id"
	# which supersedes the route "external_id" when doing a lookup
	if ( $params->%* ) {

		@mock_data = grep { $_->{customer_id} // '' eq $params->{is_customer_id} } @mock_data;

		return shift @mock_data;
	}

	@mock_data = grep { $_->{id} eq $path_params->{external_id} } @mock_data
		if $path_params->%*
	;

	return shift @mock_data;
}


# TODO: move to a JSON file
sub _get_entity_invoice {
	my ( $params ) = @_;

	$params //= {};
	my $path_params = delete $params->{ path_params } // {};

	my @mock_data = (
		{
			"amount" => 850.0,
			"category_id" => "Vv2XlY1ema",
			"customer_id" => 'FirstInvoiceCustomerID',
			"deposit_id" => "FGF7",
			"description" => "Rent For Exmouth Avenue 21",
			"end_date" => undef,
			"frequency" => "M",
			"has_invoice_period" => JSON::PP::true,
			"has_tax" => JSON::PP::false,
			"id" => "WrJvLzqD1l",
			"is_direct_debit" => JSON::PP::false,
			"payment_day" => 8,
			"property_id" => "mGX0O4zrJ3",
			"start_date" => "2022-04-08",
			"tenant_id" => "8EJAnqDyXj"
		},
		{
			"amount" => 550.0,
			"category_id" => "Vv2XlY1ema",
			"customer_id" => undef,
			"deposit_id" => "FGF7",
			"description" => "Rent For Exmouth Avenue 21",
			"end_date" => undef,
			"frequency" => "M",
			"has_invoice_period" => JSON::PP::true,
			"has_tax" => JSON::PP::false,
			"id" => "Vv2XlY1ema",
			"is_direct_debit" => JSON::PP::false,
			"payment_day" => 8,
			"property_id" => "mGX0O4zrJ3",
			"start_date" => "2022-04-08",
			"tenant_id" => "8EJAnqDyXj"
		}
	);

	# the query param in this case is "is_customer_id"
	# which supersedes the route "external_id" when doing a lookup
	if ( $params->%* ) {

		@mock_data = grep { $_->{customer_id} // '' eq $params->{is_customer_id} } @mock_data;

		return shift @mock_data;
	}

	@mock_data = grep { $_->{id} eq $path_params->{external_id} } @mock_data
		if $path_params->%*
	;

	return shift @mock_data;
}

app->start;
