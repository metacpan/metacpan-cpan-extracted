package Payvment::Facebook::API;

use warnings;
use strict;
use LWP::UserAgent;
use Data::Dumper;

=head1 NAME

Payvment::API - Payvment Facebook API

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module presents an easy to use Payvment API for Creating a webstore on Facebook.

Pl. have a look at scripts in the folder for more details

use Payvment::Facebook::API;
use Data::Dumper;
use DBI;
use DBD::mysql;

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


 

=head1 FUNCTIONS

=head2 new

=cut

our $VERSION = '0.01';

sub new {
	my $self    = shift;
	my %options = @_;
	my %url     = (
		'urlproduct' => 'https://api.payvment.com/1/admin/products/import',
		'urlproduct_status'  => 'https://api.payvment.com/1/admin/status/import'
	);
	my $options = {
		"payvment_id"      => $options{payvment_id},
		"payvment_api_key" => $options{'payvment_api_key'},
		%url

	};
	my $obj = bless $options, $self;
}

sub submitxml {
	my ( $self, %options ) = @_;
	return {
		'err'     => 1,
		'message' => 'Found incompatible method ' . $options{'method'}
	  }
	  if ( !grep { $_ eq $options{'method'} }
		( 'product', 'product_status', 'order', 'update_inventory' ) );
	my $ua = LWP::UserAgent->new;

	#	$ua->timeout(10);

	my $filecont = "";
	my $cont;
	while ( read( $options{filehandle}, $cont, 1000 ) ) {
		$filecont .= $cont;
	}

	my $req = HTTP::Request->new( POST => $self->{ 'url' . $options{method} } );
	$req->authorization_basic( $self->{payvment_id},
		$self->{payvment_api_key} );
	$req->content_type('application/x-www-form-urlencoded');
	#print $filecont;
	$req->content($filecont);

	my $res = $ua->request($req);
	if ( $res->is_success ) {
		return { 'err' => 0, cont => $res->decoded_content };
	}
	else {
		return { 'err' => 1, cont => $res->status_line };
	}

	#	$self->_submitxml(%options);
}

sub generate_xml {
	my ( $self, %options ) = @_;

	return {
		'err'     => 1,
		'message' => 'Found incompatible method ' . $options{'method'}
	  }
	  if ( !grep { $_ eq $options{'method'} }
		( 'product', 'product_status', 'order', 'update_inventory' ) );

	return { 'err' => 1, 'message' => 'Found incompatible type' }
	  if ( !grep { $_ eq $options{'type'} } ( 'header', 'body', 'footer' ) );

	$self->_generate_product_xml_header(%options)
	  if $options{'type'} eq "header" && $options{method} eq "product";

	$self->_generate_product_xml_body(%options)
	  if $options{'type'} eq "body" && $options{method} eq "product";

	$self->_generate_product_xml_footer(%options)
	  if $options{'type'} eq "footer" && $options{method} eq "product";
	return { err => 0 };
}

sub _generate_product_xml_header {
	my ( $self, %options ) = @_;
	print "hi";

	#print Dumper %options;
	print { $options{filehandle} }
	  "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
	  . "<request>\n"
	  . "<handshake>\n"
	  . "<payvment_id>"
	  . $self->{payvment_id}
	  . "</payvment_id>\n"
	  . "<version>1.x</version>"
	  . "<response_format>XML</response_format>\n"
	  . "</handshake>\n"
	  . "<products update_on_duplicate_sku=\"1\">\n";
}

sub _generate_product_xml_body {
	my ( $self, %options ) = @_;
	print { $options{filehandle} } "<product>\n" . "<name>"
	  . _cdata( $options{"name"} )
	  . "</name>\n"
	  . "<description>"
	  . _cdata( $options{"description"} )
	  . "</description>\n"
	  . "<price>"
	  . _escapexml( $options{"price"} )
	  . "</price>\n"
	  . "<currency>"
	  . _escapexml( $options{"currency"} )
	  . "</currency>\n" . "<qty>"
	  . _escapexml( $options{"qty"} )
	  . "</qty>\n"
	  . "<enable_additional_qty>"
	  . _escapexml( $options{"enable_additional_qty"} )
	  . "</enable_additional_qty>\n"
	  . "<weight>"
	  . _escapexml( $options{"weight"} )
	  . "</weight>\n"
	  . "<weight_unit>"
	  . _escapexml( $options{"weight_unit"} )
	  . "</weight_unit>\n" . "<sku>"
	  . _cdata( $options{"sku"} )
	  . "</sku>\n"
	  . "<images>"
	  . $self->_print_images( 'images' => $options{'images'} )
	  . "</images>"

	  . "<new_state>"
	  . _escapexml( $options{"new_state"} )
	  . "</new_state>\n"
	  . "<tags>"
	  . _cdata( $options{"tags"} )
	  . "</tags>\n"
	  . "<is_taxable>"
	  . _escapexml( $options{"is_taxable"} )
	  . "</is_taxable>\n"
	  . "<categories>"

	  . $self->_print_categories( 'categories' => $options{'categories'} )
	  . "</categories>"
	  . "<client_category_name>"
	  . _cdata( $options{"client_category_name"} )
	  . "</client_category_name>\n"
	  ."<shipping_method>UPS</shipping_method>"
	  . "</product>\n";

}

sub _generate_product_xml_footer {
	my ( $self, %options ) = @_;

	print { $options{filehandle} } "</products>\n</request>";

}

sub _print_categories {
	my ( $self, %options ) = @_;
	my $ret;
	foreach my $cat ( split( /\,/, $options{categories} ) ) {
		$ret .= "<code>" . _escapexml($cat) . "</code>\n";
	}
	return $ret;
}

sub _print_images {
	my ( $self, %options ) = @_;
	my $ret;
	foreach my $img ( @{ $options{images} } ) {
		$ret .= "<image>" . _escapexml($img) . "</image>\n";

	}
	return $ret;
}

sub _escapexml {
	my ($var) = @_;
	$var =~ s/</&lt;/isg;
	$var =~ s/>/&gt;/isg;
	$var =~ s/&/&amp;/isg;
	return $var;
}

sub _cdata {
	my ($var) = @_;
	return "<![CDATA[" . _escapexml($var) . "]]>";
}

#notes: Generate XML. Product, UpdateInventory,Product Status, Order.  - SubmitXML to Paymemnt

=head1 AUTHOR

"abhishek jain", C<< <"goyali at cpan.org"> >>

=head1 BUGS

Please report any bugs or feature requests directly to the author at C<< <"goyali at cpan.org"> >>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Payvment::Facebook::API

You can also email the author and rest assured of the reply

=head1 COPYRIGHT & LICENSE

Copyright 2011 "abhishek jain".

Licence   This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DESCRIPTION

This API lets one to list products and sell on facebook using the Payvment Facebook App.

At the moment these methods are implemented:

=over 4

=item C<new>

A constructor


=item C<submitxml>
As in Synopsis.

=item C<generatexml>
As in Synopsis.

=back

=head1 NOTE:

This module is provided as is, and is still underdevelopment, not suitable for Production use.

Virus free , Spam Free , Spyware Free Software and hopefully Money free software .

For more details on payvment visit http://www.payvment.com

=head1 AUTHOR

<Abhishek jain>
goyali at cpan.org

=head1 SEE ALSO

http://www.ejain.com

http://www.payvment.com

=cut

1;
