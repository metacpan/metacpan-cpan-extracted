package Scaffold::Uaf::Authorize;

our $VERSION = '0.01';

use 5.8.8;
use Scaffold::Class
  version => $VERSION,
  base    => 'Scaffold::Base',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub add_rule {
    my ($self, $rule) = @_;

    push @{$self->{rules}}, $rule;

    return 1;

}

sub xcan {
    my ($self, $user, $action, $resource) = @_;

    my ($granted, $denied) = (0,0);

    foreach my $rule (@{$self->{rules}}) {

        $granted = 1 if ($rule->grants($user, $action, $resource));
        $denied = 1  if ($rule->denies($user, $action, $resource));
        last if ($denied);

    }

    return ($granted && !$denied);

}

sub rules {
    my $self = shift;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    $self->{rules} = [];
    $self->rules();

    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Uaf::Authorize - An abstract base class to use as a
pattern for your AuthorizeFactory.

=head1 SYNOPSIS

This package is a simple abstract base class. Use it as the base for creating
your instance of an Authorize object. 

=over 4

 package MyAuthorize;

 use strict;
 use warnings;

 use XYZRule;
 use SomeOtherRule;
 use base qw(Scaffold::Uaf::Authorize);

 sub rules {
    my $self = shift;

    $self->add_rule(XYZRule->new());
    $self->add_rule(SomeOtherRule->new());

 }

 1;

=back

Then later in the main line code.

=over 4

 my $manager = $self->scaffold->authz;

 if ($manager->xcan($user, "read", "/etc/shadow")) {
    open DATA, "</etc/shadow";
     ...
 }

=back

=head1 DESCRIPTION

This module implements an authorization scheme. The basic idea is that you 
have a set of users and a set of objects that can be accessed within a system.
In the code of the system itself, you want to surround sensitive operations 
with code that determines if the current user is allowed to do that operation.

This module attempts to make such a system possible. The module requires that 
you write implementations rules for your system that are subclasses of 
Scaffold::Uaf::Rule. The rules can be written to use any data types, 
which are abstractly known as "users", "actions", and "resources." 

=over 4

A user is generally a Scaffold::Uaf::User object that your 
applications has identify as the entity operating the application. 

An action can be any data type (i.e. simply a string). It is really up
to the rule to determine what is valid. But, you have the latitude to
define anything as a action.

A resource can be any data type (i.e simply a string). But, it is really
up to the rule to determine what a resource is. Again, you have the latitude to
define anything as a resource.

=back

These are the steps needed to create an Authorize object:

=over 4

=item Step 1 

Decide what sections of your code will need to be protected, and
decide what to do if the user doesn't have access. For example if a 
screen should just hide fields, then the application code needs to 
reflect that.
 
=item Step 2

 Create an Authorize object for your application.

=item Step 3

Surround sensitive sections of code with something like:

 if ($manager->can($user, "view salary", $payrollRecord)) {

     # show salary fields

 } else {

     # hide salary fields

 }

=item Step 4

Create rules that spell out the behavior you want and add them
to your application's Authorization object. The basic idea is that
a rule can grant permission, or deny it. If it neither grants or 
denies, then the object will take the safe route and say that the 
action cannot be taken. Part of the code for the rule for protecting 
salaries might look like:

 package SalaryViewRule;

 use Scaffold::Uaf::User;
 use base qw(Scaffold::Uaf::Rule);

 sub grants {

     $self = shift;
     $user = shift;
     $action = shift;
     $resource = shift;

     # Do not grant on requests we don't understand.

     return 0 if (!$user->isa("Scaffold::Uaf::User") ||
                  !$self->isa("Scaffold::Uaf::Rule"));

     if (($action eq "view salary") && 
         ($resource->isa("Payroll::Record"))) {

        if ($user->username() eq $resource->getEmployeeName()) {

           return "user can view their own salary";

        }

     }

     return 0;

 }

Then in your subclass of AuthorizeFactory:

 use SalaryViewRule;

   ...

 $viewRule = new SalaryViewRule;
 $manager->add_rule($viewRule);

=back

=head1 METHODS

=over 4

=item new()

This method intializes the object. 

=item xcan(user, action, resource)

This is the primary method of the Authorization object. It asks if the 
specified user can do the specified action on the specified resource. 

Example:

=over 4

 $manager->xcan($user, "eat", "cake");

=back

This would return true if the user is allowed to eat cake.

=item add_rule(rule)

This method will add an new rule to the object.

Example:

=over 4

 $authz->add_rule(MyRule->new());

=back

=item rules()

This method should be overridden and your rules applied to the object. See the
above examples for usage.

=back

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::Manager
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
