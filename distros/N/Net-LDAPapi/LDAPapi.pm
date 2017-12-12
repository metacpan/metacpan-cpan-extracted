package Net::LDAPapi;

use strict;
use Carp;
use Convert::ASN1;
use vars qw($VERSION @ISA @EXPORT $AUTOLOAD);
no warnings "uninitialized";

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT =
    qw(
       ldap_create ldap_set_option ldap_get_option ldap_unbind_ext
       ldap_unbind_ext_s ldap_version ldap_abandon_ext ldap_add_ext ldap_add_ext_s
       ldap_set_rebind_proc
       ldap_rename ldap_rename_s
       ldap_compare_ext ldap_compare_ext_s ldap_delete_ext
       ldap_delete_ext_s ldap_search_ext ldap_search_ext_s ldap_result
       ldap_extended_operation ldap_extended_operation_s ldap_parse_extended_result
       ldap_parse_whoami ldap_whoami ldap_whoami_s
       ldap_msgfree ldap_msg_free ldap_msgid ldap_msgtype
       ldap_get_lderrno ldap_set_lderrno ldap_parse_result ldap_err2string
       ldap_count_entries ldap_first_entry ldap_next_entry ldap_get_dn
       ldap_err2string ldap_dn2ufn ldap_str2dn ldap_str2rdn ldap_explode_rdn
       ldap_explode_dns ldap_first_attribute ldap_next_attribute
       ldap_get_values ldap_get_values_len ldap_sasl_bind ldap_sasl_bind_s
       ldapssl_client_init ldapssl_init ldapssl_install_routines
       ldap_get_all_entries ldap_multisort_entries
       ldap_is_ldap_url ldap_url_parse ldap_url_search ldap_url_search_s
       ldap_url_search_st ber_free ldap_init ldap_initialize ldap_start_tls_s
       ldap_sasl_interactive_bind_s
       ldap_create_control ldap_control_berval
       LDAP_RES_BIND
       LDAP_RES_SEARCH_ENTRY
       LDAP_RES_SEARCH_REFERENCE
       LDAP_RES_SEARCH_RESULT
       LDAP_RES_MODIFY
       LDAP_RES_ADD
       LDAP_RES_DELETE
       LDAP_RES_MODDN
       LDAP_RES_COMPARE
       LDAP_RES_EXTENDED
       LDAP_RES_INTERMEDIATE
       LDAP_RES_ANY
       LDAP_RES_UNSOLICITED
       LDAPS_PORT
       LDAP_ADMIN_LIMIT_EXCEEDED
       LDAP_AFFECTS_MULTIPLE_DSAS
       LDAP_ALIAS_DEREF_PROBLEM
       LDAP_ALIAS_PROBLEM
       LDAP_ALREADY_EXISTS
       LDAP_AUTH_KRBV4
       LDAP_AUTH_KRBV41
       LDAP_AUTH_KRBV41_30
       LDAP_AUTH_KRBV42
       LDAP_AUTH_KRBV42_30
       LDAP_AUTH_NONE
       LDAP_AUTH_SASL
       LDAP_AUTH_SIMPLE
       LDAP_AUTH_UNKNOWN
       LDAP_BUSY
       LDAP_CACHE_CHECK
       LDAP_CACHE_LOCALDB
       LDAP_CACHE_POPULATE
       LDAP_CALLBACK
       LDAP_COMPARE_FALSE
       LDAP_COMPARE_TRUE
       LDAP_CONNECT_ERROR
       LDAP_CONSTRAINT_VIOLATION
       LDAP_CONTROL_ASSERT
       LDAP_CONTROL_DUPENT
       LDAP_CONTROL_DUPENT_ENTRY
       LDAP_CONTROL_DUPENT_REQUEST
       LDAP_CONTROL_DUPENT_RESPONSE
       LDAP_CONTROL_GROUPING
       LDAP_CONTROL_MANAGEDIT
       LDAP_CONTROL_MANAGEDSAIT
       LDAP_CONTROL_NOOP
       LDAP_CONTROL_NO_SUBORDINATES
       LDAP_CONTROL_PAGEDRESULTS
       LDAP_CONTROL_PASSWORDPOLICYREQUEST
       LDAP_CONTROL_PASSWORDPOLICYRESPONSE
       LDAP_CONTROL_PERSIST_ENTRY_CHANGE_NOTICE
       LDAP_CONTROL_PERSIST_REQUEST
       LDAP_CONTROL_POST_READ
       LDAP_CONTROL_PRE_READ
       LDAP_CONTROL_PROXY_AUTHZ
       LDAP_CONTROL_SLURP
       LDAP_CONTROL_SORTREQUEST
       LDAP_CONTROL_SORTRESPONSE
       LDAP_CONTROL_SUBENTRIES
       LDAP_CONTROL_SYNC
       LDAP_CONTROL_SYNC_DONE
       LDAP_CONTROL_SYNC_STATE
       LDAP_CONTROL_VALSORT
       LDAP_CONTROL_VALUESRETURNFILTER
       LDAP_CONTROL_VLVREQUEST
       LDAP_CONTROL_VLVRESPONSE
       LDAP_CONTROL_X_CHAINING_BEHAVIOR
       LDAP_CONTROL_X_DOMAIN_SCOPE
       LDAP_CONTROL_X_EXTENDED_DN
       LDAP_CONTROL_X_INCREMENTAL_VALUES
       LDAP_CONTROL_X_PERMISSIVE_MODIFY
       LDAP_CONTROL_X_SEARCH_OPTIONS
       LDAP_CONTROL_X_TREE_DELETE
       LDAP_CONTROL_X_VALUESRETURNFILTER
       LDAP_CUP_INVALID_DATA
       LDAP_DECODING_ERROR
       LDAP_DEREF_ALWAYS
       LDAP_DEREF_FINDING
       LDAP_DEREF_NEVER
       LDAP_DEREF_SEARCHING
       LDAP_ENCODING_ERROR
       LDAP_FILTER_ERROR
       LDAP_FILT_MAXSIZ
       LDAP_INAPPROPRIATE_AUTH
       LDAP_INAPPROPRIATE_MATCHING
       LDAP_INSUFFICIENT_ACCESS
       LDAP_INVALID_CREDENTIALS
       LDAP_INVALID_DN_SYNTAX
       LDAP_INVALID_SYNTAX
       LDAP_IS_LEAF
       LDAP_LOCAL_ERROR
       LDAP_LOOP_DETECT
       LDAP_MOD_ADD
       LDAP_MOD_BVALUES
       LDAP_MOD_DELETE
       LDAP_MOD_REPLACE
       LDAP_NAMING_VIOLATION
       LDAP_NOT_ALLOWED_ON_NONLEAF
       LDAP_NOT_ALLOWED_ON_RDN
       LDAP_NO_LIMIT
       LDAP_NO_MEMORY
       LDAP_NO_OBJECT_CLASS_MODS
       LDAP_NO_SUCH_ATTRIBUTE
       LDAP_NO_SUCH_OBJECT
       LDAP_OBJECT_CLASS_VIOLATION
       LDAP_OPERATIONS_ERROR
       LDAP_OPT_CACHE_ENABLE
       LDAP_OPT_CACHE_FN_PTRS
       LDAP_OPT_CACHE_STRATEGY
       LDAP_OPT_DEBUG_LEVEL
       LDAP_OPT_DEREF
       LDAP_OPT_DESC
       LDAP_OPT_DNS
       LDAP_OPT_IO_FN_PTRS
       LDAP_OPT_OFF
       LDAP_OPT_ON
       LDAP_OPT_PROTOCOL_VERSION
       LDAP_OPT_REBIND_ARG
       LDAP_OPT_REBIND_FN
       LDAP_OPT_REFERRALS
       LDAP_OPT_REFERRAL_HOP_LIMIT
       LDAP_OPT_RESTART
       LDAP_OPT_SIZELIMIT
       LDAP_OPT_SSL
       LDAP_OPT_THREAD_FN_PTRS
       LDAP_OPT_TIMELIMIT
       LDAP_OPT_TIMEOUT
       LDAP_OPT_NETWORK_TIMEOUT
       LDAP_OTHER
       LDAP_PARAM_ERROR
       LDAP_PARTIAL_RESULTS
       LDAP_PORT
       LDAP_PORT_MAX
       LDAP_PROTOCOL_ERROR
       LDAP_REFERRAL
       LDAP_RESULTS_TOO_LARGE
       LDAP_SASL_AUTOMATIC
       LDAP_SASL_INTERACTIVE
       LDAP_SASL_NULL
       LDAP_SASL_QUIET
       LDAP_SASL_SIMPLE
       LDAP_SCOPE_BASE
       LDAP_SCOPE_ONELEVEL
       LDAP_SCOPE_SUBTREE
       LDAP_SECURITY_NONE
       LDAP_SERVER_DOWN
       LDAP_SIZELIMIT_EXCEEDED
       LDAP_STRONG_AUTH_NOT_SUPPORTED
       LDAP_STRONG_AUTH_REQUIRED
       LDAP_SUCCESS
       LDAP_SYNC_INFO
       LDAP_TIMELIMIT_EXCEEDED
       LDAP_TIMEOUT
       LDAP_TYPE_OR_VALUE_EXISTS
       LDAP_UNAVAILABLE
       LDAP_UNAVAILABLE_CRITICAL_EXTN
       LDAP_UNDEFINED_TYPE
       LDAP_UNWILLING_TO_PERFORM
       LDAP_URL_ERR_BADSCOPE
       LDAP_URL_ERR_MEM
       LDAP_URL_ERR_NODN
       LDAP_URL_ERR_NOTLDAP
       LDAP_URL_ERR_PARAM
       LDAP_URL_OPT_SECURE
       LDAP_USER_CANCELLED
       LDAP_VERSION
       LDAP_VERSION1
       LDAP_VERSION2
       LDAP_VERSION3
       LDAP_TAG_SYNC_NEW_COOKIE
       LDAP_TAG_SYNC_REFRESH_DELETE
       LDAP_TAG_SYNC_REFRESH_PRESENT
       LDAP_TAG_SYNC_ID_SET
       LDAP_TAG_SYNC_COOKIE
       LDAP_TAG_REFRESHDELETES
       LDAP_TAG_REFRESHDONE
       LDAP_TAG_RELOAD_HINT
       LDAP_TAG_EXOP_MODIFY_PASSWD_ID
       LDAP_TAG_EXOP_MODIFY_PASSWD_OLD
       LDAP_TAG_EXOP_MODIFY_PASSWD_NEW
       LDAP_TAG_EXOP_MODIFY_PASSWD_GEN
       LDAP_TAG_MESSAGE
       LDAP_TAG_MSGID
       LDAP_TAG_LDAPDN
       LDAP_TAG_LDAPCRED
       LDAP_TAG_CONTROLS
       LDAP_TAG_REFERRAL
       LDAP_TAG_NEWSUPERIOR
       LDAP_TAG_EXOP_REQ_OID
       LDAP_TAG_EXOP_REQ_VALUE
       LDAP_TAG_EXOP_RES_OID
       LDAP_TAG_EXOP_RES_VALUE
       LDAP_TAG_IM_RES_OID
       LDAP_TAG_IM_RES_VALUE
       LDAP_TAG_SASL_RES_CREDS
       );
