use 5.008;
use strict;
use warnings;

package Dist::Zilla::Plugin::DistManifestTests;
# ABSTRACT: (DEPRECATED) Release tests for the manifest

our $VERSION = '2.000006';

use Moose;
extends 'Dist::Zilla::Plugin::Test::DistManifest';

before register_component => sub {
    warn '!!! [DistManifestTests] is deprecated and will be removed in a future release; replace it with [Test::DistManifest]';
};

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DistManifestTests - (DEPRECATED) Release tests for the manifest

=head1 VERSION

version 2.000006

=head1 SYNOPSIS

Please use L<Dist::Zilla::Plugin::Test::DistManifest>.

In C<dist.ini>:

    [Test::DistManifest]

=for test_synopsis 1;
__END__

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Test-DistManifest>
(or L<bug-Dist-Zilla-Plugin-Test-DistManifest@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Test-DistManifest@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org> and C<irc.libera.chat>.

=head1 AUTHORS

=over 4

=item *

Marcel Grünauer <marcel@cpan.org>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
