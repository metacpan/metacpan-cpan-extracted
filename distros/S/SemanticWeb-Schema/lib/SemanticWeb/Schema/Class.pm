use utf8;

package SemanticWeb::Schema::Class;

# ABSTRACT: A class

use Moo;

extends qw/ SemanticWeb::Schema::Intangible /;


use MooX::JSON_LD 'Class';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has superseded_by => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'supersededBy',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Class - A class

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A class, also often called a 'Type'; equivalent to rdfs:Class.

=head1 ATTRIBUTES

=head2 C<superseded_by>

C<supersededBy>

Relates a term (i.e. a property, class or enumeration) to one that
supersedes it.

A superseded_by should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Enumeration']>

=item C<InstanceOf['SemanticWeb::Schema::Property']>

=item C<InstanceOf['SemanticWeb::Schema::Class']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::Intangible>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
