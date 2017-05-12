package MooseX::Configuration;
BEGIN {
  $MooseX::Configuration::VERSION = '0.02';
}

use strict;
use warnings;

use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        attribute => ['MooseX::Configuration::Trait::Attribute'],
    },
    base_class_roles => ['MooseX::Configuration::Trait::Object'],
);

1;

# ABSTRACT: Define attributes which come from configuration files



=pod

=head1 NAME

MooseX::Configuration - Define attributes which come from configuration files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package MyApp::Config;

  use Moose;
  use MooseX::Configuration;

  has database_name => (
      is      => 'ro',
      isa     => 'Str',
      default => 'MyApp',
      section => 'database',
      key     => 'name',
      documentation =>
          'The name of the database.',
  );

  has database_username => (
      is      => 'ro',
      isa     => Str,
      default => q{},
      section => 'database',
      key     => 'username',
      documentation =>
          'The username to use when connecting to the database. By default, this is empty.',
  );

  my $config = MyApp::Config->new( config_file => '/path/to/config/myapp.ini' );
  $config->write_file( ... );

=head1 DESCRIPTION

This module lets you define attributes which can come from a configuration
file. It also adds a role to your class which allows you to write a
configuration file.

It is based on using a simple INI-style configuration file, which contains
sections and keys:

  key1 = value
  key2 = 42

  [section]
  key3 = 2

=head1 ATTRIBUTE API

Simply using this module in your class changes your class's attribute
metaclass to add support for defining attributes as configuration items.

There are two new parameters you can pass when defining an attribute,
C<section> and C<key>. These tell the module how to find the attribute's value
in the configuration file. The C<section> parameter is optional. If you don't
set it, but I<do> provide a key, then the section defaults to C<_>, which is
the main section of the config file.

If you pass a C<section> you must also pass a C<key>.

Defining an attribute as a configuration item has several effects. First, it
changes the default value for the attribute. Before looking at a C<default> or
C<builder> you define, the attribute will first look in the config file for a
corresponding value. If one exists, it will use that, otherwise it will fall
back to using a default you supply.

If you do supply a default, it must be a string (or number), not a reference
or undefined value.

All configuration attributes are lazy. This is necessary because the
configuration file needs to be loaded and parsed before looking up values.

The C<documentation> string is used when generating a configuration file. See
below for details.

=head1 CLASS API

Your config class will do the L<MooseX::Configuration::Trait::Object>
role. This adds several attributes and methods to your class.

=head2 config_file attribute

The C<config_file> attribute defines the location of the configuration
file. The role supplies a builder method that you can replace,
C<_build_config_file>. It should return a string or L<Path::Class::File>
object pointing to the configuration file. It can also return C<undef>.

If you I<don't> provide your own builder, then the C<config_file> will default
to C<undef>.

=head2 $config->_raw_config()

This returns the raw hash reference as read by L<Config::INI::Reader>. If no
config file was defined, then this simply returns an empty hash reference.

=head2 $config->write_config_file( ... )

This method can be used to write a configuration file. It accepts several
parameters:

=over 4

=item * file

This can be either a path or an open filehandle. The configuration text will
be written to this file. This defaults to the value of C<<
$self->config_file() >>. If no file is provided or already set in the object,
this method will die.

=item * generated_by

If this parameter is passed, it will be included as a comment at the top of
the generated file.

=item * values

This should be a hash reference of attribute names and values to write to the
config file. It is optional.

=back

When writing the configuration file, any configuration item that was set in
the configuration file originally will be set in the new file, as will any
value passed in the C<values> key. An attribute value set in the constructor
or by a default will I<not> be included in the generated file.

Keys without a value will still be included in the file as a comment.

If an attribute includes a documentation string, that string will appear as a
comment above the key. If the attribute defines a simple scalar default, that
will also be included in the comment, unless the default is the empty
string. Finally, if the attribute is required, that is also mentioned in the
comment.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-moosex-configuration@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0

=cut


__END__

