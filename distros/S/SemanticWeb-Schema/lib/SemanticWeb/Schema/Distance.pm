use utf8;

package SemanticWeb::Schema::Distance;

# ABSTRACT: Properties that take Distances as values are of the form '&lt;Number&gt; &lt;Length unit of measure&gt;'

use Moo;

extends qw/ SemanticWeb::Schema::Quantity /;


use MooX::JSON_LD 'Distance';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Distance - Properties that take Distances as values are of the form '&lt;Number&gt; &lt;Length unit of measure&gt;'

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

Properties that take Distances as values are of the form '&lt;Number&gt;
&lt;Length unit of measure&gt;'. E.g., '7 ft'.

=head1 SEE ALSO

L<SemanticWeb::Schema::Quantity>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
