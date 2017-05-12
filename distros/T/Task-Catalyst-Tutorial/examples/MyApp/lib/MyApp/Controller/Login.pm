package MyApp::Controller::Login;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

MyApp::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

Login logic

=cut

sub index : Private {
    my ($self, $c) = @_;

    # Get the username and password from form
    my $username = $c->request->params->{username} || "";
    my $password = $c->request->params->{password} || "";

    # If the username and password values were found in form
    if ($username && $password) {
        # Attempt to log the user in
        if ($c->login($username, $password)) {
            # If successful, then let them use the application
            $c->response->redirect($c->uri_for('/books/list'));
            return;
        } else {
            # Set an error message
            $c->stash->{error_msg} = "Bad username or password.";
        }
    }

    # If either of above don't work out, send to the login page
    $c->stash->{template} = 'login.tt2';
}

=head1 AUTHOR

root

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
