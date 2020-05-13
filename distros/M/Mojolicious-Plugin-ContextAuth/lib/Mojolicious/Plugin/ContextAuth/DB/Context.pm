package Mojolicious::Plugin::ContextAuth::DB::Context;

# ABSTRACT: Context object for the ContextAuth database

use Mojo::Base -base, -signatures;

use Data::UUID;
use List::Util qw(any);
use Try::Tiny;

use feature 'postderef';
no warnings 'experimental::postderef';

has [qw'dbh context_id context_name context_description error'];

sub load ($self, $id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need id" );
        return;
    }

    my $result = $self->dbh->db->select(
        corbac_contexts => [qw/context_id context_name context_description/], {
            context_id => $id,
        }
    );

    my $data = $result->hash;
    $result->finish;

    return if !$result->rows;

    my $context = __PACKAGE__->new(
        dbh => $self->dbh,
        $data->%*,
        context_id => $id,
    );

    return $context;
}

sub add ($self, %params) {
    $self->error('');

    if ( !$params{context_name} ) {
        $self->error('Need context_name');
        return;
    }

    if ( length $params{context_name} > 255 || length $params{context_name} < 3 ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    $params{context_id} = Data::UUID->new->create_str;

    my $error;
    try {
        $self->dbh->db->insert( corbac_contexts => \%params);
    } 
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    my $context = $self->load( $params{context_id} );
    return $context;
}

sub delete ($self, $id = $self->context_id) {
    $self->error('');
    
    if ( !$id ) {
        $self->error( "Need context id" );
        return;
    }

    if ( ref $id ) {
        $self->error( "Invalid context id" );
        return;
    }

    my $result;
    my $error;

    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_roles => { context_id => $id },
        );

        $self->dbh->db->delete(
            corbac_user_context_roles => { context_id => $id }
        );

        $result = $self->dbh->db->delete(
            corbac_contexts => {
                context_id => $id,
            }
        );

        $tx->commit;
    }
    catch {
        $self->error( "Cannot delete context: " . $_ );
        $error = 1;
    };

    return if $error;
    return $result->rows;
}

sub update ($self, @params) {
    $self->error('');
    
    my $id = @params % 2 ? shift @params : $self->context_id;
    my %to_update = @params;

    if ( exists $to_update{context_name} && (
        length $to_update{context_name} > 255 ||
        length $to_update{context_name} < 3 )
    ) {
        $self->error( 'Invalid parameter' );
        return;
    }

    delete $to_update{context_id};

    my $result;
    my $error;
    try {
        $result = $self->dbh->db->update(
            corbac_contexts => \%to_update,
            { context_id => $id }
        );
    }
    catch {
        $self->error( 'Invalid parameter' );
        $error = $_;
    };

    return if $error;

    if ( !$result->rows ) {
        $self->error( 'No context updated' );
        return;
    }

    return $self->load( $id );
}

sub search ($self, %params) {
    $self->error('');

    my $error;
    my @context_ids;

    try {
        my $result = $self->dbh->db->select(
            corbac_contexts => ['context_id'] => \%params,
        );

        while ( my $next = $result->hash ) {
            push @context_ids, $next->{context_id};
        }
    }
    catch {
        $self->error('Cannot search for contexts');
        $error = $_;
    };

    return if $error;
    return @context_ids;
}

sub set_user_roles ($self, %params) {
    $self->error('');
    
    if ( !$self->context_id ) {
        $self->error("Need context id");
        return;
    }

    if ( any{ !$params{$_} }qw/user_id roles/ ) {
        $self->error( "Need user_id and roles" );
        return;
    }
    
    my $user_id = $params{user_id};

    my $rows = 0;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_user_context_roles => {
                context_id => $self->context_id,
                user_id    => $user_id,
            }
        );

        $rows = -1 if !$params{roles}->@*;

        for my $role_id ( $params{roles}->@* ) {
            my $result = $self->dbh->db->insert(
                corbac_user_context_roles => {
                    user_id    => $user_id,
                    context_id => $self->context_id,
                    role_id    => $role_id,
                }
            );

            $rows += $result->rows;
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return $rows;
}

