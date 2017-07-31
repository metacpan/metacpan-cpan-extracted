package Test2Factory;

use Moose;
use namespace::autoclean;
use Test2Impl;

with 'MooseX::DIC::Injectable' => { implements => 'Test2', builder => 'Factory' };

sub build_service {
	my ($self,$service_package, $container) = @_;

	# Fetch known Test2Impl dependencies first
	my $test1 = $container->get_service('Test1');

	my $service = Test2Impl->new( dependency => $test1 );

	return $service;
}

__PACKAGE__->meta->make_immutable;
1;
