package Module::Make::Maker;
use strict;
use warnings;
use Module::Make::Base -base;

field config_class => 'Module::Make::Config';
field config => -init => '$self->require_class("config_class")->new->init';

sub import {
    my $class = shift;
    my $flag = shift || '';
    my $package = caller;
    no strict 'refs';
    if ($flag eq 'exec') {
        my $method = shift(@ARGV);
        $class->new->$method(@ARGV);
        exit;
    }
}

sub make_new_makefile {
    my $self = shift;
    my $exec_command = $self->config->exec_command;
    io('Makefile')->print(<<"...");
.PHONY: check_config_yaml

Makefile: config.yaml
	$exec_command make_makefile

config.yaml: check_config_yaml

check_config_yaml:
	$exec_command check_config_yaml
...
}

sub check_config_yaml {
    my $self = shift;
    $self->abort("Please edit config.yaml before running make\n");
}

sub abort {
    my $self = shift;
    warn "Error: ", @_;
    exit 1;
}

1;

=head1 Things a Makefile should do:

 * Make sure make.yaml has been edited once.
 * Rebuild Makefile if necessary
 * Check to make sure target files were not edited
 * Build targets if necessary

=cut
