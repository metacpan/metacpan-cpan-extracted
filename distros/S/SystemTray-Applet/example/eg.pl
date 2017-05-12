#!/usr/bin/perl -w

use strict;
use warnings;

use SystemTray::Applet;

my $applet = SystemTray::Applet->new( "text" => "hello world" , "callback" => sub { my ($self) = @_; $self->{"text"} = "hello world - " . gmtime(); } , "frequency" => 10 );

