use 5.008;
use strict;
use warnings;

package Property::Lookup::Hash;
BEGIN {
  $Property::Lookup::Hash::VERSION = '1.101400';
}
# ABSTRACT: Hash-based property lookup layer
use parent 'Property::Lookup::Base';
__PACKAGE__->mk_hash_accessors(qw(hash));

sub AUTOLOAD {
    my $self = shift;
    (my $method = our $AUTOLOAD) =~ s/.*://;
    $self->hash($method);
}

sub get_config {
    my $self = shift;
    $self->hash;
}

1;


__END__
=pod

=head1 NAME

Property::Lookup::Hash - Hash-based property lookup layer

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

This class implements a hash-based property lookup layer.

=head1 METHODS

=head2 hash

This hash accessor holds the hash in which values are being looked up.

=head2 get_config

Returns the hash with which this layer was configured.

=head2 AUTOLOAD

Determines which key is being looked up, the simply consults the C<hash>
accessor for that key.

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

