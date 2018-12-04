package Mojolicious::Plugin::DBIC::Controller::DBIC;
use Mojo::Base 'Mojolicious::Controller';
# ABSTRACT: Build simple views to DBIC data

#pod =head1 SYNOPSIS
#pod
#pod     use Mojolicious::Lite;
#pod     plugin DBIC => { schema => ... };
#pod     get '/', {
#pod         controller => 'DBIC',
#pod         action => 'list',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/list',
#pod     };
#pod
#pod =head1 DESCRIPTION
#pod
#pod This controller allows for easy working with data from the schema.
#pod Controllers are configured through the stash when setting up the routes.
#pod
#pod =head1 SEE ALSO
#pod
#pod =method list
#pod
#pod     get '/', {
#pod         controller => 'DBIC',
#pod         action => 'list',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/list',
#pod     };
#pod
#pod List data in a ResultSet.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> class to list.
#pod
#pod =back
#pod
#pod This method sets the following stash values for template rendering:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> object containing the desired objects.
#pod
#pod =back
#pod
#pod =cut

sub list {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $rs = $c->schema->resultset( $rs_class );
    return $c->render(
        resultset => $rs,
    );
}

#pod =method get
#pod
#pod     get '/blog/:id', {
#pod         controller => 'DBIC',
#pod         action => 'get',
#pod         resultset => 'BlogPosts',
#pod         template => 'blog/get',
#pod     };
#pod
#pod Fetch a single result by its ID.
#pod
#pod This method uses the following stash values for configuration:
#pod
#pod =over
#pod
#pod =item resultset
#pod
#pod The L<DBIx::Class::ResultSet> class to use.
#pod
#pod =item id
#pod
#pod The ID to pass to L<DBIx::Class::ResultSet/find>.
#pod
#pod =back
#pod
#pod This method sets the following stash values for template rendering:
#pod
#pod =over
#pod
#pod =item row
#pod
#pod The L<DBIx::Class::Row> object containing the desired object.
#pod
#pod =back
#pod
#pod =cut

sub get {
    my ( $c ) = @_;
    my $rs_class = $c->stash( 'resultset' );
    my $id = $c->stash( 'id' );
    my $rs = $c->schema->resultset( $rs_class );
    my $row = $rs->find( $id );
    return $c->render(
        row => $row,
    );
}

1;

__END__

=pod

=head1 NAME

Mojolicious::Plugin::DBIC::Controller::DBIC - Build simple views to DBIC data

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Mojolicious::Lite;
    plugin DBIC => { schema => ... };
    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

=head1 DESCRIPTION

This controller allows for easy working with data from the schema.
Controllers are configured through the stash when setting up the routes.

=head1 METHODS

=head2 list

    get '/', {
        controller => 'DBIC',
        action => 'list',
        resultset => 'BlogPosts',
        template => 'blog/list',
    };

List data in a ResultSet.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to list.

=back

This method sets the following stash values for template rendering:

=over

=item resultset

The L<DBIx::Class::ResultSet> object containing the desired objects.

=back

=head2 get

    get '/blog/:id', {
        controller => 'DBIC',
        action => 'get',
        resultset => 'BlogPosts',
        template => 'blog/get',
    };

Fetch a single result by its ID.

This method uses the following stash values for configuration:

=over

=item resultset

The L<DBIx::Class::ResultSet> class to use.

=item id

The ID to pass to L<DBIx::Class::ResultSet/find>.

=back

This method sets the following stash values for template rendering:

=over

=item row

The L<DBIx::Class::Row> object containing the desired object.

=back

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
