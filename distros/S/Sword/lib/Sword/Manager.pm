package Sword::Manager;
BEGIN {
  $Sword::Manager::VERSION = '0.102800';
}
use strict;
use warnings;

require XSLoader;
XSLoader::load('Sword', $Sword::Manager::VERSION);

# ABSTRACT: Sword library manager

1;



=pod

=head1 NAME

Sword::Manager - Sword library manager

=head1 VERSION

version 0.102800

=head1 SYNOPSIS

  use Sword;

  my $library = Sword::Manager->new;

  # List available modules (Bibles, commentaries, dictionaries, books, etc.)
  my $modules = $library->modules;

  # Get a specific module by it's short name
  my $module = $library->get_module('KJV');

=head1 DESCRIPTION

This Perl module provides access to the C<SWMgr> class from the Sword Engine API.

This documentation should cover everything that you can do with it. If something is wrong or missing, please report a bug.

=head1 METHODS

=head2 new

  my $library = Sword::Manager->new;

This constructs a new Sword Engine manager. This object will automatically load the module configuration from the system, user, and working directory module configuration files. If you have GNOME Sword installed or another Sword-based application, this should load all the library files available to that application.

This constructor configures the library for plain text markup. 

Someday, this construction will take options to allow you to customize how the library is constructed, but today is not that day.

=head2 modules

  my $modules = $library->modules;

Returns an array reference containing the L<Sword::Module> objects for all the installed modules found in the configuration.

=head2 get_module

  my $module = $library->get_module($name);

Returns the named L<Sword::Module> object or C<undef> if that module is not found.

=head1 SEE ALSO

L<Sword::Module>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

