#  Copyright (c) 2011-2014 David Caldwell,  All Rights Reserved.

package Net::DNS::Create;
use strict; use warnings;

our $VERSION='1.0.0';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(domain master soa);
our @EXPORT_OK = qw(domain master full_host local_host email interval);

my $kind;
our %config = (default_ttl=>'1h');
sub import {
    use Data::Dumper;
    my $package = shift;
    my $import_kind = shift // 'bind';

    # Tricky junk: If the first thing in our import list is "internal" then we just pass the rest to
    # Exporter::export_to_level so that our plugins can include us back and import the full_host, email, and
    # interval utility functions. Otherwise we pass the rest of the import args to the plugin's import so that
    # conf options pass all the way down. In that case we don't pass anything to Exporter::export_to_level so
    # that default export happens.
    if ($import_kind ne 'internal') {
        $kind = __PACKAGE__ . "::" . $import_kind;
        eval "require $kind"; die "$@" if $@;
        $kind->import(@_);
        %config = (%config, @_); # Keep around the config for ourselves so we get the default_ttl setting.
        @_ = ();
    }
    __PACKAGE__->export_to_level(1, $package, @_);
}

sub full_host($;$);
sub full_host($;$) {
    my ($name,$domain) = @_;
    $name eq '@' ? (defined $domain ? full_host($domain) : die "Need a domain with @") :
    $name =~ /\.$/ ? $name : "$name." . (defined $domain ? full_host($domain) : '')
}

sub local_host($$) {
    my ($fq,$domain) = (full_host(shift), full_host(shift));
    return '@' if $fq eq $domain;
    my $local = $fq;
    return $local if substr($local, -length($domain)-1, length($domain)+1, '') eq ".$domain";
    return $fq;
}

sub email($) {
    my ($email) = @_;
    $email =~ s/@/./g;
    full_host($email);
}

sub interval($) {
    $_[0] =~ /(\d+)([hmsdw])/ && $1 * { s=>1, m=>60, h=>3600, d=>3600*24, w=>3600*24*7 }->{$2} || $_[0];
}

sub escape($) {
    my $s = shift;
    # Net::DNS::RR::TXT interpolates \xxx style octally encoded escapes. We don't want this so we escape the \s
    $s =~ s/\\/\\\\/g;
    $s;
}

