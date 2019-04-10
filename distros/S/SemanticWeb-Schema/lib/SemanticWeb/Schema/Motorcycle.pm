use utf8;

package SemanticWeb::Schema::Motorcycle;

# ABSTRACT: A motorcycle or motorbike is a single-track

use Moo;

extends qw/ SemanticWeb::Schema::Vehicle /;


use MooX::JSON_LD 'Motorcycle';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Motorcycle - A motorcycle or motorbike is a single-track

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A motorcycle or motorbike is a single-track, two-wheeled motor vehicle.

=head1 SEE ALSO

L<SemanticWeb::Schema::Vehicle>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
