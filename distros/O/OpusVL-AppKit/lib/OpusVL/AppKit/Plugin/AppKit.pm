package OpusVL::AppKit::Plugin::AppKit;


###########################################################################################################################
# use lines.
###########################################################################################################################
use Moose;
use namespace::autoclean;
use 5.010;
use Tree::Simple;
use Tree::Simple::Visitor::FindByPath;
use OpusVL::AppKit::Plugin::AppKit::Node;
use OpusVL::AppKit::Plugin::AppKit::FeatureList;
use experimental 'smartmatch';
with 'Catalyst::ClassData';

###########################################################################################################################
# moose calls.
###########################################################################################################################

has appkit_controllers => ( is => 'ro',    isa => 'ArrayRef',  lazy_build => 1 );
sub _build_appkit_controllers
{   
    my ( $c ) = shift;

    my @controllers;

    # Get all the components for this app... sorted by length of the name of the componant so they are in hierarchical order (bit hacky, but think it should work)
    foreach my $comp ( sort { length($a) <=> length($b) } values %{ $c->components } )
    {   
        # Check this is a controller for AppKit.... (not sure if we need to ignore others, but it just seems cleaner)..
        if  (
                ( $comp->isa('Catalyst::Controller')    )               &&
                ( $comp->can('appkit') )
            )
        {   
            push( @controllers, $comp );
        }
    }
    return \@controllers;
}

sub apps_allowed
{
    my $self = shift;
    # return a sorted list of appkit controllers the user can use.
    return sort { $a->appkit_order <=> $b->appkit_order } 
            grep { $_->home_action && $self->can_access($_->home_action->{actionpath}) } @{$self->appkit_controllers};
}

sub menu_data
{
    # rip through the apps and construct an array of apps containing the 
    # group info too.
    my $self = shift;

    my @apps = sort { ($a->appkit_shared_module || '') cmp ($b->appkit_shared_module || '') || $b->appkit_order <=> $a->appkit_order } 
            @{$self->appkit_controllers};
    # now merge together the grouped controllers.
    my $i = 0;
    while($i + 1 < scalar @apps)
    {
        if($apps[$i]->appkit_shared_module && $apps[$i+1]->appkit_shared_module && 
            ($apps[$i]->appkit_shared_module eq $apps[$i+1]->appkit_shared_module))
        {
            splice @apps, $i + 1, 1;
        }
        else
        {
            $i++;
        }
    }
    @apps = sort { $a->appkit_order <=> $b->appkit_order } @apps;
    my $menu = [];

    for my $app (@apps)
    {
        my $actions = $app->application_action_list($self);
        if(@$actions)
        {
            push @$menu, { controller => $app, actions => $actions };
        }
    }
    return $menu;
}


has appkit_actiontree_visitor => ( is => 'ro',    isa => 'Tree::Simple::Visitor::FindByPath',  default => sub
{
    my $visitor = Tree::Simple::Visitor::FindByPath->new;
    $visitor->setNodeFilter( sub { my ($t) = @_; return $t->getNodeValue()->node_name } );
    return $visitor;
} );


# FIXME: is there any real reason to keep this a property?
sub is_unrestricted_action_name 
{ 
    my ($self, $name) = @_;
    return 1 if $name =~ /(^|\/)_/;
    return 1 if $name =~ /(^|\/)begin$/;
    return 1 if $name =~ /(^|\/)end$/;
    return 1 if $name =~ /(^|\/)auto$/;
    return 1 if $name =~ /(^|\/)default$/;
    return 1 if $name =~ /(^|\/)login$/;
    return 1 if $name =~ /(^|\/)logout$/;
    return 1 if $name =~ /(^|\/)login\/not_required$/;
    return 1 if $name =~ /View\:\:/;
    return 1 if $name =~ /(^|\/)access_denied$/;
    return 1 if $name =~ /(^|\/)not_found$/;
    return 0;
} 

###########################################################################################################################
# catalyst hook.
###########################################################################################################################


