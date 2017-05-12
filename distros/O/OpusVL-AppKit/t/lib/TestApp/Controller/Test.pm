package TestApp::Controller::Test;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Test Controller (within TestApp)',
);

=head1 NAME

    OpusVL::AppKit::Controller::Test - Test Controller for OpusVL::AppKit

=head1 DESCRIPTION

    The OpusVL::AppKit is intended to be inherited by another Catalyst App using AppBuilder.

    This controller is only used for testing.

    You can see I have 'extended' OpusVL::AppKit::Base::Controller::GUI. Doing this allows the 
    AppKit to tell the controller should be part of the GUI

=head1 METHODS

=head2 portlet_test
    This is a test of a Portlet type action.
    The intention is that any action methods with the attribute PortletName are
    seen as providing Portlet data. This basically means when called they fill
    out the 'portlet' stash key.
    This can then be interpreted by the caller.
=cut
sub portlet_test
    : PortletName('Test Portlet')
{
    my $self                = shift;
    my ($c, $portlet_type)  = @_;

    $portlet_type = 'default' unless defined $portlet_type;

    my @data = qw/thing1 thing2 thing3/;
    my $portlet_content;
    foreach ( @data )
    {   
        $portlet_content .= "<li> $_ </li>";
    }

    my $portlet_body = <<PORTLET
<div class='portlet-wrapper'>
    <div class='portlet-header'>
        Test Base Portlet
    </div>
    <div class='portlet-body'>
        <ul>
            $portlet_content
        </ul>
    </div>
</div>
PORTLET
    ;

    $c->res->body( $portlet_body );
};

=head2 index
    This is a test action for something that would appear in the AppKit Navigation
    All you need to do is include ':NavigationName("Some Name")' as a method attribute
    and the action should be included in the navigation (which are effected by ACL rules)
=cut
sub index 
    :Path 
    :Args(0)
    :NavigationHome
    :NavigationName("Test Home")
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: index');
}

sub access_admin 
    :Path('admin') 
    :Args(0)
    :NavigationName("Test Admin Access")
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: access_admin');
}

sub access_user
    :Path('user') 
    :Args(0)
    :NavigationName("Test User Access")
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: access_user');
}

sub access_user_or_admin 
    :Path('useroradmin') 
    :Args(0)
    :NavigationName("Test Admin or User Access")
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: access_user_or_admin');
}

sub access_none
    :Path('noaccess') 
    :Args(0)
    :NavigationName("Test NO Access")
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: access_none');
}

sub access_public
    :Path('publicaccess') 
    :Args(0)
    :NavigationName("Test AppKitAllAccess")
    :AppKitAllAccess
{ 
    my ($self, $c) = @_;
    $c->res->body('Controller: Test Action: access_public');
}

sub cause_error 
    :Path('error') 
    :Args(0)
    :NavigationName("Test An Error")
{ 
    my ($self, $c) = @_;
    $c->stash->{error} = 0/2;
}

sub custom
    :Local
    :Args(0)
    :NavigationName("Custom - Index")
{
    my ($self, $c) = @_;
    $c->res->body('Hello .. this is the Test Controller from TestApp - custom action' );
}

sub custom_link
    : Path('link')
    : NavigationName("Custom - Link")
{
    my ($self, $c) = @_;
    $c->res->body('Hello .. this is the Test Controller from TestApp - custom_link action' );
}

sub custom_access_denied
    : Path('ad')
{
    my ($self, $c) = @_;
    $c->stash->{error_msg} = "Custom accessd denied message";
    $c->go('/index');
}

sub who_can_access_stuff
    :Path('whocan')
    :Args(0)
    :NavigationName("Who Can Access")
{
    my ($self, $c) = @_;

    my $string = '';
    foreach my $user ( $c->who_can_access( 'test/custom' ) )
    {
        $string .= "--" . $user->username;
    }
    $c->res->body("Who: $string");
}

##
1;
