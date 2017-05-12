#!/usr/bin/perl

use strict;
use warnings;

# Load testing framework and use 'no_plan' to dynamically pick up
# all tests. Better to replace "'no_plan'" with "tests => 30" so it
# knows exactly how many tests need to be run (and will tell you if
# not), but 'no_plan' is nice for quick & dirty tests

use Test::More 'no_plan';

# Need to specify the name of your app as arg on next line
# Can also do:
#   use Test::WWW::Mechanize::Catalyst "MyApp";

use ok "Test::WWW::Mechanize::Catalyst" => "MyApp";
    
# Create two 'user agents' to simulate two different users ('test01' & 'test02')
my $ua1 = Test::WWW::Mechanize::Catalyst->new;
my $ua2 = Test::WWW::Mechanize::Catalyst->new;

# Use a simplified for loop to do tests that are common to both users
# Use get_ok() to make sure we can hit the base URL
# Second arg = optional description of test (will be displayed for failed tests)
# Note that in test scripts you send everything to 'http://localhost'
$_->get_ok("http://localhost/", "Check redirect of base URL") for $ua1, $ua2;
# Use title_is() to check the contents of the <title>...</title> tags
$_->title_is("Login", "Check for login title") for $ua1, $ua2;
# Use content_contains() to match on text in the html body
$_->content_contains("You need to log in to use this application",
    "Check we are NOT logged in") for $ua1, $ua2;

# Log in as each user
# Specify username and password on the URL
$ua1->get_ok("http://localhost/login?username=test01&password=mypass", "Login 'test01'");
#$ua2->get_ok("http://localhost/login?username=test02&password=mypass", "Login 'test02'");
# Use the form for user 'test02'
$ua2->submit_form(
    fields => {
        username => 'test02',
        password => 'mypass',
    });

# Go back to the login page and it should show that we are already logged in
$_->get_ok("http://localhost/login", "Return to '/login'") for $ua1, $ua2;
$_->title_is("Login", "Check for login page") for $ua1, $ua2;
$_->content_contains("Please Note: You are already logged in as ",
    "Check we ARE logged in" ) for $ua1, $ua2;

# 'Click' the 'Logout' link (see also 'text_regex' and 'url_regex' options)
$_->follow_link_ok({n => 1}, "Logout via first link on page") for $ua1, $ua2;
$_->title_is("Login", "Check for login title") for $ua1, $ua2;
$_->content_contains("You need to log in to use this application",
    "Check we are NOT logged in") for $ua1, $ua2;

# Log back in
$ua1->get_ok("http://localhost/login?username=test01&password=mypass", "Login 'test01'");
$ua2->get_ok("http://localhost/login?username=test02&password=mypass", "Login 'test02'");
# Should be at the Book List page... do some checks to confirm
$_->title_is("Book List", "Check for book list title") for $ua1, $ua2;

$ua1->get_ok("http://localhost/books/list", "'test01' book list");
$ua1->get_ok("http://localhost/login", "Login Page");
$ua1->get_ok("http://localhost/books/list", "'test01' book list");

$_->content_contains("Book List", "Check for book list title") for $ua1, $ua2;
# Make sure the appropriate logout buttons are displayed
$_->content_contains("/logout\">Logout</a>",
    "Both users should have a 'User Logout'") for $ua1, $ua2;
$ua1->content_contains("/books/form_create\">Create</a>",
    "Only 'test01' should have a create link");

$ua1->get_ok("http://localhost/books/list", "View book list as 'test01'");

# User 'test01' should be able to create a book with the "formless create" URL
$ua1->get_ok("http://localhost/books/url_create/TestTitle/2/4",
    "'test01' formless create");
$ua1->title_is("Book Created", "Book created title");
$ua1->content_contains("Added book 'TestTitle'", "Check title added OK");
$ua1->content_contains("by 'Stevens'", "Check author added OK");
$ua1->content_contains("with a rating of 2.", "Check rating added");
# Try a regular expression to combine the previous 3 checks & account for whitespace
$ua1->content_like(qr/Added book 'TestTitle'\s+by 'Stevens'\s+with a rating of 2./, "Regex check");

# Make sure the new book shows in the list
$ua1->get_ok("http://localhost/books/list", "'test01' book list");
$ua1->title_is("Book List", "Check logged in and at book list");
$ua1->content_contains("Book List", "Book List page test");
$ua1->content_contains("TestTitle", "Look for 'TestTitle'");

# Make sure the new book can be deleted
# Get all the Delete links on the list page
my @delLinks = $ua1->find_all_links(text => 'Delete');
# Use the final link to delete the last book
$ua1->get_ok($delLinks[$#delLinks]->url, 'Delete last book');
# Check that delete worked
$ua1->content_contains("Book List", "Book List page test");
$ua1->content_contains("Book deleted", "Book was deleted");

# User 'test02' should not be able to add a book
$ua2->get_ok("http://localhost/books/url_create/TestTitle2/2/5", "'test02' add");
$ua2->content_contains("Unauthorized!", "Check 'test02' cannot add");

