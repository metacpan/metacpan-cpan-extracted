package Mock::Data::Plugin;
use Exporter::Extensible -exporter_setup => 1;
require Carp;
our @CARP_NOT= qw( Mock::Data Mock::Data::Util );

# ABSTRACT: Optional base class for Plugins
our $VERSION = '0.04'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mock::Data::Plugin - Optional base class for Plugins

=head1 DESCRIPTION

L<Mock::Data> plugins do not need to inherit from this class.  C<Mock::Data> determines whether
a package is a plugin by whether it has a method C<apply_mockdata_plugin>.  There is no behavior
to inherit, either; a plugin may make any changes it likes to the C<Mock::Data> instance it was
given, and the tools to make these changes can be found in the C<Mock::Data::Util> package.

The process of loading a plugin is exactly:

  require $plugin_class;
  $mock= $plugin_class->apply_mockdata_plugin($mock);

=head1 EXTENDING

If you do inherit from this class, you get the benefits of L<Exporter::Extensible>, and
C<@CARP_NOT> linkage that makes L<Carp> errors point to the code that called into C<Mock::Data>
rather than the code of C<Mock::Data> that called your plugin's function.

  package Mock::Data::Plugin::MyPlugin;
  use Mock::Data::Plugin -exporter_setup => 1;
  sub apply_mockdata_plugin {
    my $mock= shift;
    ...
  }

The most common things a plugin might do in that method are:

=over

=item Add Generators

Generators added by a plugin should include the scope of the package, like

  $mock->add_generators( 'MyPlugin::something' => \&something );

This will automatically add that generator as both the name C<'MyPlugin::soomething'> and
C<'something'> if the name was not already taken.  By adding both, other modules can reference
the namespaced name when they specifically need it, rather than whatever mix of generators
are merged under the generic name or whichever module claimed it first.

=item Add Parent Classes

If C<Mock::Data> were based on L<Moo>, this would be possible by adding Roles to the object.
A similar mechanism is provided by L<Mock::Data::Util/mock_data_subclas>, which re-blesses
the L<Mock::Data> instance to include other parent classes.  This allows you to directly add
methods to L<Mock::Data>.  Be careful not to use nouns when adding methods, because generators
use this same method namespace.

=back

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 VERSION

version 0.04

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
