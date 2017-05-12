use 5.008;
use strict;
use warnings;

package Property::Lookup;
BEGIN {
  $Property::Lookup::VERSION = '1.101400';
}
# ABSTRACT: Object property lookup across multiple layers
use Error::Hierarchy::Util qw/assert_defined load_class/;
use Property::Lookup::Local;
use Property::Lookup::Hash;

# Don't rely on UNIVERSAL::throw if we defined an AUTOLOAD...
use Error::Hierarchy::Internal::CustomMessage;
use parent qw(Class::Accessor::Complex Class::Accessor::Constructor);
__PACKAGE__->mk_singleton_constructor(qw(new instance))
  ->mk_array_accessors(qw(layers))
  ->mk_scalar_accessors(qw(local_layer default_layer));

sub init {
    my $self = shift;
    $self->local_layer(Property::Lookup::Local->new);
    $self->default_layer(Property::Lookup::Hash->new);
}

sub add_layer {
    my $self = shift;
    my $type = shift;
    assert_defined $type, 'missing configuration type';
    if ($type eq 'file') {
        my $spec = shift;
        assert_defined $spec, 'missing file configuration spec';
        my ($class, $conf_filename);
        if (index($spec, ';') != -1) {
            ($class, $conf_filename) = split /;/ => $spec;
            assert_defined $_,
              sprintf("can't determine file configuration class from spec [%s]",
                $spec)
              for $class, $conf_filename;
        } else {

            # assume a default class, and the spec _is_ the conf file name
            $class         = 'Property::Lookup::File';
            $conf_filename = $spec;
        }
        load_class $class, 0;
        $self->layers_push($class->new(filename => $conf_filename));
    } elsif ($type eq 'hash') {
        my $options = shift;
        assert_defined $options, 'missing hash configuration spec';
        $self->layers_push(Property::Lookup::Hash->new(hash => $options));
    } else {
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => sprintf 'unknown configuration type [%s]',
            $type
        );
    }
}

sub get_layers {
    my $self = shift;
    ($self->local_layer, $self->layers, $self->default_layer)
}

# FIXME Provide a way to tell Property::Lookup about cumulative methods.
# get_config() differs from all other autoloaded methods in that the results
# are cumulative over the layers; for the other methods, the first layer that
# responds wins. So maybe the user of Property::Lookup should be able to
# specify which methods are supposed to be cumulative.

sub get_config {
    my $self = shift;
    my %config;
    for my $layer ($self->get_layers) {
        %config = (%config, $layer->get_config);
    }
    wantarray ? %config : \%config;
}

# Define functions and class methods lest they be handled by AUTOLOAD.
sub DEFAULTS               { () }
sub FIRST_CONSTRUCTOR_ARGS { () }
sub DESTROY                { }

# Ask every layer in turn; return the first defined answer we're given.
sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    if (@_) {
        throw Error::Hierarchy::Internal::CustomMessage(
            custom_message => sprintf 'configuration key [%s] is read-only',
            $method
        );
    }

    for my $layer ($self->get_layers) {
        my $answer = $layer->$method;
        return $answer if defined $answer;
    }
    undef;
}

1;


__END__
=pod

=head1 NAME

Property::Lookup - Object property lookup across multiple layers

=head1 VERSION

version 1.101400

=head1 SYNOPSIS

    use Property::Lookup;

    my %opt;
    GetOptions(\%opt, '...');

    my $config = Property::Lookup->new;
    $config->add_layer(file => 'conf.yaml');
    $config->add_layer(hash => \%opt);
    $config->default_layer({
        foo => 23,
    });

    my $foo = $config->foo;

    # ...

    use Property::Lookup::Local;
    local %Property::Lookup::Local::opt = (bar => 'baz');

=head1 DESCRIPTION

This module provides a way to look up an object property in a layer of
objects. The user can define various layers; when the user asks this main
object to look up a key, it will ask each layer in turn whether it has a value
for the given key. When a layer responds, that answer will be returned to the
user and no more layers will be asked.

This is useful in application configuration. Suppose you have a configuration
file, which is your primary mechanism for configuring the application. But the
user should also be able to override individual values using command line
arguments. And even if a key is found neither on the command line nor in the
configuration file, you want to provide a default.

This scenario is easy to implement with this module.

Because application configuration is the primary intended use, this module is
a singleton.

=head1 METHODS

=head2 new

Creates the singleton object.

=head2 instance

Synonymous for C<new>.

=head2 init

Called when the object is constructed, it initializes the local and default layers.

=head2 local_layer

    local %Property::Lookup::Local::opt = (bar => 'baz');

This is initialized as a L<Property::Lookup::Local> object. It can be used to
temporarily override lookup values; if you use C<local>, the values will
automatically forgotten at the end of the current scope. When a property is
looked up via C<AUTOLOAD>, this layer is always checked first.

=head2 default_layer

    my $config = Property::Lookup->new;
    $config->default_layer({ foo => 42 });

This is initialized as a L<Property::Lookup::Hash> object. It can be used to
set default values. When a property is looked up via C<AUTOLOAD>, this layer
is always checked last.

=head2 add_layer

This method adds a layer to the singleton lookup object. The first argument
determines which kind of layer is added; the rest are arguments passed to the
layer. The first argument can be C<file> to construct a file lookup layer, or
C<hash> to construct a hash lookup layer.

    my $config = Property::Lookup->new;
    $config->add_layer(file => 'conf.yaml');

With C<file>, a layer of class L<Property::Lookup::File> is constructed. The
second argument is the name of the YAML file from which values are taken.

    my $config = Property::Lookup->new;
    $config->add_layer(hash => \%opt);

With C<hash>, a layer of class L<Property::Lookup::Hash> is constructed. The
second argument is the name of the YAML file from which values are taken.

If the layer-specific arguments are wrong, or the layer type is not one of the
names given above, an exception occurs.

=head2 get_layers

Returns the list of layer objects. The local layer is special; it always comes
first, no matter which layers have been specified. Likewise for the default
layer, which always comes last.

=head2 get_config

This method calls C<get_config()> on all layers and accumulates the data in a
hash, which is then returned. The individual C<get_config()> methods are
supposed to return the data with which a layer was configured with: The
options hash for the C<Local> layer; the hash for a L<Hash> layer.

=head2 AUTOLOAD

Determines which method was called, then asks every layer in turn. It returns
the first defined answer it finds. The local layer is special - it always
comes first, no matter which layers have been specified. Likewise for the
default layer, which always comes last.

=head2 DEFAULTS

This accessor is used by L<Class::Accessor::Constructor>. It is defined as an
empty list here so C<AUTOLOAD> won't try to handle it.

=head2 FIRST_CONSTRUCTOR_ARGS

This accessor is used by L<Class::Accessor::Constructor>. It is defined as an
empty list here so C<AUTOLOAD> won't try to handle it.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Property-Lookup>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Property-Lookup/>.

The development version lives at
L<http://github.com/hanekomu/Property-Lookup/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

