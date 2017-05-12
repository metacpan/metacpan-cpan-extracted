package Net::Rexster::Response;

use warnings;
use strict;
use Carp;

use Moose;
use utf8;

has 'content' => (is => 'rw', isa => 'HashRef', required => 1);

__PACKAGE__->meta->make_immutable;
no Moose;

sub get_name { shift->content->{name} }
sub get_version { shift->content->{version}}
sub get_graphs { shift->content->{graphs}}
sub get_queryTime { shift->content->{queryTime}}
sub get_upTime { shift->content->{upTime}}
sub get_results { shift->content->{results}}
sub get_totalSize { shift->content->{totalSize}}
sub get_keys { shift->content->{'keys'}}
sub get_conents { shift->content }

1; # Magic true value required at end of module
