use utf8;

package SemanticWeb::Schema::EmailMessage;

# ABSTRACT: An email message.

use Moo;

extends qw/ SemanticWeb::Schema::Message /;


use MooX::JSON_LD 'EmailMessage';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::EmailMessage - An email message.

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

An email message.

=head1 SEE ALSO

L<SemanticWeb::Schema::Message>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
