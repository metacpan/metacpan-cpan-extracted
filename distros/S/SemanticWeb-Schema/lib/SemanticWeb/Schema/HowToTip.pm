use utf8;

package SemanticWeb::Schema::HowToTip;

# ABSTRACT: An explanation in the instructions for how to achieve a result

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork SemanticWeb::Schema::ListItem /;


use MooX::JSON_LD 'HowToTip';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::HowToTip - An explanation in the instructions for how to achieve a result

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

An explanation in the instructions for how to achieve a result. It provides
supplementary information about a technique, supply, author's preference,
etc. It can explain what could be done, or what should not be done, but
doesn't specify what should be done (see HowToDirection).

=head1 SEE ALSO

L<SemanticWeb::Schema::ListItem>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
