package MooseX::App::Plugin::Depends;

use Moose::Role;
use namespace::autoclean;

sub plugin_metaroles {
    my ($self, $class) = @_;

    return {
        attribute => ['MooseX::App::Plugin::Depends::Meta::Attribute'],
        class     => ['MooseX::App::Plugin::Depends::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Depends - Adds dependent options

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Depends);
 
 use Moose::Util::TypeConstraints;

 option 'FileFormat' => (
   is  => 'ro',
   isa => enum( [qw(tsv csv xml)] ),
 );

 option 'WriteToFile' => (
   is       => 'ro',
   isa      => 'Bool',
   depends => [qw(FileFormat)],
 );

In your script:

 #!/usr/bin/env perl

 use strict;
 use warnings;

 use MyApp;

 MyApp->new_with_options( WriteToFile => 1 );
 # generates Error
 # Option 'WriteToFile' requires 'FileFormat' to be defined

 MyApp->new_with_options( WriteToFile => 1, FileFormat => 'tsv );
 # generates no errors

 MyApp->new_with_options();
 # generates no errors

=head1 DESCRIPTION

In many real-world scenarios, sets of options are, by design, needed to be
specified together. This plugin adds the ability to create dependent options
to your application, options that require one or more other options
for your application to perform properly.

=cut
