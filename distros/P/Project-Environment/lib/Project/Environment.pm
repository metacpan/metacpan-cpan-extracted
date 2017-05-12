package Project::Environment;

# ABSTRACT: Set and detect project environment via .environment file.

use Moose;
with 'Project::Environment::Role';
with 'MooseX::Role::Flyweight';

use version; our $VERSION = version->new('v1.2.0');

use overload '""' => sub { shift->project_environment };


has _caller => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub {
        for (0 .. 10) {
            my @caller = caller($_);
            return \@caller if $caller[3] eq 'Moose::Object::new';
        }
    },
);

1;    ## eof

__END__

=pod

=encoding UTF-8

=head1 NAME

Project::Environment - Set and detect project environment via .environment file.

=head1 VERSION

version v1.2.0

=head1 SYNOPSIS

Add a .environment file into the root of your project:

  .
  |-- .environment (<-- add this)
  |-- .git
  |-- lib
      |-- MyApp
      |  |-- Environment.pm
      |-- MyApp.pm

Define a subclass for your application:

 package MyApp::Environment;

 use Moose;
 extends 'Project::Environment';

 1;

Now, somewhere inside your application code:

 my $env = MyApp::Environment->instance->project_environment; ## or ->env

=head1 DESCRIPTION

This module provides a way to determine the environment an application is
running in (e.g. development, production, testing, etc.).

Mainly the environment is detected from C<.environment> file in the project
root.

You can also set the environment via C<%ENV>.

Most of the functionality defined and documented in
L<Project::Environment::Role>.

This consumer class provides 2 things:

=head2 singularity

This isn't exactly a singleton. And all of the magic is provided by
L<MooseX::Role::Flyweight>.

In short, all you have to do is call C<instance> constructor instead of C<new>
and you get only one instance of the object and the result of the figuring out
the environment is cached.

=head2 stringification

An instance of L<Project::Environment> will stringify into the
environment name properly. This is useful if you were to store the instance
of the L<Project::Environment> object in an attribute, rather than
the string name of the environment.

 has environment => (
     is      => 'ro',
     default => sub { MyApp::Environment->instance },
 );

Somewhere else in the application code:

 if ($self->environment eq 'production') {
     ## do not break
 } else {
     ## break everything
 }

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
