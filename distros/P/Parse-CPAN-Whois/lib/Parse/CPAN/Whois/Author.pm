# vim: sts=3 sw=3 et
package Parse::CPAN::Whois::Author;
use strict;
use warnings;

our $VERSION='0.01';

=head1 NAME

Parse::CPAN::Whois::Author

=head1 METHODS

=head2 email

=cut

sub email {
   return $_[0]->{email};
}

=head2 name

=cut

sub name {
   return $_[0]->{fullname};
}

=head2 pauseid

=cut

sub pauseid {
   return $_[0]->{id};
}

=head2 asciiname

name transliterated to ASCII

=cut

sub asciiname {
   return $_[0]->{asciiname};
}

=head2 homepage

=cut

sub homepage {
   return $_[0]->{homepage};
}

1;
