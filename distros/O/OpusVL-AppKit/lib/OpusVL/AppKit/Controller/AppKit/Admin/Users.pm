package OpusVL::AppKit::Controller::AppKit::Admin::Users;

use Moose;
use namespace::autoclean;
use String::MkPasswd qw/mkpasswd/;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_myclass              => 'OpusVL::AppKit',
);


sub auto
    : Action
    : AppKitFeature('User Administration')
{
    my ( $self, $c ) = @_;

    # add to the bread crumb..
    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Users', url => $c->uri_for( $c->controller('AppKit::Admin::Users')->action_for('index') ) } );

    # stash all users..
    my $users_rs = $c->model('AppKitAuthDB::User')->search;
    $users_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @users = $users_rs->all;
    $c->stash->{users} = \@users;

}


sub index
    : Path
    : Args(0)
    : AppKitFeature('User Administration')
{
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'appkit/admin/users/show_user.tt';
}


sub adduser
    : Local
    : Args(0)
    : AppKitFeature('User Administration')
    : AppKitForm("appkit/admin/users/user_form.yml")
{
    my ( $self, $c ) = @_;

    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Add', url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('adduser') ) } );

    my $form = $c->stash->{form};

    my $ignore_password = $c->model('AppKitAuthDB')->schema->can('password_check');
    if($ignore_password)
    {
        my $password = $form->get_all_element('password');
        $password->parent->remove_element($password);
    }
    else
    {
        # add 'Required' constraint to form .. adding means you must have set a password...
        $form->get_all_element('password')->constraint('Required');
    }
    $form->process();

    if ( $c->stash->{form}->submitted_and_valid )
    {
        my $password = $ignore_password ? mkpasswd : $form->param_value('password');
        
        # FIXME: is this a security hole?
        # should we be recording the fact we're not using the password field
        # really?
        
        my $newuser = $c->model('AppKitAuthDB::User')->new_result( { password => $password } );

        $c->stash->{form}->model->update( $newuser );

        $c->stash->{status_msg} = "User added";
        $c->stash->{thisuser}   = $newuser;
        $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Users')->action_for('show_user'), [ $c->stash->{thisuser}->id ] ) ) ;
    }
    $c->stash->{template} = "appkit/admin/users/user_form.tt";
}


sub user_specific
    : Chained('/')
    : PathPart('user')
    : CaptureArgs(1)
    : AppKitFeature('User Administration')
{
    my ( $self, $c, $user_id ) = @_;
    ( $c->stash->{thisuser} ) = $c->model('AppKitAuthDB::User')->find( $user_id );
}


