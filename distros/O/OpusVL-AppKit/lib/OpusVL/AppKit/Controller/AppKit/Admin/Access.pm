package OpusVL::AppKit::Controller::AppKit::Admin::Access;

use Moose;
use namespace::autoclean;
use Tree::Simple::View::HTML;
use Tree::Simple::VisitorFactory;

BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_myclass              => 'OpusVL::AppKit',
);



sub auto
    : AppKitFeature('Role Administration')
    : Action
{
    my ( $self, $c ) = @_;

    # add to the bread crumb..
    push ( @{ $c->stash->{breadcrumbs} }, { name => 'Access', url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('index') ) } );

}


sub index
    : Path
    : Args(0)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'appkit/admin/access/show_role.tt';
}


sub addrole
    : Local
    : AppKitFeature('Role Administration')
{
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST')
    {
        my $rolename    = $c->req->param('rolename');
        if($rolename)
        {
            my $role = grep /^\Q$rolename\E$/, $c->user->roles;
            $c->flash->{error_msg} = 'Role already exists' if $role;
            $role = $c->user->add_to_roles( { role => $rolename } ) if !$role;

            if ( $role )
            {
                $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_role'), [ $rolename ] ) );
            }
            else
            {
                $c->stash->{error_msg} = 'Role not added';
            }
        }
        else
        {
            $c->stash->{error_msg} = 'Specify a role name!';
        }
    }

    # basically run the action for the index for this page..
    $c->go( $c->controller('AppKit::Admin::Access')->action_for('index') );
}


sub role_specific
    : Chained('/')
    : PathPart('admin/access/role')
    : CaptureArgs(1)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c, $rolename ) = @_;

    # put role into stash..
    $c->stash->{role} = $c->model('AppKitAuthDB::Role')->find( { role => $rolename } );
    if(!$c->stash->{role})
    {
        $c->detach('/not_found');
    }

}


sub role_management
    : Chained('role_specific')
    : PathPart('management')
    : Args(0)
    : AppKitForm
    : AppKitFeature('Role Administration')
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my $role = $c->stash->{role};

    if($c->req->param('cancel'))
    {
        $c->response->redirect($c->uri_for($self->action_for('show_role'), [ $role->role ]));
        $c->detach;
    }
    my $selection = $form->get_all_element({ type => 'Checkboxgroup', name => 'roles_allowed_roles'});
    my @all_roles = $c->model('AppKitAuthDB::Role')->all;
    my @options = map { [ $_->id, $_->role ] } @all_roles;
    $selection->options(\@options);
    my @selected = $role->roles_allowed_roles->get_column('role_allowed')->all;
    my $can_change_any_role = $role->can_change_any_role;
    if(@selected || $can_change_any_role)
    {
        my $defaults = { can_change_any_role => $can_change_any_role };
        $defaults->{ roles_allowed_roles } = \@selected if @selected;
        $form->default_values( { 
            roles_allowed_roles => \@selected,
            can_change_any_role => $can_change_any_role,
        } );
    }
    $form->process;

    if($form->submitted_and_valid)
    {
        my $ids = $form->param_array('roles_allowed_roles');
        my $can_change_any_role = $form->param_value('can_change_any_role');
        if(!$can_change_any_role)
        {
            $role->delete_related('roles_allowed_roles');
            $role->create_related('roles_allowed_roles', { role_allowed => $_}) for @$ids;
        }
        $role->can_change_any_role($can_change_any_role);
        $c->flash->{status_msg} = 'Permissions changed';
    }

}


sub user_for_role
    : Chained('role_specific')
    : PathPart('user')
    : CaptureArgs(1)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c, $user_id ) = @_;
    $c->stash->{roleuser} = $c->model('AppKitAuthDB::User')->find( $user_id );
}


sub user_delete_from_role
    : Chained('user_for_role')
    : PathPart('delete')
    : Args(0)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c ) = @_;
    # delete user/role lookup..
    $c->stash->{role}->delete_related('user_roles', { user_id => $c->stash->{roleuser}->id } );
    # refresh show page..
    $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_role'), [ $c->stash->{role}->role ] ) ) ;
}


sub delete_role
    : Chained('role_specific')
    : PathPart('delrole')
    : Args(0)
    : AppKitForm("appkit/admin/confirm.yml")
    : AppKitFeature('Role Administration')
{   
    my ( $self, $c ) = @_;

    $c->stash->{question} = "Are you sure you want to delete the role: " . $c->stash->{role}->role;
    $c->stash->{template} = 'appkit/admin/confirm.tt';

    if ( $c->stash->{form}->submitted_and_valid )
    {   
        $c->stash->{role}->delete;
        $c->flash->{status_msg} = "Role deleted";
        $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('index') ) );
    }
    elsif( $c->req->method eq 'POST' )
    {
        $c->flash->{status_msg} = "Role NOT deleted";
        $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('index') ) );
    }

}