sub execute 
{
    my ( $c, $class, $action ) = @_;

    $c->stash->{version} = eval '$' . $c->config->{name}. '::VERSION'
            if $c->config->{appkit_display_app_version};
    #  to check roles we need the plugin!
    $c->isa("Catalyst::Plugin::Authorization::Roles") or die "Please use the Authorization::Roles plugin.";

    if  ( 
        Scalar::Util::blessed($action)
        )
    {
        # ensure the user is logged in...
        if ( $c->can_access( $action->reverse ) )
        {
            # do nothing..
            $c->log->debug("************** AppKit - Allows Access to - " . $action->reverse ) if $c->debug;
        }
        else
        {
            $c->log->debug("************** AppKit - DENIED Access to - " . $action->reverse ) if $c->debug;
            $c->detach_to_appkit_access_denied( $action ) if !$c->user;

            $c->detach('/access_denied');
        }
    }
    $c->maybe::next::method( $class, $action );
}

###########################################################################################################################
# plugin methods.
###########################################################################################################################

__PACKAGE__->mk_classdata('_appkit_features');
sub appkit_features
{
    # NOTE: this property is setup when the appkit_actiontree is setup.
    my $self = shift;
    my $features = $self->_appkit_features;
    unless($features)
    {
        my $tree = $self->appkit_actiontree(1);
        $features = $self->_appkit_features;
    }
    return $features;
}


sub appkit_actiontree 
{
    my ($c, $rebuild) = @_;

    # 'state' var means this will only be called once .. if Perl encounters this line again it knows not to run again..
    state $appkit_actiontree = $c->_build_appkit_actiontree;
    state $created = time;
    # force a re-read of the tree.. (for example, if access control changes)...
    if($rebuild || $c->_are_permissions_modified($created))
    {
        $appkit_actiontree = $c->_build_appkit_actiontree;
        $created = time;
        if($rebuild)
        {
            $c->_set_permissions_modified($created);
        }
    }

    return $appkit_actiontree;
}

sub _set_permissions_modified
{
    my $c = shift;
    my $updated = shift;
    state $key = $c->config->{name} . 'permissions_modified';
    $c->cache->set($key, $updated);
}

sub _are_permissions_modified
{
    my $c = shift;
    my $updated = shift;

    state $key = $c->config->{name} . 'permissions_modified';
    my $ts = $c->cache->get($key);
    unless($ts)
    {
        $ts = 0;
        $c->cache->set($key, $ts); # is this a good idea?
    }
    return $ts > $updated;
}


sub _build_appkit_actiontree
{
    my ( $c ) = shift;

    # get the vistor..
    my $visitor = $c->appkit_actiontree_visitor;

    # make a tree root (based on code from Catalyst::Plugin::Authorization::ACL::Engine)
    my $root = Tree::Simple->new('AppKit', Tree::Simple->ROOT);
    my $features = OpusVL::AppKit::Plugin::AppKit::FeatureList->new;

    AKCONTROLLERS: foreach my $cont ( @{ $c->appkit_controllers } )
    {   
        # Loop through all this AppKit controllers actionmethods...
        AKACTIONS: foreach my $action_method ( $cont->get_action_methods )
        {   
            # skip internal type action names...
            next if $c->is_unrestricted_action_name( $action_method->name );

            my $action = $cont->action_for( $action_method->name );
            next unless defined $action;

            # Deal with path...
            my $action_path = $action->reverse;
            my @path = split '/', $action_path;
            my $name = pop @path;

            # build AppKit::Node object...
            my $appkit_action_object = OpusVL::AppKit::Plugin::AppKit::Node->new
            (
                node_name       => $name,
                action_path     => $action_path,
                action_attrs    => $action->attributes,
                access_only     => [],  # default to "no roles allowed"
                in_feature      => defined $action->attributes->{AppKitFeature},
            );
            $features->add_action($cont->appkit_name, $action);

            ## look for any ACL rules for this action_path...
            if ( my $allowed_roles = $c->_allowed_roles_from_db( $action_path ) )
            {
                $appkit_action_object->access_only( $allowed_roles );
            }

            # If this is deeper than a top level action_path...
            # See if we have already added it into the tree..
            # ..if so, add a child to it and loop..
            if (@path)
            {   

                $visitor->setResults; # clear any results.
                $visitor->setSearchPath(@path);
                $root->accept($visitor);

                if ( my $namespace_node = $visitor->getResult )
                {   

                    # final 'belt and braces' check to see if we have already added it..
                    foreach my $kid ( $namespace_node->getAllChildren )
                    {
                        if ( $kid->getNodeValue->node_name eq $appkit_action_object->node_name )
                        {   
                            $c->debug->error("Action path $action_path, already in tree!!!??.. not a massive problem, but strange that it is happening");
                            next AKACTIONS
                        }
                    }

                    # add a child to the already created tree node....
                    $namespace_node->addChild( Tree::Simple->new( $appkit_action_object ) );
                    next;
                }
            }

            # here we add all of the required path for the action we are adding to the tree..
            my $node = $root;
            for my $path_part ( @path )
            {   
                my $found;
                foreach my $kid ( @{ $node->getAllChildren } )
                {   
                    my $kidnode =  $kid->getNodeValue;
                    if ( $path_part eq $kidnode->node_name )
                    {   
                        $found = $kid;
                    }
                }

                if  ( defined $found )
                {
                    $node = $found;
                }
                else
                {

                    # build AppKit::Node object...
                    my $branch_appkit_action_object = OpusVL::AppKit::Plugin::AppKit::Node->new
                    (
                        node_name   => $path_part,
                        in_feature => 0,
                    );

                    # add tree branch..
                    $node = Tree::Simple->new( $branch_appkit_action_object, $node);
                }
            }

            # add the child/action name to the node we have found/created..
            $node->addChild( Tree::Simple->new( $appkit_action_object ) );
        }
    }
    my $feature_list = $features->feature_names_with_app;
    for my $feature (@$feature_list)
    {
        if( my $roles = $c->_allowed_feature_roles_from_db( $c, $feature ) )
        {
            $features->set_roles_allowed($feature, $roles);
        }
    }

    $c->_appkit_features($features);

    # finished :) 
    return $root;
}

