use utf8;

package SemanticWeb::Schema::CarUsageType;

# ABSTRACT: A value indicating a special usage of a car

use Moo;

extends qw/ SemanticWeb::Schema::QualitativeValue /;


use MooX::JSON_LD 'CarUsageType';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::CarUsageType - A value indicating a special usage of a car

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A value indicating a special usage of a car, e.g. commercial rental,
driving school, or as a taxi.

=head1 SEE ALSO

L<SemanticWeb::Schema::QualitativeValue>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
