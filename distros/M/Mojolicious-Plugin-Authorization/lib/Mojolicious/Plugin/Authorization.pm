package Mojolicious::Plugin::Authorization;
BEGIN {
  $Mojolicious::Plugin::Authorization::VERSION = '1.05';
}
use Mojo::Base 'Mojolicious::Plugin';
# The dog is good, but our real competition is the Hypnotoad.
sub register {
    my ($self, $app, $args) = @_;
    $args ||= {};
    for my $sub_ref ( qw/ has_priv is_role user_privs user_role / ) {
        die __PACKAGE__, ": missing '$sub_ref' subroutine ref in parameters\n"
            unless $args->{$sub_ref} && ref($args->{$sub_ref}) eq 'CODE';
    }
    my $has_priv_cb    = $args->{has_priv};
    my $is_role_cb     = $args->{is_role};
    my $user_privs_cb  = $args->{user_privs};
    my $user_role_cb   = $args->{user_role};
    my $fail_render    = $args->{fail_render};
    $app->routes->add_condition(has_priv => sub {
        my ($r, $c, $captures, $priv) = @_;
        my $res = ($priv && $has_priv_cb->($c,$priv)) ? 1 : 0;
        $c->render( %$fail_render ) if $fail_render && ! $res;
        return $res;
    });
    for my $helper_name ( qw/ is_role is / ) {
        $app->routes->add_condition($helper_name => sub {
            my ($r, $c, $captures, $role) = @_;
            my $res = ($role && $is_role_cb->($c,$role)) ? 1 : 0;
            $c->render( %$fail_render ) if $fail_render && ! $res;
            return $res;
        });
    }
    $app->helper(privileges => sub {
        my ($c, $extradata) = @_;
        return $user_privs_cb->($c, $extradata);
    });
    for my $helper_name ( qw/ has_priv has_privilege / ) {
        $app->helper($helper_name => sub {
            my ($c, $priv, $extradata) = @_;
            my $has_priv = $has_priv_cb->($c, $priv, $extradata);
            return $has_priv;
        });
    }
    for my $helper_name ( qw/ is is_role / ) {
        $app->helper($helper_name => sub {
            my ($c, $role, $extradata) = @_;
            return $is_role_cb->($c, $role, $extradata);
        });
    }
    $app->helper(role => sub {
       my ($c, $extradata) = @_;
        return $user_role_cb->($c, $extradata);
    });
}
1;
__END__
=pod

=head1 NAME

Mojolicious::Plugin::Authorization - A plugin to make Authorization a bit easier

=head1 VERSION

version 1.05

=head1 SYNOPSIS

    use Mojolicious::Plugin::Authorization
    $self->plugin('Authorization' => {
        'has_priv'    => sub { ... },
        'is_role'     => sub { ... },
        'user_privs'  => sub { ... },
        'user_role'   => sub { ... },
        'fail_render' => { status => 401, json => { ... } },
    });
    if ($self->has_priv('delete_all', { optional => 'extra data stuff' })) {
        ...
    }

=head1 DESCRIPTION

A very simple API implementation of role-based access control (RBAC). This plugin is only an API you will
have to do all the work of setting up your roles and privileges and then provide four subs that are used by
the plugin.
The plugin expects that the current session will be used to get the role its privileges. It also assumes that
you have already been authenticated and your role set.
That is about it you are free to implement any system you like.

=head1 METHODS

=head2 has_priv('privilege', $extra_data) or has_privilege('privilege', $extra_data)

'has_priv' and 'has_privilege' will use the supplied C<has_priv> subroutine ref to check if the current session has the
given privilege. Returns true when the session has the privilege or false otherwise.
You can pass additional data along in the extra_data hashref and it will be passed to your C<has_priv>
subroutine as-is.

=head2 is('role',$extra_data) or is_role('role',$extra_data)

'is' and 'is_role' will use the supplied C<is_role> subroutine ref to check if the current session is the
given role. Returns true when the session has privilege or false otherwise.
You can pass additional data along in the extra_data hashref and it will be passed to your C<is_role>
subroutine as-is.

=head2 privileges($extra_data)

'privileges' will use the supplied C<user_privs> subroutine ref and return the privileges of the current session.
You can pass additional data along in the extra_data hashref and it will be passed to your C<user_privs>
subroutine as-is. The returned data is dependent on the supplied C<user_privs> subroutine.

=head2 role($extra_data)

'role' will use the supplied C<user_role> subroutine ref and return the role of the current session.
You can pass additional data along in the extra_data hashref and it will be passed to your C<user_role>
subroutine as-is. The returned data is dependent on the supplied C<user_role> subroutine.

=head1 CONFIGURATION

The following options must be set for the plugin:

=over 4

=item has_priv (REQUIRED) A coderef for checking to see if the current session has a privilege (see L</"HAS PRIV">).

=item is_role (REQUIRED) A coderef for checking to see if the current session is a certain role (see L</"IS / IS ROLE">).

=item user_privs (REQUIRED) A coderef for returning the privileges of the current session (see L</"PRIVILEGES">).

