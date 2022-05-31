use strict;
use warnings;
package Rubric::WebApp::URI 0.157;
# ABSTRACT: URIs for Rubric web requests

#pod =head1 DESCRIPTION
#pod
#pod This module provides methods for generating the URIs for Rubric requests.
#pod
#pod =cut

use Rubric::Config;
use Scalar::Util ();

#pod =head1 METHODS
#pod
#pod =head2 root
#pod
#pod the URI for the root of the Rubric; taken from uri_root in config
#pod
#pod =cut

sub root { Rubric::Config->uri_root }

#pod =head2 stylesheet
#pod
#pod the URI for the stylesheet
#pod
#pod =cut

sub stylesheet {
  my $href = Rubric::Config->css_href;
  return $href if $href;
  return Rubric::Config->uri_root . '/style/rubric.css';
}

#pod =head2 logout
#pod
#pod URI to log out
#pod
#pod =cut

sub logout { Rubric::Config->uri_root . '/logout' }

#pod =head2 login
#pod
#pod URI to form for log in
#pod
#pod =cut

sub login {
  my $uri = Rubric::Config->uri_root . '/login';
  $uri =~ s/^http:/https:/i if Rubric::Config->secure_login;
  return $uri;
}

#pod =head2 reset_password
#pod
#pod URI to reset user password
#pod
#pod =cut

sub reset_password {
	my ($class, $arg) = @_;
	my $uri = Rubric::Config->uri_root . '/reset_password';
	if ($arg->{user} and defined $arg->{reset_code}) {
		$uri .= "/$arg->{user}/$arg->{reset_code}";
	}
	return $uri;
}

#pod =head2 newuser
#pod
#pod URI to form for new user registration form;  returns false if registration is
#pod closed.
#pod
#pod =cut

sub newuser {
	return if Rubric::Config->registration_closed;
	return Rubric::Config->uri_root . '/newuser';
}

#pod =head2 entries(\%arg)
#pod
#pod URI for entry listing; valid keys for C<%arg>:
#pod
#pod  user - entries for one user
#pod  tags - arrayref of tag names
#pod
#pod =cut

sub entries {
	my ($class, $arg) = @_;
	$arg->{tags} ||= {};
  $arg->{tags} = { map { $_ => undef } @{$arg->{tags}} }
    if ref $arg->{tags} eq 'ARRAY';

	my $format = delete $arg->{format};

	my $uri = $class->root . '/entries';
	$uri .= "/user/$arg->{user}" if $arg->{user};
	$uri .= '/tags/' . join('+', keys %{$arg->{tags}}) if %{$arg->{tags}};
	for (qw(has_body has_link)) {
		$uri .= "/$_/" . ($arg->{$_} ? 1 : 0)
			if (defined $arg->{$_} and $arg->{$_} ne '');
	}
	$uri .= "/urimd5/$arg->{urimd5}" if $arg->{urimd5};
	$uri .= "?format=$format" if $format;
	return $uri;
}

#pod =head2 entry($entry)
#pod
#pod URI to view entry
#pod
#pod =cut

sub entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/entry/" . $entry->id;
}

#pod =head2 edit_entry($entry)
#pod
#pod URI to edit entry
#pod
#pod =cut

sub edit_entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/edit/" . $entry->id;
}

#pod =head2 delete_entry($entry)
#pod
#pod URI to delete entry
#pod
#pod =cut

sub delete_entry {
	my ($class, $entry) = @_;
	return unless Scalar::Util::blessed($entry) && $entry->isa('Rubric::Entry');

	return Rubric::Config->uri_root . "/delete/" . $entry->id;
}

#pod =head2 post_entry
#pod
#pod URI for new entry form
#pod
#pod =cut

sub post_entry { Rubric::Config->uri_root . "/post"; }

#pod =head2 by_date
#pod
#pod URI for by_date
#pod
#pod =cut

sub by_date {
	my ($class) = @_;
  shift;
  my $year = shift;
  my $month = shift;
  my $uri = '/calendar';
  $uri .= "/$year" if ($year);
  $uri .= "/$month" if ($month);

	Rubric::Config->uri_root . $uri;
}



#pod =head2 tag_cloud
#pod
#pod URI for all tags / tag cloud
#pod
#pod =cut

sub tag_cloud {
	my ($class) = @_;
	Rubric::Config->uri_root . "/tag_cloud";
}

#pod =head2 preferences
#pod
#pod URI for preferences form
#pod
#pod =cut


sub preferences { Rubric::Config->uri_root . "/preferences"; }

#pod =head2 verify_user
#pod
#pod URI for new entry form
#pod
#pod =cut

sub verify_user {
	my ($class, $user) = @_;
	Rubric::Config->uri_root . "/verify/$user/" . $user->verification_code;
}

#pod =head2 doc($doc_page)
#pod
#pod URI for documentation page.
#pod
#pod =cut

sub doc {
	my ($class, $doc_page) = @_;
	Rubric::Config->uri_root . "/doc/" . $doc_page;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rubric::WebApp::URI - URIs for Rubric web requests

=head1 VERSION

version 0.157

=head1 DESCRIPTION

This module provides methods for generating the URIs for Rubric requests.

=head1 PERL VERSION

This code is effectively abandonware.  Although releases will sometimes be made
to update contact info or to fix packaging flaws, bug reports will mostly be
ignored.  Feature requests are even more likely to be ignored.  (If someone
takes up maintenance of this code, they will presumably remove this notice.)
This means that whatever version of perl is currently required is unlikely to
change -- but also that it might change at any new maintainer's whim.

=head1 METHODS

=head2 root

the URI for the root of the Rubric; taken from uri_root in config

=head2 stylesheet

the URI for the stylesheet

=head2 logout

URI to log out

=head2 login

URI to form for log in

=head2 reset_password

URI to reset user password

=head2 newuser

URI to form for new user registration form;  returns false if registration is
closed.

=head2 entries(\%arg)

URI for entry listing; valid keys for C<%arg>:

 user - entries for one user
 tags - arrayref of tag names

=head2 entry($entry)

URI to view entry

=head2 edit_entry($entry)

URI to edit entry

=head2 delete_entry($entry)

URI to delete entry

=head2 post_entry

URI for new entry form

=head2 by_date

URI for by_date

=head2 tag_cloud

URI for all tags / tag cloud

=head2 preferences

URI for preferences form

=head2 verify_user

URI for new entry form

=head2 doc($doc_page)

URI for documentation page.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
