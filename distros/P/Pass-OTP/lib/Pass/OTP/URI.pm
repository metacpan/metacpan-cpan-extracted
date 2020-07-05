package Pass::OTP::URI;

=encoding utf8

=head1 NAME

Pass::OTP::URI - Parse otpauth:// URI

=head1 SYNOPSIS

    use Pass::OTP::URI qw(parse);

    my $uri = "otpauth://totp/ACME:john.doe@email.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ&issuer=ACME&digits=6";
    my %options = parse($uri);

=cut

use utf8;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(parse);

=head1 FUNCTIONS

=over 4

=item parse($uri)

=cut

sub parse {
    my ($uri) = @_;

    my %options = (
        base32 => 1,
    );
    ($options{type}, $options{label}, my $params) = $uri =~ m#^otpauth://([th]otp)/((?:[^:?]+(?::|%3A))?[^:?]+)\?(.*)#;

    foreach my $param (split(/&/, $params)) {
        my ($option, $value) = split(/=/, $param);
        $options{$option} = $value;
    }

    return (%options);
}

=back

=head1 SEE ALSO

L<Pass::OTP>

L<https://github.com/google/google-authenticator/wiki/Key-Uri-Format>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020 Jan Baier

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
