#!/usr/bin/env perl

use strict;
use warnings;
use Plack::App::RDF::LinkedData;
use RDF::LinkedData;
use Plack::Request;
use Plack::Builder;
use Config::ZOMG;
use Carp qw(confess);
use Module::Load::Conditional qw[can_load];

=head1 NAME

linked_data.psgi - A simple Plack server for RDF as linked data

=head1 INSTRUCTIONS

See L<Plack::App::RDF::LinkedData> for instructions on how to use this.

=cut



my $config;
BEGIN {
	unless ($config = Config::ZOMG->open(
                                        name => "RDF::LinkedData"
                                       )) {
		if ($ENV{'PERLRDF_STORE'}) {
			$config->{store} = $ENV{'PERLRDF_STORE'};
			$config->{base_uri} = 'http://localhost:5000';
		} else {
			confess "Couldn't find config";
		}
	}
}

if ($ENV{'LOG_ADAPTER'}) {
  use Log::Any::Adapter;
  Log::Any::Adapter->set($ENV{'LOG_ADAPTER'});
}


my $linkeddata = Plack::App::RDF::LinkedData->new();

$linkeddata->configure($config);

my $rdf_linkeddata = $linkeddata->to_app;

builder {
	enable "Head";
	enable "ContentLength";
	enable "ConditionalGET";
	if (defined($config->{expires}) && (can_load( modules => { 'Plack::Middleware::Expires' => 0 }))) {
		enable 'Expires',
		  content_type => qr//,
		  expires => $config->{expires}
	  };
	if (can_load( modules => { 'Plack::Middleware::CrossOrigin' => 0 })) { enable 'CrossOrigin' => %{$config->{cors}}};
	$rdf_linkeddata;
};


__END__


=head1 AUTHOR

Kjetil Kjernsmo C<< <kjetilk@cpan.org> >>

=head1 COPYRIGHT

Copyright (c) 2010 ABC Startsiden AS and Gregory Todd Williams and
2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kjetil Kjernsmo. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=cut
