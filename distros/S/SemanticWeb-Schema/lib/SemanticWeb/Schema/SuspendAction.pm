use utf8;

package SemanticWeb::Schema::SuspendAction;

# ABSTRACT: The act of momentarily pausing a device or application (e

use Moo;

extends qw/ SemanticWeb::Schema::ControlAction /;


use MooX::JSON_LD 'SuspendAction';
use Ref::Util qw/ is_plain_hashref /;
# RECOMMEND PREREQ: Ref::Util::XS

use namespace::autoclean;

our $VERSION = 'v0.0.2';




1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SemanticWeb::Schema::SuspendAction - The act of momentarily pausing a device or application (e

=head1 VERSION

version v0.0.2

=head1 DESCRIPTION

The act of momentarily pausing a device or application (e.g. pause music
playback or pause a timer).

=head1 SEE ALSO

L<SemanticWeb::Schema::ControlAction>

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