sub user_add_to_role
    : Chained('role_specific')
    : PathPart('adduser')
    : Args(0)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c ) = @_;

    if ( $c->req->method eq 'POST' )
    {
        # create the look up..
        my $user_id        = $c->req->param('user_id');
        $c->stash->{role}->update_or_create_related('user_roles', { user_id => $user_id } );
    }

    # refresh show page..
    $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_role'), [ $c->stash->{role}->role ] ) ) ;
}


sub action_rule_for_role
    : Chained('role_specific')
    : PathPart('rule')
    : Args(2)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c, $action, $action_path ) = @_;

    # find any access control rule for the passed action path..
    my $aclrule =  $c->model('AppKitAuthDB::Aclrule')->find( { actionpath => $action_path } );

    if ( ! $aclrule )
    {
        $aclrule =  $c->model('AppKitAuthDB::Aclrule')->create( { actionpath => $action_path } );
    }

    if ( $action eq 'deny' )
    {
        $c->stash->{status_msg} .= "Removed role " . $c->stash->{role}->role . " from access control rule:" . $aclrule->actionpath;
        $aclrule->delete_related('aclrule_roles', { role_id => $c->stash->{role}->id } );
    }
    elsif ( $action eq 'allow' )
    {
        $c->stash->{status_msg} .= "Added role " . $c->stash->{role}->role . " to access control rule:" . $aclrule->actionpath;
        $aclrule->create_related('aclrule_roles', { role_id => $c->stash->{role}->id } );
    }
    elsif ( $action eq 'revoke' )
    {
        $c->stash->{status_msg} .= "Revoked access control for:" . $aclrule->actionpath;
        $aclrule->delete;
    }

    # refresh show page..
    $c->res->redirect( $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_role'), [ $c->stash->{role}->role ] ) ) ;
}


sub show_role
    : Chained('role_specific')
    : PathPart('show')
    : Args(0)
    : AppKitFeature('Role Administration')
{
    my ( $self, $c ) = @_;

    push ( @{ $c->stash->{breadcrumbs} }, { name => $c->stash->{role}->role, url => $c->uri_for( $c->controller('AppKit::Admin::Access')->action_for('show_role'), [ $c->stash->{role}->id ] ) } );

    # stash the tree..
    $c->stash->{action_tree} = $c->appkit_actiontree;

    # get role to show from stash..
    my $show_role = $c->stash->{role}->role;

    # build my visitor to get the path to the root..
    my $path2root_visitor = Tree::Simple::VisitorFactory->getVisitor("PathToRoot");
    $path2root_visitor->setNodeFilter(sub { my ($t) = @_; return $t->getNodeValue()->node_name });
    $c->stash->{appkit_features} = $c->appkit_features->feature_list($show_role);
    $c->stash->{descriptions} = $c->model('AppKitAuthDB::Aclfeature')->descriptions;

    # test if need to process some rules submission...
    if ( $c->req->method eq 'POST' )
    {
        my @features_allowed;
        my @features_denied;
        for my $app (keys %{$c->stash->{appkit_features}})
        {
            my $features = $c->stash->{appkit_features}->{$app};
            for my $feature (keys %$features)
            {
                if($c->req->params->{"feature_$app/$feature"})
                {
                    push @features_allowed, "$app/$feature";
                }
                else
                {
                    push @features_denied, "$app/$feature";
                }
            }
        }
        for my $feature (@features_allowed)
        {
            $c->log->debug("****************ALLOWING FEATURE:" . $feature . "\n") if $c->debug;
            my $aclfeature = $c->model('AppKitAuthDB::Aclfeature')->find_or_create( { feature => $feature } );
            $c->stash->{role}->update_or_create_related('aclfeature_roles', { aclfeature_id => $aclfeature->id } );
        }
        for my $feature (@features_denied)
        {
            $c->log->debug("****************DENYING FEATURE:" . $feature . "\n") if $c->debug;
            my $aclfeature = $c->model('AppKitAuthDB::Aclfeature')->find_or_create( { feature => $feature } );
            $c->stash->{role}->search_related('aclfeature_roles', { aclfeature_id => $aclfeature->id } )->delete;
        }
        # now we run traverse the tree finding if we are allowing access or not...

        my $allowed = [];
        my $denied  = [];
        $c->stash->{action_tree}->traverse
        (
            sub 
            {
                my ($_tree) = @_;
                $_tree->accept($path2root_visitor);
                my $path = $path2root_visitor->getPathAsString("/");
                if ( $c->req->params->{'action_' . $path} )
                {
                    push ( @$allowed, $path );
                }
                else
                {
                    push ( @$denied, $path );
                }
            },
        );

        foreach my $path ( @$allowed )
        {
            $c->log->debug("***************ALLOWING:" . $path . "\n") if $c->debug;
            my $aclrule = $c->model('AppKitAuthDB::Aclrule')->find_or_create( { actionpath => $path } );
            $c->stash->{role}->update_or_create_related('aclrule_roles', { aclrule_id => $aclrule->id } );
        }
        foreach my $path ( @$denied )
        {
            $c->log->debug("****************DENYING:" . $path . "\n") if $c->debug;
            my $aclrule = $c->model('AppKitAuthDB::Aclrule')->find_or_create( { actionpath => $path } );
            $c->stash->{role}->search_related('aclrule_roles', { aclrule_id => $aclrule->id } )->delete;
        }

        # now we have allowed and denied access to the different parts of the tree... we need to rebuild it..
        $c->stash->{action_tree} = $c->appkit_actiontree(1); # built with a 'force re-read'
        $c->stash->{appkit_features} = $c->appkit_features->feature_list($show_role);

    }


    # create the tree view...
    # need to prune items that are in_feature 
    # to prevent confusion.
    my $display_tree = $c->stash->{action_tree}->clone;
    my @remove;
    $display_tree->traverse(sub {
        my ($tree) = @_;
        push @remove, $tree if($tree->getNodeValue->in_feature);
        push @remove, $tree if($tree->getNodeValue->action_attrs && defined $tree->getNodeValue->action_attrs->{AppKitAllAccess});
    });
    for my $item (@remove)
    {
        my $parent = $item->getParent;
        $parent->removeChild($item);
        while($parent->getChildCount == 0)
        {
            my $item = $parent;
            $parent = $parent->getParent;
            last if !$parent->can('removeChild');
            $parent->removeChild($item);
        }
    }
    my $tree_view = Tree::Simple::View::HTML->new
    (
        $display_tree => 
        (
            list_css                => "list-style: circle;",
            list_item_css           => "font-family: courier;",
            node_formatter          => sub 
            {
                my ($tree) = @_;
                my $node_string = $tree->getNodeValue()->node_name;

                $tree->accept($path2root_visitor);
                my $checkbox_name = $path2root_visitor->getPathAsString("/");

                my $checked             = '';
                my $color               = 'blue';

                if($tree->getNodeValue->in_feature)
                {
                    # it's part of a feature so avoid using this mechanism.
                    $color = 'grey';
                }
                elsif ( defined $tree->getNodeValue->action_path )
                {
                    $color = 'red';
                    if ( my $roles = $tree->getNodeValue->access_only )
                    {
                       my $matched_role = 0;
                       foreach my $allowed_role ( @{ $tree->getNodeValue->access_only } )
                       {
                           $matched_role = 1 if ( $allowed_role eq $show_role );
                       }
                       if ( $matched_role ) # rules and a matched.. therefore, access :)..
                       {
                           $checked = 'checked';
                           $color   = 'green';
                       }
                    }
                    $node_string = "<input type='checkbox' name='action_$checkbox_name' value='allow' $checked>" . $node_string;
                }
                else
                {
                    $node_string = $node_string;
                }
                $node_string = "<font color='$color'>" . $node_string . "</font>";
                return $node_string;
            }
        )
    );  
    $c->stash->{access_control_role_tree} = $tree_view;

    # manually set (as we may forward to this action).
    $c->stash->{template} = 'appkit/admin/access/show_role.tt';
}