sub _allowed_feature_roles_from_db
{
    my $self = shift;
    my $c = shift;
    my $feature = shift;

    my $aclfeature = $c->model('AppKitAuthDB::Aclfeature')->find( { feature => $feature } );
    # return undef if not match found..
    return undef unless $aclfeature;

    $c->log->debug("AppKit Feature ACL : Matched Rule: " . $aclfeature->id . " FOR: $feature ") if $c->debug;

    #.. pull out all the allowed roles for this rule..
    my $allowed_roles = [ map { $_->role } $aclfeature->roles ];

    # return array ref of roles..
    return $allowed_roles;
}


sub can_access
{   
    my $c               = shift;
    my ($action_path)   = @_;

    # did we get passed a path?...
    return undef unless defined $action_path;

    if ( ref $action_path )
    {
        $c->log->debug("can_access called with a non-string action path: $action_path .. converting..") if $c->debug;
        $action_path    = $action_path->reverse;
    }
    if ($c->is_unrestricted_action_name( $action_path ))
    {
        $c->log->debug("Unrestricted action name: $action_path") if $c->debug;
        return 1 
    }

    # check if action path matches that of the 'access denied' action path.. in which case, we must allow access..
    if ( $action_path eq $c->config->{'appkit_access_denied'} )
    {
        $c->log->debug("Access denied path: $action_path") if $c->debug;
        return 1 
    }

    # find this actions node in the tree ...
    my $action_node = $c->_find_node_in_appkit_actiontree( $action_path );
    if ( ! $action_node )
    {
        # NOTE: this should fix cache issues.
        $c->appkit_actiontree(1);
        $action_node = $c->_find_node_in_appkit_actiontree( $action_path );
        unless($action_node) 
        {
            $c->log->warn("Could not find ::Node in tree for: $action_path ");
            return 0;
        }
    }

    # Have we been told to "NOT APPLY ACCESS CONTROL" ?? ...
    if ( exists $action_node->action_attrs->{AppKitAllAccess} || exists $action_node->action_attrs->{Public} )
    {
        $c->log->debug("The following action has AppKitAllAccess / Public for $action_path . No access control being applied ") if $c->debug;
        return 1;
    }

    # check if we have list of actionpaths to allow (regardless of rules)...
    if(  $c->user )
    {
        if ( $c->config->{'appkit_can_access_actionpaths'} )
        {
            foreach my $allowed_path ( @{ $c->config->{'appkit_can_access_actionpaths'} } )
            {
                # FIXME: this logic looks broken.
                if($action_path eq $allowed_path)
                {
                    $c->log->debug("Hit an action path that's automatically allowed - $allowed_path") if $c->debug;
                    return 1 
                }
            }
        }

        # check if we have been told to allow everything...
        if ( $c->config->{'appkit_can_access_everything'} )
        {
            $c->log->debug("Allowing Access to EVERYTHING! - Turn off in the config if you do not want this!") if $c->debug;
            return 1;
        }
    }

    # -- above here we see if we are blindly allowing access --- 

    # find all allowed roles for this action path...
    my $allowed_roles = $c->_allowed_roles_from_tree( $action_path );
    my @allowed;
    push @allowed, @$allowed_roles;
    push @allowed, @{$c->appkit_features->roles_allowed_for_action( $action_path )};

    # if none found.. do NOT allow access..
    unless (@allowed)
    {
        #$c->log->debug("************** can_access - DENIED Access to - " . $action_path ) if $c->debug;
        return 0;
    }

    # return a test that will check for the roles
    my $allow = $c->check_roles(\@allowed);
    #$c->log->debug("************** can_access - DENIED Access to - " . $action_path ) if !$allow && $c->debug;
    return $allow;
}

