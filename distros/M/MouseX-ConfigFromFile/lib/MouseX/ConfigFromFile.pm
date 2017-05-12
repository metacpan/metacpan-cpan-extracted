package MouseX::ConfigFromFile;

use 5.008_001;
use Mouse::Role;
use MouseX::Types::Path::Class;

our $VERSION = '0.05';

requires 'get_config_from_file';

has 'configfile' => (
    is        => 'ro',
    isa       => 'Path::Class::File',
    coerce    => 1,
    predicate => 'has_configfile',
);

sub new_with_config {
    my ($class, %params) = @_;

    my $file = defined $params{configfile} ? $params{configfile} : do {
        my $attr = $class->meta->get_attribute('configfile');
        if ($attr->has_default) {
            my $default = $attr->default;
            ref($default) eq 'CODE' ? $default->($class) : $default;
        }
        elsif ($attr->has_builder) {
            my $builder = $attr->builder;
            $class->$builder();
        }
        else {
            undef;
        }
    };

    my %args = (
        defined $file ? %{ $class->get_config_from_file($file) } : (),
        %params,
    );

    return $class->new(%args);
}

no Mouse::Role; 1;

=head1 NAME

MouseX::ConfigFromFile - An abstract Mouse role for setting attributes from a configfile

=head1 SYNOPSIS

A real role based on this abstract role:

  package MyApp::ConfigRole;
  use Mouse::Role;
  with 'MouseX::ConfigFromFile';

  use MyApp::ConfigLoader;

  sub get_config_from_file {
      my ($class, $file) = @_;

      my $config_hashref = MyApp::ConfigLoader->load($file);

      return $config_hashref;
  }

A class that uses it:

  package MyApp;
  use Mouse;
  with 'MyApp::ConfigRole';

  # optionally, default the configfile:
  has '+configfile' => ( default => '/tmp/myapp.yml' );

A script that uses the class with a configfile:

  my $app = MyApp->new_with_config(
      configfile => '/etc/myapp.yml',
      other_opt  => 'foo',
  );

=head1 DESCRIPTION

This is an abstract role which provides an alternate constructor for
creating objects using parameters passed in from a configuration file.
The actual implementation of reading the configuration file is left to
concrete subroles.

It declares an attribute C<configfile> and a class method
C<new_with_config>, and requires that concrete roles derived from it
implement the class method C<get_config_from_file>.

Attributes specified directly as arguments to C<new_with_config>
supercede those in the configfile.

=head1 METHODS

=head2 new_with_config(%params?)

This is an alternate constructor, which knows to look for the
C<configfile> option in its arguments and use that to set attributes.
It is much like L<MouseX::Getopts>' C<new_with_options>.

Example:

  my $app = MyApp->new_with_config( configfile => '/etc/foo.yaml' );

Explicit arguments will override anything set by the configfile.

=head2 get_config_from_file($file)

This method is not implemented in this role, but it is required
of all subroles. Its two arguments are the class name and the configfile,
and it is expected to return a hashref of arguments to pass to C<new()>
which are sourced from the configfile.

Example:

  sub get_config_from_file {
      my ($class, $file) = @_;

      my $config = {};

      # ... load config from $file ...

      return $config;
  }

=head1 PROPERTIES

=head2 configfile

This is a L<Path::Class::File> object which can be coerced from a regular
path name string. This is the file your attributes are loaded from.
You can add a default configfile in the class using the role and it will
be honored at the appropriate time:

  has '+configfile' => ( default => '/etc/myapp.yaml' );

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

Brandon L. Black, L<MooseX::ConfigFromFile/AUTHOR>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Mouse>, L<Mouse::Role>, L<MouseX::Types::Path::Class>, L<MooseX::ConfigFromFile>

=cut