$VERSION = '3.0.5';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
        if ($! =~ /Invalid/) {

            # try constants_h
            $val = '"'.constant_s($constname).'"';
            goto SUBDEF if ($! == 0);

            $AutoLoader::AUTOLOAD = $AUTOLOAD;
            goto &AutoLoader::AUTOLOAD;
        } else {
            croak "Your vendor has not defined LDAP macro $constname";
        }
    }
SUBDEF:
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Net::LDAPapi $VERSION;


# creats blessed ldap object.
# accepts following arguments '-host', '-port', '-url', '-debug'
# if '-url' is given then then '-host' and '-port' are not used
sub new
{
    my ($this, @args) = @_;
    my $class = ref($this) || $this;
    my $self  = {};
    my $ld;
    bless $self, $class;

    my ($host, $port, $url, $debug) =
        $self->rearrange(['HOST','PORT','URL', 'DEBUG'],@args);

    if ( defined($url) ) {
        return -1 unless (ldap_initialize($ld, $url) == $self->LDAP_SUCCESS );

    } else {
        $host = "localhost"      unless $host;
        $port = $self->LDAP_PORT unless $port;

        return -1 unless ( ldap_initialize($ld, "ldap://$host:$port") == $self-> LDAP_SUCCESS);
    }

    # Following ASN.1 contains definitions for synrepl API
    my $asn = Convert::ASN1->new;
    $asn->prepare(<<ASN) or die "prepare: ", $asn->error;

    syncUUID ::= OCTET STRING

    syncCookie ::= OCTET STRING

    syncRequestValue ::= SEQUENCE {
				mode ENUMERATED {
						refreshOnly       (1),
						refreshAndPersist (3)
				},
        cookie     syncCookie OPTIONAL,
        reloadHint BOOLEAN
        }

    syncStateValue ::= SEQUENCE {
        state     ENUMERATED,
        entryUUID syncUUID,
        cookie    syncCookie OPTIONAL
        }

    refresh_Delete ::= SEQUENCE {
        cookie         syncCookie OPTIONAL,
        refreshDone    BOOLEAN OPTIONAL
        }

    refresh_Present ::= SEQUENCE {
        cookie         syncCookie OPTIONAL,
        refreshDone    BOOLEAN OPTIONAL
        }

    syncId_Set      ::= SEQUENCE {
        cookie         syncCookie OPTIONAL,
        refreshDeletes BOOLEAN OPTIONAL,
        syncUUIDs      SET OF syncUUID
        }

    syncInfoValue ::= CHOICE {
        newcookie      [0] syncCookie,
        refreshDelete  [1] refresh_Delete,
        refreshPresent [2] refresh_Present,
        syncIdSet      [3] syncId_Set
        }
ASN

    $self->{"asn"}       = $asn;
    $self->{"ld"}        = $ld;
    $self->{"errno"}     = 0;
    $self->{"errstring"} = undef;
    $self->{"debug"}     = $debug;
    ldap_set_option($ld, $self->LDAP_OPT_PROTOCOL_VERSION, $self->LDAP_VERSION3);
    return $self;
} # end of new


sub DESTROY {};


sub abandon
{
    my ($self, @args) = @_;

    my ($status, $sctrls, $cctrls);

    my ($msgid, $serverctrls, $clientctrls) =
        $self->rearrange(['MSGID', 'SCTRLS', 'CCTRLS'], @args);

    croak("Invalid MSGID") if ($msgid < 0);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_abandon_ext($self->{"ld"}, $msgid, $sctrls, $cctrls);

    $self->errorize($status);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    return $status;
} # end of abandon


# synonim for abandon(...)
sub abandon_ext {
    my ($self, @args) = @_;

    return $self->abandon(@args);
} # end of abandon_ext