sub txt($) {
    my ($t) = @_;
    return escape($t) if length $t < 255;
    my @part;
    push @part, escape($1) while ($t =~ s/^(.{255})//);
    (@part, $t);
}


sub arrayize($) { # [1,2,3,4] -> (1,2,3,4), 1 -> (1)
    (ref $_[0] eq 'ARRAY' ? @{$_[0]} : $_[0])
}
sub arrayize2($) { # [[1,2],[3,4]] -> ([1,2],[3,4]), [1,2] -> ([1,2])
    (ref $_[0] eq 'ARRAY' && ref $_[0]->[0] eq 'ARRAY' ? @{$_[0]} : $_[0])
}

use Hash::Merge::Simple qw(merge);
use Net::DNS::RR;
sub domain($@) {
    my ($domain, @entry_hashes) = @_;
    my $entries = {};
    for my $e (@entry_hashes) {
        $entries = merge($entries, $e);
    }

    my $fq_domain = full_host($domain);
    my $ttl = interval($config{default_ttl});
    $entries = [ map { my $node = $_;
                          my $fqdn = full_host($_,$domain);
                          map {
                              my $rr = lc $_;
                              my $val = $entries->{$node}->{$_};
                              my %common = (name => $fqdn,
                                            ttl => $ttl,
                                            type => uc $rr);
                              $rr eq 'cname' || $rr eq 'soa' ?
                                  Net::DNS::RR->new(%common,
                                                    $rr eq 'cname' ? (cname         => full_host($val, $fq_domain)) :
                                                    $rr eq 'soa'   ? (mname         => full_host($val->{primary_ns}, $domain),
                                                                      rname         => $val->{rp_email},
                                                                      serial        => $val->{serial} // 0,
                                                                      refresh       => interval($val->{refresh}),
                                                                      retry         => interval($val->{retry}),
                                                                      expire        => interval($val->{expire}),
                                                                      minimum       => interval($val->{min_ttl})) :
                                                    die "can't happen") :

                              $rr eq 'a'   ? map { Net::DNS::RR->new(%common, address       => $_)} sort(arrayize($val)) :

                              $rr eq 'rp'  ? map { Net::DNS::RR->new(%common, mbox          => email($_->[0]),
                                                                              txtdname      => full_host($_->[1], $fq_domain)) } sort(arrayize2($val)) :

                              $rr eq 'txt' ? map { Net::DNS::RR->new(%common, char_str_list => [txt($_)]) } sort {$a cmp $b} arrayize($val) :
                              $rr eq 'mx'  ? map { Net::DNS::RR->new(%common, preference => $_, exchange => full_host($val->{$_}, $fq_domain)) } sort(keys %$val) :
                              $rr eq 'ns'  ? map { Net::DNS::RR->new(%common, nsdname => $_) } sort(arrayize($val)) :
                              $rr eq 'srv' ? map {
                                                my $target = $_;
                                                map {
                                                    Net::DNS::RR->new(%common,
                                                                      priority => $_->{priority} // 0,
                                                                      weight   => $_->{weight}   // 0,
                                                                      port     => $_->{port},
                                                                      target   => full_host($target))
                                                  } sort {$a cmp $b} (ref $val->{$_} eq 'ARRAY' ? @{$val->{$_}} : $val->{$_})
                                              } sort(keys %$val) :
                                 die uc($rr)." is not supported yet :-("; # Remember to add support for all the backends, too.
                          } keys %{$entries->{$node}};
                      } keys %$entries ];

    $kind->domain($fq_domain, $entries);
}

sub master {
    $kind->master(@_);
}

sub list_files() {
    no warnings;
    *domain = *main::domain = \&{"$kind\::domain_list"};
    *master = *main::master = \&{"$kind\::master_list"};
}

sub list_domains() {
    no warnings;
    *domain = *main::domain = sub { print "$_[0]\n" };
    *master = *main::master = sub {};
}


1;
__END__

=head1 NAME

Net::DNS::Create - Create DNS configurations from a nice Perl structure based DSL.

=head1 SYNOPSIS

 use Net::DNS::Create qw(Bind),    default_ttl => "1h",
                                   conf_prefix => "local_",
                                   dest_dir    => "./bind";
 # or
 use Net::DNS::Create qw(Tiny),    default_ttl => "1h";
 # or
 use Net::DNS::Create qw(Route53), default_ttl => "1h",
                                   amazon_id   => "AKIxxxxxxx",
                                   amazon_key  => "kjdhakjsfnothisisntrealals";


 # Then, for each domain you have:
 domain "example.com", { %records };      # The simplest way.
 domain "example.net", { %records },      # Records in %more_records override
                       { %more_records }; # the ones in %record

 # Then,
 master "master.conf", "/etc/bind/"; # Bind (which requires absolute paths)
 # or
 master "data";                      # Tiny
 # or
 master;                             # Route53


 # The different records Types:
 domain "example.com", {
   'www' => { a => '127.0.0.1' },            # names are non-qualified
   'www1' => { a => ['127.0.0.2',
                     '127.0.0.3'] },         # Use an array for multiple As

   'www2' => { cname => 'www' },             # no trailing dot for local names
   'www2' => { cname => '@' },               # @ is supported
   'www3' => { cname => 'a.example.net.' },  # trailing-dot for external names

   '@' => { soa => { primary_ns => 'ns1.example.com.',
                     rp_email   => 'some-email@example.com',
                     serial     => 1234, # Set this to zero for auto-serial
                     refresh    => '8h',
                     retry      => '2h',
                     expire     => '4w',
                     min_ttl    => '1h' } },

   'a' => { ns => 'ns1.example.com.' },
   'b' => { ns => ['ns1', 'ns2'] },           # use an array for multiple NSes

   'c' => { mx => { 0  => 'mail',
                    10 => 'smtp' } },

   'd' => { txt => "v=spf1 mx -all" },
   'e' => { txt => ["v=spf1 mx -all",         # use an array for multiple TXTs
                    "another different text record" ] },

   '_carddavs._tcp' => { srv => { "www"  => { port => 443 },
                                              # priority & weight default to 0
                                  "www2" => { port => 443,
                                              priority => 2,
                                              weight   => 3 }, } },

   'server' => { rp => ['david@example.com', david.people] },

   'server2' => { rp => [['david@example.com', david.people] # use an array for
                         ['bob@example.com', bob.people]] }, # multiple RPs
 };

 # Multiple record types for a name
 domain "example.com", {
    '@' => { soa => { ... },
             ns  => ['ns1', 'ns2'],
             mx  => { 0  => 'mail',
                      10 => 'smtp' },
             txt => "v=spf1 mx -all",
             a   => '127.0.0.1' },
 };

 # Overriding specific records
 my %standard = ('@' => { soa => { ... },
                          ns  => ['ns1', 'ns2'],
                          mx  => { 0  => 'mail',
                                   10 => 'smtp' },
                          txt => "v=spf1 mx -all",
                          a   => '127.0.0.1' });

 domain "example.com", { %standard }, {
   '@' => { a => '127.0.0.2' },  # 'A' record overridden, others remain intact.
 };

=head1 DESCRIPTION

B<Net::DNS::Create> lets you specify your DNS configuration in a Perl script so
that all the duplication that normally occurs in DNS config files can be
expressed with variables and functions. This ultimately results in a (hopefully)
DRY (Don't Repeat Yourself) representation of your DNS config data, making it
easier and less error prone to change.

B<Net::DNS::Create> supports multiple backends which means you can change out
your DNS server software with minimal effort.

=head1 TIME INTERVALS

The C<default_ttl> option and the SOA record's C<refresh> C<retry>, C<expire>,
and C<min_ttl> parameters all take time intervals. They can be conveniently
specified using units:

 s -> seconds
 m -> minutes
 h -> hours
 d -> days
 w -> weeks

This way you can say "I<1h>" instead of "I<3600>" and "I<2w>" instead of
"I<1209600>".

=head1 OPTIONS

Options to the backends are specified in the use line. For instance:

 use Net::DNS::Create qw(Bind), default_ttl => "1h", conf_prefix => "local_", dest_dir => "./bind";

The following options are generic to all the backends:

=over 4

=item C<default_ttl>

This lets you set the default TTL for the entries. Currently there is no way to
set TTLs for individual records.

The default value is "I<1h>".

=back

See a backend's documentation for the descriptions of the backend's specific
options.

=head1 SEE ALSO

L<Net::DNS::Create::Bind>

L<Net::DNS::Create::Tiny>

L<Net::DNS::Create::Route53>

L<The Net::DNS::Create Home Page|https://github.com/caldwell/net-dns-create>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
