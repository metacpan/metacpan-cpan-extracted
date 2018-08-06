package SemanticWeb::Schema::Duration;

# ABSTRACT: Quantity: Duration (use <a href="http://en

use Moo;

extends qw/ SemanticWeb::Schema::Quantity /;


use MooX::JSON_LD 'Duration';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::Duration - Quantity: Duration (use <a href="http://en

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

=for html Quantity: Duration (use <a href="http://en.wikipedia.org/wiki/ISO_8601">ISO
8601 duration format</a>).

=head1 SEE ALSO

L<SemanticWeb::Schema::Quantity>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
