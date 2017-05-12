## Domain Registry Interface, .NO Domain extensions
##
## Copyright (c) 2008-2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
##                    Trond Haugen E<lt>info@norid.noE<gt>
##                    All rights reserved.
##
## This file is part of Net::DRI
##
## Net::DRI is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## See the LICENSE file that comes with this distribution for more details.
#
# 
#
####################################################################################################

package Net::DRI::Protocol::EPP::Extensions::NO::Domain;

use strict;
use Net::DRI::DRD::NO;
use Net::DRI::Protocol::EPP::Core::Domain;
use Net::DRI::Util;
use Net::DRI::Exception;
use Net::DRI::Protocol::EPP::Util;
use Net::DRI::Protocol::EPP::Extensions::NO::Host;

our $VERSION = do { my @r = ( q$Revision: 1.3 $ =~ /\d+/gmx ); sprintf( "%d" . ".%02d" x $#r, @r ); };

=pod

=head1 NAME

Net::DRI::Protocol::EPP::Extensions::NO::Domain - .NO EPP Domain extension commands for Net::DRI

=head1 DESCRIPTION

Please see the README file for details.

=head1 SUPPORT

For now, support questions should be sent to:

E<lt>netdri@dotandco.comE<gt>

Please also see the SUPPORT file in the distribution.

=head1 SEE ALSO

E<lt>http://www.dotandco.com/services/software/Net-DRI/E<gt>

=head1 AUTHOR

Trond Haugen, E<lt>info@norid.noE<gt>

=head1 COPYRIGHT

Copyright (c) 2008-2010 UNINETT Norid AS, E<lt>http://www.norid.noE<gt>,
Trond Haugen E<lt>info@norid.noE<gt>
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

See the LICENSE file that comes with this distribution for more details.

=cut

####################################################################################################

sub register_commands {
    my ( $class, $version ) = @_;
    my %tmp = (
       check            => [ \&facet, undef ],
       info             => [ \&facet, undef ],
       create           => [ \&facet, undef ],
        transfer_cancel  => [ \&facet, undef ],
       transfer_query   => [ \&facet, undef ],
       renew            => [ \&facet, undef ],

       update           => [ \&update, undef ],
        delete           => [ \&delete,           undef ],
        transfer_request => [ \&transfer_request, undef ],
        transfer_execute => [
            \&transfer_execute,
            \&Net::DRI::Protocol::EPP::Core::Domain::transfer_parse
        ],
        withdraw         => [ \&withdraw, undef ],
    );
    return { 'domain' => \%tmp };
}

####################################################################################################

sub build_command_extension {
    my ( $mes, $epp, $tag ) = @_;

    return $mes->command_extension_register(
        $tag,
        sprintf(
            'xmlns:no-ext-domain="%s" xsi:schemaLocation="%s %s"',$mes->nsattrs('no_domain')
        )
    );
}

sub facet {
    my ( $epp, $o, $rd ) = @_;

    return Net::DRI::Protocol::EPP::Extensions::NO::Host::build_facets( $epp, $rd );
}

sub update {
    my ( $epp, $domain, $todo ) = @_;

    my $fs = $todo->set('facets');
    return unless ( defined($fs) && $fs);    # No facets set

    my $rd;
    $rd->{facets} = $fs;
    return facet($epp, $domain, $rd);
}


sub delete {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $dfd = $rd->{deletefromdns};
    my $dfr = $rd->{deletefromregistry};
    my $fs  = $rd->{facets};

    return unless ( ( defined($dfd) || defined($dfr) || defined($fs) ) && ( $dfd || $dfr || $fs ) );

    my $r;
    if ( $dfd || $dfr ) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-domain:delete' );
       my @e;
       push @e, [ 'no-ext-domain:deleteFromDNS', $dfd ] if ( defined($dfd) && $dfd );
       push @e, [ 'no-ext-domain:deleteFromRegistry', $dfr ] if ( defined($dfr) && $dfr );

       $r = $mes->command_extension( $eid, \@e ) if (@e);
    }
    if ($fs) {
       $r = facet($epp, $domain, $rd);
    }
    return $r;

}


sub transfer_request {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $mp = $rd->{mobilephone};
    my $em = $rd->{email};
    my $fs = $rd->{facets};

    return unless ( ( defined($mp) || defined($em) || defined($fs) ) && ( $mp || $em || $fs) );

    my $r;
    if ($mp || $em) {
       my $eid = build_command_extension( $mes, $epp, 'no-ext-domain:transfer' );

       my @d;
       push @d,
        Net::DRI::Protocol::EPP::Util::build_tel(
           'no-ext-domain:mobilePhone', $mp )
            if ( defined($mp) && $mp );
       push @d, [ 'no-ext-domain:email', $em ] if ( defined($em) && $em );

       my @e;
       push @e, [ 'no-ext-domain:notify', @d ];
       $r = $mes->command_extension( $eid, \@e );

    }
    if ($fs) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}


sub withdraw {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $transaction;
    $transaction = $rd->{transactionname} if $rd->{transactionname};

    my $fs = $rd->{facets};

    return unless ( $transaction && $transaction eq 'withdraw');

    Net::DRI::Exception::usererr_insufficient_parameters(
        'Witdraw command requires a domain name')
        unless ( defined($domain) && $domain );

    my $r;

    my (undef,$NS,$NSX)=$mes->nsattrs('no_domain');
    my (undef,$ExtNS,$ExtNSX)=$mes->nsattrs('no_epp');

    my $eid = $mes->command_extension_register( 'command',
              'xmlns="' 
            . $ExtNS
            . '" xsi:schemaLocation="'
            . $ExtNS
            . " $ExtNSX"
            . '"' );

    my $cltrid=$mes->cltrid();

    my %domns;
    $domns{'xmlns:domain'}       = $NS;
    $domns{'xsi:schemaLocation'} = $NS . " $NSX";

    $r=$mes->command_extension(
        $eid,
        [   [   'withdraw',
                [   'domain:withdraw', [ 'domain:name', $domain ],
                    \%domns, \%domns
                ]
            ],
            [ 'clTRID', $cltrid ]
        ]
       );

    if ( defined($fs) && $fs ) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}

sub transfer_execute {
    my ( $epp, $domain, $rd ) = @_;
    my $mes = $epp->message();

    my $transaction;
    $transaction = $rd->{transactionname} if $rd->{transactionname};

    return unless ( $transaction && $transaction eq 'transfer_execute' );

    my (undef,$NS,$NSX)=$mes->nsattrs('no_domain');
    my (undef,$ExtNS,$ExtNSX)=$mes->nsattrs('no_epp');

    my ( $auth, $du, $token, $fs );
    $auth  = $rd->{auth}     if $rd->{auth};
    $du    = $rd->{duration} if $rd->{duration};
    $token = $rd->{token}    if $rd->{token};
    $fs    = $rd->{facets}   if $rd->{facets};

    # An execute must contain either an authInfo or a token, optionally also a duration
    Net::DRI::Exception::usererr_insufficient_parameters(
        'transfer_execute requires either an authInfo or a token')
        unless ( defined($token) || defined($auth) && ( $token || $auth ) );

    # Duration is optional
    my $dur;
    if (   defined($du)
        && $du
        && Net::DRI::Util::has_duration( $rd )
        )
    {
        Net::DRI::Util::check_isa( $du, 'DateTime::Duration' );

        Net::DRI::Exception->die( 0, 'DRD::NO', 3, 'Invalid duration' )
            if Net::DRI::DRD::NO->verify_duration_renew( $du, $domain );
        $dur = Net::DRI::Protocol::EPP::Util::build_period($du);
    }

    my $eid = $mes->command_extension_register( 'command',
              'xmlns="' 
            . $ExtNS
            . '" xsi:schemaLocation="'
            . $ExtNS
            . " $ExtNSX"
            . '"' );


    my $cltrid=$mes->cltrid();

    my %domns;
    $domns{'xmlns:domain'} = 'urn:ietf:params:xml:ns:domain-1.0';
    $domns{'xsi:schemaLocation'}
        = 'urn:ietf:params:xml:ns:domain-1.0 domain-1.0.xsd';

    my %domns2;
    $domns2{'xmlns:no-ext-domain'} = $NS;
    $domns2{'xsi:schemaLocation'}  = $NS . " $NSX";

    my $r;

    if ( Net::DRI::Util::has_auth( $rd )
        && ( ref( $rd->{auth} ) eq 'HASH' ) )
    {
        $r=$mes->command_extension(
            $eid,
            [   [   'transfer',
                    { 'op' => 'execute' },
                    [   'domain:transfer',
                        \%domns,
                        [ 'domain:name', $domain ],
                        $dur,
                        Net::DRI::Protocol::EPP::Util::domain_build_authinfo(
                            $epp, $rd->{auth}
                        ),
                    ],
                ],
                [ 'clTRID', $cltrid ]
            ]
        );
    } elsif ($token) {
        $r=$mes->command_extension(
            $eid,
            [   [   'transfer',
                    { 'op' => 'execute' },
                    [   'domain:transfer', \%domns,
                        [ 'domain:name', $domain ], $dur,
                    ],
                ],
                [   'extension',
                    [   'no-ext-domain:transfer', \%domns2,
                        [ 'no-ext-domain:token', $token ]
                    ]
                ],
                [ 'clTRID', $cltrid ]
            ]
        );
    }

    if ( defined($fs) && $fs ) {
       $r = facet($epp, $domain, $rd);
    }

    return $r;

}

####################################################################################################
1;
