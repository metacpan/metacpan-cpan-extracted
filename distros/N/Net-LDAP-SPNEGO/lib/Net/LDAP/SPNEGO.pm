package Net::LDAP::SPNEGO;
our $VERSION = '0.1.7';

=encoding utf8

=head1 NAME

Net::LDAP::SPNEGO - Net::LDAP support for NTLM/SPNEGO authentication

=head1 SYNOPSIS

 use Net::LDAP::SPNEGO;
 use Mojolicious::Lite;

 my $SERVER = $ENV{AD_SERVER} // die "AD_SERVER env variable not set";

 my %cCache;

 app->secrets(['My secret passphrase here']);

 hook before_dispatch => sub {
     my $c = shift;

     # once the user property is set, we are happy
     # and don't try to re-authenticate
     return if $c->session('user');

     my $cId = $c->tx->connection;
     my $cCache = $cCache{$cId} //= { status => 'init' };
     my $authorization = $c->req->headers->header('Authorization') // '';
     my ($AuthBase64) = ($authorization =~ /^NTLM\s(.+)$/);
     for ($AuthBase64 and $cCache->{status} =~ /^expect(Type\d)/){
         my $ldap = $cCache->{ldapObj}
            //= Net::LDAP::SPNEGO->new($SERVER,debug=>0);
         /^Type1/ && do {
             my $mesg = $ldap->bind_type1($AuthBase64);
             if ($mesg->{ntlm_type2_base64}){
                 $c->res->headers->header(
                    'WWW-Authenticate' => 'NTLM '.$mesg->{ntlm_type2_base64}
                 );
                 $c->render(
                    text => 'Waiting for Type3 NTLM Token',
                    status => 401
                 );
                 $cCache->{status} = 'expectType3';
                 return;
             }
             # lets try with a new connection
             $ldap->unbind;
             delete $cCache->{ldapObj};
         };
         /^Type3/ && do {
             my $mesg = $ldap->bind_type3($AuthBase64);
             if (my $user = $mesg->{ldap_user_entry}){
                 $c->session('user',$user->{samaccountname});
                 $c->session('name',$user->{displayname});
                 my $groups = $ldap->get_ad_groups($user->{samaccountname});
                 $c->session('groups',[ sort keys %$groups]);
             }
             $ldap->unbind;
             delete $cCache->{ldapObj};
         };
     }
     $c->res->headers->header( 'WWW-Authenticate' => 'NTLM' );
     $c->render( text => 'Waiting for Type 1 NTLM Token', status => 401 );
     $cCache->{status} = 'expectType1';
 };

 get '/' => 'index';

 app->start;

 __DATA__

 @@ index.html.ep
 <!DOCTYPE html>
 <html>
 <head>
 <title>NTLM Auth Test</title>
 </head>
 <body>
     <h1>Hello <%= session 'name' %></h1>
     <div>Your account '<%= session 'user' %>'
        belongs to the following groups:</div>
     <ul>
     % for my $group (@{session 'groups' }) {
         <li>'<%= $group %>'</li>
     % }
     </ul>
 </body>
 </html>

=head1 DESCRIPTION

C<Net::LDAP::SPNEGO> provides the essential building blocks to implement NTLM SSO
from Windows clients to webservers. Its purpose is to proxy NTLM tokens
from the webbrowser to an active directory server using the SPNEGO protocol.

The dialog between browser and the webserver in an NTLM authentication dialog looks
like this:

 1: C  --> S  GET ...
    S  --> C  401 Unauthorized
              WWW-Authenticate: NTLM

 2: C  --> S  GET ...
              Authorization: NTLM <base64-encoded type-1-message>
    S  --> C  401 Unauthorized
              WWW-Authenticate: NTLM <base64-encoded type-2-message>

 3: C  --> S  GET ...
              Authorization: NTLM <base64-encoded type-3-message>
    S  --> C 200 Ok

In contrast to modern web APIs, the NTLM authentication exchange relies on a presistant
connection between browser and server to correlate steps 2 and 3 of the dialog.

The example above uses L<Mojolicious::Lite> but there is no inherent dependency on
that particular framework, except that NTLM authentication relies on a persistent
http connections (keepalive) to link the multi step authentication together.
In other words, a CGI implementation will not work since the CGI process gets
restarted with every request.

Windows will only engage in seamless NTLM negotiation with sites residing in the
local zone this may have to be configured in the Internet Settings dialog.

