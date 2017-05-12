package RDF::AllegroGraph::Transaction4;

use strict;
use warnings;

use base qw(RDF::AllegroGraph::Session4);

use Data::Dumper;
use feature "switch";

use JSON;
use URI::Escape qw/uri_escape_utf8/;

use HTTP::Request::Common;

=pod

=head1 NAME

RDF::AllegroGraph::Transaction4 - AllegroGraph transaction handle for AGv4

=head1 INTERFACE

=cut

sub new {
    my $class = shift;
    return bless { @_ }, $class;
}

sub DESTROY {
    my $self = shift;
    $self->rollback;
}

=pod

=head2 Methods (additional to L<RDF::AllegroGraph::Session4>)

=over

=item B<commit>

Commits all changes done inside the transaction to the underlying model.

B<NOTE>: When the transaction object is still accessible, it will have the same content as the
'mother' session.

=cut

sub commit {
    my $self = shift;
    my $url  = new URI ($self->{path} . '/commit');
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->post ($url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
}

=pod

=item B<rollback>

Discards all changes.

B<NOTE>: When the transaction object is still accessible, it will be empty.

=cut

sub rollback {
    my $self = shift;
    my $url  = new URI ($self->{path} . '/rollback');
    my $resp = $self->{CATALOG}->{SERVER}->{ua}->post ($url);
    die "protocol error: ".$resp->status_line.' ('.$resp->content.')' unless $resp->is_success;
}

=pod

=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>

=cut

1;

__END__