sub check_roles
{
    my ($c, $allowed) = @_;
    my $allow = $c->user && $c->check_any_user_role( @$allowed )
        || 'PUBLIC' ~~ @$allowed;
    return $allow;
}


sub who_can_access
{   
    my $c               = shift;
    my ($action_path)   = @_;

    # find all allowed roles for this action path...
    my $allowed_roles = $c->_allowed_roles_from_tree( $action_path );
    return undef unless defined $allowed_roles;

    # get an resultset of user_id's...
    my $inside_rs = $c->model('AppKitAuthDB::UsersRole')->search
    (
        {
            'role.role' => { 'IN' => $allowed_roles },
        },
        {
            select  => ['users_id'],
            as      => ['users_id'],
            join    => ['role']
        }
    );

    # return all users with the roles..
    return $c->model('AppKitAuthDB::User')->search( 
        { 'id' => 
            { 'IN' => $inside_rs->get_column('users_id')->as_query } }, 
            { distinct => 1 } );

}



use Memoize;
memoize('_find_node_in_appkit_actiontree');

sub _find_node_in_appkit_actiontree
{   
    my $c               = shift;
    my ($action_path)   = @_;

    # get the important bits...
    my $visitor = $c->appkit_actiontree_visitor;
    my $root = $c->appkit_actiontree;

    # look for action path in the tree...
    my @path = split '/', $action_path;
    $visitor->setResults; # clear any results.
    $visitor->setSearchPath(@path);
    $root->accept($visitor);

    if ( my $node = $visitor->getResult )
    {   
        # got it, return it...
        return $node->getNodeValue;
    }

    # .. can't find it!
    $c->log->debug("AppKit ACL : Could not find node for: " . $action_path ) if $c->debug;
    return undef;
}


sub _allowed_roles_from_tree
{   
    my $c               = shift;
    my ($action_path)   = @_;

    # find the node in the tree..
    my $node = $c->_find_node_in_appkit_actiontree( $action_path );

    return [] if ( ! defined $node );

    #.. pull out the array ref of roles the allowed for this node (action path)..
    my $roles = $node->access_only;

    return $node->access_only;
}


sub _allowed_roles_from_db
{
    my $c               = shift;
    my ($action_path)   = @_;

    # did we get passed a path?...
    return undef unless defined $action_path;

    my @action_path     = grep { $_ ne "" } split( "/", $action_path );
    my $action_name     = pop @action_path;

    # always allow to method starting with underscore (_) ... typically they are internal methods..
    return undef if $action_name =~ /^_/;

    # we are looking for an exact match for this action path..
    my $aclrule = $c->model('AppKitAuthDB::Aclrule')->find( { actionpath => $action_path } );

    # return undef if not match found..
    return undef unless $aclrule;

    $c->log->debug("AppKit ACL : Matched Rule: " . $aclrule->id . " FOR: $action_path ") if $c->debug;

    #.. pull out all the allowed roles for this rule..
    my $allowed_roles = [ map { $_->role } $aclrule->roles ];

    # return array ref of roles..
    return $allowed_roles;
}


