use strict;
use warnings;
no warnings 'once';
package Net::Continental::Zone 0.017;
# ABSTRACT: a zone of IP space

use Locale::Codes::Country 3.29 ();
use Net::Domain::TLD ();

#pod =method new
#pod
#pod B<Achtung!>  There is no C<new> method for you to use.  Instead, do this:
#pod
#pod   my $zone = Net::Continental->zone('au');
#pod
#pod =cut

sub _new { bless $_[1] => $_[0] }

#pod =method code
#pod
#pod This returns the zone's zone code.
#pod
#pod =method in_nerddk
#pod
#pod This is true if the nerd.dk country blacklist is capable, using its encoding
#pod scheme, of indicating a hit from this country.
#pod
#pod =method nerd_response
#pod
#pod This returns the response that will be given by the nerd.dk country blacklist
#pod for IPs in this zone, if one is defined.
#pod
#pod =method continent
#pod
#pod This returns the continent in which the zone has been placed.  These are
#pod subject to change, for now, and there may be a method by which to define your
#pod own classifications.  I do not want to get angry email from people in Georgia!
#pod
#pod =method description
#pod
#pod This is a short description of the zone, like "United States" or "Soviet
#pod Union."
#pod
#pod =method is_tld
#pod
#pod This returns true if the zone code is also a country code TLD.
#pod
#pod =cut

sub code          { $_[0][0] }

sub in_nerddk     {
  return defined $_[0]->nerd_response;
}

sub nerd_response {
  my ($self) = @_;

  my $n = Locale::Codes::Country::country_code2code(
    $self->code,
    'alpha-2',
    'numeric',
  );

  return unless $n;
  my $top = $n >> 8;
  my $bot = $n % 256;
  return "127.0.$top.$bot";
}

sub continent     { $Net::Continental::Continent{ $_[0][1] } }
sub description   { $_[0][2] }
sub is_tld        { Net::Domain::TLD::tld_exists($_[0][0], 'cc'); }

sub tld           {
  return $_[0][3] if Net::Domain::TLD::tld_exists($_[0][3], 'cc');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Continental::Zone - a zone of IP space

=head1 VERSION

version 0.017

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

B<Achtung!>  There is no C<new> method for you to use.  Instead, do this:

  my $zone = Net::Continental->zone('au');

=head2 code

This returns the zone's zone code.

=head2 in_nerddk

This is true if the nerd.dk country blacklist is capable, using its encoding
scheme, of indicating a hit from this country.

=head2 nerd_response

This returns the response that will be given by the nerd.dk country blacklist
for IPs in this zone, if one is defined.

=head2 continent

This returns the continent in which the zone has been placed.  These are
subject to change, for now, and there may be a method by which to define your
own classifications.  I do not want to get angry email from people in Georgia!

=head2 description

This is a short description of the zone, like "United States" or "Soviet
Union."

=head2 is_tld

This returns true if the zone code is also a country code TLD.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
