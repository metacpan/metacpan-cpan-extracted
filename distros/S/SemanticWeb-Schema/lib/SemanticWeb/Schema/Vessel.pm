use utf8;

package SemanticWeb::Schema::Vessel;

# ABSTRACT: A component of the human body circulatory system comprised of an intricate network of hollow tubes that transport blood throughout the entire body.

use Moo;

extends qw/ SemanticWeb::Schema::AnatomicalStructure /;


use MooX::JSON_LD 'Vessel';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Vessel - A component of the human body circulatory system comprised of an intricate network of hollow tubes that transport blood throughout the entire body.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A component of the human body circulatory system comprised of an intricate
network of hollow tubes that transport blood throughout the entire body.

=head1 SEE ALSO

L<SemanticWeb::Schema::AnatomicalStructure>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
