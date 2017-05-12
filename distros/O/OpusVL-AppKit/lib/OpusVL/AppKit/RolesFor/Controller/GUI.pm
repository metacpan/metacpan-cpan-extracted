package OpusVL::AppKit::RolesFor::Controller::GUI;


##################################################################################################################################
# use lines.
##################################################################################################################################
use strict;
use Moose::Role;

##################################################################################################################################
# moose calls.
##################################################################################################################################

has appkit                      => ( is => 'ro',    isa => 'Int',                       default => 1 );
has appkit_name                 => ( is => 'rw',    isa => 'Str',                       default => 'AppKit' );
has appkit_myclass              => ( is => 'ro',    isa => 'Str',                       );
has appkit_shared_module        => ( is => 'rw',    isa => 'Str');
has navigation_items_merged     => ( is => 'rw',    isa => 'Bool', default => 0 );
has appkit_method_group_order   => ( is => 'rw',    isa => 'Int', default => 0);
has appkit_method_group         => ( is => 'rw',    isa => 'Str', default => '');
has appkit_order                => ( is => 'rw',    isa => 'Int', default => 0);

has _default_order              => ( is => 'rw',    isa => 'Int', default => 0);


has home_action             => ( is => 'rw',    isa => 'HashRef'        );


has navigation_actions      => ( is => 'rw',    isa => 'ArrayRef',  default => sub { [] } );


has navigation_actions_grouped      => ( is => 'rw',    isa => 'ArrayRef',  default => sub { [] } );


has portlet_actions         => ( is => 'rw',    isa => 'ArrayRef',  default => sub { [] } );


has search_actions         => ( is => 'rw',    isa => 'ArrayRef',  default => sub { [] } );


before create_action  => sub 
{ 
    my $self = shift;
    my %args = @_;

    # add any ActionClass's to this action.. so when it is called, some extra code is excuted....
    if ( defined $args{attributes}{AppKitForm} ) { push @{ $args{attributes}{ActionClass} }, "OpusVL::AppKit::Action::AppKitForm"; }

    if ( defined $args{attributes}{NavigationHome} )
    {
        # This action has been identified as a Home action...
        $self->home_action
        ( 
            {
                actionpath  => $args{reverse},
                actionname  => $args{name},
            }
        );
    }

    if ( defined $args{attributes}{NavigationName} )
    {
        # This action has been identified as a Navigation item..
        my $array = $self->navigation_actions;
        $array = [] unless defined $array;
        $self->_default_order($self->_default_order+1);
        my $order;
        if(defined $args{attributes}{NavigationOrder})
        {
            $order = $args{attributes}{NavigationOrder}->[0] 
        }
        else
        {
            $order = $self->_default_order;
        }

        my $hide = {};
        if ($args{attributes}{Hide}) {
            my ($key, $value) = split(':', $args{attributes}{Hide}->[0]);
            if ($key && $value) {
                $hide = {
                    hidden => 1,
                    as     => $key,
                    with   => $value
                };
            }
        }

        push 
        ( 
            @$array,
            {
                value       => $args{attributes}{NavigationName}->[0],
                actionpath  => $args{reverse},
                actionname  => $args{name},
                title       => $args{attributes}{Description}->[0],
                controller  => $self,
                sort_index  => $order,
                hide_as     => $hide->{as}||0,
                hide_with   => $hide->{with}||0,
            }
        );

        $self->navigation_actions( $array );
    }
    
    if ( defined $args{attributes}{PortletName} )
    {
        # This action has been identified as a Portlet action...
        my $array = $self->portlet_actions;
        $array = [] unless defined $array;
        push 
        ( 
            @$array,
            {
                value       => $args{attributes}{PortletName}->[0],
                actionpath  => $args{reverse},
                actionname  => $args{name},
            }
        );
        $self->portlet_actions ( $array );
    }

    if ( defined $args{attributes}{SearchName} )
    {
        # This action has been identified as a Search action...
        my $array = $self->search_actions;
        $array = [] unless defined $array;
        push 
        ( 
            @$array,
            {
                value       => $args{attributes}{SearchName}->[0],
                actionpath  => $args{reverse},
                actionname  => $args{name},
            }
        );
        $self->search_actions ( $array );
    }
};

sub intranet_action_list
{
    my $self = shift;
    my $c = shift;

    my $actions = $self->navigation_actions;
    return $self->_sorted_filtered_actions($c, $actions);
}

sub _sorted_filtered_actions
{
    my $self = shift;
    my $c = shift;
    my $actions = shift;

    return [] if !$actions;
    my @actions = sort { $a->{sort_index} <=> $b->{sort_index} } 
        grep { $c->can_access($_->{controller}->action_for($_->{actionname})) } @$actions;
    return \@actions;
}

sub application_action_list
{
    # this list includes groups too.
    my $self = shift;
    my $c = shift;

    my $grouped_actions = $self->navigation_actions_grouped;
    return [] if !$grouped_actions;
    my @groups;
    for my $group (@$grouped_actions)
    {
        my $filtered = $self->_sorted_filtered_actions($c, $group->{actions});
        push @groups, { group => $group->{group}, actions => $filtered } if @$filtered;
    }
    return \@groups;
}


##################################################################################################################################
# controller actions.
##################################################################################################################################

sub date_long 
{
    my ($self, $dt) = @_;
    
    return if !$dt;
    return join '',
        $dt->day_name,
        ', ',
        sprintf("%02d ",$dt->day),
        $dt->month_name,
        ' ',
        $dt->year;
}

sub date_short
{
    my ($self, $dt) = @_;
    return if !$dt;
    return join '',
        sprintf("%02d", $dt->day),
        '-',
        $dt->month_abbr,
        '-',
        $dt->year;
}

