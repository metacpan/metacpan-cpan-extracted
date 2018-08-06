package SemanticWeb::Schema::ChildrensEvent;

# ABSTRACT: Event type: Children's event.

use Moo;

extends qw/ SemanticWeb::Schema::Event /;


use MooX::JSON_LD 'ChildrensEvent';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.1';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ChildrensEvent - Event type: Children's event.

=head1 VERSION

version v0.0.1

=head1 DESCRIPTION

Event type: Children's event.

=head1 SEE ALSO

L<SemanticWeb::Schema::Event>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
