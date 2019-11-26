package Pithub::SearchV3;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01035';
# ABSTRACT: Github v3 Search API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub issues {
    my $self = shift;
    return $self->_search('issues', @_);
}


sub repos {
    my $self = shift;
    return $self->_search('repositories', @_);
}


sub users {
    my $self = shift;
    return $self->_search('users', @_);
}


sub code {
    my $self = shift;
    return $self->_search('code', @_);
}

sub _search {
    my ( $self, $thing_to_search, %args ) = @_;
    croak 'Missing key in parameters: q' unless exists $args{q};
    return $self->request(
        method => 'GET',
        path   => '/search/' . $thing_to_search,
        query => {
            q => delete $args{q},
            (exists $args{sort}  ? (sort  => delete $args{sort})  : ()),
            (exists $args{order} ? (order => delete $args{order}) : ()),
        },
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::SearchV3 - Github v3 Search API

=head1 VERSION

version 0.01035

=head1 METHODS

=head2 issues

=over

=item *

Find issues by state and keyword.

    GET /search/issues

Examples:

    my $search = Pithub::Search->new;
    my $result = $search->issues(
        q => 'some keyword',
    );

=back

=head2 repos

=over

=item *

Find repositories by keyword.

    GET /search/repositories

Examples:

    my $search = Pithub::SearchV3->new;
    my $result = $search->repos(
        q => 'github language:Perl',
    );

=back

=head2 users

=over

=item *

Find users by keyword.

    GET /search/users

Examples:

    my $search = Pithub::SearchV3->new;
    my $result = $search->users(
        q => 'plu',
    );

=back

=head2 code

=over

=item *

Search code by keyword.

    GET /search/code

Examples:

    my $search = Pithub::SearchV3->new;
    my $result = $search->code(
        q => 'addClass repo:jquery/jquery',
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011-2019 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