The module works with NTML as well as NTLMv2 tokens.

If you are working with L<Mojolicious> you may find the L<Mojolicious::Plugin::SPNEGO>
of interest.

=head1 METHODS

B<Net::LDAP::SPNEGO> provides all the methods of L<Net::LDAP> as well as the following:

=cut

use v5.10;
use strict;
use warnings;

use parent 'Net::LDAP';
use Net::LDAP::Constant qw(LDAP_SASL_BIND_IN_PROGRESS LDAP_SUCCESS LDAP_LOCAL_ERROR);
use Net::LDAP::Util qw(escape_filter_value);
use MIME::Base64 qw(decode_base64 encode_base64);
use Net::LDAP::Message;
use Encoding::BER::DER;
use Encode;

=head2 my $response = $ldap->bind_type1($type1B64)

Start binding the ldap connection. The argument to this method is the base64 encoded type1
NTLM token received from a browser request in the C<Authorization> header.

 Authorization: NTLM Base64EncodedNtlmToken

The C<bind_type1> call encodes this token in an SPNEGO message and uses it to
initiate a bind call to the active directory server.

The C<bind_type1> call returns the L<Net::LDAP::Message> object received from the
AD server in the same way the L<Net::LDAP> call will in a regular bind request.
If the request has been successful the response has an C<ntlm_type2_base64>
property you can hand to your webbrowser to trigger a type3 reponse.

 WWW-Authenticate: NTLM $res->{ntlm_type2_base64}

=cut


sub bind_type1 {
    my $self = shift;
    my $tokenType1 = decode_base64(shift);
    my $resp = $self->_send_spnego($self->_wrap_type1_token($tokenType1));
    if ( $resp->code == LDAP_SASL_BIND_IN_PROGRESS){
        if (my $serverSaslCreds = $resp->{serverSaslCreds}){
            if (my $data = $self->_ber_encoder->decode($serverSaslCreds)){
                if (my $token = $data->{value}[0]{value}[2]{value}) {
                    if ($token =~ /^NTLMSSP/){
                        my $base64Token = encode_base64($token);
                        $base64Token =~ s/[\s\n\r]+//g;
                        $resp->{ntlm_type2_base64} = $base64Token;
                        return $resp;
                    }
                }
            }
        }
        $resp->set_error(LDAP_LOCAL_ERROR, 'no type2 token found in server response');
    }
    return $resp;
}

=head2 my $mesg = $ldap->bind_type3($type3B64)

Complete binding the ldap connection. The argument to this method is the base64
encoded type3 NTLM token received from the browser request in the C<Authorization>
header.

 Authorization: NTLM Base64EncodedNtlmToken

The C<bind_type3> call returns the L<Net::LDAP::Message> object received from the
AD server in the same way the L<Net::LDAP> call will in a regular bind request.

The successful response object comes with the extra property: C<ldap_user_entry>
containing the ldap user information.

 {
   'pwdlastset' => '131153165937657397',
   'objectcategory' => 'CN=Person,CN=Schema,CN=Configuration,DC=oetiker,DC=local',
   'displayname' => 'Tobi Test',
   'usncreated' => '362412',
   'distinguishedname' => 'CN=TobiTest TT. Tobi,CN=Users,DC=oetiker,DC=local',
   'countrycode' => '0',
   'whenchanged' => '20160820154613.0Z',
   'instancetype' => '4',
   'lastlogontimestamp' => '131161815735975291',
   ...
 }

=cut

sub bind_type3 {
    my $self = shift;
    my $tokenType3 = decode_base64(shift);
    my $resp = $self->_send_spnego($self->_wrap_type3_token($tokenType3));
    if ($resp->code == LDAP_SUCCESS) {
        my $username = $self->_get_user_from_ntlm_type3($tokenType3);
        $resp->{ldap_user_entry} = $self->_get_ad_user($username);
    }
    return $resp;
}

=head2 my $group_hash = $ldap->get_value_ad_groups($username)

Query the ldap server for all the users group memberships,
including the primary group and all the inherited group memberships.

The function uses the magic C<member:1.2.840.113556.1.4.1941:> query
to effect a recursive search.