sub show_user
    : Chained('user_specific')
    : PathPart('show')
    : AppKitFeature('User Administration')
    : Args(0)
{
    my ( $self, $c ) = @_;

    push ( @{ $c->stash->{breadcrumbs} }, { name => $c->stash->{thisuser}->username, url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_user'), [ $c->stash->{thisuser}->id ] ) } );

    # test if need to process user submission...
    if ( $c->req->method eq 'POST' )
    {   
        # add related user lookup for the submitted roles...
        my $user_roles = $c->req->params->{user_role};
        $user_roles = [ $user_roles ] if defined $user_roles && ! ref $user_roles;
        foreach my $role_id ( @$user_roles )
        {
            $c->stash->{thisuser}->find_or_create_related('users_roles', { role_id => $role_id } );
        }

        #$c->log->debug("************************** SUBMITTED ROLES: $#$user_roles :" . join('|', @$user_roles) );

        #.. delete any roles not required..
        $c->stash->{thisuser}->search_related('users_roles', { role_id => { 'NOT IN' => $user_roles } } )->delete;

        $c->stash->{status_msg} = "User Roles updated";
    }

    # capture and stash role information for the user..
    my @roles;
    foreach my $role_rs ( $c->user->roles_modifiable->all )
    {
        my $checked = '';
        if ( $c->stash->{thisuser}->search_related('users_roles', { role_id => $role_rs->id } )->count > 0 )
        {
            $checked = 'checked';
        }
        push( @roles, { role => $role_rs->role, input => "<INPUT TYPE='checkbox' NAME='user_role' VALUE='".$role_rs->id."' $checked>" } );
    }
    $c->stash->{roles} = \@roles;
}

sub reset_password
    : Chained('user_specific')
    : PathPart('reset')
    : AppKitFeature('User Password Administration')
    : Args(0)
    : AppKitForm
{
    my ( $self, $c ) = @_;

    my $user = $c->stash->{thisuser};
    my $prev_url = $c->uri_for( $self->action_for('show_user'), [ $user->id ] );

    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Reset password', url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('reset_password'), [ $user->id ] ) } );

    $c->forward('/appkit/admin/users/reset_password_form', [ $prev_url, $user ] );
}

# to allow other controllers to forward to this setting their own 
# breadcrumbs and passing their own url.
sub reset_password_form
    : Action
    : AppKitFeature('User Password Administration,Password Reset')
{
    my ($self, $c, $prev_url, $user) = @_;

    if ($c->req->param('cancel'))
    {
        $c->response->redirect( $prev_url );
        $c->detach;
    }

    my $form = $c->stash->{form};
    if ( $form->submitted_and_valid )
    {
        my $password = $form->param_value('newpassword');

        $user->update( { password => $password } );
        $c->flash->{status_msg} = 'Reset password';
        $c->response->redirect( $prev_url );
    }
    else
    {
        $c->stash->{form}->default_values( {
                newpassword => mkpasswd,
                user => $user->username,
            });
    }
}


sub edit_user
    : Chained('user_specific')
    : PathPart('form')
    : Args(0)
    : AppKitForm("appkit/admin/users/user_form.yml")
    : AppKitFeature('User Administration')
{
    my ( $self, $c ) = @_;

    my $form = $c->stash->{form};
    my $ignore_password = $c->model('AppKitAuthDB')->schema->can('password_check');
    if($ignore_password)
    {
        my $password = $form->get_all_element('password');
        $password->parent->remove_element($password);
    }
    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Edit', url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('edit_user'), [ $c->stash->{thisuser}->id ] ) } );

    if ( $form->submitted_and_valid )
    {
        # update the user from the form..
        $form->model->update( $c->stash->{thisuser} );

        # .. alter password if we have been passed one..
        unless($ignore_password) 
        {
            $c->stash->{thisuser}->update( 
                { password => $c->stash->{form}->param_value('password') } 
            ) if $c->stash->{form}->param_value('password');
        }

        $c->stash->{status_msg} = "User updated";
    }

    # set default values..
    $form->model->default_values( $c->stash->{thisuser} );
    $c->stash->{template} = "appkit/admin/users/user_form.tt";
}


sub delete_user
    : Chained('user_specific')
    : PathPart('delete')
    : Args(0)
    : AppKitForm("appkit/admin/confirm.yml")
    : AppKitFeature('User Administration')
{
    my ( $self, $c ) = @_;

    $c->stash->{question} = "Are you sure you want to delete the user:" . $c->stash->{thisuser}->username;
    $c->stash->{template} = 'appkit/admin/confirm.tt';

    if ( $c->stash->{form}->submitted_and_valid )
    {
        $c->stash->{thisuser}->delete;
        $c->flash->{status_msg} = "User deleted";
        $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::User')->action_for('index') ) );
    }
    elsif( $c->req->method eq 'POST' )
    {
         $c->flash->{status_msg} = "User NOT deleted";
        $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::User')->action_for('index') ) );
    }

}


sub delete_parameter
    : Chained('user_specific')
    : PathPart('deleteparameter')
    : Args(1)
    : AppKitFeature('User Administration')
{
    my ( $self, $c, $param_id ) = @_;

    $c->stash->{thisuser}->delete_related('users_parameters', { parameter_id => $param_id } );
    $c->flash->{status_msg} = "Parameter deleted";
    $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::User')->action_for('show_user'), [ $c->stash->{thisuser}->id ] ) );
}


sub add_parameter
    : Chained('user_specific')
    : PathPart('addparameter')
    : Args(0)
    : AppKitFeature('User Administration')
{
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' )
    {
        my $parameter_id        = $c->req->param('parameter_id');
        my $parameter_value     = $c->req->param('parameter_value');
        $c->stash->{thisuser}->update_or_create_related('users_parameters', { parameter_id => $parameter_id, value => $parameter_value } );
        $c->stash->{status_msg} = "Parameter updated";
    }

    # refresh show page..
    $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::User')->action_for('show_user'), [ $c->stash->{thisuser}->id ] ) ) ;
}


sub get_parameter_input
    : Chained('user_specific')
    : PathPart('addparaminput')
    : Args(1)
    : AppKitFeature('User Administration')
{
    my ( $self, $c, $param_id ) = @_;

    my $param = $c->model('AppKitAuthDB::Parameter')->find( $param_id );
    return undef unless $param;

    # get and values ther might be (for the user in the stash)...
    my $up = $c->stash->{thisuser}->find_related('users_parameters', { parameter_id => $param_id } );
    my $value = $up->value if ( $up );

    # output correct HTML..
    my $html = '';
    if ( $param->data_type eq 'boolean' )
    {
        $html .= '<div class="radio label">';
        $html .= "<label for='parameter_value_true'>True</label><input type='radio' name='parameter_value' value='1' id='parameter_value_true' " . ( $value ? "checked='1'" : '') . ">";
        $html .= '</div><div class="radio label">';
        $html .= "<label for='parameter_value_false'>False</label><input type='radio' name='parameter_value' value='0' id='parameter_value_false' " . ( $value ? '' : "checked='1'") . ">";
        $html .= "</div>";
    }
    elsif ( $param->data_type eq 'select' )
    {
        $html .= "<select name='parameter_value'> \n";
        foreach my $pdef ( $param->parameter_defaults )
        {
            my $thisval = $pdef->data;
            my $selected = $thisval eq $value ? 'selected' : '';
            $html .= "<option $selected value='$thisval'> $thisval</option>\n";
        }
        $html .= "</select> \n";
    }
    elsif ( $param->data_type eq 'integer' )
    {
        $html .= "<input type='text' name='parameter_value' value='$value' id='parameter_value' size='5'>";
    }
    else 
    {
        $html .= "<input type='text' name='parameter_value' value='$value' id='parameter_value'>";
    }

    $c->stash->{no_wrapper} = 1;
    $c->stash->{html} = $html;

}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::AppKit::Admin::Users

=head1 VERSION

version 2.29

=head2 auto

    Default action for this controller.

=head2 index

    default action for access administration.

=head2 adduser

=head2 user_specific

    Start of chain.

=head2 show_user

    End of chain.
    Display a users details.

=head2 edit_user

    End of chain.
    Display a users details.

=head2 delete_user

    End of chain.

=head2 delete_parameter

    End of chain.

=head2 add_parameter

    End of chain.

=head2 get_parameter_input

    End of chain.
    Returns the input for a parameter.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
