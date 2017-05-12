#!/usr/bin/env perl

use Mojolicious::Lite;
use lib qw(lib ../lib);

plugin 'FormChecker';

get '/' => 'index';
post '/' => sub {
    my $c = shift;

    $c->form_checker(
        rules => {
            name  => { max => 200 },
            email => {
                must_match => qr/\@/,
                must_match_error
                    => 'Email field does not contain a valid email address',
            },
            message => {},
        },
    );
} => 'index';

app->start;

__DATA__

@@ index.html.ep

% if ( form_checker_ok() ) {

    <p class="message success">Check was alright!
        <a href="/">Do it again!</a></p>

% } else {
    %= form_for index => (method => 'POST') => begin
        %= csrf_field
        <%== form_checker_error_wrapped %>

        <ul>
            <li><label for="name">*Name:</label><%= text_field 'name' %></li>
            <li><label for="email">*Email:</label><%= text_field 'email'%></li>
            <li><label for="Message" class="textarea_label">*Message:</label
                ><%= text_area 'message', cols => 40, rows => 5 %>
            </li>
        </ul>
        %= submit_button 'Send'
    % end
% }