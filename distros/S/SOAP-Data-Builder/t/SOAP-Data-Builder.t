# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl SOAP-Data-Builder.t'

#########################

use Test::More tests => 3;

# 1
BEGIN { use_ok('SOAP::Data::Builder') };

# 2
my $builder = SOAP::Data::Builder->new();
isa_ok( $builder, 'SOAP::Data::Builder' );

my $products = [
                {productOffering => 'XPD-2333', action => 'add', setting => [
                                                                           {settingName=>'Speed',settingValue=>'256'},
                                                                           {settingName=>'Name',settingValue=>'test'},
                                                                          ]
                },
               ];

foreach my $product (@{$products}) {
    my $this_product = $builder->add_elem(name=>'Product');
    foreach (qw/productOffering action/) {
	next unless exists $product->{$_};
	$builder->add_elem(name=>$_, value=>$product->{$_}, parent=>$this_product);
    }

    my @settings = ();
    foreach my $setting (@{$product->{setting}}) {
	my $this_setting = $this_product->add_elem(name=>'setting');
	foreach (qw/settingName settingValue/) {
	    $this_setting->add_elem(name=>$_, value=>$setting->{$_},);
	}
    }
}

my $data = SOAP::Data->name('soap:env' => \SOAP::Data->value($builder->to_soap_data ));

# 3
isa_ok ($data,SOAP::Data);

