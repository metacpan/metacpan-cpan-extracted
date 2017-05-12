#  Copyright (c) 2009-2014 David Caldwell,  All Rights Reserved.

package Net::DNS::Create::Tiny;
use feature ':5.10';
use strict;
use warnings;

use Net::DNS::Create qw(internal full_host email interval);
use File::Slurp qw(write_file);

our %config;
sub import {
    my $package = shift;
    my %c = @_;
    $config{$_} = $c{$_} for keys %c;
}

sub tiny_escape($) {
    my ($f) = @_;
    $f =~ s/(:|\\|[^ -~])/sprintf "\\%03o", ord($1)/eg;
    $f
}

sub domainname_encode($;$) {
    my ($node, $domain) = @_;
    $node = full_host($node, $domain);
    join('', map { chr(length $_).$_ } split /\./, $node, -1);
}

sub C(@) { # "Colon"
    join(':', @_)
}

my @domain;
sub domain($$) {
    my ($package, $domain, $entries) = @_;

    my @conf = map { ;
                     my $rr = lc $_->type;
                     my $fqdn = $_->name . '.';

                     $rr eq 'a'     ? '='.C($fqdn,$_->address,$_->ttl) :
                     $rr eq 'cname' ? 'C'.C($fqdn,$_->cname.'.',$_->ttl) :
                     $rr eq 'rp'    ? ':'.C($fqdn,17,tiny_escape(domainname_encode(email($_->mbox)).domainname_encode($_->txtdname)),$_->ttl) :
                     $rr eq 'mx'    ? '@'.C($fqdn,'',$_->exchange.'.',$_->preference,'',$_->ttl) :
                     $rr eq 'ns'    ? '&'.C($fqdn,'',$_->nsdname.'.',$_->ttl) :
                     $rr eq 'txt'   ? "'".C($fqdn,tiny_escape(join('',$_->char_str_list)),$_->ttl) :
                     $rr eq 'soa'   ? 'Z'.C($fqdn,
                                            $_->mname.'.',
                                            email($_->rname),
                                            $_->serial || '',
                                            $_->refresh, $_->retry, $_->expire, $_->minimum, $_->ttl) :
                     $rr eq 'srv'   ? ':'.C($fqdn,33,tiny_escape(pack("nnn", $_->priority, $_->weight, $_->port)
                                                                 .domainname_encode($_->target)),$_->ttl) :
                        die "Don't know how to handle \"$rr\" RRs yet.";

                   } @$entries;

    push @domain, "# $domain\n" .
                  "#\n" .
                  join('', map { "$_\n" } @conf) .
                  "\n";
}

sub master {
    my ($package, $filename) = @_;
    write_file($filename, @domain);
}

sub domain_list($@) {
    # There are no separate zone files in a tiny setup.
}

sub master_list($$) {
    print "$_[0]\n"
}

1;
__END__

=head1 NAME

Net::DNS::Create::Bind - TinyDNS (djbdns) backend for Net::DNS::Create

=head1 SYNOPSIS

 use Net::DNS::Create qw(Tiny), default_ttl => "1h";

 domain "example.com", { %records };

 master "data";

=head1 DESCRIPTION

You should never use B<Net::DNS::Create::Tiny> directly. Instead pass "Tiny" to
B<< L<Net::DNS::Create> >> in the "use" line.

=head1 OPTIONS

B<Net::DNS::Create::Tiny> has no specific options.

=head1 MASTER PARAMETERS

 master "filename";

=over 4

=item C<filename>

The file name for the configuration data. Most likely, 'I<data>'.

=back

=head1 SEE ALSO

L<The TinyDNS (djbdns) Home Page|http://cr.yp.to/djbdns.html>

L<Net::DNS::Create>

L<The Net::DNS::Create Home Page|https://github.com/caldwell/net-dns-create>

=head1 AUTHOR

David Caldwell E<lt>david@porkrind.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2014 by David Caldwell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
