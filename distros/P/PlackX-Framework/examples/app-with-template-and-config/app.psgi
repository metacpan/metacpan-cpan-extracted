#!perl
use v5.36;

# Here we have chosen to also use the Config module, which is optional.
# If not otherwise specified, the Template module will look for Template
# options in config->{pxf}{template}.
use MyApp::Config './config.pl';

# Load our app and return app coderef
use MyApp;
MyApp->app;

=pod