The function returns a hash indexed by the C<sAMAccountName> of the groups
containing the DN and the description of each group.

 {
  'Remote Desktop Users' => {
    'dn' => 'CN=Remote Desktop Users,CN=Builtin,DC=oetiker,DC=local',
    'description' => 'Members in this group are granted the right ...'
   },
  'Users' => {
    'dn' => 'CN=Users,CN=Builtin,DC=oetiker,DC=local',
    'description' => 'Users are prevented from making accidental ...'
  },
  'Domain Users' => {
    'description' => 'All domain users',
    'dn' => 'CN=Domain Users,CN=Users,DC=oetiker,DC=local'
   }
 }

=cut

sub get_ad_groups {
    my $self = shift;
    my $user = $self->_get_ad_user(shift);
    return [] unless $user;

    my $userDN = $user->{distinguishedname};
    my $primaryGroupSID = _rid2sid($user->{objectsid},$user->{primarygroupid});

    my $primaryGroup = $self->search(
        base => $self->_get_base_dn,
        filter => '(objectSID='._ldap_quote($primaryGroupSID).')',
        attrs => [],
    )->entry(0);

    my @groups;
    my $search = $self->search(
        base => $self->_get_base_dn,
        filter => '(|'
        .'(objectSID='._ldap_quote($primaryGroupSID).')'
        .'(member:1.2.840.113556.1.4.1941:='.escape_filter_value($userDN).')'
        .'(member:1.2.840.113556.1.4.1941:='.escape_filter_value($primaryGroup->dn).')'
        .')',
        attrs => ['sAMAccountName','description']
    );
    if ($search->is_error) {
        warn "LDAP Search failed: ".$search->error;
        return {};
    }
    while (my $entry = eval { $search->shift_entry }){
        push @groups, $entry;
    };
    if ($@) {
        warn "Problem fetching search entry $@";
    }
    if ($search->is_error) {
        warn "LDAP Search error: ".$search->error;
    }

    return {
     map {
         scalar $_->get_value('samaccountname') => {
             dn => $_->dn,
             description => scalar $_->get_value('description')
         }
     } @groups
    }
}

# AD LDAP helpers
#
sub _get_base_dn {
 my $self = shift;
 if (not $self->{baseDN}){
     my $rootDSE = $self->search(
         base => '',
         filter => '(objectclass=*)',
         scope => 'base',
         attrs => ['defaultNamingContext'],
     )->entry(0);
     $self->{baseDN} = $rootDSE->get_value('defaultnamingcontext');
 }
 return $self->{baseDN};
}

sub _get_ad_user {
 my $self = shift;
 my $sAMAccountName = shift // '';
 my $user = $self->search(
     base => $self->_get_base_dn,
     scope => 'sub',
     filter => "(sAMAccountName=".escape_filter_value($sAMAccountName).')',
     attrs => [],
 )->entry(0);

 return undef unless ref $user;

 return {
     map {
         lc($_) => scalar $user->get_value($_)
     } $user->attributes
 };
}

sub _ldap_quote {
    return join '', map { sprintf "\\%02x", $_ } unpack('C*',shift);
}
# with inspiration from
# https://github.com/josephglanville/posix-ldap-overlay/blob/master/lib/SID.pm

sub _unpack_sid {
    return unpack 'C Vxx C V*', shift;
}

sub _sid2string {
    my ($rev, $auth, $sa_cnt, @sa) = _unpack_sid(shift);
    return join '-', 'S', $rev, $auth, @sa;
}

sub _sid2rid {
    return [_unpack_sid(shift)]->[-1];
}

sub _rid2sid {
    my ($rev, $auth, $sacnt, @sa) = _unpack_sid(shift);
    $sa[-1] = shift;
    return pack 'C Vxx C V*', $rev, $auth, scalar @sa, @sa;
}


# wrap and send an spnego token
sub _send_spnego {
    my $self = shift;
    my $token = shift;
    my $mesg = Net::LDAP::Message->new($self);
    $mesg->encode(
        bindRequest => {
            name => '',
            version => $self->version,
            authentication => {
                sasl => {
                    mechanism => 'GSS-SPNEGO',
                    credentials => $token
                }
            }
        },
        controls => undef
    );
 $self->_sendmesg($mesg);
}

# our BER encoder and decoder

sub _ber_encoder {
    my $self = shift;
    return $self->{_ber_encoder} if $self->{_ber_encoder};
    my $enc = $self->{_ber_encoder} = Encoding::BER::DER->new( error => sub{ die "BER: $_[1]\n" } );
    $enc->add_implicit_tag('context', 'constructed', 'mechToken', 2,'octet_string');
    $enc->add_implicit_tag('context', 'constructed', 'supportedMech', 1,'oid');
    $enc->add_implicit_tag('context', 'constructed', 'negResult', 0,'enum');
    $enc->add_implicit_tag('application','constructed','spnego',0,'sequence');
};

