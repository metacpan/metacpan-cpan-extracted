package Provision::Unix::DNS;
# ABSTRACT: generic class for common DNS tasks
$Provision::Unix::DNS::VERSION = '1.08';
use strict;
use warnings;

use English qw( -no_match_vars );
use Params::Validate qw(:all);

use lib 'lib';
use Provision::Unix::Utility;
my $util;

sub new {
    my $class = shift;
    my %p     = validate(
        @_,
        {   prov  => { type => OBJECT },
            debug => { type => BOOLEAN, optional => 1, default => 1 },
            fatal => { type => BOOLEAN, optional => 1, default => 1 },
        }
    );

    my $self = {
        prov  => $p{prov},
        debug => $p{debug},
        fatal => $p{fatal},
    };
    bless( $self, $class );

    $util = Provision::Unix::Utility->new( log => $p{prov}, debug=>$p{debug},fatal=>$p{fatal} );
    $self->{server} = $self->_get_server() or return;
    $self->{prov}->audit("loaded DNS");

    return $self;
}

sub connect {
    my $self = shift;
    my %args = @_;
    foreach ( keys %args ) { delete $args{$_} if ! defined $args{$_}; };
    $self->{server}->connect(%args);
}

sub create_zone {

    ############################################
    # Usage      : $dns->create_zone({ zone=>'example.com' });
    # Purpose    : Create a new zone
    # Returns    : failure: undef
    #            : success: zone_id for nictool, 1 for others methods
    # Parameters
    #   Required : S - zone       - the fully qualified zone name
    #   Optional : S - contact    - the email address of the hostmaster
    #            : I - ttl, refresh, retry, expire, minimum
    #            : S - template   - the name of a template to use
    #            : S - ip         - an IP address for the template
    #            : S - mailip     - an IP address for the zones MX
    # Throws     : no exceptions

    my $self = shift;
    my %args = @_;
    foreach ( keys %args ) { delete $args{$_} if ! defined $args{$_}; };
    $self->{server}->create_zone(%args);
}

sub create_zone_record {

    ############################################
    # Usage      : $dns->create_zone_record();
    # Purpose    : Create a new zone record
    # Returns    : failure: undef, success: 1
    # Parameters
    #   Required : S - zone       - the fully qualified zone name
    #            : S - name       - the zone record name
    #            : S - type       - A, MX, CNAME, NS, SRV, TXT
    #            : S - address    - an IP address
    #            : S - port       - SRV records only
    #            : S - priority   - SRV records only
    #   Optional : S - ttl        - TTL
    #            : S - zone_id    - zone id
    #            : S - weight (mx & srv records only)

    my $self = shift;
    $self->{server}->create_zone_record(@_);
}

sub get_zone {

    ############################################
    # Usage      : $dns->get_zone( zone=>'example.com');
    # Purpose    : Find a zone
    # Returns    : depends on $dns backend
    # Parameters
    #   Required : S - zone   - the fully qualified zone name

    my $self = shift;
    return $self->{server}->get_zone(@_);
}

sub modify_zone {
}

sub delete_zone {

    my $self = shift;
    return $self->{server}->delete_zone(@_);
}

sub delete_zone_record {

    my $self = shift;
    return $self->{server}->delete_zone_record(@_);
}

sub qualify {

 # this is server dependent. BIND and NicTool support shortcuts like @. Others
 # need to be fully qualified (like tinydns).

    my $self = shift;
    return $self->{server}->qualify(@_);
}

sub _get_server {

    my $self = shift;
    my $prov = $self->{prov};
    my $debug = $self->{debug};
    my $fatal = $self->{fatal};

    my $chosen_server = $prov->{config}{DNS}{server}
        or $prov->error( 'missing [DNS] server setting in provision.conf',
            fatal  => $fatal,
            debug  => $debug,
        );

    # try to autodetect the server
    if ( ! $chosen_server ) {
        if ( $util->find_bin( 'tinydns', debug=>0,fatal => 0 ) ) {
            $chosen_server = 'tinydns';
        }
        elsif ( $util->find_bin( 'named', debug=>0,fatal => 0) ) {
            $chosen_server = 'bind';
        };
    };

    if ( ! $chosen_server ) {
        return $prov->error( "No DNS server selected and I could not find one installed. Giving up.",
            fatal  => $fatal,
            debug  => $debug,
        );
    };

    if ( $chosen_server eq 'nictool' ) {
        eval { require Provision::Unix::DNS::NicTool; };
        if ($EVAL_ERROR) {
            return $prov->error ( $EVAL_ERROR, fatal => $fatal, debug => $debug );
        };
        my $r = Provision::Unix::DNS::NicTool->new( 
            prov => $prov, 
            fatal => $fatal, 
            debug => $debug,
        );
#warn Data::Dumper::Dumper($r);
        if ( ! $r ) {
            return $prov->error( $prov->get_last_error(),
                debug => $debug,
                fatal => $fatal,
            );    
        }
        return $r;
    }
    elsif ( $chosen_server eq 'tinydns' ) {
        require Provision::Unix::DNS::tinydns;
        return Provision::Unix::DNS::tinydns->new( prov => $prov );
    }
    elsif ( $chosen_server eq 'bind' ) {
        require Provision::Unix::DNS::BIND;
        return Provision::Unix::DNS::BIND->new( prov => $prov );
    }
    else {
        return $prov->error( "no support for $chosen_server yet",
            fatal  => $fatal,
            debug  => $debug,
        );
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Provision::Unix::DNS - generic class for common DNS tasks

=head1 VERSION

version 1.08

=head1 SYNOPSIS

The Provision::Unix::DNS provides a consistent API for managing DNS zones and records regardless of the underlying DNS server. Applications make calls to Provision::Unix::DNS such as create_zone, create_zone_record, modify_zone, etc.

    use Provision::Unix::DNS;

    my $dns = Provision::Unix::DNS->new();
    $dns->zone_create( zone=>'example.com' );

    $dns->zone_modify( zone=>'example.com', hostmaster=>'dnsadmin@admin-zone.com' );

=head1 DESCRIPTION

Rather than write code to generate BIND zone files, tinydns data files, or API calls to various servers, write your application to use Provision::Unix::DNS instead. The higher level DNS class contains methods for each type of DNS task as well as error handling, rollback support, and logging. Based on the settings in your provision.conf file, your request will be dispatched to your DNS Server of choice.  Subclasses are created for each type of DNS server.

Support is included for NicTool via its native API and tinydns. I will leave it to others (or myself in the unplanned future) to write modules to interface with other DNS servers. Good candidates for modules are BIND and PowerDNS.

=head1 FUNCTIONS

=head2 create_zone

=head2 create_zone_record

=head2 get_zone

=head1 BUGS

Please report any bugs or feature requests to C<bug-unix-provision-dns at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Provision-Unix>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Provision::Unix::DNS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Provision-Unix>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Provision-Unix>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Provision-Unix>

=item * Search CPAN

L<http://search.cpan.org/dist/Provision-Unix>

=back

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by The Network People, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
