package RTx::EmailCompletion;

use strict;
use RT::Users;

our $VERSION = "0.06";

use constant DEBUG => 0;

sub search_rdbms {
    my $Email = shift;
    my $CurrentUser = shift;

    return unless $CurrentUser->Privileged() or defined $RT::EmailCompletionUnprivileged;

    my @emails;

    my $Users = RT::Users->new( $CurrentUser );
    foreach my $field (@{$RT::EmailCompletionSearchFields}) {
	$Users->Limit(SUBCLAUSE => 'EmailCompletion', ALIAS => 'main', FIELD => $field, OPERATOR => $RT::EmailCompletionSearch, VALUE => $Email, ENTRYAGGREGATOR => 'OR');
    }
 
    $RT::Logger->debug($Users->BuildSelectQuery);

    my @users;
    while (my $User = $Users->Next()) {
	next if $User->id == $RT::Nobody->id;

	# some cleaning on emailaddress
	next if $User->EmailAddress !~ m{[a-zA-Z0-9_.-]+@[^.]+\.[^.]};
	next if $User->EmailAddress =~ m{[,?!/;\\]};

	push @users, $User;
    }

    # if you're privileged user you can see anybody
    #
    # if you're not by default you can see nobody 
    # if RT::EmailCompletionUnprivileged is set to anybody you can see anybody
    # else you can see only privileged users

    if ( $CurrentUser->Privileged() or $RT::EmailCompletionUnprivileged eq 'everybody' ) {
	# Ok, show everybody

    } elsif ( $RT::EmailCompletionUnprivileged eq 'privileged' ) {
	@users = grep { $_->Privileged()  } @users;

    } elsif ( ref($RT::EmailCompletionUnprivileged) eq 'Regexp' ) {
	@users = grep { $_->EmailAddress() =~ m/$RT::EmailCompletionUnprivileged/ } @users;

    } else {
	@users = ();
    }

    my @email = map { $_->EmailAddress() } @users;
}

# we dynamically build search function

our $AUTOLOAD;
sub AUTOLOAD {
    (my $function = $AUTOLOAD) =~ s/.*:://;
    die "Unable to find search function in AUTOLOAD" unless $function eq 'search';

    my $mod_ldap;
    if ($RT::EmailCompletionLdapServer and not $RT::EmailCompletionLdapDisabled) {
	eval {
	    require RTx::EmailCompletion::Ldap;
	};
	if ($@) {
	    $RT::Logger->crit("Unable to load RTx::EmailCompletion::Ldap, perhaps you forgot to install Net::LDAP: $@\n");
	} else {
	    $mod_ldap = 1;
	}
    }
    my $str = 'sub search { my (@emails, @ldaps);';
    $str   .= '@emails = search_rdbms(@_);'                            unless $RT::EmailCompletionRdbmsDisabled;
    $str   .= '@ldaps  = RTx::EmailCompletion::Ldap::search_ldap(@_);' if $mod_ldap;
    $str   .= 'return (\@emails, \@ldaps); }';

    $RT::Logger->debug("function used is $str\n") if DEBUG;

    eval $str;
    goto &search;
}


1;

__END__

=head1 NAME

RTx::EmailCompletion - Add auto completion on RT email fields

=head1 VERSION

This document describes version 0.06 of RTx::EmailCompletion.

=head1 DESCRIPTION

