package SemanticWeb::Schema::LockerDelivery;

# ABSTRACT: A DeliveryMethod in which an item is made available via locker.

use Moo;

extends qw/ SemanticWeb::Schema::DeliveryMethod /;


use MooX::JSON_LD 'LockerDelivery';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LockerDelivery - A DeliveryMethod in which an item is made available via locker.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A DeliveryMethod in which an item is made available via locker.

=head1 SEE ALSO

L<SemanticWeb::Schema::DeliveryMethod>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
