use 5.008;
use strict;
use warnings;

package Property::Lookup::Local;
BEGIN {
  $Property::Lookup::Local::VERSION = '1.101400';
}
# ABSTRACT: Package hash-based property lookup layer
use parent 'Property::Lookup::Base';
our %opt;    # so it can be overridden via local()

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    our %opt;
    $opt{$method};
}

sub get_config {
    our %opt;
    wantarray ? %opt: \%opt;
}

1;


__END__
=pod

=head1 NAME

Property::Lookup::Local - Package hash-based property lookup layer

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

This class implements a package hash-based property lookup layer. It has a
package global C<%opt> which the user can override - usually using C<local> so
only the scope in which this layer is used is affected.

=head1 METHODS

=head2 get_config

Returns the options hash with which this layer was configured.

=head2 AUTOLOAD

Determines which key is being looked up, the simply consults the C<%opt> for
that key.

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

