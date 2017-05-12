package Net::OpenSSH::Compat;

our $VERSION = '0.09';

use strict;
use warnings;
use Carp;

my %impl = ('Net::SSH2'      => 'SSH2',
            'Net::SSH::Perl' => 'Perl',
            'Net::SSH'       => 'SSH');

sub import {
    my $class = shift;
    for my $mod (@_) {
        my $impl = $impl{$mod};
        defined $impl or croak "$mod compatibility is not available";
        my $adapter = __PACKAGE__ . "::$impl";
        eval "use $adapter ':supplant';";
        die if $@;
    }
    1;
}

1;
__END__

=head1 NAME

Net::OpenSSH::Compat - Compatibility modules for Net::OpenSSH

=head1 SYNOPSIS

  use Net::OpenSSH::Compat 'Net::SSH2';
  use Net::OpenSSH::Compat 'Net::SSH::Perl';

=head1 DESCRIPTION

This package contains a set of adapter modules that run on top of
Net::OpenSSH providing the APIs of other SSH modules available from
CPAN.

Currently, there are adapters available for L<Net::SSH2> and
L<Net::SSH::Perl>. Adapters for L<Net::SSH> and L<Net::SFTP> are
planned... maybe also for L<Net::SCP> and L<Net::SCP::Expect> if
somebody request them.

=head1 BUGS AND SUPPORT

B<This is a work in progress.>

If you find any bug fill a report at the CPAN RT bugtracker
(L<https://rt.cpan.org/Ticket/Create.html?Queue=Net-OpenSSH-Compat>)
or just send me an e-mail with the details.

=head2 Git repository

The source code repository is at
L<https://github.com/salva/p5-Net-OpenSSH-Compat>.

=head2 My wishlist

If you like this module and you're feeling generous, take a look at my
Amazon Wish List: L<http://amzn.com/w/1WU1P6IR5QZ42>

Also consider contributing to the OpenSSH project this module builds
upon: L<http://www.openssh.org/donations.html>.

=head1 SEE ALSO

L<Net::OpenSSH>, L<Net::OpenSSH::Compat::SSH2>,
L<Net::OpenSSH::Compat::Perl>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2014-2016 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
