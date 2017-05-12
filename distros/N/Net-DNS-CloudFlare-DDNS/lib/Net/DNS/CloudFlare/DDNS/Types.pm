package Net::DNS::CloudFlare::DDNS::Types;
# ABSTRACT: Types for Net::DNS::CloudFlare::DDNS

use Modern::Perl '2012';
use autodie      ':all';
no  indirect     'fatal';
use namespace::autoclean;

use Type::Library -base;
# Theres a bug about using undef as a hashref before this version
use Type::Utils 0.039_12 -all;

our $VERSION = 'v0.63.1'; # VERSION

class_type 'CloudFlare::Client';
class_type 'LWP::UserAgent';

1; # End of Net::DNS::CloudFlare::DDNS::Types

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DNS::CloudFlare::DDNS::Types - Types for Net::DNS::CloudFlare::DDNS

=head1 VERSION

version v0.63.1

=head1 SYNOPSIS

Provides types used in Net::DNS::CloudFlare::DDNS

    use Net::DNS::CloudFlare::DDNS::Types 'CloudFlareClient';

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Net::DNS::CloudFlare::DDNS|Net::DNS::CloudFlare::DDNS>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::DNS::CloudFlare::DDNS

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Net-DNS-CloudFlare-DDNS>

=back

=head2 Email

You can email the author of this module at C<me+dev@peter-r.co.uk> asking for help with any problems you have.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/pwr22/Net-DNS-CloudFlare-DDNS>

  git clone git://github.com/pwr22/Net-DNS-CloudFlare-DDNS.git

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/pwr22/Net-DNS-CloudFlare-DDNS/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Peter Roberts <me+dev@peter-r.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Peter Roberts.

This is free software, licensed under:

  The MIT (X11) License

=cut
