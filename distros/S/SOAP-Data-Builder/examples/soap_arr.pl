#!/usr/bin/perl -w

use strict;
use SOAP::Lite;
use SOAP::Data::Builder;
use Data::Dumper;

my $products = [
		{productOffering => 'XPD-2333', action => 'add', setting => [
									   {settingName=>'Speed',settingValue=>'256'},
									   {settingName=>'Name',settingValue=>'test'},
									  ]
		},
	       ];

my $builder = SOAP::Data::Builder->new();
foreach my $product (@{$products}) {
    my $this_product = $builder->add_elem(name=>'Product');
    warn "this product : $this_product\n";
    foreach (qw/productOffering action/) {
	next unless exists $product->{$_};
	$builder->add_elem(name=>$_, value=>$product->{$_}, parent=>$this_product);
    }

    my @settings = ();
    foreach my $setting (@{$product->{setting}}) {
	my $this_setting = $this_product->add_elem(name=>'setting');
	warn "this_setting : $this_setting\n";
	foreach (qw/settingName settingValue/) {
	    $this_setting->add_elem(name=>$_, value=>$setting->{$_},);
	}
    }
}

my $data = SOAP::Data->name('soap:env' => \SOAP::Data->value($builder->to_soap_data ));

my $serialized_xml = SOAP::Serializer->autotype(0)->serialize( $data );

print $serialized_xml;
print Dumper($soap_data_builder->elems());
