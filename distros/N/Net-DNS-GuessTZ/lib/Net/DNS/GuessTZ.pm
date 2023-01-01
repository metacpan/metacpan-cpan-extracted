use strict;
use warnings;
package Net::DNS::GuessTZ 0.005;
# ABSTRACT: guess the time zone of a host

#pod =head1 SYNOPSIS
#pod
#pod   use Net::DNS::GuessTZ qw(tz_from_host);
#pod
#pod   my $tz = tz_from_host('cr.yp.to');
#pod
#pod =head1 DESCRIPTION
#pod
#pod Brazenly stolen from L<Plagger::Plugin::Filter::GuessTimeZoneByDomain>, this
#pod module makes an effort to guess an appropriate time zone for a given host.  It
#pod will look up the location of the IP addresses owner and it will also consider
#pod the country code top-level domain, if the host is under one.
#pod
#pod =head1 CAVEATS
#pod
#pod This is fine if you don't really care too much about being correct.  It's
#pod probably better than just always assuming local time.
#pod
#pod Still, if possible, ask the user for his time zone when you can!
#pod
#pod =cut

use DateTime::TimeZone 0.51;
use List::Util ();

use Sub::Exporter::Util;
use Sub::Exporter -setup => {
  exports => [ tz_from_host => Sub::Exporter::Util::curry_method ],
};

my $ICF;
sub _icf {
  $ICF ||= do {
    require IP::Country::Fast;
    IP::Country::Fast->new;
  };
}

sub _all_tz_from_cctld {
  my ($self, $host) = @_;
  return unless my ($cctld) = $host =~ /\.(\w{2})\z/;
  DateTime::TimeZone->names_in_country($cctld);
}

sub _all_tz_from_ip {
  my ($self, $host) = @_;
  return unless my $cc = $self->_icf->inet_atocc($host);
  my @names = DateTime::TimeZone->names_in_country($cc);
}

#pod =method tz_from_host
#pod
#pod   my $tz_name = Net::DNS::GuessTZ->tz_from_host($hostname, %arg);
#pod
#pod This routine returns a guess at the given host's time zone, or false if no
#pod guess can be made.
#pod
#pod Valid arguments are:
#pod
#pod   priority   - which method to give priority to: "cc" or "ip"; default: ip
#pod   ip_country - whether to check the IP address's owner with IP::Country;
#pod                defaults to true
#pod
#pod Unlike the Plagger plugin, this routine will gladly make a guess when the
#pod country it finds has more than three time zones.
#pod
#pod =cut

sub tz_from_host {
  my ($self, $host, $arg) = @_;
  return unless $host;
  $arg ||= {};
  $arg->{ip_country} = 1 unless exists $arg->{ip_country};

  my %result;

  my @names = $self->_all_tz_from_cctld($host);
  $result{cc} = $names[0] if @names; # and @names <= 3;

  if ($arg->{ip_country}) {
    my @names = $self->_all_tz_from_ip($host);
    $result{ip} = $names[0] if @names; # if @names <= 3;
  }

  my @cand = ($arg->{priority}||'ip') eq 'cc'
           ? @result{qw(cc ip)}
           : @result{qw(ip cc)};

  if (my $tz = List::Util::first { defined } @cand) {
    return $tz;
  } else {
    return;
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DNS::GuessTZ - guess the time zone of a host

=head1 VERSION

version 0.005

=head1 SYNOPSIS

  use Net::DNS::GuessTZ qw(tz_from_host);

  my $tz = tz_from_host('cr.yp.to');

=head1 DESCRIPTION

Brazenly stolen from L<Plagger::Plugin::Filter::GuessTimeZoneByDomain>, this
module makes an effort to guess an appropriate time zone for a given host.  It
will look up the location of the IP addresses owner and it will also consider
the country code top-level domain, if the host is under one.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 tz_from_host

  my $tz_name = Net::DNS::GuessTZ->tz_from_host($hostname, %arg);

This routine returns a guess at the given host's time zone, or false if no
guess can be made.

Valid arguments are:

  priority   - which method to give priority to: "cc" or "ip"; default: ip
  ip_country - whether to check the IP address's owner with IP::Country;
               defaults to true

Unlike the Plagger plugin, this routine will gladly make a guess when the
country it finds has more than three time zones.

=head1 CAVEATS

This is fine if you don't really care too much about being correct.  It's
probably better than just always assuming local time.

Still, if possible, ask the user for his time zone when you can!

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTOR

=for stopwords Ricardo Signes

Ricardo Signes <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
