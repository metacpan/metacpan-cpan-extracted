package Pithub::Repos::Stats;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01034';
# ABSTRACT: Github v3 repos / stats API

use Moo;

extends 'Pithub::Base';


sub contributors {
    my ( $self, %args ) = @_;
    # The default is to not wait for 200
    my $sleep = delete $args{wait_for_200} || 0;
    $self->_validate_user_repo_args( \%args );
    my $req = {
        method => 'GET',
        path => sprintf(
            '/repos/%s/%s/stats/contributors',
            delete $args{user}, delete $args{repo}
        ),
        %args
    };
    my $res = $self->request(
        %$req
    );

    if ($sleep) {
        while ($res->response->code == 202) {
            sleep $sleep;
            $res = $self->request(%$req);
        }
    }
    return $res;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Stats - Github v3 repos / stats API

=head1 VERSION

version 0.01034

=head1 METHODS

=head2 contributors

Extra arguments

=over

=item * wait_for_200

If this is set, and we receive the 202 status from github, we will sleep for
this many seconds before trying the request again. We will keep trying until we
get anything else than 202 status

=back

List contributors with stats

    GET /repos/:user/:repo/stats/contributors

Examples:

    my $repos  = Pithub::Repos::Stats->new;
    my $result = $repos->contributors( user => 'plu', repo => 'Pithub' );

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
