#!/usr/local/bin/perl
# =============================================================================
# cksimple.pl - Check system information of hosts
# -----------------------------------------------------------------------------
$main::VERSION = '1.04';
# -----------------------------------------------------------------------------

=head1 NAME

cksimple.pl - Check system information of hosts

=head1 SYNOPSIS

    $ simpchk.pl [-v VERSION] [-c COMMUNITY_NAME]
        [-r RETRIES] [-t TIMEOUT] HOST [,HOST ...]

    VERSION        ... SNMP version; 1, 2, 2c or 3. Default is 2.
    COMMUNITY_NAME ... SNMP Community Name. Omitting uses 'public'.
    RETRIES        ... Retrying number. Default is 1.
    TIMEOUT        ... Timeout seconds. Default is 2(sec).
    HOST           ... Target hosts to check.

=head1 DESCRIPTION

This program get some system entry MIB values from several hosts with C<snmpget()>.

=head1 NOTE

This script is a sample of C<Net::SNMP::Util>.

=cut


use strict;
use warnings;
use Getopt::Std;
use Net::SNMP::Util qw(:para);

my %opt;
getopts('hv:c:r:t:', \%opt);

sub HELP_MESSAGE {
    print "Usage: $0 [-v VERSION] [-c COMMUNITY_NAME] ".
          "[-r RETRIES] [-t TIMEOUT] HOST [,HOST2 ...]\n";
    exit 1;
}
HELP_MESSAGE() if ( !@ARGV || $opt{h} );

(my $version = ($opt{v}||2)) =~ tr/1-3//cd; # now "2c" is ok
my ($ret, $err) = snmpparaget(
    hosts => \@ARGV,
    snmp  => { -version   => $version,
               -timeout   => $opt{t} || 2,
               -retries   => $opt{r} || 1,
               -community => $opt{c} || "public" },
    oids  => { descr    => '1.3.6.1.2.1.1.1.0',
               uptime   => '1.3.6.1.2.1.1.3.0',
               name     => '1.3.6.1.2.1.1.5.0',
               location => '1.3.6.1.2.1.1.6.0',
    }
);
die "[ERROR] $err\n" unless defined $ret;

foreach my $h ( @ARGV ){
    if ( $ret->{$h} ){
        printf "%s @%s (up %s) - %s\n",
             map { $ret->{$h}{$_} or 'N/A' } qw(name location uptime descr);
    } else {
        my $ehash = get_errhash();
        printf "%s [ERROR]%s\n", $h, $ehash->{$h} || '';
    }
}

__END__


=head1 REQUIREMENTS

C<Net::SNMP>, C<Net::SNMP::Util>

=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>

=head1 SEE ALSO

L<Net::SNMP> - Core module of C<Net::SNMP::Util> which brings us good SNMP
implementations.
L<Net::SNMP::Util::OID> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat OID.
L<Net::SNMP::Util::TC> - Sub module of C<Net::SNMP::Util> which provides
easy and simple functions to treat textual conversion.

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2011- Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
