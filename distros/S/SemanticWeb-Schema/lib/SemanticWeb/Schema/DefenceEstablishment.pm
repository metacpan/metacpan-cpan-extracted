package SemanticWeb::Schema::DefenceEstablishment;

# ABSTRACT: A defence establishment

use Moo;

extends qw/ SemanticWeb::Schema::GovernmentBuilding /;


use MooX::JSON_LD 'DefenceEstablishment';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DefenceEstablishment - A defence establishment

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A defence establishment, such as an army or navy base.

=head1 SEE ALSO

L<SemanticWeb::Schema::GovernmentBuilding>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
