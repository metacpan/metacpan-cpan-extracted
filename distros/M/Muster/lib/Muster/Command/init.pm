package Muster::Command::init;
$Muster::Command::init::VERSION = '0.93';
#ABSTRACT: Muster::Command::init - generate initial boilerplate app
=head1 NAME

Muster::Command::init - generate initial boilerplate app

=head1 VERSION

version 0.93

=head1 DESCRIPTION

Content management system - generating boilerplate app.

=cut

use Mojo::Base 'Mojolicious::Command';
use Muster::Generator;

has description => 'Generates a boilerplate Muster directory structure in your current working directory';
has usage       => "Usage: APPLICATION init\n";

sub run {
    my ($self, @args) = @_;

    print "generating muster boilerplate...\n";
    Muster::Generator->new->init;
    print "done.\n";
}

1;
