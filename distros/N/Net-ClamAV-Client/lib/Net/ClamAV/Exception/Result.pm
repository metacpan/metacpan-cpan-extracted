use strict;
package Net::ClamAV::Exception::Result;
# ABSTRACT: Exception class for result exceptions
$Net::ClamAV::Exception::Result::VERSION = '0.1';
use warnings;

use Moose;
with 'Throwable';
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::ClamAV::Exception::Result - Exception class for result exceptions

=head1 VERSION

version 0.1

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Net::ClamAV::Client/>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Dominik Meyer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