sub _appkit_stash_portlets 
{
    my ( $c ) = @_;
    my @portlets;
    foreach my $apc ( @{ $c->appkit_controllers } )
    {   
        next unless $apc->portlet_actions;

        $c->log->debug("AppKit - RREALLY LOOKING FOR PORTLETS IN : " . $apc ) if $c->debug;

        foreach my $portlet ( @{ $apc->portlet_actions } )
        {   
            my $portlet_action = $apc->action_for( $portlet->{actionname} );

            # dont stash if we can't access it..
            next unless $c->can_access( $portlet_action->reverse );

            # forward to the portlet action..
            {
                local $c->stash->{breadcrumbs};
                local $c->stash->{output_type} = 'plain';
                $c->visit( $portlet_action );
            }

            # take things from the stash (that the action should have just filled out)
            push
            (   
                @portlets,
                {   
                    name    => $portlet->{value},
                    html    => $c->res->body,
                }
            ) if($c->res->status == 200);
            $c->res->status(200);
            $c->res->body(undef);
        }
    }
    $c->stash->{portlets} = \@portlets;
}


sub _appkit_stash_searches 
{
    my ( $c, $q ) = @_;

    my @search_results;
    foreach my $apc ( @{ $c->appkit_controllers } )
    {
        next unless $apc->search_actions;
        foreach my $search ( @{ $apc->search_actions } )
        {   
            my $search_action = $apc->action_for( $search->{actionname} );

            # dont stash if we can't access it..
            next unless $c->can_access( $search_action->reverse );

            # run the search action..
            {
                local $c->stash->{breadcrumbs};
                local $c->stash->{output_type} = 'plain';
                undef $c->stash->{search_results};
                
                # Stop the default end action from rendering a view
                $c->res->body('do_not_render');
                $c->visit( $search_action, [], [$q] );
                $c->res->body(undef);
            }

            # take things from the stash (that the action should have just filled out)
            if ($c->stash->{search_results})
            {
                push @search_results,
                {   
                    name    => $search->{value},
                    results => $c->stash->{search_results},
                };
            }
        }
    }

    $c->stash->{search_results} = \@search_results;
}


sub _appkit_stash_navigation
{
    my ( $c ) = @_;
    my @navigations;
    foreach my $apc ( @{ $c->appkit_controllers } )
    {   
        next unless $apc->navigation_actions;
        foreach my $nav ( @{ $apc->navigation_actions } )
        {   
            my $nav_action = $apc->action_for( $nav->{actionname} );

            # test we can access this action..
            next unless $c->can_access( $nav_action->reverse );

            # build an array of navigation information...
            push
            (   
                @navigations,
                {   
                    text    => $nav->{value},
                    uri     => $c->uri_for( $nav_action ),
                }
            );
        }
    }
    $c->stash->{navigation} = \@navigations;
}

sub REST_403
{
    my ($c) = @_;
    $c->response->status(403);
    $c->stash->{rest} = { message => 'Access Denied' };
    $c->detach;
}

sub in_REST_action
{
    my ($c) = @_;

    return $c->action && $c->action->isa('Catalyst::Action::REST');
}

sub detach_to_appkit_access_denied
{
    my ( $c, $denied_access_to_action ) = @_;

    if($c->in_REST_action)
    {
        $c->log->debug("AppKit - Not Allowed Access to " . $denied_access_to_action->reverse . " - part of REST controller so sending plain 403.") if $c->debug;
        $c->REST_403;
    }

    my $access_denied_action_path = $c->config->{'appkit_access_denied'};
    $c->log->debug("AppKit - Not Allowed Access to " . $denied_access_to_action->reverse . " - Detaching to $access_denied_action_path  ") if $c->debug;
    my $message = "Access denied - Please login with an account that has permissions to access the requested area";
    $message = $c->config->{AppKit}->{login_message}
        if exists $c->config->{AppKit}->{login_message};
    $c->controller('Login')->login_redirect($c, $message);
    $c->detach();
}


