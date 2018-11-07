use utf8;

package SemanticWeb::Schema::ShareAction;

# ABSTRACT: The act of distributing content to people for their amusement or edification.

use Moo;

extends qw/ SemanticWeb::Schema::CommunicateAction /;


use MooX::JSON_LD 'ShareAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.4';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::ShareAction - The act of distributing content to people for their amusement or edification.

=head1 VERSION

version v0.0.4

=head1 DESCRIPTION

The act of distributing content to people for their amusement or
edification.

=head1 SEE ALSO

L<SemanticWeb::Schema::CommunicateAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
