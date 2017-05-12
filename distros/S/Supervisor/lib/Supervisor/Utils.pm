package Supervisor::Utils;

use 5.008;

use strict;
use warnings;

use Badger::Exception;
use base 'Badger::Utils';

our $EXPORT_ANY = 'env_store env_restore env_create env_parse env_dump';

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub env_store {

    my %env;

    while ((my $key, my $value) = each(%ENV)) {

        delete $ENV{$key};
        $env{$key} = $value;

    }

    return \%env;

}

sub env_restore {
    my $env = shift;

    while ((my $key, my $value) = each(%ENV)) {

        delete $ENV{$key};

    }

    while ((my $key, my $value) = each(%{$env})) {

        $ENV{$key} = $value;

    }

}

sub env_create {
    my $env = shift;

    while ((my $key, my $value) = each(%{$env})) {

        $ENV{$key} = $value;

    }

}

sub env_parse {
    my $env = shift;

    my ($key, $value, %env);
    my @envs = split(';;', $env);

    foreach my $y (@envs) {

        ($key, $value) = split('=', $y);
        $env{$key} = $value;

    }

    return \%env;

}

sub env_dump {

    my $env;

    while ((my $key, my $value) = each(%ENV)) {

        $env .= "$key=$value;;";

    }

    # remove the ;; at the end

    chop $env;
    chop $env;

    return $env;

}

1;

__END__

=head1 NAME

Supervisor::Utils - Usefull utility routines for the Supervisor

=head1 SYNOPSIS

 use Supervisor::Class
   version => '0.01',
   base    => 'Supervisor::Base',
   utils   => 'env_store',
 ;

=head1 DESCRIPTION

This module provides a set of basic utilities that don't depend on a blessed
object to function. These utilites currently only provide functions to 
manipulate the global $ENV variable.

=head1 METHODS

=over 4

=item env_store

Remove all items from the $ENV variable and store them in a hash variable.

Example:
    my $env = env_store();

=item env_restore

Remove all items from $ENV variable and restore it back to a saved hash variable.

Example:
    env_restore($env);

=item env_create

Store all the items from a hash variable into the $ENV varable.

Example:
    env_create($env);

=item env_parse

Take a formated string and parse it into a hash variable. The string must have
this format: "item=value;;item2=value2";

Example:
    my $string = "item=value;;item2=value2";
    my $env = env_parse($string);
    env_create($env);

=item env_dump

Take the items from the current $ENV variable and create a formated string.

Example:
    my $string = env_dump();
    my $env = env_create($string);

=back

=head1 EXPORTS

 env_restore() 
 env_create() 
 env_parse() 
 env_dump()
 env_store()

=head1 SEE ALSO

 Badger::Utils

 Supervisor
 Supervisor::Base
 Supervisor::Class
 Supervisor::Constants
 Supervisor::Controller
 Supervisor::Log
 Supervisor::Process
 Supervisor::ProcessFactory
 Supervisor::Session
 Supervisor::Utils
 Supervisor::RPC::Server
 Supervisor::RPC::Client

=head1 AUTHOR

Kevin L. Esteb, E<lt>kesteb@wsipc.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
