#/usr/bin/perl

use strict;

use Payvment::Facebook::API;
use Data::Dumper;
use DBI;
use DBD::mysql;

my $subsidiary = "us";
my $xml        = "product";
my $operation  = "generatexml";

my $infile={product=>'productout.xml',
			product_status	=>	'productoutstatus.xml'
};

my $pfapi = Payvment::Facebook::API->new(
	'payvment_id'      => '',   # Enter values here
	'payvment_api_key' => ''    # Enter values here
);

if ( $operation eq 'generatexml' ) {
	open FILE, ">".$infile->{$xml};

	$pfapi->generate_xml(
		'method'     => $xml,
		'type'       => 'header',
		'filehandle' => *FILE
	);

	
		my $images = [];
		
		#	push @$images, $image_url; #repeat this
		
		$pfapi->generate_xml(
			'method'              => 'product',
			'type'                => 'body',
			'filehandle'          => *FILE,
			name                  => $row->{name},
			description           => $row->{description},
			price                 => $row->{price},
			currency              => $row->{currency},
			qty                   => $row->{qty},
			enable_additional_qty => $row->{enable_additional_qty},
			weight                => $row->{weight},
			weight_unit           => $row->{weight_unit},
			sku                   => $row->{sku},

			images               => $images,
			new_state            => $row->{new_state},
			tags                 => $row->{tags},
			is_taxable           => $row->{is_taxable},
			categories           => $row->{ppcategories},
			client_category_name => $row->{client_category_name}
		);
	}

	$pfapi->generate_xml(
		'method'     => 'product',
		'type'       => 'footer',
		'filehandle' => *FILE
	);

	close FILE;
	print "done create xml";


} elsif ( $operation eq 'submit' ) {

	open FILE, "<".$infile->{$xml} or die"cannt open file";

	my $cont = $pfapi->submitxml(
		'method'     => $xml,
		'filehandle' => *FILE
	);
	my $user = "dbuser";
	my $pass = 'password';
	my $dsn  = 'dbi:mysql:db:localhost:3306';
	my $dbh  = DBI->connect( $dsn, $user, $pass )
	  or die "Can't connect to the DB: $DBI::errstr\n";

	my $query =
"insert into payvment_requests(pr_responsecont,pr_dated,pr_type) values(?, now(),?)";
	my $sth = $dbh->prepare($query);
	$sth->bind_param( 1, $cont->{cont} );
	$sth->bind_param( 2, $xml );
	$sth->execute;

	close FILE or die"";
	print "done submit xml";
}

