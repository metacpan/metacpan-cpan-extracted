package Regexp::Common::net::CIDR;

use strict;
use warnings;

our $VERSION = '0.03';

use Regexp::Common qw(pattern clean no_defaults);

my $ip_unit = "(?:25[0-5]|2[0-4][0-9]|[0-1]?[0-9]?[0-9])";

pattern name => [qw(net CIDR IPv4)],
    create => "(?k:$ip_unit\\.$ip_unit(?:\\.$ip_unit)?(?:\\.$ip_unit)?)\\/(?k:3[0-2]|[1-2]?[0-9])";

1;

__END__

=head1 NAME

Regexp::Common::net::CIDR -- provide patterns for CIDR blocks.

=head1 SYNOPSIS

    use Regexp::Common ();
    use Regexp::Common::net::CIDR ();

    while (<>) {
        /$RE{net}{CIDR}{IPv4}/ and print "Contains a CIDR.\n";
    }

=head1 DESCRIPTION

Patterns for CIDR blocks. Now only next IPv4 formats are supported:

  xxx.xxx/xx
  xxx.xxx.xxx/xx
  xxx.xxx.xxx.xxx/xx

With {-keep} stores address in $1 and number of bits in $2.

=head1 INSTALLATION

  perl Makefile.PL
  make
  make install

=head1 CAVEATS

As L<Regexp::Common> doesn't work well with extensions
named C<Regexp::Common::xxx::yyy> you have to load this extension
yourself with C<use> or C<require>.

=head1 AUTHOR

Ruslan U. Zakirov <ruz@bestpractical.com>

=cut