# prepare the ntlm token for the SPNEGO request to the ldap server
sub _wrap_type1_token {
    my $self = shift;
       my $ntlm_token = shift;
    my $enc = $self->_ber_encoder;
    my $spnegoOID = '1.3.6.1.5.5.2';
    my $ntlmOID = '1.3.6.1.4.1.311.2.2.10';
    return  $enc->encode({
        type => 'spnego',
        value => [
            {
                type => 'oid',
                value => $spnegoOID
            },
            {
                type => ['context','constructed',0],
                value => [{
                    type => 'sequence',
                    value => [
                        {
                            type => ['context','constructed',0],
                            value => [{
                                type => 'sequence',
                                value => [
                                    {
           type => 'oid',
           value => $ntlmOID
                                    }
                                ]
                            }]
                        },
                        {
                            type => 'mechToken',
                            value => $ntlm_token
                        }
                    ]
                }]
            }
        ]
    });
}

# prepare the type3 token for next step in the authentication process
sub _wrap_type3_token {
       my $self = shift;
       my $ntlm_token = shift;
       my $enc = $self->_ber_encoder;
       return $enc->encode({
           type => ['context','constructed',1],
           value => [{
               type => 'sequence',
               value => [{
                   type => 'mechToken',
                   value => $ntlm_token
               }]
           }]
       });
}

# parse a ntlm type3 token to figure out the username, domain and host
# of the connecting browser

sub _get_user_from_ntlm_type3 {
    my $self = shift;
    my $msg = shift;
    my $sb = 'v xx V';
    my ($sig,$type,$lmL,$lmO,$ntL,$ntO,
        $dnL,$dnO, #domain
        $unL,$unO, #user
        $hnL,$hnO, #host
        $skL,$skO, #sessionkey
        $flags, $osMin,$osMaj,$osBuild,$NTLMv) = unpack('Z8 V' . ($sb x 6) . ' V C C v C',$msg);
    # Parse a Type3 NTLM message (binary form, not encoded in Base64).
    #return a tuple (username, domain)
    my $NTLMSSP_NEGOTIATE_UNICODE = 0x00000001;
    my $username = substr($msg,$unO,$unL);
    # my $domain = substr($msg,$dnO,$dnL);
    # my $host = substr($msg,$hnO,$hnL);
    if ($flags & $NTLMSSP_NEGOTIATE_UNICODE){
        # $domain = decode('utf-16-le',$domain);
        $username =  decode('utf-16-le',$username);
        # $host =  decode('utf-16-le',$host);
    }
    return $username;
}

1;

__END__

=head1 EXAMPLE

The included example script F<eg/mojolite-demo.pl> shows how to use the module to implement
NTLM authentication for a L<Mojolicious::Lite> web application.

Use the following steps to run the demo:

 $ perl Makefile.PL
 $ make 3rd
 $ env AD_SERVER=ad-server.example.com ./eg/mojolite-demo.pl deamon

Now connect with your webbrowser to the webserver runing on port 3000. If you
login from a Windows host and the url you are connecting resides in the local zone,
you will see (or rather not see) seemless authentication taking place. Finally
a webpage will be displayed showing a list of groups you are a member of.

The demo script stores your authentication in a cookie in your brower, so once
you are authenticated, you will have to restart the browser or remove the cookie
to force another authentication.

=head1 ACKNOWLEGEMENTS

Implementing this module would not have been possible without the access
to these imensly enlightening documents:
L<NTLM Authentication Scheme for HTTP|http://www.innovation.ch/personal/ronald/ntlm.html> by Ronald Tschalär,
L<The NTLM Authentication Protocol and Security Support Provider|http://davenport.sourceforge.net/ntlm.html> by Eric Glass
as well as L<The PyAuthenNTLM2 Module|https://github.com/Legrandin/PyAuthenNTLM2> by Helder Eijs.

Thank you for makeing that information avaialble.

=head1 COPYRIGHT

Copyright (c) 2016 by OETIKER+PARTNER AG. All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

S<Tobias Oetiker E<lt>tobi@oetiker.chE<gt>>

=head1 HISTORY

 2016-08-19 to 0.1.0 initial version

=cut