sub add
{
    my ($self,@args) = @_;

    my ($msgid, $sctrls, $cctrls, $status);

    my ($dn, $mod, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'MOD', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");
    croak("LDAPMod structure is not a hash reference.") if( ref($mod) ne "HASH" );

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_add_ext($self->{"ld"}, $dn, $mod, $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of add

# synonym for add
sub add_ext
{
    my ($self, @args) = @_;

    return $self->add(@args);
} # end of add_ext


sub add_s
{
    my ($self,@args) = @_;

    my ($sctrls, $cctrls, $status);

    my ($dn, $mod, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'MOD', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");
    croak("LDAP Modify Structure Not a HASH Reference") if (ref($mod) ne "HASH");

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_add_ext_s($self->{"ld"}, $dn, $mod, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);

    return $status;
} # end of add_s


# synonym for add_s
sub add_ext_s
{
    my ($self, @args) = @_;

    return $self->add_s(@args);
} # end of add_ext_s


sub bind
{
    my ($self,@args) = @_;

    my ($msgid, $sctrls, $cctrls, $status);

    my ($dn, $pass, $authtype, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'PASSWORD', 'TYPE', 'SCTRLS', 'CCTRLS'],@args);

    $dn       = "" unless $dn;
    $pass     = "" unless $pass;
    $authtype = $authtype || $self->LDAP_AUTH_SIMPLE;

    croak("bind supports only LDAP_AUTH_SIMPLE auth type")
        unless $authtype == $self->LDAP_AUTH_SIMPLE;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_sasl_bind($self->{"ld"}, $dn,     $pass,
                             $sctrls,       $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of bind


sub bind_s
{
    my ($self, @args) = @_;

    my ($status, $servercredp, $sctrls, $cctrls);

    my ($dn, $pass, $authtype, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'PASSWORD', 'TYPE', 'SCTRLS', 'CCTRLS'], @args);

    $dn       = "" unless $dn;
    $pass     = "" unless $pass;
    $sctrls   = 0 unless $sctrls;
    $cctrls   = 0 unless $cctrls;
    $authtype = $authtype || $self->LDAP_AUTH_SIMPLE;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    if ($authtype == $self->LDAP_AUTH_SASL) {
        $status =
            ldap_sasl_interactive_bind_s($self->{"ld"}, $dn, $pass,
                                         $sctrls, $cctrls, $self->{"saslmech"},
                                         $self->{"saslrealm"},
                                         $self->{"saslauthzid"},
                                         $self->{"saslsecprops"},
                                         $self->{"saslflags"});

    } else {
        # not sure here what to do with $servercredp
        $status = ldap_sasl_bind_s($self->{"ld"}, $dn, $pass,
                                   $sctrls, $cctrls, \$servercredp);
    }

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);

    return $status;
} # end of bind_s


sub sasl_parms
{
    my ($self,@args) = @_;
    my ($mech,  $realm, $authzid, $secprops, $flags) =
        $self->rearrange(['MECH', 'REALM', 'AUTHZID', 'SECPROPS', 'FLAGS'],
                         @args);

    $mech     = ""                     unless $mech;
    $realm    = ""                     unless $realm;
    $authzid  = ""                     unless $authzid;
    $secprops = ""                     unless $secprops;
    $flags    = $self->LDAP_SASL_QUIET unless defined($flags);

    $self->{"saslmech"}     = $mech;
    $self->{"saslrealm"}    = $realm;
    $self->{"saslauthzid"}  = $authzid;
    $self->{"saslsecprops"} = $secprops;
    $self->{"saslflags"}    = $flags;
} # end of sasl_parms


sub compare
{
    my ($self, @args) = @_;

    my ($status, $msgid, $sctrls, $cctrls);

    my ($dn, $attr, $value, $serverctrls, $clientctrls) =
        $self->rearrange(['DN','ATTR', ['VALUE', 'VALUES'], 'SCTRLS', 'CCTRLS'],  @args);

    croak("No DN Specified") if ($dn eq "");
    $value = "" unless $value;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status =
        ldap_compare_ext($self->{"ld"}, $dn, $attr, $value, $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of compare


# synonym for compare
sub compare_ext {
    my ($self, @args) = @_;

    return $self->compare(@args);
} # end of compare_ext


# needs to use ldap_compare_ext_s
sub compare_s
{
    my ($self, @args) = @_;

    my ($status, $sctrls, $cctrls);

    my ($dn, $attr, $value, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'ATTR' , ['VALUE', 'VALUES'], 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");
    $value = "" unless $value;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_compare_ext_s($self->{"ld"}, $dn, $attr, $value, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    return $status;
} # end of compare_s


# synonym for compare
sub compare_ext_s {
    my ($self, @args) = @_;

    return $self->compare_s(@args);
} # end of compare_ext


# needs DOC in POD bellow. XXX
sub start_tls
{
    my ($self, @args) = @_;

    my ($msgid, $status, $sctrls, $cctrls);

    my ($serverctrls, $clientctrls) =
        $self->rearrange(['SCTRLS', 'CCTRLS'], @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_start_tls($self->{"ld"}, $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of start_tls


# needs DOC in POD bellow. XXX
sub start_tls_s
{
    my ($self, @args) = @_;

    my ($status, $sctrls, $cctrls);
    $sctrls=0;
    $cctrls=0;

    my ($serverctrls, $clientctrls) = $self->rearrange(['SCTRLS', 'CCTRLS'], @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_start_tls_s($self->{"ld"}, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);

    return $status;
} # end of start_tls_s


sub count_entries
{
    my ($self, @args) = @_;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    croak("No result is given") unless $result;

    return ldap_count_entries($self->{"ld"}, $result);
} # end of count_entries


sub delete
{
    my ($self,@args) = @_;

    my ($msgid, $status, $sctrls, $cctrls);

    my ($dn, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");

    $sctrls = 0;
    $cctrls = 0;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_delete_ext($self->{"ld"}, $dn, $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of delete

sub delete_s
{
    my ($self,@args) = @_;

    my ($status, $sctrls, $cctrls);

    my ($dn, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_delete_ext_s($self->{"ld"}, $dn, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);

    return $status;
} # end of delete_s

sub dn2ufn
{
    my ($self, @args) = @_;

    my ($dn) = $self->rearrange(['DN'], @args);

    return ldap_dn2ufn($dn);
} # end of dn2ufn


sub explode_dn
{
    my ($self, @args) = @_;

    my ($dn, $notypes) = $self->rearrange(['DN', 'NOTYPES'],@args);

    return ldap_explode_dn($dn, $notypes);
} # end of explode_dn


sub explode_rdn
{
    my ($self, @args) = @_;

    my (@components);

    my ($rdn, $notypes) = $self->rearrange(['RDN', 'NOTYPES'], @args);

    return ldap_explode_rdn($rdn, $notypes);
} # end of explode_rdn


sub first_message
{
    my ($self, @args) = @_;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    croak("No Current Result") unless $result;

    $self->{"msg"} = ldap_first_message($self->{"ld"}, $self->{"result"});

    return $self->{"msg"};
} # end of first_message


sub next_message
{
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    $msg = $self->{"msg"} unless $msg;

    croak("No Current Message") unless $msg;

    $self->{"msg"} = ldap_next_message($self->{"ld"}, $msg);

    return $self->{"msg"};
} # end of next_message


# using this function you don't have to call fist_message and next_message
# here is an example:
#
# print "message = $message\n" while( $msg = $ld->result_message );
#
sub result_message
{
    my ($self, @args) = @_;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    croak("No Current Result") unless $result;

    if( $self->{"msg"} == 0 ) {
        $self->{"msg"} = ldap_first_message($self->{"ld"}, $self->{"result"});
    } else {
        $self->{"msg"} = ldap_next_message($self->{"ld"},  $self->{"msg"});
    }

    return $self->{"msg"};
} # end of result_message


sub next_changed_entries {
    my ($self, @args) = @_;

    my ($msgid, $allnone, $timeout) =
        $self->rearrange(['MSGID', 'ALL', 'TIMEOUT'], @args);

    my ($rc,             $msg,            $msgtype, $asn,            $syncInfoValue,
        $syncInfoValues, $refreshPresent, $ctrl,    $oid,            %parsed,
        $retdatap,       $retoidp,        @entries, $syncStateValue, $syncStateValues,
        $state,          $berval,         $cookie);

    $rc = $self->result($msgid, $allnone, $timeout);

    @entries = ();

    if ($self->{'status'} == 0) { # ldap_result return 0 = timeout
        return @entries;
    }
    
    $asn = $self->{"asn"};

    while( $msg = $self->result_message ) {
        $msgtype = $self->msgtype($msg);

        if( $msgtype eq $self->LDAP_RES_SEARCH_ENTRY ) {
            my %entr =  ('entry' => $msg);
            push(@entries, \%entr);
            $self->{"entry"} = $msg;

            # extract controls if any
            my @sctrls = $self->get_entry_controls($msg);
            foreach $ctrl (@sctrls) {
                $oid = $self->get_control_oid($ctrl);
                if( $oid eq $self->LDAP_CONTROL_SYNC_STATE ) {
                    $berval = $self->get_control_berval($ctrl);
                    $syncStateValue = $asn->find('syncStateValue');
                    $syncStateValues = $syncStateValue->decode($berval);
                    $state = $syncStateValues->{'state'};
                    if(      $state == 0 ) {
                        $entr{'state'} = "present";
                    } elsif( $state == 1 ) {
                        $entr{'state'} = "add";
                    } elsif( $state == 2 ) {
                        $entr{'state'} = "modify";
                    } elsif( $state == 3 ) {
                        $entr{'state'} = "delete";
                    } else {
                        $entr{'state'} = "unknown";
                    }
                }

                $cookie = $syncStateValues->{'cookie'};
                if( $cookie ) {
                    # save the cookie
										save_cookie($cookie, $self->{"cookie"});
                }
            }

        } elsif( $msgtype eq $self->LDAP_RES_INTERMEDIATE ) {
            %parsed = $self->parse_intermediate($msg);
            $retdatap = $parsed{'retdatap'};
            $retoidp  = $parsed{'retoidp'};

            if( $retoidp eq $self->LDAP_SYNC_INFO ) {
                my $cookie;

                $asn->configure(encoding => "DER");
                $syncInfoValue = $asn->find('syncInfoValue');
                $syncInfoValues = $syncInfoValue->decode($retdatap);

                # trying to get the cookie from one of the foolowing choices.
                $cookie = $syncInfoValues->{'newcookie'};

                my $refreshPresent = $syncInfoValues->{'refreshPresent'};
                $cookie = $refreshPresent->{'cookie'} if( $refreshPresent );

                my $refreshDelete = $syncInfoValues->{'refreshDelete'};
                $cookie = $refreshDelete->{'cookie'} if( $refreshDelete );

                my $syncIdSet = $syncInfoValues->{'syncIdSet'};
                $cookie = $syncIdSet->{'cookie'} if( $syncIdSet );

                $asn->configure(encoding => "BER");

                # see if we got any and save it.
                if( $cookie ) {
										save_cookie($cookie, $self->{"cookie"});
                }
            }
        }
    }

    return @entries;
} # next_changed_entries

sub save_cookie
{
    my ($self,@args) = @_;
    my $cookiestr = $_[0];
    my $cookie = $_[1];

    # Skip all if there's no csn value
    if ($cookiestr =~ m/csn=/) {

        # Get new CSN array and a copy
        chomp(my @newcsns = split(';',$cookiestr =~ s/(rid=\d{3},)|(sid=\d{3},)|(csn=)//rg));

        # These will be the CSNs to write to the cookie file
        # All CSNs from the new cookie must be used
        # my @outcsns = @newcsns;
        my @outcsns = @newcsns;

        # Get the old cookie for comparison/persisting
        if (-w $cookie) {
            open(COOKIE_FILE, "<", $cookie) || die("Cannot open file '".$cookie."' for reading.");
            chomp(my @oldcsns = <COOKIE_FILE>);
            close(COOKIE_FILE);

            # Look for old CSNs with SIDs that don't match any of the new
            # CSNs. If there are no matches, push the old CSN to the list
            # of CSNs to be written to the cookie file.
            foreach my $oldcsn (@oldcsns) {
                my $match = 0;
                my $p_sid  = ($oldcsn =~ /(#\d{3}#)/i)[0];
                foreach my $newcsn (@newcsns) {
                    if ($newcsn =~ m/\Q$p_sid/) {
                        $match = 1;
                        last;
                    }
                }
                if (!$match) { push @outcsns,$oldcsn; }
            }
        }

        # Write the cookie
        open(COOKIE_FILE, ">", $cookie) || die("Cannot open file '".$cookie."' for writing.");
        print COOKIE_FILE "$_\n" for @outcsns;
        close(COOKIE_FILE);
    }
} # end save_cookie


sub first_entry
{
    my ($self) = @_;

    croak("No Current Result") if ($self->{"result"} == 0);

    $self->{"entry"} = ldap_first_entry($self->{"ld"}, $self->{"result"});

    return $self->{"entry"};
} # end of first_entry

sub next_entry
{
    my ($self) = @_;

    croak("No Current Entry") if ($self->{"entry"} == 0);

    $self->{"entry"} = ldap_next_entry($self->{"ld"}, $self->{"entry"});

    return $self->{"entry"};
} # end of next_entry


# using this function you don't have to call fist_entry and next_entry
# here is an example:
#
# print "entry = $entry\n" while( $entry = $ld->result_entry );
#
sub result_entry
{
    my ($self) = @_;

    croak("No Current Result") if ($self->{"result"} == 0);

    if( $self->{"entry"} == 0 ) {
        $self->{"entry"} = ldap_first_entry($self->{"ld"}, $self->{"result"});
    } else {
        $self->{"entry"} = ldap_next_entry($self->{"ld"},  $self->{"entry"});
    }

    return $self->{"entry"};
} # end of result_entry


sub get_entry_controls
{
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    $msg = $self->{"msg"} unless $msg;

    croak("No Current Message/Entry") unless $msg;

    my @serverctrls = ();
    my $serverctrls_ref = \@serverctrls;

    ldap_get_entry_controls($self->{"ld"}, $msg, $serverctrls_ref);

    return @serverctrls;
} # end of get_entry_controls


sub get_control_oid {
    my ($self, @args) = @_;

    my ($ctrl) = $self->rearrange(['CTRL'], @args);

    return ldap_control_oid($ctrl);
} # end of get_control_oid


sub get_control_berval {
    my ($self, @args) = @_;

    my ($ctrl) = $self->rearrange(['CTRL'], @args);

    return ldap_control_berval($ctrl);
} # end of get_control_berval


sub get_control_critical {
    my ($self, @args) = @_;

    my ($ctrl) = $self->rearrange(['CTRL'], @args);

    return ldap_control_critical($ctrl);
} # end of get_control_critical


sub first_attribute
{
    my ($self) = @_;

    my ($attr, $ber);

    croak("No Current Entry") if ($self->{"entry"} == 0);

    $attr = ldap_first_attribute($self->{"ld"}, $self->{"entry"}, $ber);

    $self->{"ber"} = $ber;

    return $attr;
} # end of first_attribute


sub next_attribute
{
    my ($self) = @_;

    my ($attr);

    croak("No Current Entry") if ($self->{"entry"} == 0);
    croak("Empty Ber Value")  if ($self->{"ber"}   == 0);

    $attr = ldap_next_attribute($self->{"ld"}, $self->{"entry"}, $self->{"ber"});

    ber_free($self->{"ber"}, 0) if (!$attr);

    return $attr;
} # end of next_attribute


# using this function you don't have to call fist_attribute and next_attribute
# as in the following example:
#
# print "<$attr>\n" while( $attr = $ld->entry_attribute );
#
sub entry_attribute {

    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    my ($attr, $ber);

    $msg = $self->{"entry"} unless $msg;

    croak("No Current Entry") unless $msg;

    if ($self->{"ber"} == 0) {
        $attr = ldap_first_attribute($self->{"ld"}, $msg, $ber);
        $self->{"ber"} = $ber;

    } else {
        croak("Empty Ber Value") if ($self->{"ber"} == 0);
        $attr = ldap_next_attribute($self->{"ld"}, $msg, $self->{"ber"});
        if (!$attr) {
            ber_free($self->{"ber"}, 0);
            $self->{"ber"} = undef;
        }
    }

    return $attr;
} # end of entry_attribute


sub parse_result {
    my ($self, @args) = @_;

    my ($msg, $freeMsg) = $self->rearrange(['MSG', 'FREEMSG'], @args);

    my ($status, %result);

    $freeMsg = 0            unless $freeMsg;
    $msg = $self->{"entry"} unless $msg;

    my ($errcode, $matcheddn, $errmsg, @referrals, @serverctrls);

    @serverctrls = ();
    my $serverctrls_ref = \@serverctrls;

    @referrals = ();
    my $referrals_ref = \@referrals;

    $status =
        ldap_parse_result($self->{"ld"}, $msg,           $errcode,         $matcheddn,
                          $errmsg,       $referrals_ref, $serverctrls_ref, $freeMsg);


    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    $result{"errcode"}     = $errcode;
    $result{"matcheddn"}   = $matcheddn;
    $result{"errmsg"}      = $errmsg;
    $result{"referrals"}   = $referrals_ref;
    $result{"serverctrls"} = $serverctrls_ref;

    return %result;
} # end of parse_result(...)

sub parse_extended_result {
    my ($self, @args) = @_;

    my ($msg, $freeMsg) = $self->rearrange(['MSG', 'FREEMSG'], @args);

    my ($status, %result);

    $freeMsg = 0          unless $freeMsg;
    $msg = $self->{"msg"} unless $msg;

    my ($retoidp, $retdatap);

    $status =
        ldap_parse_extended_result($self->{"ld"}, $msg, $retoidp, $retdatap,  $freeMsg);

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    $result{"retoidp"}     = $retoidp;
    $result{"retdatap"}    = $retdatap;

    return %result;
} # end of parse_extended_result(...)

# needs docs bellow in POD. XXX
sub parse_intermediate {
    my ($self, @args) = @_;

    my ($msg, $freeMsg) = $self->rearrange(['MSG', 'FREEMSG'], @args);

    my ($status, %result);

    $freeMsg = 0          unless $freeMsg;
    $msg = $self->{"msg"} unless $msg;

    my ($retoidp, $retdatap, @serverctrls);

    @serverctrls = ();
    my $serverctrls_ref = \@serverctrls;

    $status =
        ldap_parse_intermediate($self->{"ld"}, $msg,             $retoidp,
                                $retdatap,     $serverctrls_ref, $freeMsg);

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    $result{"retoidp"}     = $retoidp;
    $result{"retdatap"}    = $retdatap;
    $result{"serverctrls"} = $serverctrls_ref;

    return %result;
} # end of parse_result(...)

sub parse_whoami {
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    my ($status, %result);

    $msg = $self->{"msg"} unless $msg;

    my ($authzid);

    $status =
        ldap_parse_whoami($self->{"ld"}, $msg, $authzid);

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $authzid;
} # end of parse_whoami(...)

sub perror
{
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    ldap_perror($self->{"ld"}, $msg);
}

# get dn for current entry
sub get_dn
{
    my ($self, @args) = @_;

    my ($entry) = $self->rearrange(['MSG'], @args);

    $entry = $self->{"entry"} unless $entry;

    croak("No Current Entry") unless $entry;

    my $dn = ldap_get_dn($self->{"ld"}, $entry);

    return $dn;
} # end of get_dn


# get array of values for current entry and a given attribute
sub get_values
{
    my ($self, @args) = @_;

    my ($attr) = $self->rearrange(['ATTR'], @args);

    croak("No Current Entry")       if ($self->{"entry"} == 0);
    croak("No Attribute Specified") if ($attr eq "");

    my @vals = ldap_get_values_len($self->{"ld"}, $self->{"entry"}, $attr);

    return @vals;
} # end of get_values


# synonym for get_values(...)
sub get_values_len {
    my ($self, @args) = @_;

    return $self->get_values(@args);
} # end of get_values_len


sub msgfree
{
    my ($self, @args) = @_;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    return ldap_msgfree($self->{"result"});
} # end of msgfree


sub modify
{
    my ($self, @args) = @_;

    my ($msgid, $sctrls, $cctrls, $status);

    my ($dn, $mod, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'MOD', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");
    croak("LDAP Modify Structure Not a Reference") if (ref($mod) ne "HASH");

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_modify_ext($self->{"ld"}, $dn, $mod, $sctrls, $cctrls, $msgid);

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    return $msgid;
} # end of modify


# synonym for modify
sub modify_ext
{
    my ($self, @args) = @_;

    return $self->modify(@args);
} # end of modify_ext


sub modify_s
{
    my ($self,@args) = @_;

    my ($status, $sctrls, $cctrls);

    my ($dn, $mod, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'MOD', 'SCTRLS', 'CCTRLS'], @args);

    croak("No DN Specified") if ($dn eq "");
    croak("LDAP Modify Structure Not a Reference") if (ref($mod) ne "HASH");

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_modify_ext_s($self->{"ld"}, $dn, $mod, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    return $status;
} # end of modify_s


# synonym for modify
sub modify_ext_s
{
    my ($self, @args) = @_;

    return $self->modify_s(@args);
} # end of modify_ext


# needs updated docs in POD bellow
sub rename {
    my ($self, @args) = @_;

    my ($sctrls, $cctrls, $msgid, $status);

    my ($dn, $newrdn, $newsuper, $delete, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'NEWRDN', 'NEWSUPER', 'DELETE', 'SCTRLS', 'CCTRLS'],
                         @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status =
        ldap_rename($self->{"ld"}, $dn,     $newrdn, $newsuper,
                    $delete,       $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of rename


# needs updated docs in POD bellow
sub rename_s {
    my ($self, @args) = @_;

    my ($sctrls, $cctrls, $status);

    my ($dn, $newrdn, $newsuper, $delete, $serverctrls, $clientctrls) =
        $self->rearrange(['DN', 'NEWRDN', 'NEWSUPER', 'DELETE', 'SCTRLS', 'CCTRLS'],
                         @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status =
        ldap_rename_s($self->{"ld"}, $dn,     $newrdn, $newsuper,
                      $delete,       $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);

    return $status;
} # end of rename_s


# this function is used to retrieve results of asynchronous search operation
# it returns LDAPMesage which is to be processed by functions first_entry,
# result_entry, first_message, result_message. To find message type one
# should use function msgtype(...)
sub result
{
    my ($self, @args) = @_;
    my ($result, $status, $err) = (undef, undef, undef);

    my ($msgid, $allnone, $timeout) =
        $self->rearrange(['MSGID', 'ALL', 'TIMEOUT'], @args);

    croak("Invalid MSGID") if ($msgid < 0);

    $status = ldap_result($self->{"ld"}, $msgid, $allnone, $timeout, $result);
    $self->{"result"} = $result;
    $self->{"status"} = $status;

    $self->errorize($status);
    if( $status == -1 || $status == 0 ) {
        return undef;
    }

    return $result;
} # end of result


sub is_ldap_url
{
    my ($self,@args) = @_;

    my ($url) = $self->rearrange(['URL'],@args);

    return ldap_is_ldap_url($url);
} # end of is_ldap_url


sub url_parse
{
    my ($self,@args) = @_;
    my ($url) = $self->rearrange(['URL'],@args);

    return ldap_url_parse($url);
} # end of url_parse


# needs testing XXX. present only in Mozilla SDK
sub url_search
{
    my ($self,@args) = @_;
    my ($msgid,$errdn,$extramsg);

    my ($url,$attrsonly) = $self->rearrange(['URL','ATTRSONLY'],@args);

    if (($msgid = ldap_url_search($self->{"ld"},$url,$attrsonly)) < 0)
    {
        $self->{"errno"} = ldap_get_lderrno($self->{"ld"},$errdn,$extramsg);
        $self->{"extramsg"} = undef;
    } else {
        $self->{"errno"} = 0;
        $self->{"extramsg"} = "";
    }
    return $msgid;
} # end of url_search


# needs testing XXX. present only in Mozilla SDK
sub url_search_s
{
    my ($self, @args) = @_;
    my ($result, $status, $errdn, $extramsg);

    my ($url,$attrsonly) = $self->rearrange(['URL', 'ATTRSONLY'], @args);

    if( ($status = ldap_url_search_s($self->{"ld"}, $url, $attrsonly, $result)) !=
        $self->LDAP_SUCCESS )
    {
        $self->{"errno"} = ldap_get_lderrno($self->{"ld"},$errdn,$extramsg);
        $self->{"extramsg"} = $extramsg;
    } else {
        $self->{"errno"} = 0;
        $self->{"extramsg"} = undef;
    }
    $self->{"result"} = $result;
    return $status;
} # end of url_search_s


# needs testing XXX. present only in Mozilla SDK
sub url_search_st
{
    my ($self,@args) = @_;
    my ($result,$status,$errdn,$extramsg);

    my ($url,$attrsonly,$timeout) = $self->rearrange(['URL','ATTRSONLY',
                                                      'TIMEOUT'],@args);

    if (($status = ldap_url_search_st($self->{"ld"},$url,$attrsonly,$timeout,
                                      $result)) != $self->LDAP_SUCCESS)
    {
        $self->{"errno"} = ldap_get_lderrno($self->{"ld"},$errdn,$extramsg);
        $self->{"extramsg"} = $extramsg;
    } else {
        $self->{"errno"} = 0;
        $self->{"extramsg"} = undef;
    }
    $self->{"result"} = $result;
    return $status;
} # end of url_search_st


# needs testing XXX. present only in Mozilla SDK
sub multisort_entries
{
    my ($self,@args) = @_;
    my ($status,$errdn,$extramsg);

    my ($attr) = $self->rearrange(['ATTR'],@args);

    if (!$self->{"result"})
    {
        croak("No Current Result");
    }

    $status = ldap_multisort_entries($self->{"ld"},$self->{"result"},$attr);
    $self->errorize($status);
    return $status;
} # end of multisort_entries


sub listen_for_changes
{
    my ($self, @args) = @_;

    my ($msgid, $status, $sctrls, $the_cookie, $syncRequestBerval);

    my ($basedn,    $scope,   $filter,    $attrs,
        $attrsonly, $timeout, $sizelimit, $cookie, $rid) =
            $self->rearrange(['BASEDN',    'SCOPE',   'FILTER',    'ATTRS',
                              'ATTRSONLY', 'TIMEOUT', 'SIZELIMIT', 'COOKIE', 'RID'], @args);

    croak("No Filter Specified") if (!defined($filter));
    croak("No cookie file specified") unless $cookie;

    $self->{"cookie"} = $cookie;
    $self->{"rid"} = defined($rid) ? $rid : '000';

    if( !defined($attrs) ) {
        my @null_array = ();
        $attrs = \@null_array;
    }

    # load cookie from the file
    if( open(COOKIE, $cookie) ) {
				chomp(my @csns = <COOKIE>);
        if (scalar(@csns)) {
				  $the_cookie = sprintf("rid=%d,csn=%s",$rid,join(';',@csns));
        }
    } else {
        warn "Failed to open file '".$cookie."' for reading.\n";
    }

    my $asn = $self->{"asn"};
    my $syncRequestValue  = $asn->find('syncRequestValue');

    # refreshAndPersist mode
    if( $the_cookie ) { # we have the cookie
        $syncRequestBerval = $syncRequestValue->encode(mode => 3, cookie => $the_cookie, reloadHint => 1);
    } else {
        $syncRequestBerval = $syncRequestValue->encode(mode => 3, reloadHint => 1);
    }

    my $ctrl_persistent =
        $self->create_control(-oid      => $self->LDAP_CONTROL_SYNC,
                              -berval   => $syncRequestBerval,
                              -critical => $self->CRITICAL);

    my @controls = ($ctrl_persistent);
    $sctrls = $self->create_controls_array(@controls);

    $status =
        ldap_search_ext($self->{"ld"}, $basedn,    $scope,  $filter,
                        $attrs,        $attrsonly, $sctrls, undef,
                        $timeout,      $sizelimit, $msgid);

    ldap_controls_array_free($sctrls);
    ldap_control_free($ctrl_persistent);

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # listen_for_changes


sub search
{
    my ($self, @args) = @_;
    my ($msgid, $status, $sctrls, $cctrls);

    my ($basedn,      $scope,       $filter,  $attrs,    $attrsonly,
        $serverctrls, $clientctrls, $timeout, $sizelimit) =
            $self->rearrange(['BASEDN',    'SCOPE',  'FILTER', 'ATTRS',
                              'ATTRSONLY', 'SCTRLS', 'CCTRLS', 'TIMEOUT',
                              'SIZELIMIT'],
                             @args);

    croak("No Filter Specified") if (!defined($filter));

    if( !defined($attrs) ) {
        my @null_array = ();
        $attrs = \@null_array;
    }

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status =
        ldap_search_ext($self->{"ld"}, $basedn,    $scope,  $filter,
                        $attrs,        $attrsonly, $sctrls, $cctrls,
                        $timeout,      $sizelimit, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of search


# synonym for search
sub search_ext
{
    my ($self, @args) = @_;

    return $self->search(@args);
} # end of search_ext


sub search_s
{
    my ($self, @args) = @_;

    my ($result, $status, $sctrls, $cctrls);

    my ($basedn,      $scope,       $filter,  $attrs,    $attrsonly,
        $serverctrls, $clientctrls, $timeout, $sizelimit) =
            $self->rearrange(['BASEDN',    'SCOPE',  'FILTER', 'ATTRS',
                              'ATTRSONLY', 'SCTRLS', 'CCTRLS', 'TIMEOUT',
                              'SIZELIMIT' ], @args);

    croak("No Filter Passed as Argument 3") if ($filter eq "");

    if( !defined($attrs) ) {
        my @null_array = ();
        $attrs = \@null_array;
    }

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status =
        ldap_search_ext_s($self->{"ld"}, $basedn,    $scope,   $filter,
                          $attrs,        $attrsonly, $sctrls,  $cctrls,
                          $timeout,      $sizelimit, $result);


    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    $self->{"result"} = $result;
    return $status;
} # end of search_s


# synonym for search_s(...)
sub search_ext_s
{
    my ($self, @args) = @_;

    return $self->search_s(@args);
} # end of search_ext_s

sub extended_operation
{
    my ($self, @args) = @_;
    my ($msgid, $status, $sctrls, $cctrls);

    my ($oid, $berval, $serverctrls, $clientctrls) =
            $self->rearrange(['OID',    'BERVAL',  
                              'SCTRLS', 'CCTRLS'],
                             @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_extended_operation($self->{"ld"}, $oid, $berval, length($berval),
                        $sctrls, $cctrls,
                        $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of extended_operation

sub extended_operation_s
{
    my ($self, @args) = @_;
    my ($status, $retoidp, $retdatap, $sctrls, $cctrls);

    my ($oid, $berval, $serverctrls, $clientctrls, $result) =
            $self->rearrange(['OID',    'BERVAL',  
                              'SCTRLS', 'CCTRLS', 'RESULT'],
                             @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_extended_operation_s($self->{"ld"}, $oid, $berval, length($berval),
                        $sctrls, $cctrls,
                        $retoidp, $retdatap);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    
    $result->{'retoidp'} = $retoidp;
    $result->{'retdatap'} = $retdatap;
    
    return $status;
} # end of extended_operation_s

sub whoami
{
    my ($self, @args) = @_;
    my ($msgid, $status, $sctrls, $cctrls);

    my ($serverctrls, $clientctrls) =
            $self->rearrange(['SCTRLS', 'CCTRLS'],
                             @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_whoami($self->{"ld"}, $sctrls, $cctrls, $msgid);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    if( $status != $self->LDAP_SUCCESS ) {
        return undef;
    }

    return $msgid;
} # end of whoami

sub whoami_s
{
    my ($self, @args) = @_;
    my ($status, $authzidOut, $sctrls, $cctrls);

    my ($authzid, $serverctrls, $clientctrls) =
            $self->rearrange(['AUTHZID', 'SCTRLS', 'CCTRLS'],
                             @args);

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_whoami_s($self->{"ld"}, $authzidOut, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    
    $$authzid = $authzidOut;
    
    return $status;
} # end of whoami_s

sub count_references
{
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    $msg = $self->{"entry"} unless $msg;

    return ldap_count_references($self->{"ld"}, $msg);
} # end of count_references


sub get_option
{
    my ($self, @args) = @_;
    my ($status);

    my ($option, $optdata) = $self->rearrange(['OPTION', 'OPTDATA'], @args);

    $status = ldap_get_option($self->{"ld"}, $option, $optdata);

    return $status;
} # end of get_option


sub set_option
{
    my ($self,@args) = @_;
    my ($status);

    my ($option,$optdata) = $self->rearrange(['OPTION','OPTDATA'],@args);

    $status = ldap_set_option($self->{"ld"},$option,$optdata);

    return $status;
} # end of set_option


# needs testing more XXX
sub set_rebind_proc
{
    my ($self, @args) = @_;
    my ($status);

    my ($rebindproc, $params) = $self->rearrange(['REBINDPROC', 'PARAMS'], @args);

    if( ref($rebindproc) eq "CODE" ) {
        $status = ldap_set_rebind_proc($self->{"ld"}, $rebindproc, $params);
    } else {
        croak("REBINDPROC is not a CODE Reference");
    }

    return $status;
} # end of set_rebind_proc


# needs docs in a POD bellow. XXX
sub get_all_entries
{
    my ($self, @args) = shift;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    croak("NULL Result") unless $result;

    return ldap_get_all_entries($self->{"ld"}, $result);
} # end of get_all_entries


sub unbind
{
    my ($self, @args) = @_;

    my ($status, $sctrls, $cctrls);

    my ($serverctrls, $clientctrls) =
        $self->rearrange(['SCTRLS', 'CCTRLS'], @args);

    $sctrls = 0;
    $cctrls = 0;

    $sctrls = $self->create_controls_array(@$serverctrls) if $serverctrls;
    $cctrls = $self->create_controls_array(@$clientctrls) if $clientctrls;

    $status = ldap_unbind_ext_s($self->{"ld"}, $sctrls, $cctrls);

    ldap_controls_array_free($sctrls) if $sctrls;
    ldap_controls_array_free($cctrls) if $cctrls;

    $self->errorize($status);
    return $status;
} # end of unbind


# do we need these ssl function
sub ssl_client_init
{
    my ($self,@args) = @_;
    my ($status);

    my ($certdbpath,$certdbhandle) = $self->rearrange(['DBPATH','DBHANDLE'],
                                                      @args);

    $status = ldapssl_client_init($certdbpath,$certdbhandle);
    return($status);
} # end of ssl_client_init


# do we need these ssl function
sub ssl
{
    my ($self) = @_;
    my ($status);

    $status = ldapssl_install_routines($self->{"ld"});
    return $status;
} # end of ssl


sub entry
{
    my ($self) = @_;
    return $self->{"entry"};
} # end of entry


sub err
{
    my ($self) = @_;
    return $self->{"errno"};
} # end of err


sub errno
{
    my ($self) = @_;
    return $self->{"errno"};
} # end of errno


sub errstring
{
    my ($self) = @_;
    return ldap_err2string($self->{"errno"});
} # end of errstring


sub extramsg
{
    my ($self) = @_;
    return $self->{"extramsg"};
} # end of extramsg


sub ld
{
    my ($self) = @_;
    return $self->{"ld"};
} # end of ld


sub msgtype
{
    my ($self, @args) = @_;

    my ($msg) = $self->rearrange(['MSG'], @args);

    $msg = $self->{"msg"} unless $msg;

    return ldap_msgtype($msg);
} # end of msgtype

sub msgtype2str
{
    my ($self, @args) = @_;

    my ($type) = $self->rearrange(['TYPE'], @args);

    if(      $type == $self->LDAP_RES_BIND ) {
        return "LDAP_RES_BIND";
    } elsif( $type == $self->LDAP_RES_SEARCH_ENTRY ) {
        return "LDAP_RES_SEARCH_ENTRY";
    } elsif( $type == $self->LDAP_RES_SEARCH_REFERENCE ) {
        return "LDAP_RES_SEARCH_REFERENCE";
    } elsif( $type == $self->LDAP_RES_SEARCH_RESULT ) {
        return "LDAP_RES_SEARCH_RESULT";
    } elsif( $type == $self->LDAP_RES_MODIFY ) {
        return "LDAP_RES_MODIFY";
    } elsif( $type == $self->LDAP_RES_ADD ) {
        return "LDAP_RES_ADD";
    } elsif( $type == $self->LDAP_RES_DELETE ) {
        return "LDAP_RES_DELETE";
    } elsif( $type == $self->LDAP_RES_MODDN ) {
        return "LDAP_RES_MODDN";
    } elsif( $type == $self->LDAP_RES_COMPARE ) {
        return "LDAP_RES_COMPARE";
    } elsif( $type == $self->LDAP_RES_EXTENDED ) {
        return "LDAP_RES_EXTENDED";
    } elsif( $type == $self->LDAP_RES_INTERMEDIATE ) {
        return "LDAP_RES_INTERMEDIATE";
    } elsif( $type == $self->LDAP_RES_ANY ) {
        return "LDAP_RES_ANY";
    } elsif( $type == $self->LDAP_RES_UNSOLICITED ) {
        return "LDAP_RES_UNSOLICITED";
    } else {
        return "UNKNOWN";
    }
} # end of msgtype2str


sub msgid
{
    my ($self, @args) = @_;

    my ($result) = $self->rearrange(['RESULT'], @args);

    $result = $self->{"result"} unless $result;

    return ldap_msgid($self->{"ld"}, $result);
} # end of msgid

# Given array of elements of type Net::LDAP::Control
# array of controls sutable for passing to C-calls is created.
# It is to be freed by calling ldap_controls_array_free(...)
# Note that this method is *NOT* to be used by the end user of
# this library.
sub create_controls_array
{
    my ($self, @args) = @_;

    my ($location, $status, $ctrlp);

    my $ctrls = ldap_controls_array_init($#args + 2);
    for( $location = 0; $location < $#args + 1; $location++ ) {
        ldap_control_set($ctrls, $args[$location], $location);
    }
    ldap_control_set($ctrls, undef, $#args + 1);

    return $ctrls;
} # create_controls_array


# Creates control given its OID and berval. Default value of criticality is true.
sub create_control
{
    my ($self, @args) = @_;

    my ($oid, $berval, $critical) = $self->rearrange(['OID', 'BERVAL', 'CRITICAL'], @args);

    croak("No OID of controls is passed") unless $oid;
    croak("No BerVal is passed")          unless $berval;
    $critical = 1                         if !defined($critical);

    my ($ctrl) = undef;
    my $status = ldap_create_control($oid, $berval, length($berval), $critical, $ctrl);

    $self->errorize($status);
    return $ctrl;
} # end of create_control


sub free_control
{
    my ($self, @args) = @_;

    my ($control) = $self->rearrange(['CONTROL'], @args);

    ldap_control_free($control);
} # end of free_control


# This subroutine was borrowed from CGI.pm.  It does a wonderful job and
# is much better than anything I created in my first attempt at named
# arguments.  I may replace it later.
sub make_attributes
{
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape = shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
        my($key) = $_;
        $key=~s/^\-//;     # get rid of initial - if present

        # old way: breaks EBCDIC!
        # $key=~tr/A-Z_/a-z-/; # parameters are lower case, use dashes

        ($key="\L$key") =~ tr/_/-/; # parameters are lower case, use dashes

        my $value = $escape ? simple_escape($attr->{$_}) : $attr->{$_};
        push(@att, defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
} # end of make_attributes


sub rearrange
{
    my($self, $order, @param) = @_;
    return () unless @param;

    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');

    my $i;
    for ($i=0;$i<@param;$i+=2) {
        $param[$i]=~s/^\-//;     # get rid of initial - if present
        $param[$i]=~tr/a-z/A-Z/; # parameters are upper case
    }

    my(%param) = @param;                # convert into associative array
    my(@return_array);

    my($key)='';
    foreach $key (@$order) {
        my($value);
        # this is an awful hack to fix spurious warnings when the
        # -w switch is set.
        if (ref($key) && ref($key) eq 'ARRAY') {
            foreach (@$key) {
                last if defined($value);
                $value = $param{$_};
                delete $param{$_};
            }
        } else {
            $value = $param{$key};
            delete $param{$key};
        }
        push(@return_array,$value);
    }
    push (@return_array, $self->make_attributes(\%param)) if %param;
    return (@return_array);
} # end of rearrange


# places internal ldap errors into $self under keys "errno" and "extramsg"
sub errorize {
    my ($self, $status) = @_;

    my ($errdn, $extramsg);

    if ($status != $self->LDAP_SUCCESS) {
        $self->{"errno"}    = ldap_get_lderrno($self->{"ld"}, $errdn, $extramsg);
        $self->{"extramsg"} = $extramsg;

        if( $self->{"debug"} ) {
            print  "LDAP ERROR STATUS: $status ".ldap_err2string($status)."\n";
            printf("LDAP ERROR CODE:   %x\n", $self->{"errno"});
            print  "LDAP ERROR MESSAGE: $extramsg\n";
        }
    } else {
        $self->{"errno"}=0;
        $self->{"errstring"}=undef;
    }
} # end of errorize


sub CRITICAL {
    1;
}


sub NONCRITICAL {
    0;
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Net::LDAPapi - Perl5 Module Supporting LDAP API

=head1 SYNOPSIS

  use Net::LDAPapi;

  See individual items and Example Programs for Usage

=head1 DESCRIPTION

  This module allows Perl programmers to access and manipulate an LDAP
  based Directory.

  Versions beginning with 1.40 support both the original "C API" and
  new "Perl OO" style interface methods.  With version 1.42, I've added
  named arguments.

=head1 THE INTIAL CONNECTION

  All connections to the LDAP server are started by creating a new
  "blessed object" in the Net::LDAPapi class.  This can be done quite
  easily by the following type of statement.

  $ld = new Net::LDAPapi($hostname);

  Where $hostname is the name of your LDAP server.  If you are not using
  the standard LDAP port (389), you will also need to supply the
  portnumber.

  $ld = new Net::LDAPapi($hostname, 15555);

  The new method can also be called with named arguments.

  $ld = new Net::LDAPapi(-host=>$hostname, -port=>15389);

  Instead of the above mentioned argumens -url can be used in the
  following form

  $ld = new Net::LDAPapi(-url=>"ldap://host:port");

  Setting -debug=>"TRUE" will enable more verbose error messages.

  Note that with named arguments, the order of the arguments is
  insignificant.

=head1 CONTROLS

  In LDAP v3 controls are an additional piece of data, which can be
  submitted with most of the requests to the server and returned back
  attached to the result.  Controls, passed to the call, are separated
  in two types.  The client side controls, which are not passed to the
  server and are of not much use.  They are denoted by -cctrls named
  parameter.  The server side controls, denoted by -sctrls named
  parameter are actually passed to the server and may affect its
  operation or returned results.  Each entry of the result may have
  controls attached to it as well ( see parse_entry(...) call ).

  -cctrls and -sctrls must be reference to array of controls.

  To create control call create_control(...) method. Bellow is an
  example of creating valsort control.

  my $asn = Convert::ASN1->new;
  $asn->prepare('SEQUENCE { b BOOLEAN }');
  my $berval = $asn->encode(b=>1); # or 1

  my $ctrl =
    $ld->create_control(-oid=>Net::LDAPapi::LDAP_CONTROL_VALSORT,
                        -berval=>$berval,
                        -critical=>Net::LDAPapi::CRITICAL);

  The control is to be freed by calling free_control($ctrl).

  If contol is attached to results entry, it can be retrieved by
  calling parse_result($entry). If no entry is passed to
  parse_result(...) then current entry is used. It returns hash
  with following keys

  Key           Value
  -------------------
  matcheddn     string
  errmsg        string
  referrals     array reference
  serverctrls   array reference

  You can look into content of the control by using get_contol_XXX
  functions like this:

  local %parsed = $ld->parse_result($entry);
  local $serverctrls = $parsed{"serverctrls"};
  local @sctrls = @$serverctrls;
  if( scalar(@sctrls) > 0 ) {
    foreach $ctrl (@sctrls) {
      print "\nreceived control\n";
      print "oid = ".$ld->get_control_oid($ctrl)."\n";
      print "berval = ".$ld->get_control_berval($ctrl)."\n";
      print "critical = ".$ld->get_control_critical($ctrl)."\n";
    }
  }

=head1 BINDING

  After creating a connection to the LDAP server, you may need to
  bind to the server prior to performing any LDAP related functions.
  This can be done with the 'bind' methods.

  An anonymous bind can be performed without arguments:

  $status = $ld->bind_s;

  A simple bind can be performed by specifying the DN and PASSWORD of
  the user you are authenticating as:

  $status = $ld->bind_s($dn, $password);

  Note that if $password above was "", you would be doing a reference
  bind, which would return success even if the password in the
  directory was non-null.  Thus if you were using the bind to check a
  password entered with one in the directory, you should first check
  to see if $password was NULL.

  To perform SASL bind fill in appropriate parameters calling
  sasl_params(...) and call

  $status = $ld->bind_s(-type=>LDAP_AUTH_SASL)

  Bellow is an example of GSSAPI K5 bind parameters.

  $ld->sasl_parms(-mech=>"GSSAPI", -realm=>"domain.name.com",
                  -authzid=>"",    -secprops=>"",
                  -flags=>LDAP_SASL_QUIET);

  For all of the above operations, you could compare $status to
  LDAP_SUCCESS to see if the operation was successful.

  Additionally, you could use 'bind' rather than 'bind_s' if you wanted
  to use the Asynchronous LDAP routines.  The asynchronous routines
  would return a MSGID rather than a status.  To find the status of an
  Asynchronous bind, you would need to first obtain the result with a
  call to $ld->result.  See the entry for result later in the man page,
  as well as the 'ldapwalk.pl' example for further information on
  obtaining results from Asynchronous operations.

  The bind operations can also accept named arguments.

  $status = $ld->bind_s(-dn=>$dn,
                        -password=>$password,
                        -type=>LDAP_AUTH_SIMPLE);

  As with all other commands that support named arguments, the order of
  the arguments makes no difference.

=head1 GENERATING AN ADD/MODIFY HASH

  For the add and modify routines you will need to generate
  a list of attributes and values.

  You will do this by creating a HASH table.  Each attribute in the
  hash contains associated values.  These values can be one of three
  things.

    - SCALAR VALUE    (ex. "Clayton Donley")
    - ARRAY REFERENCE (ex. ["Clayton Donley","Clay Donley"])
    - HASH REFERENCE  (ex. {"r",["Clayton Donley"]}
         note:  the value inside the HASH REFERENCE must currently
             be an ARRAY REFERENCE.

  The key inside the HASH REFERENCE must be one of the following for a
  modify operation:
    - "a" for LDAP_MOD_ADD (Add these values to the attribute)
    - "r" for LDAP_MOD_REPLACE (Replace these values in the attribute)
    - "d" for LDAP_MOD_DELETE (Delete these values from the attribute)

  Additionally, in add and modify operations, you may specify "b" if the
  attributes you are adding are BINARY (ex. "rb" to replace binary).

  Currently, it is only possible to do one operation per add/modify
  operation, meaning you can't do something like:

     {"d",["Clayton"],"a",["Clay"]}   <-- WRONG!

  Using any combination of the above value types, you can do things like:

  %ldap_modifications = (
     "cn", "Clayton Donley",                    # Replace 'cn' values
     "givenname", ["Clayton","Clay"],           # Replace 'givenname' values
     "mail", {"a",["donley\@cig.mcel.mot.com"],  #Add 'mail' values
     "jpegphoto", {"rb",[$jpegphotodata]},      # Replace Binary jpegPhoto
  );

  Then remember to call the add or modify operations with a REFERENCE to
  this HASH.  Something like:

  $ld->modify_s($modify_dn,\%ldap_modifications);

=head1 GETTING/SETTING LDAP INTERNAL VALUES

  The following methods exist to obtain internal values within a
  Net::LDAPapi object:

  o errno - The last error-number returned by the LDAP library for this
    connection.
          ex:  print "Error Number: " . $ld->errno . "\n";

  o errstring - The string equivalent of 'errno'.
          ex:  print "Error: " . $ld->errstring . "\n";

  o ld - Reference to the actual internal LDAP structure.  Only useful if
    you needed to obtain this pointer for use in non-OO routines.
          ex:  $ldptr = $ld->ld;

  o entry - Reference to the current entry.  Not typically needed, but method
    supplied, just in case.
          ex:  $entry = $ld->entry;

  o msgid - Get msgid from an LDAP Result.
          ex:  $msgid = $ld->msgid;  #  msgid of current result
          ex:  $msgid = $ld->msgid($result) # msgid of $result

  o msgtype - Get msgtype from an LDAP Result.
      ex:  $msgtype = $ld->msgtype;  # msgtype of current result
          ex:  $msgtype = $ld->msgtype($result) # msgtype of $result

  These methods are only useful for GETTING internal information, not setting
  it.  No methods are currently available for SETTING these internal values.

=head1 GETTING AND SETTING LDAP SESSION OPTIONS

  The get_option and set_option methods can be used to get and set LDAP
  session options.

  The following LDAP options can be set or gotten with these methods:
    LDAP_OPT_DEREF - Dereference
    LDAP_OPT_SIZELIMIT - Maximum Number of Entries to Return
    LDAP_OPT_TIMELIMIT - Timeout for LDAP Operations
    LDAP_OPT_REFERRALS - Follow Referrals

  For both get and set operations, the first argument is the relivant
  option.  In get, the second argument is a reference to a scalar variable
  that will contain the current value of the option.  In set, the second
  argument is the value at which to set this option.

  Examples:
    $ld->set_option(LDAP_OPT_SIZELIMIT,50);
    $ld->get_option(LDAP_OPT_SIZELIMIT,\$size);

  When setting LDAP_OPT_REFERRALS, the second argument is either LDAP_OPT_ON
  or LDAP_OPT_OFF.  Other options require a number.

  Both get_option and set_option return 0 on success and non-zero otherwise.

=head1 SSL SUPPORT

  When compiled with the Mozilla SDK, this module now supports SSL.
  I do not have an SSL capable server, but I'm told this works.  The
  functions available are:

  o ssl - Turn on SSL for this connection.
    Install I/O routines to make SSL over LDAP possible
  o ssl_client_init($certdbpath,$certdbhandle)
    Initialize the secure parts (called only once)

  Example:
    $ld = new Net::LDAPapi("host",LDAPS_PORT);
    $ld->ssl_client_init($certdbpath,$certdbhandle);
    $ld->ssl;

=head1 SETTING REBIND PROCESS

  As of version 1.42, rebinding now works properly.

  The set_rebind_proc method is used to set a PERL function to supply DN,
  PASSWORD, and AUTHTYPE for use when the server rebinds (for referals,
  etc...).

  Usage should be something like:
    $rebind_ref = \&my_rebind_proc;
    $ld->set_rebind_proc($rebind_ref);

  You can then create the procedure specified.  It should return 3 values.

  Example:
    sub my_rebind_proc
    {
       return($dn,$pass,LDAP_AUTH_SIMPLE);
    }

=head1 EXTENDED OPERATIONS

  Extended operations are supported.
  
  The extended_operation and extended_operation_s methods are used to
  invoke extended operations.
  
  Example (WHOAMI):
  
    %result = ();
  
    if ($ld->extended_operation_s(-oid => "1.3.6.1.4.1.4203.1.11.3", -result => \%result) != LDAP_SUCCESS)
    {
      $ld->perror("ldap_extended_operation_s");
      exit -1;
    }
  
  Note that WHOAMI is already natively implemented via whoami and whoami_s 
  methods.
           
=head1 SUPPORTED METHODS

=over 4

=item abandon MSGID SCTRLS CCTRLS

  This cancels an asynchronous LDAP operation that has not completed.  It
  returns an LDAP STATUS code upon completion.

  Example:

    $status = ldap_abandon($ld, $msgid); # XXX fix this

=item add DN ATTR SCTRLS CCTRLS

  Begins an an asynchronous LDAP Add operation.  It returns a MSGID or undef
  upon completion.

  Example:

    %attributes = (
       "cn", ["Clayton Donley","Clay Donley"] #Add Multivalue cn
       "sn", "Donley",                #Add sn
       "telephoneNumber", "+86-10-65551234",  #Add telephoneNumber
       "objectClass", ["person","organizationalPerson"],
                        # Add Multivalue objectClass
       "jpegphoto", {"b",[$jpegphoto]},  # Add Binary jpegphoto
    );

    $entrydn = "cn=Clayton Donley, o=Motorola, c=US";

    $msgid = $ld->add($entrydn, \%attributes);

  Note that in most cases, you will need to be bound to the LDAP server
  as an administrator in order to add users.

=item add_s DN ATTR SCTRLS CCTRLS

  Synchronous version of the 'add' method.  Arguments are identical
  to the 'add' method, but this operation returns an LDAP STATUS,
  not a MSGID.

  Example:

    $ld->add_s($entrydn, \%attributes);

  See the section on creating the modify structure for more information
  on populating the ATTRIBUTES field for Add and Modify operations.

=item bind DN PASSWORD TYPE SCTRLS CCTRLS

  Asynchronous method for binding to the LDAP server.  It returns a
  MSGID.

  Examples:

    $msgid = $ld->bind;
    $msgid = $ld->bind("cn=Clayton Donley, o=Motorola, c=US", "abc123");


=item bind_s DN PASSWORD TYPE SCTRLS CCTRLS

  Synchronous method for binding to the LDAP server.  It returns
  an LDAP STATUS.

  Examples:

    $status = $ld->bind_s;
    $status = $ld->bind_s("cn=Clayton Donley, o=Motorola, c=US", "abc123");


=item compare DN ATTR VALUE SCTRLS CCTRLS

  Asynchronous method for comparing a value with the value contained
  within DN.  Returns a MSGID or undef.

  Example:

    $msgid = $ld->compare("cn=Clayton Donley, o=Motorola, c=US", \
        $type, $value);

=item compare_s DN ATTR VALUE SCTRLS CCTRLS

  Synchronous method for comparing a value with the value contained
  within DN.  Returns an LDAP_COMPARE_TRUE, LDAP_COMPARE_FALSE or an error code.

  Example:

    $status = $ld->compare_s("cn=Clayton Donley, o=Motorola, c=US", \
        $type, $value);

=item count_entries

  Returns the number of entries in an LDAP result chain.

  Example:

    $number = $ld->count_entries;

=item count_references MSG

  Return number of references in a given/current message.

  Example:

    $number = $ld->count_references

=item delete DN

  Asynchronous method to delete DN.  Returns a MSGID or -1 if error.

  Example:

    $msgid = $ld->delete("cn=Clayton Donley, o=Motorola, c=US");

=item delete_s DN

  Synchronous method to delete DN.  Returns an LDAP STATUS.

  Example:

    $status = $ld->delete_s("cn=Clayton Donley, o=Motorola, c=US");

=item dn2ufn DN

  Converts a Distinguished Name (DN) to a User Friendly Name (UFN).
  Returns a string with the UFN.

  Since this operation doesn't require an LDAP object to work, you
  could technically access the function directly as 'ldap_dn2ufn' rather
  that the object oriented form.

  Example:

    $ufn = $ld->dn2ufn("cn=Clayton Donley, o=Motorola, c=US");

=item explode_dn DN NOTYPES

  Splits the DN into an array comtaining the separate components of
  the DN.  Returns an Array.  NOTYPES is a 1 to remove attribute
  types and 0 to retain attribute types.

  Can also be accessed directly as 'ldap_explode_dn' if no session is
  initialized and you don't want the object oriented form.

  In OpenLDAP this call is depricated.

  Example:

    @components = $ld->explode_dn($dn, 0);

=item explode_rdn RDN NOTYPES

  Same as explode_dn, except that the first argument is a
  Relative Distinguished Name.  NOTYPES is a 1 to remove attribute
  types and 0 to retain attribute types.  Returns an array with
  each component.

  Can also be accessed directly as 'ldap_explode_rdn' if no session is
  initialized and you don't want the object oriented form.

  In OpenLDAP this call is depricated.

  Example:

    @components = $ld->explode_rdn($rdn, 0);

=item extended_operation OID BERVAL SCTRLS CCTRLS

  Asynchronous method for invoking an extended operation. 
  
  Returns a non-negative MSGID upon success.
  
  Examples:
  
    $msgid = $ld->extended_operation("1.3.6.1.4.1.4203.1.11.3");

=item extended_operation_s OID BERVAL SCTRLS CCTRLS RESULT

  Synchronous method for invoking an extended operation. 
  
  Returns LDAP_SUCCESS upon success.
      
  Examples:
  
    $status = $ld->extended_operation_s(-oid => "1.3.6.1.4.1.4203.1.11.3", \
        -result => \%result);
    
=item first_attribute

  Returns pointer to first attribute name found in the current entry.
  Note that this only returning attribute names (ex: cn, mail, etc...).
  Returns a string with the attribute name.

  Returns an empty string when no attributes are available.

  Example:

    $attr = $ld->first_attribute;

=item first_entry

  Sets internal pointer to the first entry in a chain of results.  Returns
  an empty string when no entries are available.

  Example:

    $entry = $ld->first_entry;

=item first_message

   Return the first message in a chain of result returned by the search
   operation. LDAP search operations return LDAPMessage, which is a head
   in chain of messages accessable to the user. Not all all of them are
   entries though. Type of the message can be obtained by calling
   msgtype(...) function.

=item get_all_entries RESULT

  Returns result of the search operation in the following format
    (HASH)
    dn -> (HASH)
          key -> (ARRAY)

  Example:
    my $all_entries_ref = $ld->get_all_entries;
    my %all_entries = %$all_entries_ref;

    foreach (keys %all_entries) {
        print "<$_> -> <".$all_entries{$_}.">\n";
        $entry = $all_entries{$_};

        local %entry_h = %$entry;
        foreach $k (keys %entry_h) {
            $values = $entry_h{$k};

            print "  <$k> ->\n";
            foreach $val (@$values) {
                print "     <$val>\n";
            }
        }
    }

=item get_dn MSG

  Returns a string containing the DN for the specified message or an
  empty string if an error occurs. If no message is specified then
  then default entry is used.

  Example:

    $dn = $ld->get_dn;

=item get_entry_controls MSG

  Returns an array of controls returned with the given entry. If not MSG
  is given as a paramater then current message/entry is used.

  Example:

    my @sctrls = $ld->get_entry_controls($msg);
    foreach $ctrl (@sctrls) {
        print "control oid is ".$self->get_control_oid($ctrl)."\n";
    }

=item get_values ATTR

  Obtain a list of all values associated with a given attribute.
  Returns an empty list if none are available.

  Example:

    @values = $ld->get_values("cn");

  This would put all the 'cn' values for $entry into the array @values.

=item get_values_len ATTR

  Retrieves a set of binary values for the specified attribute.

  Example:

    @values = $ld->get_values_len("jpegphoto");

  This would put all the 'jpegphoto' values for $entry into the array @values.
  These could then be written to a file, or further processed.

=item is_ldap_url URL

  Checks to see if a specified URL is a valid LDAP Url.  Returns 0 on false
  and 1 on true.

  Example:

    $isurl = $ld->is_ldap_url("ldap://x500.my.org/o=Org,c=US");

=item listen_for_changes BASEDN SCOPE FILTER ATTRS ATTRSONLY TIMEOUT SIZELIMIT COOKIE

  Experimental function which implements syncrepl API in
  refreshAndPersist mode. All but one arguments are the same as in search
  function. Argument 'cookie' is the special one here. It must be specified
  and is a file name in which cookie is to be stored. On a subsequent
  restart of the seach only the newer results will be returned than those
  indicated by the stored cookie. To refresh all entries, one would have to
  remove that file.

  This function is to be used in conjunction with next_changed_entries(...),
  there you will also find example of its usage.

=item msgfree

  Frees the current LDAP result.  Returns the type of message freed.

  Example:

    $type = $ld->msgfree;

=item msgtype MSG

  Returns the numeric id of a given message. If no MSG is given as a parameter
  then current message is used. Following types are recognized: LDAP_RES_BIND,
  LDAP_RES_SEARCH_ENTRY, LDAP_RES_SEARCH_REFERENCE, LDAP_RES_SEARCH_RESULT,
  LDAP_RES_MODIFY, LDAP_RES_ADD, LDAP_RES_DELETE, LDAP_RES_MODDN,
  LDAP_RES_COMPARE, LDAP_RES_EXTENDED, LDAP_RES_INTERMEDIATE, LDAP_RES_ANY,
  LDAP_RES_UNSOLICITED.

  Example:

    $type = $ld->msgtype

=item msgtype2str TYPE

  Returns string representation of a given numeric message type.

  Example:
    print "type = ".$ld->msgtype2str($ld->msgtype)."\n";

=item modify DN MOD

  Asynchronous method to modify an LDAP entry.  DN is the DN to
  modify and MOD contains a hash-table of attributes and values.  If
  multiple values need to be passed for a specific attribute, a
  reference to an array must be passed.

  Returns the MSGID of the modify operation.

  Example:

    %mods = (
      "telephoneNumber", "",     #remove telephoneNumber
      "sn", "Test",              #set SN to TEST
      "mail", ["me\@abc123.com","me\@second-home.com"],  #set multivalue 'mail'
      "pager", {"a",["1234567"]},  #Add a Pager Value
      "jpegphoto", {"rb",[$jpegphoto]},  # Replace Binary jpegphoto
    );

    $msgid = $ld->modify($entrydn,\%mods);

  The above would remove the telephoneNumber attribute from the entry
  and replace the "sn" attribute with "Test".  The value in the "mail"
  attribute for this entry would be replaced with both addresses
  specified in @mail.  The "jpegphoto" attribute would be replaced with
  the binary data in $jpegphoto.

=item modify_s DN MOD

  Synchronous version of modify method.  Returns an LDAP STATUS.  See the
  modify method for notes and examples of populating the MOD
  parameter.

  Example:

    $status = $ld->modify_s($entrydn,\%mods);

=item modrdn2 DN NEWRDN DELETE

  No longer available. Use function 'rename'.

=item modrdn2_s DN NEWRDN DELETE

  No longer available. Use function 'rename_s'.

=item next_attribute

  Similar to first_attribute, but obtains next attribute.
  Returns a string comtaining the attribute name.  An empty string
  is returned when no further attributes exist.

  Example:

    $attr = $ld->next_attribute;

=item next_changed_entries MSGID ALL TIMEOUT

 This function is too be used together with listen_for_changes(...) (see above).
 It returns an array of Entries, which has just changed. Each element in this
 array is a hash reference with two key value pairs, 'entry' which contains usual
 entry and 'state' which contain one of the following strings 'present', 'add',
 'modify' or 'delete'.

 Example:

    my $msgid = $ld->listen_for_changes('', LDAP_SCOPE_SUBTREE, "(cn=Dm*)", NULL, NULL,
                                    NULL, NULL, $cookie);

    while(1) {
        while( @entries = $ld->next_changed_entries($msgid, 0, -1) ) {
            foreach $entry (@entries) {
                print "entry dn is <".$ld->get_dn($entry->{'entry'})."> ".
                    $entry->{'state'}."\n";
            }
        }
    }

=item next_entry

  Moves internal pointer to the next entry in a chain of search results.

  Example:

    $entry = $ld->next_entry;

=item next_message

  Moves internal pointer to the next message in a chain of search results.

  Example:

    $msg = $ld->next_message;

=item parse_result MSG FREEMSG

  This function is used to retrieve auxiliary data associated with the
  message. The return value is a hashtable containing following kevalue
  pairs.
    'errcode'     -> numeric
    'matcheddn'   -> string
    'errmsg'      -> string
    'referrals'   -> array reference
    'serverctrls' -> array reference

  The FREEMSG parameter determines whether the parsed message is freed
  or not after the extraction. Any non-zero value will make it free the
  message. The msgfree() routine can also be used to free the message
  later.

=item perror MSG

  If an error occurs while performing an LDAP function, this procedure
  will display it.  You can also use the err and errstring methods to
  manipulate the error number and error string in other ways.

  Note that this function does NOT terminate your program.  You would
  need to do any cleanup work on your own.

  Example:

    $ld->perror("add_s");

=item rename DN NEWRDN NEWSUPER DELETE SCTRLS CCTRLS

  Asynchronous method to change the name of an entry. NEWSUPER is a new
  parent (superior entry).  If set to NULL then only the RDN is changed.
  Set DELETE to non-zero if you wish to remove the attribute values from the
  old name.  Returns a MSGID.

  Example:

    $msgid = $ld->rename("cn=Clayton Donley, o=Motorola, c=US", \
        "cn=Clay Donley", NULL, 0);

=item rename_s DN NEWRDN NEWSUPER DELETE SCTRLS CCTRLS

  Synchronous method to change the name of an entry. NEWSUPER is a new
  parent (superior entry).  If set to NULL then only the RDN is changed.
  Set DELETE to non-zero if you wish to remove the attribute values from the
  old name.  Returns a LDAP STATUS.

  Example:

    $status = $ld->rename("cn=Clayton Donley, o=Motorola, c=US", \
        "cn=Clay Donley", NULL, 0);

=item result MSGID ALL TIMEOUT

  Retrieves the result of an operation initiated using an asynchronous LDAP
  call.  It calls internally ldap_result function.  Returns LDAP message or
  undef if error. Return value of ldap_result call stored in $ld->{"status"}
  and is set -1 if something wrong happened, 0 if specified timeout was
  exceeded or type of the returned message.

  MSGID is the MSGID returned by the Asynchronous LDAP call.  Set ALL to
  0 to receive entries as they arrive, or non-zero to receive all entries
  before returning.  Set TIMEOUT to the number of seconds to wait for the
  result, or -1 for no timeout.

  Example:

    $entry = $ld->result($msgid, 0, 1);
    print "msgtype = ".$ld->msgtype2str($ld->{"status"})."\n";

=item result_entry

  This function is a shortcut for moving pointer along the chain of entries
  in the result. It is used instead of first_entry and next_entry functions.

  Example
    while( $entry = $ld->result_entry ) {
        print "dn = ".$ld->get_dn($entry)."\n";
    }

=item result_message

  This function is a shortcut for moving pointer along the chain of messages
  in the result. It is used instead of first_message and next_message functions.

  Example
    while( $msg = $ld->result_message ) {
        $msgtype = $self->msgtype($msg);
    }

=item search BASE SCOPE FILTER ATTRS ATTRSONLY

  Begins an asynchronous LDAP search.  Returns a MSGID or -1 if an
  error occurs.  BASE is the base object for the search operation.
  FILTER is a string containing an LDAP search filter.  ATTRS is a
  reference to an array containing the attributes to return.  An
  empty array would return all attributes.  ATTRSONLY set to non-zero
  will only obtain the attribute types without values.

  SCOPE is one of the following:
        LDAP_SCOPE_BASE
        LDAP_SCOPE_ONELEVEL
        LDAP_SCOPE_SUBTREE

  Example:

    @attrs = ("cn","sn");    # Return specific attributes
    @attrs = ();             # Return all Attributes

    $msgid = $ld->search("o=Motorola, c=US", LDAP_SCOPE_SUBTREE, \
        "(sn=Donley), \@attrs, 0);

=item search_s BASE SCOPE FILTER ATTRS ATTRSONLY (rewrite XXX)

  Performs a synchronous LDAP search.  Returns an LDAP STATUS.  BASE
  is the base object for the search operation.  FILTER is a string
  containing an LDAP search filter.  ATTRS is a reference to an array
  containing the attributes to return.  An empty array would return all
  attributes.  ATTRSONLY set to non-zero will only obtain the attribute
  types without values.

  SCOPE is one of the following:
        LDAP_SCOPE_BASE
        LDAP_SCOPE_ONELEVEL
        LDAP_SCOPE_SUBTREE

  Example:

    @attrs = ("cn","sn");    # Return specific attributes
    @attrs = ();             # Return all attributes

    $status = $ld->search_s("o=Motorola, c=US",LDAP_SCOPE_SUBTREE, \
        "(sn=Donley)",\@attrs,0);

=item search_st BASE SCOPE FILTER ATTRS ATTRSONLY TIMEOUT (rewrite/remove XXX)

  Performs a synchronous LDAP search with a TIMEOUT.  See search_s
  for a description of parameters.  Returns an LDAP STATUS.  Results are
  put into RESULTS.  TIMEOUT is a number of seconds to wait before giving
  up, or -1 for no timeout.

  Example:

    $status = $ld->search_st("o=Motorola, c=US",LDAP_SCOPE_SUBTREE, \
        "(sn=Donley),[],0,3);

=item unbind SCTRLS CCTRLS

  Unbind LDAP connection with specified SESSION handler.

  Example:

    $ld->unbind;

=item url_parse URL

  Parses an LDAP URL into separate components.  Returns a HASH reference
  with the following keys, if they exist in the URL:

  host      - LDAP Host
  port      - LDAP Port
  dn        - LDAP Base DN
  attr      - LDAP Attributes to Return (ARRAY Reference)
  filter    - LDAP Search Filter
  scope     - LDAP Search Scope
  options   - Mozilla key specifying LDAP over SSL

  Example:

    $urlref = $ld->url_parse("ldap://ldap.my.org/o=My,c=US");

=item url_search URL ATTRSONLY

  Perform an asynchronous search using an LDAP URL.  URL is the LDAP
  URL to search on.  ATTRSONLY determines whether we are returning
  the values for each attribute (0) or only returning the attribute
  names (1).  Results are retrieved and parsed identically to a call
  to the search method.

  Returns a non-negative MSGID upon success.

  Example:

    $msgid = $ld->url_search($my_ldap_url, 0);

=item url_search_s URL ATTRSONLY

  Synchronous version of the url_search method.  Results are retrieved
  and parsed identically to a call to the search_s method.

  Returns LDAP_SUCCESS upon success.

  Example:

    $status = $ld->url_search_s($my_ldap_url, 0);

=item url_search_st URL ATTRSONLY TIMEOUT

  Similar to the url_search_s method, except that it allows a timeout
  to be specified.  The timeout is specified as seconds.  A timeout of
  0 specifies an unlimited timeout.  Results are retrieved and parsed
  identically to a call to the search_st method.

  Returns LDAP_SUCCESS upon success.

  Example:

    $status = $ld->url_search_s($my_ldap_url,0,2);

=item whoami SCTRLS CCTRLS

  Asynchronous method for invoking an LDAP whoami extended operation. 

  Returns a non-negative MSGID upon success.
      
  Examples:
  
    $msgid = $ld->whoami();

=item whoami_s AUTHZID SCTRLS CCTRLS

  Synchronous method for invoking an LDAP whoami extended operation.
  
  Returns LDAP_SUCCESS upon success.
    
  Examples:
  
    $status = $ld->whoami_s(\$authzid);

=back

=head1 AUTHOR

Clayton Donley, donley@wwa.com
http://miso.wwa.com/~donley/

=head1 SEE ALSO

perl(1).

=cut
