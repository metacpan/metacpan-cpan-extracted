package Tapper::Reports::Web::Controller::Tapper::Reports::Info;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::Controller::Tapper::Reports::Info::VERSION = '5.0.15';
use strict;
use warnings;

use Data::Dumper;

use parent 'Tapper::Reports::Web::Controller::Base';

sub firstid :Path('firstid') :Args(0) {
    my ( $self, $c ) = @_;

    # SELECT MIN(id) FROM report;
    my $first_id = $c->model('TestrunDB')->resultset('Report')->get_column("id")->min;
    $c->response->body($first_id);
}

sub lastid :Path('lastid') :Args(0) {
    my ( $self, $c ) = @_;

    # SELECT MAX(id) FROM report;
    my $last_id = $c->model('TestrunDB')->resultset('Report')->get_column("id")->max;
    $c->response->body($last_id);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::Controller::Tapper::Reports::Info

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
