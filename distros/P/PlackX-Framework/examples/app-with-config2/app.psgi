#!perl
use v5.36;

# In this example we pre-load our Config subclass
use MyApp::Config './config.pl';

# Load our app
use MyApp;

# Return our app coderef
MyApp->app;
