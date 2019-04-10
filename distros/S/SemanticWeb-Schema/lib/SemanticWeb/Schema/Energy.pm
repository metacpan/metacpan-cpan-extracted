use utf8;

package SemanticWeb::Schema::Energy;

# ABSTRACT: Properties that take Energy as values are of the form '&lt;Number&gt; &lt;Energy unit of measure&gt;'.

use Moo;

extends qw/ SemanticWeb::Schema::Quantity /;


use MooX::JSON_LD 'Energy';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v3.5.0';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Energy - Properties that take Energy as values are of the form '&lt;Number&gt; &lt;Energy unit of measure&gt;'.

=head1 VERSION

version v3.5.0

=head1 DESCRIPTION

Properties that take Energy as values are of the form '&lt;Number&gt;
&lt;Energy unit of measure&gt;'.

=head1 SEE ALSO

L<SemanticWeb::Schema::Quantity>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
