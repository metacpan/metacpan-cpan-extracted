package Starch;
$Starch::VERSION = '0.07';
use Starch::Factory;
use Moo::Object qw();

use strictures 2;
use namespace::clean;

sub new {
    my $class = shift;
    my $args = Moo::Object->BUILDARGS( @_ );

    my $plugins = delete( $args->{plugins} );
    my $factory = Starch::Factory->new(
        defined($plugins) ? (plugins=>$plugins) : (),
    );

    return $factory->manager_class->new(
        %$args,
        factory => $factory,
    );
}

1;
__END__

=head1 NAME

Starch - Implementation independent persistent statefulness.

=head1 SYNOPSIS

    my $starch = Starch->new(
        expires => 60 * 15, # 15 minutes
        store => {
            class   => '::Memory',
        },
    ); # Returns a Starch::Manager object.
    
    my $new_state = $starch->state();
    my $existing_state = $starch->state( $id );

=head1 DESCRIPTION

This module provides the main entry point to Starch and provides
the C<new> method for constructing new L<Starch::Manager> objects.

Starch documentation can be found at L<Starch::Manual>.

=head1 AUTHOR

Aran Clary Deltac <bluefeetE<64>gmail.com>

=head1 CONTRIBUTORS

=over

=item *

Arthur Axel "fREW" Schmidt <frioux+cpanE<64>gmail.com>

=item *

Jonathan Scott Duff <duffE<64>pobox.com>

=item *

Ismail Kerim <ismail.kerim<64>assurant.com>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to L<ZipRecruiter|https://www.ziprecruiter.com/>
for encouraging their employees to contribute back to the open
source ecosystem.  Without their dedication to quality software
development this distribution would not exist.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