sub set_role_users ($self, %params) {
    $self->error('');
    
    if ( !$self->context_id ) {
        $self->error("Need context id");
        return;
    }

    if ( any{ !$params{$_} }qw/role_id users/ ) {
        $self->error( "Need role_id and users" );
        return;
    }

    my $role_id = $params{role_id};

    my $rows = 0;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        $self->dbh->db->delete(
            corbac_user_context_roles => {
                context_id => $self->context_id,
                role_id    => $role_id,
            }
        );

        $rows = -1 if !$params{users}->@*;

        for my $user_id ( $params{users}->@* ) {
            my $result = $self->dbh->db->insert(
                corbac_user_context_roles => {
                    user_id    => $user_id,
                    context_id => $self->context_id,
                    role_id    => $role_id,
                }
            );

            $rows += $result->rows;
        }

        $tx->commit;
    }
    catch {
        $self->error( "Transaction error: $_" );
        $error = $_;
    };

    return if $error;
    return $rows;
}

sub role_users ($self, %params) {
    $self->error('');
    
    if ( !$self->context_id ) {
        $self->error("Need context id");
        return;
    }

    my $role_id = $params{role_id};
    if ( !$role_id ) {
        $self->error( "No role id given" );
        return;
    }

    my @users;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        my $result = $self->dbh->db->select(
            corbac_user_context_roles => ['user_id'] => {
                context_id => $self->context_id,
                role_id    => $role_id,
            }
        );
        
        while ( my $next = $result->hash ) {
            push @users, $next->{user_id};
        }

        $tx->commit;
    }
    catch {
        $self->error( "Cannot get list of role users: $_" );
        $error = $_;
    };

    return if $error;
    return @users;
}

sub user_roles ($self, %params) {
    $self->error('');
    
    if ( !$self->context_id ) {
        $self->error("Need context id");
        return;
    }

    my $user_id = $params{user_id};
    if ( !$user_id ) {
        $self->error( "No user_id given" );
        return;
    }

    my @roles;
    my $error;
    try {
        my $tx = $self->dbh->db->begin;

        my $result = $self->dbh->db->select(
            corbac_user_context_roles => ['role_id'] => {
                context_id => $self->context_id,
                user_id    => $user_id,
            }
        );
        
        while ( my $next = $result->hash ) {
            push @roles, $next->{role_id};
        }

        $tx->commit;
    }
    catch {
        $self->error( "Cannot get list of user roles: $_" );
        $error = $_;
    };

    return if $error;
    return @roles;
}

1;

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::ContextAuth::DB::Context - Context object for the ContextAuth database

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    my $db = Mojolicious::Plugin::ContextAuth::DB->new(
        dsn => 'sqlite:' . $file,
    );

    my $context = Mojolicious::Plugin::ContextAuth::DB::Context->new(
        dbh => $db->dbh,
    );

    my $new_context = $context->add(
        context_name        => 'test',
        context_description => 'hallo', 
    );

    my $updated_context = $new_context->update(
        context_name        => 'ernie',
        context_description => 'bert',
    );

    # create context object with data for context id 1
    my $found_context = $context->load( 1 );

    # delete context
    $new_context->delete;

=head1 ATTRIBUTES

=over 4

=item * dbh

=item * context_name

=item * context_description

=item * context_id

=item * error

=back

=head1 METHODS

=head2 load

    # create context object with data for context id 1
    my $found_context = $context->load( 1 );

=head2 add

    my $new_context = $context->add(
        contextname      => 'test',
        context_password => 'hallo', 
    );

=head2 update

    my $updated_context = $new_context->update(
        contextname      => 'ernie',
        context_password => 'bert',
    );

=head2 delete

    $context->delete;

=head2 set_user_roles

    $context->set_user_roles(
        user_id => 123,
        roles   => [
            123,
            456,
            789,
        ],
    );

=head2 set_role_users

    $context->set_role_users(
        role_id => 123,
        users   => [
            123,
            456,
            789,
        ],
    );

=head2 role_users

    my @user_ids = $context->role_users(
        role_id => 123,
    );

=head2 user_roles

    my @role_ids = $context->user_roles(
        user_id => 123,
    );

=head2 search

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__END__
TODO:
 * bei add/update prüfen, dass contextname noch nicht existiert
 * name darf keinen Punkt enthalten