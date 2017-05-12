package MooseX::App::Plugin::MutexGroup;

use Moose::Role;
use namespace::autoclean;

sub plugin_metaroles {
    my ($self, $class) = @_;

    return {
        attribute => ['MooseX::App::Plugin::MutexGroup::Meta::Attribute'],
        class     => ['MooseX::App::Plugin::MutexGroup::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::MutexGroup - Adds mutually exclusive options

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(MutexGroup);
 
 option 'UseAmmonia' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'NonMixableCleaningChemicals',
 );
 
 option 'UseChlorine' => (
   is         => 'ro',
   isa        => 'Bool',
   mutexgroup => 'NonMixableCleaningChemicals'
 );

In your script:

 #!/usr/bin/env perl
 
 use strict;
 use warnings;
 
 use MyApp;
 
 MyApp->new_with_options( UseAmmonia => 1, UseChlorine => 1 );
 # generates Error
 # More than one attribute from mutexgroup NonMixableCleaningChemicals('UseAmmonia','UseChlorine') *cannot* be specified
 
 MyApp->new_with_options();
 # generates Error
 # One attribute from mutexgroup NonMixableCleaningChemicals('UseAmmonia','UseChlorine') *must* be specified
 
 MyApp->new_with_options( UseAmmonia => 1 );
 # generates no errors
 
 MyApp->new_with_options( UseChlorine => 1 );
 # generates no errors

=head1 DESCRIPTION

This plugin adds mutually exclusive options to your application. In the current implementation, all defined
MutexGroups *must* have exactly one initialized option. This means that there is an implicit requiredness
of one option from each MutexGroup.

=cut