=item user_role (REQUIRED) A coderef for returning the role of the current session (see L</"ROLE">).

=back

The following options are not required but allow greater control:

=over 4

=item fail_render (OPTIONAL) A hashref for setting the status code and rendering json/text/etc when routing fails (see L</"ROUTING VIA CALLBACK">).

=back

=head2 HAS PRIV / HAS PRIVILEGE

'has_priv' is used when you need to confirm that the current session has the given privilege.
The coderef you pass to the C<has_priv> configuration key has the following signature:

    sub {
        my ($app, $privilege,$extradata) = @_;
        ...
    }

You must return either 0 for a fail and 1 for a pass.  This allows C<ROUTING VIA CONDITION> to work correctly.

=head2 IS / IS ROLE

'is' / 'is_role' is used when you need to confirm that the current session is set to the given role.
The coderef you pass to the C<is_role> configuration key has the following signature:

    sub {
        my ($app, $role, $extradata) = @_;
        ...
        return $role;
    }

You must return either 0 for a fail and 1 for a pass.  This allows C<ROUTING VIA CONDITION> to work correctly.

=head2 PRIVILEGES

'privileges' is used when you need to get all the privileges of the current session.
The coderef you pass to the C<user_privs> configuration key has the following signature:

    sub {
        my ($app,$extradata) = @_;
        ...
        return $privileges;
    }

You can return anything you want. It would normally be an arrayref of privileges but you are free to
return a scalar, hashref, arrayref, blessed object, or undef.

=head2 ROLE

'role' is used when you need to get the role of the current session.
The coderef you pass to the C<user_privs> configuration key has the following signature:

    sub {
        my ($app,$extradata) = @_;
        ...
        return $role;
    }

You can return anything you want. It would normally be just a scalar but you are free to
return a scalar, hashref, arrayref, blessed object, or undef.

=head1 EXAMPLES

For a code example using this, see the F<t/01-functional.t> test,
it uses L<Mojolicious::Lite> and this plugin.

=head1 ROUTING VIA CONDITION

This plugin also exports a routing condition you can use in order to limit access to certain documents to only
sessions that have a privilege.

    $r->route('/delete_all')->over(has_priv => 'delete_all')->to('mycontroller#delete_all');
    my $delete_all_only = $r->route('/members')->over(has_priv => 'delete_all')->to('members#delete_all');
    $delete_all_only->route('delete')->to('members#delete_all');

If the session does not have the 'delete_all' privilege, these routes will not be considered by the dispatcher and unless you have set up a catch-all route,
 a 404 Not Found will be generated instead.

Another condition you can use to limit access to certain documents to only those sessions that
have a role.

    $r->route('/view_all')->over(is => 'ADMIN')->to('mycontroller#view_all');
    my $view_all_only = $r->route('/members')->over(is => 'view_all')->to('members#view_all');
    $view_all_only->route('view')->to('members#view_all');

If the session is not the 'ADMIN' role, these routes will not be considered by the dispatcher and unless you have set up a catch-all route,
 a 404 Not Found will be generated instead.
This behavior is similar to the "has" condition.

=head1 ROUTING VIA CALLBACK

It is not recommended to route un-authorized requests to anything but a 404 page. If you do route to some sort
of 'You are not allowed page' you are telling a hacker that the URL was correct while the 404 tells them nothing.
This is just my opinion.

However in the case of publicly documented APIs returning a 404 when priv/role checks fails can confuse users, so
you can override the default 404 status on failure by supplying a 'fail_render' value in the plugin config. This
will be passed to the Mojolicious ->render method when the has_priv/is/is_role routing fails. For example, to
return a status code of 401 with JSON:

    fail_render => { status => 401, json => { error => 'Denied' } },

=head1 SEE ALSO

L<Mojolicious::Sessions>, L<Mojocast 3: Authorization|http://mojocasts.com/e3#>

=head1 AUTHOR

John Scoles, C<< <byterock  at hotmail.com> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests through the web interface at L<https://github.com/byterock/mojolicious-plugin-authorization/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.
    perldoc Mojolicious::Plugin::Authorization
You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation L<http://annocpan.org/dist/Mojolicious-Plugin-Authorization>

=item * CPAN Ratings L<http://cpanratings.perl.org/d/Mojolicious-Plugin-Authorization>

=item * Search CPAN L<http://search.cpan.org/dist/Mojolicious-Plugin-Authorization/>

=back

=head1 ACKNOWLEDGEMENTS

Ben van Staveren   (madcat)

    -   For 'Mojolicious::Plugin::Authentication' which I used as a guide in writing up this one.

Chuck Finley

    -   For staring me off on this.

Abhijit Menon-Sen

    -   For the routing suggestions

Roland Lammel

    -   For some other good suggestions

Lee Johnson

    -   For the latest updates for version 1.04
    
=head1 LICENSE AND COPYRIGHT

Copyright 2012 John Scoles.
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
See http://dev.perl.org/licenses/ for more information.

=cut
