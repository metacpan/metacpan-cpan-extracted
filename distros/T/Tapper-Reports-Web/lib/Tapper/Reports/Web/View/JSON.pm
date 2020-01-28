package Tapper::Reports::Web::View::JSON;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::Reports::Web::View::JSON::VERSION = '5.0.15';
use strict;
use warnings;

use base qw/Catalyst::View/;

sub process {

    my ( $or_self, $or_c ) = @_;

    $or_c->response->content_type('text/plain');

    if ( $or_c->stash->{content} ) {
        $or_c->response->body(
            JSON::XS::encode_json( $or_c->stash->{content} )
        );
    }
    else {
        $or_c->response->body('');
    }

    return 1;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::Reports::Web::View::JSON

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
