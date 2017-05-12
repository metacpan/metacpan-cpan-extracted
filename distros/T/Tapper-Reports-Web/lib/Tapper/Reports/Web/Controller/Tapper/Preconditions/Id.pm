package Tapper::Reports::Web::Controller::Tapper::Preconditions::Id;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Preconditions::Id::VERSION = '5.0.13';
use strict;
use warnings;

use parent 'Tapper::Reports::Web::Controller::Base';

sub index :Path :Args(1)
{
        my ( $self, $c, $id ) = @_;

        my $precond_search = $c->model('TestrunDB')->resultset('Precondition')->find($id);
        if (not $precond_search) {
                $c->response->body(qq(No precondition with id "$id" found in the database!));
                return;
        }
        $c->stash->{precondition} = $precond_search->precondition_as_hash;
        $c->stash->{precondition}{id} = $precond_search->id;
        return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Preconditions::Id

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