I'm so tired to type email address by hand that I've done this module
to add AJAX autocompletion on all email field of RT. As adding
completion is dynamic, it should work on most RT releases (see later
if it's not the case).

There's 4 S<things :>

=over

=item *

a small web service C<html/Ajax/EmailCompletion> which search in all
known users in the S<database ;>

=item *

prototype library to manipulate DOM and scriptaculous library to
S<autocomplete ;>

=item *

a small javascript which parse html pages and add autocomplete on
known input tags.

=item *

a perl module to handle all the logic

=back

=head1 INSTALLATION

if upgrading from a previous release see later UPGRADE FROM PREVIOUS RELEASE

if you upgrade from a version older than 0.05 of this module with RT >=
3.8, see later SCRIPTACULOUS AND RT 3.8

Install it like a standard perl module :

 RTHOME=/opt/rt3 perl Makefile.PL
 make
 make install

=head1 CONFIGURATION

In RT 3.8 and later, to enable EmailCompletion plugin, you must add
something like that in your etc/RT_SiteConfig.pm :

    Set(@Plugins,(qw(RTx::EmailCompletion)));

This section is fairly long but you don't really need to read it if
you just want the basic : autocompletion only for privileged users
against all registred users of RT database.

=head2 unprivileged users autocompletion

By default, completion works only for privileged users.

You can activate it for unprivileged users (in the SelfService) by
setting $EmailCompletionUnprivileged in
F<RTHOME/etc/RT_SiteConfig.pm>. There's three ways :

=over

=item *
show everybody

  Set($EmailCompletionUnprivileged,"everybody");

B<Be careful>, this will also show all yours LDAP users.

=item *
show only privileged users

  Set($EmailCompletionUnprivileged,"privileged");

This won't show LDAP users

=item *
show only email matching a regexp

  Set($EmailCompletionUnprivileged, qr/\@my\.corp\.domain$/ );

This will also show LDAP user mails that matchs the regexp

=back

=head2 change the database clause to search email

You can also change the operator used in the C<where> clause to search
email with the global var $RT::EmailCompletionSearch. The default one
is C<LIKE>.

To change it, add a line like this in F<RTHOME/etc/RT_SiteConfig.pm> :

 Set($EmailCompletionSearch, "STARTSWITH");

This variable can take the values C<LIKE>, C<STARTSWITH> and
C<ENDSWITH>.

By default, the plugin searches on Users.EmailAddress.

You can change where it searches by setting $EmailCompletionSearchFields
in RTHOME/etc/RT_SiteConfig.pm to an arrayref of fields from the
Users table.

   Set( $EmailCompletionSearchFields, [qw(EmailAddress RealName Name)] );

This would allow you to search by usernames, full names and email addresses

=head2 LDAP configuration

Starting with RTx::EmailCompletion 0.03, autocompletion works with LDAP
servers.

If you already have installed and configured LDAP authentication
overlay, this configuration will be used and it should/could work just
as it is.

The following configuration parameters applied :

=over

=item *
EmailCompletionLdapServer : the ldap server (mandatory)

  Set($EmailCompletionLdapServer, "my.ldap.server");

If not set, RTx::EmailCompletion will search for LdapServer parameter
(configured for the LDAP RT authentification layout and some others
LDAP RT extensions).

=item *
EmailCompletionLdapBase : the ldap base (mandatory)

  Set($EmailCompletionLdapBase, "dc=debian,dc=org");

If not set, RTx::EmailCompletion will search for LdapBase parameter
(configured for the LDAP RT authentification layout and some others
LDAP RT extensions).

=item *
EmailCompletionLdapUser : the ldap user if you need authentication

  Set($EmailCompletionLdapUser, "myldapuser");

If not set, RTx::EmailCompletion will search for LdapUser parameter
(configured for the LDAP RT authentification layout and some others
LDAP RT extensions).

=item *
EmailCompletionLdapPass : the ldap password if you need authentication

  Set($EmailCompletionLdapPass, "mypassword");

If not set, RTx::EmailCompletion will search for LdapPass parameter
(configured for the LDAP RT authentification layout and some others
LDAP RT extensions).

=item *
EmailCompletionLdapFilter : the ldap filter if needed

  Set($EmailCompletionLdapFilter, "(objectclass=person)");

If not set, RTx::EmailCompletion will search for LdapFilter parameter
(configured for the LDAP RT authentification layout).

=item *
EmailCompletionLdapAttrSearch : the ldap search attributes

  Set($EmailCompletionLdapAttrSearch, [qw/mail cn/]);

Default value is mail.

=item *
EmailCompletionLdapAttrShow : the mail attribute name

  Set($EmailCompletionLdapAttrShow, "mail");

Default value is mail

=item *
EmailCompletionLdapMinLength : minimum parameter length to send an ldap request

  Set(EmailCompletionLdapMinLength, 6);

Default value is 4

=back

The minimum LDAP configuration look somethink like this :

  Set($EmailCompletionLdapServer, "db.debian.org");
  Set($EmailCompletionLdapBase, "dc=debian,dc=org");

You can disable ldap completion (useful if you have installed ldap
authentication overlay and you don't want ldap completion) with :

  Set($EmailCompletionLdapDisabled, 1);

If you want to keep only LDAP completion, you can also disable RDBMS :

  Set($EmailCompletionRdbmsDisabled, 1);

The given value must be true for perl.

=head1 HOW TO ADD FIELD TO AUTOCOMPLETION

If you find email field without autocomplete, you can modify
C<html/NoAuth/js/emailcompletion.js> to handle this field (and email
me to patch this module).

At the beginning of this file you will find two global vars
C<multipleCompletion> and C<singleCompletion>. They are array of
regexp.

Regexp must match all the word because C<^> and C<$> are added for
matching. So if you want to match C<Field1> and C<Field2> you must add
something like C<Field.> or better C<Field[12]>.

To verify that javascript find your input tag, you can uncomment the
line just after the "DEBUGGING PURPOSE" one. All input tags find by
the script will appear with a big red border.

=head1 UPGRADE FROM PREVIOUS RELEASE

Because of a change in Makefile.PL, if you upgrade from a previous
release, you should delete everything from this package. You can find

  find RTHOME | grep -i emailcompletion

=head1 SCRIPTACULOUS AND RT 3.8

RT 3.8 and later come with their own scriptaculous library. So if you
have installed an release older than 0.05 of this module with RT 3.8
and later, the original scriptaculous will be overriden by this
module.

The best solution is to remove RTHOME/share/html/NoAuth/js/ and copy
RTSOURCE/share/html/NoAuth/js/ to RTHOME/share/html/NoAuth/.

This release is not subject to this problem.

=head1 HISTORY

The first version (unreleased) modify html pages. The better method
actually used allow this module to be compatible with, virtually, all
RT release.

=head1 AUTHORS

Nicolas Chuche E<lt>nchuche@barna.beE<gt>

=head1 COPYRIGHT

Copyright 2007 by Nicolas Chuche E<lt>nchuche@barna.beE<gt>

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

All Scriptaculous and Prototype program are placed under MIT licence
and are copyrighted by their owners (see top of files).

=cut
