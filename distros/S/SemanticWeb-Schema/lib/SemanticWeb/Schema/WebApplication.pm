use utf8;

package SemanticWeb::Schema::WebApplication;

# ABSTRACT: Web applications.

use Moo;

extends qw/ SemanticWeb::Schema::SoftwareApplication /;


use MooX::JSON_LD 'WebApplication';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';


has browser_requirements => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'browserRequirements',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::WebApplication - Web applications.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

Web applications.

=head1 ATTRIBUTES

=head2 C<browser_requirements>

C<browserRequirements>

Specifies browser requirements in human-readable text. For example,
'requires HTML5 support'.

A browser_requirements should be one of the following types:

=over

=item C<Str>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::SoftwareApplication>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
