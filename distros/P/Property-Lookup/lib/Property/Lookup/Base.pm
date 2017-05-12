use 5.008;
use strict;
use warnings;

package Property::Lookup::Base;
BEGIN {
  $Property::Lookup::Base::VERSION = '1.101400';
}
# ABSTRACT: Base class for property lookup classes
use parent 'Class::Accessor::Constructor';
__PACKAGE__->mk_constructor;

# Define functions and class methods lest they be handled by AUTOLOAD.
sub DEFAULTS               { () }
sub FIRST_CONSTRUCTOR_ARGS { () }
sub DESTROY                { }

# Each lookup layer should answer any call, so return undef for all options
# unknown to this layer.
sub AUTOLOAD { }

1;


__END__
=pod

=head1 NAME

Property::Lookup::Base - Base class for property lookup classes

=head1 VERSION

version 1.101400

=head1 SYNOPSIS

    use Property::Lookup;

    my %opt;
    GetOptions(\%opt, '...');

    my $config = Property::Lookup->new;
    $config->add_layer(file => 'conf.yaml');
    $config->add_layer(getopt => \%opt);
    $config->default_layer({
        foo => 23,
    });

    my $foo = $config->foo;

    # ...

    use Property::Lookup::Local;
    local %Property::Lookup::Local::opt = (bar => 'baz');

=head1 DESCRIPTION

This is the base class for property lookup layers.

=head1 METHODS

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

