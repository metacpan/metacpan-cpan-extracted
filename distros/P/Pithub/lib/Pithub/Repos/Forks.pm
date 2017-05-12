package Pithub::Repos::Forks;
$Pithub::Repos::Forks::VERSION = '0.01033';
our $AUTHORITY = 'cpan:PLU';

# ABSTRACT: Github v3 Repo Forks API

use Moo;
use Carp qw(croak);
extends 'Pithub::Base';


sub create {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    if ( my $org = delete $args{org} ) {
        return $self->request(
            method => 'POST',
            path   => sprintf( '/repos/%s/%s/forks', delete $args{user}, delete $args{repo} ),
            data => { organization => $org },
            %args,
        );
    }
    return $self->request(
        method => 'POST',
        path   => sprintf( '/repos/%s/%s/forks', delete $args{user}, delete $args{repo} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/forks', delete $args{user}, delete $args{repo} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Repos::Forks - Github v3 Repo Forks API

=head1 VERSION

version 0.01033

=head1 METHODS

=head2 create

=over

=item *

Create a fork for the authenicated user.

    POST /repos/:user/:repo/forks

Examples:

    my $f = Pithub::Repos::Forks->new;
    my $result = $f->create(
        user => 'plu',
        repo => 'Pithub',
    );

    # or fork to an org
    my $result = $f->create(
        user => 'plu',
        repo => 'Pithub',
        org  => 'CPAN-API',
    );

=back

=head2 list

=over

=item *

List forks

    GET /repos/:user/:repo/forks

Examples:

    my $f = Pithub::Repos::Forks->new;
    my $result = $f->list(
        user => 'plu',
        repo => 'Pithub',
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
