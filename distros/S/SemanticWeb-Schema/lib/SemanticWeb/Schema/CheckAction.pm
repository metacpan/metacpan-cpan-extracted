use utf8;

package SemanticWeb::Schema::CheckAction;

# ABSTRACT: An agent inspects

use Moo;

extends qw/ SemanticWeb::Schema::FindAction /;


use MooX::JSON_LD 'CheckAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CheckAction - An agent inspects

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An agent inspects, determines, investigates, inquires, or examines an
object's accuracy, quality, condition, or state.

=head1 SEE ALSO

L<SemanticWeb::Schema::FindAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
