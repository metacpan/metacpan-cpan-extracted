package SemanticWeb::Schema::GovernmentService;

# ABSTRACT: A service provided by a government organization

use Moo;

extends qw/ SemanticWeb::Schema::Service /;


use MooX::JSON_LD 'GovernmentService';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';


has service_operator => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'serviceOperator',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::GovernmentService - A service provided by a government organization

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

A service provided by a government organization, e.g. food stamps, veterans
benefits, etc.

=head1 ATTRIBUTES

=head2 C<service_operator>

C<serviceOperator>

The operating organization, if different from the provider. This enables
the representation of services that are provided by an organization, but
operated by another organization like a subcontractor.

A service_operator should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Organization']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Service>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
