use utf8;

package SemanticWeb::Schema::Car;

# ABSTRACT: A car is a wheeled

use Moo;

extends qw/ SemanticWeb::Schema::Vehicle /;


use MooX::JSON_LD 'Car';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Car - A car is a wheeled

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

A car is a wheeled, self-powered motor vehicle used for transportation.

=head1 SEE ALSO

L<SemanticWeb::Schema::Vehicle>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
