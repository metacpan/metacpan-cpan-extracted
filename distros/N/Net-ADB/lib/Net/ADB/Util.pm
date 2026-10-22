package Net::ADB::Util;

use strict;
use warnings;
use utf8;
use v5.16;

use Carp ();
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(wantlist croak_unknown_params shell_quote);
our @CARP_NOT  = qw(Net::ADB Net::ADB::Device);

# Must be called as the expression of a "return": the caller's context is
# passed through (return wantlist(\@list), not my $x = wantlist(...))
sub wantlist { wantarray ? @{$_[0]} : $_[0] }

sub croak_unknown_params {
    my $params = shift;
    Carp::croak('Unknown parameters: ' . join ', ', sort keys %{$params}) if %{$params};
    return;
}

sub shell_quote {
    my $string = shift;
    $string =~ s/'/'\\''/g;
    return "'$string'";
}

1;

__END__

=encoding utf-8

=head1 NAME

Net::ADB::Util - Internal utility functions for Net::ADB

=head1 SYNOPSIS

    use Net::ADB::Util qw(wantlist croak_unknown_params shell_quote);

=head1 DESCRIPTION

Internal utility functions used by L<Net::ADB> and L<Net::ADB::Device>.

B<NOTE>: This module is not part of the public API: the functions may change
or be removed without notice.

No function is exported by default.


=head1 FUNCTIONS

=head2 wantlist

    return wantlist(\@list);

Return the list in list context, or the array reference in scalar context.

It must be called as the expression of C<return>, so that it receives the
context of the caller.

=head2 croak_unknown_params

    croak_unknown_params(\%params);

Croak with the names of the parameters left in the hash (C<Unknown parameters: ...>).

=head2 shell_quote

    my $command = 'cat -- ' . shell_quote($file);

Quote a string for the device shell, with single quotes.


=head1 SEE ALSO

=over

=item * L<Net::ADB>

=item * L<Net::ADB::Device>

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-ADB/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-ADB>

    git clone https://github.com/giterlizzi/perl-Net-ADB.git


=head1 AUTHOR

=over

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Giuseppe Di Terlizzi.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
