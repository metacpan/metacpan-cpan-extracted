package RDF::AllegroGraph::Server3;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Server);

=pod

=head1 NAME

RDF::AllegroGraph::Server3 - AllegroGraph server handle for the AGv3 series

=head1 SYNOPSIS

# same interface as RDF::AllegroGraph::Server

=cut

use JSON;
use Data::Dumper;

use RDF::AllegroGraph::Catalog3;

=pod

=head1 INTERFACE

=head2 Methods

=over

=cut

sub catalogs {
    my $self = shift;
    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/catalogs');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $cats = from_json ($resp->content);
#    warn Dumper $cats;
    return 
	map { $_ => RDF::AllegroGraph::Catalog3->new (NAME => $_, SERVER => $self) }
        map { s|^/catalogs|| && $_ }   
        @$cats;
}

sub ping {
    my $self = shift;
    $self->catalogs and return 1;                                    # even if there are no catalogs, we survived the call
}

sub models {
    my $self = shift;
    my %cats = $self->catalogs;                                      # find all catalogs
    return
	map { $_->id => $_ }                                         # generate a hash, because the id is a good key
	map { $_->repositories }                                     # generate from the catalog all its repos
        values %cats;          
}

sub model {
    my $self = shift;
    my $id   = shift;
    my %options = @_;

    my ($catid, $repoid) = ($id =~ q|(/.+?)(/.+)|) or die "id must be of the form /something/else";

    my %catalogs = $self->catalogs;
    die "no catalog '$catid'" unless $catalogs{$catid};

    return $catalogs{$catid}->repository ($id, $options{mode});
}

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(0[9]|11) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

our $VERSION  = '0.02';

1;

__END__

#sub protocol {
#    my $self = shift;
#    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/protocol');
#    die "protocol error: ".$resp->status_line unless $resp->is_success;
#    return $resp->content;
#}

