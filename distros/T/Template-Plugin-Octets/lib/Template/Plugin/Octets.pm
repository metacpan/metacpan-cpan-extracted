package Template::Plugin::Octets;

# ABSTRACT: TT2 plugin to format numeric values as binary octets

use 5.008009;
use strict;
use warnings;
use base 'Template::Plugin::Procedural';

our $VERSION = '0.18'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

use constant KIBIO_DIV => 1024;            # 1 KBio
use constant MIBIO_DIV => 1024*1024;       # 1 MBio
use constant GIBIO_DIV => 1024*1024*1024;  # 1 GBio

#
# kibioctets
sub kio { _formatter(KIBIO_DIV, $_[0]) }

#
# mebioctets
sub mio { _formatter(MIBIO_DIV, $_[0]) }

#
# gibioctets
sub gio { _formatter(GIBIO_DIV, $_[0]) }

#
# Format octets
sub _formatter {
    my ($divider, $value) = @_;

    $value = 0 if $value eq '' or !defined $value;

    $value = sprintf '%.1f', $value/$divider;

    return '~0' if $value eq '0.0';
    return $value;
}

1; # End of Template::Plugin::Octets

__END__

=pod

=head1 NAME

Template::Plugin::Octets - TT2 plugin to format numeric values as binary octets

=head1 VERSION

version 0.18

=head1 SYNOPSIS

    [% USE Octets %]

    Xmit [% Octets.kio(100500) -%] Kio
    Recv [% Octets.mio(9000) -%] Mio

    # Output:
    # Xmit 98.1 Kio
    # Recv ~0 Mio

=head1 DESCRIPTION

Template::Plugin::Octets is a plugin for Template Toolkit v2, which allows you to format numbers in templates.
Try to run

    tpage eg/traffic.tt

to see it in action.

=head1 METHODS

=head2 kio

Format value as kibioctets (2^10 octets).

=head2 mio

Format value as mebioctets (2^20 octets).

=head2 gio

Format value as gibioctets (2^30 octets).

=head1 SEE ALSO

L<Template>

L<Template::Plugin::Procedural>

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