sub generate_class_name
{
    my $self = shift;
    my $var = shift;
    $var =~ s/\W+//; # remove all non word chars
    return lc $var;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::Plugin::AppKit

=head1 VERSION

version 2.29

=head1 DESCRIPTION

    People not developing the actual AppKit should not really need to know much about this plugin.

    It is used by the OpusVL::AppKit which intended to be inherited by another Catalyst App using 
    CatalystX::AppBuilder..

=head1 NAME

    OpusVL::AppKit::Plugin::AppKit - Common functions to get OpusVL::AppKit working.

=head1 METHODS

=head2 apps_allowed

Returns a list of the appkit controllers the user has access to sorted as the app config
specifies.  Generally used for building up the menu.

=head2 menu_data

List of apps and the group data for the full blown menu

    [
        {
            'controller' => bless( {
                    'appkit_method_group' => 'Leads',
                    'appkit_name' => 'Customers',
                    }, 'Aquarius::Controller::Leads' ),
                'actions' => [
                {
                    'actions' => [
                        {
                            'controller' => $controller,
                            'actionname' => 'index',
                            'value' => 'PO Approvers',
                            'sort_index' => 1,
                            'actionpath' => 'accounts/auth/index'
                        },
                        {
                            'controller' => $controller,
                            'actionname' => 'index',
                            'value' => 'Next Item',
                            'sort_index' => 1,
                            'actionpath' => 'accounts/auth/index'
                        },
                        $VAR1->[4]{'controller'}{'navigation_actions'}[3],
                        $VAR1->[4]{'controller'}{'navigation_actions'}[5],
                        $VAR1->[4]{'controller'}{'navigation_actions'}[4]
                    ],
                    'group' => 'Leads'
                },
                {
                    'actions' => [
                        $VAR1->[4]{'controller'}{'navigation_actions'}[0],
                        $VAR1->[4]{'controller'}{'navigation_actions'}[2],
                        $VAR1->[4]{'controller'}{'navigation_actions'}[1]
                    ],
                    'group' => 'Customers'
                }
            ]
        }
    ];

=head2 appkit_actiontree_visitor
    Use for find node in the appkit_actiontree...

=head2 is_unrestricted_action_name
    Little helper to ascertain if an action's name is one we dont apply access control to.

=head2 execute
    The method hooks into the catalyst despatch path.
    If the current logged in used is denied access to the action this will detach to the 'access_denied' action.

=head2 appkit_features

Returns a OpusVL::AppKit::Plugin::AppKit::FeatureList object that allows the querying of the features permissions
that sit on top of our roles management.

=head2 appkit_actiontree
    This returns a Tree::Simple of OpusVL::AppKit::Plugin::AppKit::Node's.
    Based on code from Catalyst::Plugin::Authorization::ACL::Engine, it is basically a Tree of this apps actions.
    This attribute is used to define access to actions.(but could be used for many more things)

    Arguments:
        $_[0]   -   Self
        $_[1]   -   Optional flag to say "re-read the tree"

=head2 _build_appkit_actiontree
    internal only method that supports the appkit_actiontree routine.
    This basically builds a tree of actions/controllers in the current catalyst app.           

=head2 can_access
    Checks the ACL structure against the current user and action.
    return 1 or 0 depending on if the user can access the action_path

    Used like so:
        if ( $c->can_access( 'controller/action/path' ) )
        {
            # $c->user must have the correct roles.
        }

    THIS NEEDS A MASSIVE CLEAN UP ONCE WE ARE HAPPY APPKIT WORKS WELL.

=head2 who_can_access
    Checks the ACL structure to see who can access a passed action_path.
    Returns:
         undef      - if not allowed roles
        resultset   - of users that can access the otherwise returns a resultset

=head2 _find_node_in_appkit_actiontree
    Returns OpusVL::AppKit::Plugin::AppKit::Node that represents the action_path.
    .. or undef if not found.

=head2 _allowed_roles_from_tree
    Returns ArrayRef of roles that can access the passed action path. 
    This checks the 'appkit_actiontree' .. so should be quick.

=head2 _allowed_roles_from_db
    Returns ArrayRef of roles that can access the passed action path. 
    This checks the database (model)

=head2 _appkit_stash_portlets
    Put all the AppKit Controller Portlets data in the stash
    If you forward to this action, you should end up with a stash value keyed by 'portlets'.
        eg. $c->forward('stash_portlets');
    The value of 'portlets' is an ArrayRef of HashRefs.
    The HashRefs contain 2 keys:
        name    = The name of the portlet
        html    = The HTML content of the portlet

=head2 _appkit_stash_navigation
    Put all the AppKit Controller Navigation data in the stash
    If you forward to this action, you should end up with a stash value keyed by 'navigation'.
        eg. $c->forward('stash_navigation');
    The value of 'navigation' is an ArrayRef of HashRefs.
    The HashRefs contain 2 keys:
        text    = The text of the navigation item
        uri     = The uri if the action the navigation relates to.

=head2 generate_class_name

A simple utility function to turn a string into a css class by removing whitespace and non word characters, then lower casing it.

This should provide a way to get predictable and legitimate css class names from data.

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