sub edit_descriptions
    : Local
    : AppKitFeature('Feature Documentation')
    : AppKitForm
{
    my ($self, $c) = @_;

    my $form = $c->stash->{form};
    my @features = $c->model('AppKitAuthDB::Aclfeature')->sorted->all;
    my $count = @features;
    $self->add_final_crumb($c, 'Feature documentation');
    $form->get_all_element('features')->repeat($count);
    my $defaults = {};
    if($form->submitted_and_valid)
    {
        my %by_id = map { $_->id => $_ } @features;
        my $schema = $c->model('AppKitAuthDB')->schema;
        my $guard = $schema->storage->txn_scope_guard;
        for(my $i = 1; $i <= $count; $i++)
        {
            my $id = $c->req->params->{"id_$i"};
            my $description = $c->req->params->{"feature_description_$i"} || undef;
            my $feature = $by_id{$id};
            if($feature)
            {
                $feature->update({ feature_description => $description });
            }
        }
        $guard->commit;
        $c->flash->{status_msg} = 'Changes saved';
        $c->res->redirect($c->req->uri);
    }
    else
    {
        my $i = 1;
        for my $f (@features)
        {
            $form->get_all_element("feature_description_$i")->label($f->feature);
            $defaults->{"id_$i"} = $f->id;
            #$defaults->{"feature_$i"} = $f->feature;
            $defaults->{"feature_description_$i"} = $f->feature_description;
            $i++;
        }
        $form->default_values($defaults);
    }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Controller::AppKit::Admin::Access

=head1 VERSION

version 2.29

=head2 auto

    Default action for this controller.

=head2 index

    default action for access administration.

=head2 addrole

    Add a role

=head2 role_specific

    Start of chain.
    Action to capture role specific action..

=head2 role_management

=head2 user_for_role

    Middle of chain.

=head2 user_delete_from_role

    End of chain.
    Add a user to a role (and give it a value)

=head2 delete_role

    End of chain.
    Deletes a role (after confirmation)

=head2 user_add_to_role

    End of chain.
    Adds a user to a role

=head2 action_rule_for_role

    End of chain.

=head2 show_role

    End of chain.
    Action to display role info page.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
