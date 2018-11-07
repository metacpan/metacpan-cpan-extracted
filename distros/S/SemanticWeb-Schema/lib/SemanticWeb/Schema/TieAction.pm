use utf8;

package SemanticWeb::Schema::TieAction;

# ABSTRACT: The act of reaching a draw in a competitive activity.

use Moo;

extends qw/ SemanticWeb::Schema::AchieveAction /;


use MooX::JSON_LD 'TieAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::TieAction - The act of reaching a draw in a competitive activity.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of reaching a draw in a competitive activity.

=head1 SEE ALSO

L<SemanticWeb::Schema::AchieveAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
