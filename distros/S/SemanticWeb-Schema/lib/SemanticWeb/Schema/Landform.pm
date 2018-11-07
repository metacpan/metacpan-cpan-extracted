use utf8;

package SemanticWeb::Schema::Landform;

# ABSTRACT: A landform or physical feature

use Moo;

extends qw/ SemanticWeb::Schema::Place /;


use MooX::JSON_LD 'Landform';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Landform - A landform or physical feature

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

A landform or physical feature. Landform elements include mountains,
plains, lakes, rivers, seascape and oceanic waterbody interface features
such as bays, peninsulas, seas and so forth, including sub-aqueous terrain
features such as submersed mountain ranges, volcanoes, and the great ocean
basins.

=head1 SEE ALSO

L<SemanticWeb::Schema::Place>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
