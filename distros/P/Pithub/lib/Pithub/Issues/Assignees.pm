package Pithub::Issues::Assignees;
our $AUTHORITY = 'cpan:PLU';
our $VERSION = '0.01037';
# ABSTRACT: Github v3 Issue Assignees API

use Moo;
use Carp qw( croak );
extends 'Pithub::Base';


sub check {
    my ( $self, %args ) = @_;
    croak 'Missing key in parameters: assignee' unless $args{assignee};
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/assignees/%s', delete $args{user}, delete $args{repo}, delete $args{assignee} ),
        %args,
    );
}


sub list {
    my ( $self, %args ) = @_;
    $self->_validate_user_repo_args( \%args );
    return $self->request(
        method => 'GET',
        path   => sprintf( '/repos/%s/%s/assignees', delete $args{user}, delete $args{repo} ),
        %args,
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pithub::Issues::Assignees - Github v3 Issue Assignees API

=head1 VERSION

version 0.01037

=head1 METHODS

=head2 check

=over

=item *

You may also check to see if a particular user is an assignee for a repository.

    GET /repos/:user/:repo/assignees/:assignee

If the given assignee login belongs to an assignee for the repository, a 204
header with no content is returned.

Examples:

    my $c      = Pithub::Issues::Assignees->new;
    my $result = $c->check(
        repo     => 'Pithub',
        user     => 'plu',
        assignee => 'plu',
    );
    if ( $result->success ) {
        print "plu is an assignee for the repo plu/Pithub.git";
    }

=back

=head2 list

=over

=item *

This call lists all the available assignees (owner + collaborators)
to which issues may be assigned.

    GET /repos/:user/:repo/assignees

Examples:

    my $c      = Pithub::Issues::Assignees->new;
    my $result = $c->list(
        repo => 'Pithub',
        user => 'plu',
    );

=back

=head1 AUTHOR

Johannes Plunien <plu@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Johannes Plunien.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
