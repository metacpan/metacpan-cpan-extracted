use utf8;

package SemanticWeb::Schema::DepartAction;

# ABSTRACT: The act of departing from a place

use Moo;

extends qw/ SemanticWeb::Schema::MoveAction /;


use MooX::JSON_LD 'DepartAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DepartAction - The act of departing from a place

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of departing from a place. An agent departs from an fromLocation
for a destination, optionally with participants.

=head1 SEE ALSO

L<SemanticWeb::Schema::MoveAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
