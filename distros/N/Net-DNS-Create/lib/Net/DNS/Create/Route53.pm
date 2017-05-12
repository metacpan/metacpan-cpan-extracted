#  Copyright (c) 2013-2014 David Caldwell,  All Rights Reserved.

package Net::DNS::Create::Route53;
use feature ':5.10';
use strict;
use warnings;

use Net::DNS::Create qw(internal full_host email interval);
use Net::Amazon::Route53;

our %config;
sub import {
    my $package = shift;
    my %c = @_;
    $config{$_} = $c{$_} for keys %c;
}

my $r53;
sub r53() {
    $r53 //= Net::Amazon::Route53->new(id  => $config{amazon_id},
                                       key => $config{amazon_key});
}

my $zones;
sub hosted_zone($) {
    # The eval works around a bug in Net::Amazon::Route53 where it dies if there are no zones at all.
    $zones = eval { [r53->get_hosted_zones()] } || []  unless defined $zones;
    (grep { $_->name eq $_[0] } @$zones)[0] // undef;
}

sub txt(@) {
    map { s/[^-a-zA-Z0-9._='():;* ]/$& eq '"' ? '\\"' : sprintf("\\%03o", ord($&))/ge;
        "\"$_\"" } @_;
}

sub group_by_type_and_name($$) {
    my ($re, $entries) = @_;
    my %set;
    for my $r (grep { lc($_->type) =~ $re } @$entries) {
        push @{$set{$r->type .'_'. $r->name}}, $r;
    }
    map { $set{$_} } keys %set;
}

my @domain;
sub _domain() { @domain } # Hook for testing
sub domain($$) {
    my ($package, $domain, $entries) = @_;

    my @entries = map { ;
                        my $rr = lc $_->type;

                        $rr eq 'soa' ? () : # Amazon manages its own SOA stuff. Just ignore things we might have.
                        $rr eq 'rp'  ? (warn("Amazon doesn't support RP records :-(") && ()) :

                        $rr eq 'a' || $rr eq 'mx' || $rr eq 'ns' || $rr eq 'srv' || $rr eq 'txt' ? () : # Handled specially, below

                        +{
                          action => 'create',
                          name   => $_->name.'.',
                          ttl    => $_->ttl,
                          type   => uc $rr,
                          $rr eq 'cname' ? (value => $_->cname.'.') :
                          (err => warn "Don't know how to handle \"$rr\" RRs yet.")

                         }
                    } @$entries;

    # Amazon wants all NS,MX,TXT and SRV entries for a particular name in one of their entries. We get them in as
    # separate entries so first we have to group them together.
    push @entries, map { my @set = @$_;
                         my $rr = lc $set[0]->type;
                         $rr eq 'ns' && $set[0]->name.'.' eq $domain ? () : # Amazon manages its own NS stuff. Just ignore things we might have.
                         +{
                           action => 'create',
                           name   => $set[0]->name.'.',
                           ttl    => $set[0]->ttl,
                           type   => uc $rr,
                           $rr eq 'a'     ? (records => [map { $_->address } @set]) :
                           $rr eq 'mx'    ? (records => [map { $_->preference." ".$_->exchange.'.' } @set]) :
                           $rr eq 'ns'    ? (records => [map { $_->nsdname.'.' } @set] ) :
                           $rr eq 'srv'   ? (records => [map { $_->priority ." ".$_->weight ." ".$_->port ." ".$_->target.'.' } @set]) :
                           $rr eq 'txt'   ? (records => [map { join ' ', txt($_->char_str_list) } @set]) :
                           (err => die uc($rr)." can't happen here!")
                          }
                       } group_by_type_and_name(qr/^(?:mx|ns|srv|txt|a)$/, $entries);

    push @domain, { name => $domain,
                    entries => \@entries };
}

my $counter = rand(1000);
sub master() {
    my ($package) = @_;
    local $|=1;

    for my $domain (@domain) {
        my $zone = hosted_zone(full_host($domain->{name}));
        if (!$zone && scalar @{$domain->{entries}}) {
            my $hostedzone = Net::Amazon::Route53::HostedZone->new(route53 => r53,
                                                                   name => $domain->{name},
                                                                   comment=>(getpwuid($<))[0].'/'.__PACKAGE__,
                                                                   callerreference=>__PACKAGE__."-".localtime."-".($counter++));
            print "New Zone: $domain->{name}...";
            $hostedzone->create();
            $zone = $hostedzone;
            print "Created. Nameservers:\n".join('', map { "  $_\n" } @{$zone->nameservers});
        }

        if ($zone) {
            my $current = [ grep { $_->type ne 'SOA' && ($_->type ne 'NS' || $_->name ne $domain->{name}) } @{$zone->resource_record_sets} ];
            my $new = [ map { Net::Amazon::Route53::ResourceRecordSet->new(%{$_},
                                                                           values => [$_->{value} // @{$_->{records}}],
                                                                           route53 => r53,
                                                                           hostedzone => $zone) } @{$domain->{entries}} ];
            printf "%s: %d -> %d\n", $domain->{name}, scalar @$current, scalar @$new;
            my $change = scalar @$current > 0 ? r53->atomic_update($current,$new) :
                         scalar @$new     > 0 ? r53->batch_create($new)           :
                                                undef;

            unless (scalar @{$domain->{entries}}) {
                print "Deleting $domain->{name}\n";
                $zone->delete;
            }
        }
    }
}

sub domain_list($@) {
    my $zone = hosted_zone(full_host($_[0]));
    printf "%-30s %-30s %s\n", $zone ? $zone->id : '', $_[0], !$zone ? '' : ' ['.join(" ",@{$zone->nameservers}).']';
}

sub master_list($$) {
    # This doesn't really make sense in the route53 context
}

1;
__END__

=head1 NAME

Net::DNS::Create::Route53 - Amazon AWS Route53 backend for Net::DNS::Create

=head1 SYNOPSIS

 use Net::DNS::Create qw(Route53), default_ttl => "1h",
                                   amazon_id => "AKIxxxxxxx",
                                   amazon_key => "kjdhakjsfnothisisntrealals";

 domain "example.com", { %records };

 master;

=head1 DESCRIPTION

You should never use B<Net::DNS::Create::Route53> directly. Instead pass "Route53"
to B<< L<Net::DNS::Create> >> in the "use" line.

=head1 OPTIONS

The following options are specific to B<Net::DNS::Create::Route53>:

=over 4

=item C<amazon_id>

The Amazon AWS user ID that is authorized to access Route53.

=item C<amazon_key>

The Amazon AWS user key that is authorized to access Route53.

=back

=head1 THE MASTER FUNCTION

There are no parameters to the C<master> function when using the Route53 back
end:

 master;

Calling C<master> will sync the zones' records to Route53, deleting and adding
zones and records as appropriate.

B<Net::DNS::Create::Route53> will never delete zones that have not been
referenced by calls to the C<domain> function. This means that if you want to
delete a zone you need to explicitly list it as empty:

 domain "example.com", undef;

Once it has been deleted you may remove it from the source code.

=head1 SEE ALSO

L<The Route53 Home Page|https://aws.amazon.com/route53/>

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
