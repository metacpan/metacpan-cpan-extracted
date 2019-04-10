use utf8;

package SemanticWeb::Schema::LifestyleModification;

# ABSTRACT: A process of care involving exercise

use Moo;

extends qw/ SemanticWeb::Schema::MedicalEntity /;


use MooX::JSON_LD 'LifestyleModification';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::LifestyleModification - A process of care involving exercise

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A process of care involving exercise, changes to diet, fitness routines,
and other lifestyle changes aimed at improving a health condition.

=head1 SEE ALSO

L<SemanticWeb::Schema::MedicalEntity>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
