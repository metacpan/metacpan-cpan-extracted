use utf8;

package SemanticWeb::Schema::DataCatalog;

# ABSTRACT: A collection of datasets.

use Moo;

extends qw/ SemanticWeb::Schema::CreativeWork /;


use MooX::JSON_LD 'DataCatalog';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';


has dataset => (
    is        => 'rw',
    predicate => 1,
    json_ld   => 'dataset',
);





1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::DataCatalog - A collection of datasets.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

A collection of datasets.

=head1 ATTRIBUTES

=head2 C<dataset>

A dataset contained in this catalog.

A dataset should be one of the following types:

=over

=item C<InstanceOf['SemanticWeb::Schema::Dataset']>

=back

=head1 SEE ALSO

L<SemanticWeb::Schema::CreativeWork>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
