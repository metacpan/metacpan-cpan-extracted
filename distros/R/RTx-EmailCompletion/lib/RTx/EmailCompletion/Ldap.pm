package RTx::EmailCompletion::Ldap;

use Net::LDAP;
use Net::LDAP::Constant qw(LDAP_SUCCESS LDAP_PARTIAL_RESULTS);
use Net::LDAP::Util qw (ldap_error_name);
use RT::Users;

sub search_ldap {
    my $param = shift;
    my $CurrentUser = shift;

    return if length($param) < $RT::EmailCompletionLdapMinLength;

    # if user isn't privileged and we want only show privileged user, return now
    return if not $CurrentUser->Privileged() and $RT::EmailCompletionUnprivileged eq 'privileged';

    my $ldap = new Net::LDAP($RT::EmailCompletionLdapServer);

    my $mesg = defined $RT::EmailCompletionLdapUser && $RT::EmailCompletionLdapUser ne '' ?
	$ldap->bind($RT::EmailCompletionLdapUser, password => $RT::EmailCompletionLdapPass)
	    : $ldap->bind();

    if ($mesg->code != LDAP_SUCCESS) {
	$RT::Logger->crit("Unable to bind to $RT::EmailCompletionLdapServer: ", ldap_error_name($mesg->code), "\n");
	return;
    }

    my $filter = "(|" . join('', map { "($_=*$param*)" } @{ $RT::EmailCompletionLdapAttrSearch }) . ")";
    $filter = "(&" . $RT::EmailCompletionLdapFilter . $filter . ")" if $RT::EmailCompletionLdapFilter;

    $RT::Logger->debug("LDAP filter is: $filter\n") if RTx::EmailCompletion::DEBUG;

    $mesg = $ldap->search(base   => $RT::EmailCompletionLdapBase,
			  filter => $filter,
			  attrs  => $RT::EmailCompletionLdapAttrShow);
    
    if ($mesg->code != LDAP_SUCCESS and $mesg->code != LDAP_PARTIAL_RESULTS)  {
	$RT::Logger->crit("Unable to search in LDAP: ", ldap_error_name($mesg->code), "\n");
    }

    my @emails = map { $_->get_attribute( $RT::EmailCompletionLdapAttrShow ) } $mesg->entries;

    @emails = grep { m/$RT::EmailCompletionUnprivileged/ } @emails
	if ref($RT::EmailCompletionUnprivileged) eq 'Regexp' and not $CurrentUser->Privileged();

    $mesg = $ldap->unbind();
    if ($mesg->code != LDAP_SUCCESS) {
	$RT::Logger->crit("Unable to unbind from LDAP:", ldap_error_name($mesg->code), "\n");
	return;
    }

    $RT::Logger->debug("emails returned are: @emails\n") if RTx::EmailCompletion::DEBUG;

    sort @emails;
}

1;