sub london_date
{
    my ($self, $dt) = @_;
    return if !$dt;
    $dt->set_time_zone('Europe/London');
}

sub time_long
{
    my ($self, $dt) = @_;
    return if !$dt;

    return join '',
        sprintf('%02d', $dt->hour),
        ':',
        sprintf('%02d', $dt->minute),
        ':',
        sprintf('%02d', $dt->second);

}

sub time_short
{
    my ($self, $dt) = @_;
    return if !$dt;

    return join '',
        sprintf('%02d', $dt->hour),
        ':',
        sprintf('%02d', $dt->minute);

}


sub add_breadcrumb
{
    my $self = shift;
    my $c = shift;
    my $args = shift;
    push @{$c->stash->{breadcrumbs}}, $args;
}


sub add_final_crumb
{
    my $self = shift;
    my $c = shift;
    my $title = shift;
    push @{$c->stash->{breadcrumbs}}, { name => $title, url => $c->req->uri };
}


sub flag_callback_error
{
    my ($self, $c, $field_name, $message) = @_;
    return $self->flag_callback_error_ex($c, $field_name, { message => $message });
}

sub flag_callback_error_ex
{
    my ($self, $c, $field_name, $args) = @_;

    $args //= {};
    my $message = $args->{message};
    my $no_detach = $args->{no_detach};

    my $form = $c->stash->{form};
    my $constraint = $form->get_field($field_name)->get_constraint({ type => 'Callback' });
    $constraint->callback(sub { 0});
    $constraint->message($message) if $message;
    $form->process;
    $c->detach unless $no_detach;
}

##
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpusVL::AppKit::RolesFor::Controller::GUI

=head1 VERSION

version 2.29

=head1 SYNOPSIS

    package MyApp::Controller::SomeFunkyThing;
    use Moose;
    BEGIN{ extends 'Catalyst::Controller' };
    with 'OpusVL::AppKit::RolesFor::Controller::GUI';

    __PACKAGE__->config( appkit_name        => 'My Funky App' );
    __PACKAGE__->config( appkit_icon        => 'static/funkster/me.gif' );
    __PACKAGE__->config( appkit_myclass     => 'MyApp' );
    
    sub index
        :Path
        :Args(0)
        :NavigationHome
        :NavigationName("Funky Home")
        :PortletName("Funky Portlet")
        :AppKitForm
    {   
        # .. do some funky stuff .. 
    }

=head1 DESCRIPTION

    If you use this Moose::Role with a controller it can be intergrated into the OpusVL::AppKit.

    You can just do: 
        use Moose;
        with 'OpusVL::AppKit::RolesFor::Controller::GUI';

    Give your Controller a name within the GUI:
        __PACKAGE__->config( appkit_name => 'Some Name' );

    To make use of the additional features you will have to use one of the following
    action method attributes:

        NavigationHome
            This tells the GUI this action is the 'Home' action for this controller.

        NavigationName
            Tells the GUI this action is a navigation item and what its name should be.

        PortletName
            Tells the GUI this action is a portlet action, so calling is only garented to fill
            out the 'portlet' stash key.

        AppKitForm
            Behaves like FormConfig option in FormFu Controller, except it loads form from the 
            ShareDir of namespace passed in 'appkit_myclass'
            
        SearchName
            Tells the GUI this action is a search action and what its name should be

=head1 NAME

    OpusVL::AppKit::RolesFor::Controller::GUI - Role for Controllers wanting to interact with AppKit

=head1 METHODS

=head2 home_action

    This should be the hash of action details that pertain the the 'home action' of a controller.
    If there is none defined for a controller, it should be undef.

=head2 navigation_actions

    This should be an Array Ref of HashRef's pertaining the actions that make up the navigation

=head2 navigation_actions_grouped

    This should be an Array Ref of HashRef's pertaining the actions that make up the navigation
    grouped by appkit_method_group.

=head2 portlet_actions

    This should be an Array Ref of HashRef's pertaining the actions that are Portlet's

=head2 search_actions

    This should be an Array Ref of HashRef's pertaining the actions that are Portlet's

=head2 create_action

    Hook into the creation of the actions.
    Here we read the action attributes and act accordingly.

=head2 intranet_action_list

Returns a sorted list of actions for the menu filtered by what the user can access.

=head2 application_action_list

Returns a sorted list of actions for the menu filtered by what the user can access.

It returns a list of hashes containing two keys, group (the group name) and actions, a list of 
the actions for that group.

=head2 date_long

Provides a standard L<DateTime> formatting function that is also mirrored (and called) from TT using
the date_long() function.

Monday, 10 May 2010

=head2 date_short

Provides a short date format function for DD-MM-YYYY display.

=head2 time_long

Provides a long time format function, HH:MM:SS

=head2 time_short

Provides a short time format function, HH:MM

=head2 add_breadcrumb

Adds the a breadcrumb on your breadcrumb trial.  Pass it the context object and the breadcumb info,

    $self->add_breadcrumb($c, { name => 'Title', url => $search_url });

=head2 add_final_crumb

Adds the final breadcrumb on your trial.  Simply pass it the title of the breadcrumb.

    $self->add_final_crumb($c, 'Title');

=head2 flag_callback_error

Flags an HTML::FormFu callback error.

Setup a callback constraint on your form,

  - type: Text
    name: project
    label: Project
    constraints:
      - type: Callback
        message: Project is invalid

Then within your controller you can do, 

    $self->flag_callback_error($c, 'project');

This will terminate the processing of the action too, by doing a $c->detach;

=head1 SEE ALSO

    L<CatalystX::AppBuilder>,
    L<OpusVL::AppKit>,
    L<Catalyst>

=head1 AUTHOR

OpusVL - www.opusvl.com

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by OpusVL - www.opusvl.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
