use utf8;

package SemanticWeb::Schema::PostOffice;

# ABSTRACT: A post office.

use Moo;

extends qw/ SemanticWeb::Schema::GovernmentOffice /;


use MooX::JSON_LD 'PostOffice';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::PostOffice - A post office.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A post office.

=head1 SEE ALSO

L<SemanticWeb::Schema::GovernmentOffice>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
