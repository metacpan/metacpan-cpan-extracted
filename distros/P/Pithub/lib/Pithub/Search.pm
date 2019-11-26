package Pithub::Search;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01035';
# ABSTRACT: Github legacy Search API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub email {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: email' unless $args{email};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/legacy/user/email/%s', delete $args{email} ),
        %args,
    );
}


sub issues {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    croak 'Missing key in parameters: state' unless $args{state};
    croak 'Missing key in parameters: keyword' unless $args{keyword};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/legacy/issues/search/%s/%s/%s/%s', delete $args{user}, delete $args{repo}, delete $args{state}, delete $args{keyword} ),
        %args,
    );
}


sub repos {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: keyword' unless $args{keyword};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/legacy/repos/search/%s', delete $args{keyword} ),
        %args,
    );
}


sub users {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: keyword' unless $args{keyword};
    return $self->request(
        method => 'GET',
        path   => sprintf( '/legacy/user/search/%s', delete $args{keyword} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Search - Github legacy Search API

=head1 VERSION

version 0.01035

=head1 METHODS

=head2 email

=over

=item *

This API call is added for compatibility reasons only. There's
no guarantee that full email searches will always be available.

    GET /legacy/user/email/:email

Examples:

    my $search = Pithub::Search->new;
    my $result = $search->email(
        email => 'plu@pqpq.de',
    );

=back

=head2 issues

=over

=item *

Find issues by state and keyword.

    GET /legacy/issues/search/:owner/:repository/:state/:keyword

Examples:

    my $search = Pithub::Search->new;
    my $result = $search->issues(
        user    => 'plu',
        repo    => 'Pithub',
        state   => 'open',
        keyword => 'some keyword',
    );

=back

=head2 repos

=over

=item *

Find repositories by keyword. Note, this legacy method does not
follow the v3 pagination pattern. This method returns up to 100
results per page and pages can be fetched using the start_page
parameter.

    GET /legacy/repos/search/:keyword

Examples:

    my $search = Pithub::Search->new;
    my $result = $search->repos(
        keyword => 'github',
        params  => {
            language   => 'Perl',
            start_page => 0,
        }
    );

=back

=head2 users

=over

=item *

Find users by keyword.

    GET /legacy/user/search/:keyword

Examples:

    my $search = Pithub::Search->new;
    my $result = $search->users(
        keyword => 'plu',
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2019 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
