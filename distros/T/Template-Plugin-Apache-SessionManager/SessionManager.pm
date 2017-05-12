package Template::Plugin::Apache::SessionManager;

use Apache::SessionManager;
use Template::Plugin;
use vars qw( $VERSION );
use base qw( Template::Plugin );
use strict;

$VERSION = '0.02';

sub new {
	my ($class, $context, @params) = @_; 
	my $session = Apache::SessionManager::get_session(Apache->request);
	bless {
		_CONTEXT => $context,
		session  => $session,
	}, $class;
}

sub get {
	my $self = shift;
	my @args = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
	if ( ! @args ) {
		@args = keys %{$self->{session}};
	}
	my @ary;
	foreach ( @args ) {
		push @ary, $self->{session}->{$_};
	}
	return @ary;
}

sub set {
	my ($self, @args) = @_;
	my $config = @args && ref $args[-1] eq 'HASH' ? pop(@args) : {};
	foreach ( keys %$config ) {
		# to avoid ovverride session special keys
		next if /^_session/;
		$self->{session}->{$_} = $config->{$_};
	}
	return '';
}

sub delete {
	my $self = shift;
	my @args = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;
	foreach ( @args ) {
		# to avoid ovverride session special keys
		next if /^_session/;
		delete $self->{session}->{$_};
	}
	return '';
}

sub destroy {
	my $self = shift;
	Apache::SessionManager::destroy_session(Apache->request);
}

1;

__END__

=pod 

=head1 NAME

Template::Plugin::Apache::SessionManager - Session manager Template Toolkit plugin 

=head1 SYNOPSIS

   [% USE my_sess = Apache.SessionManager %]

   # Getting single session value
   SID = [% my_sess.get('_session_id') %]

   # Getting multiple session values
   [% FOREACH s = my_sess.get('_session_id','_session_timestamp') %]
   * [% s %]
   [% END %]
   # same as
   [% keys = ['_session_id','_session_timestamp'];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]
   [% END %]

   # Getting all session values
   [% FOREACH s = my_sess.get %]
   * [% s %]
   [% END %]

   # Setting session values:
   [% my_sess.set('foo' => 10, 'bar' => 20, ...) %]

   # Deleting session value(s)
   [% my_sess.delete('foo', 'bar') %]
   # same as
   [% keys = ['foo', 'bar'];
      my_sess.delete(keys) %]

   # Destroying session
   [% my_sess.destroy %]

=head1 DESCRIPTION

This Template Toolkit plugin provides an interface to L<Apache::SessionManager|Apache::SessionManager>
module wich provides a session manager for a web application. 
This modules allows you to integrate a transparent session management into your
template documents (it handles for you the cookie/URI session tracking management
of a web application)

An C<Apache.SessionManager> plugin object can be created as follows:

   [% USE my_sess = Apache.SessionManager %]

or directly: 

   [% USE Apache.SessionManager %]

This restore a pre-existent session (or create new if this fails).
You can then use the plugin methods.

=head1 METHODS

=head2 get([array])

Reads a session value(s) and returns an array containing the keys values:

   Session id is [% my_sess.get('_session_id') %]

   [% FOREACH s = my_sess.get('foo', 'bar') %]
   * [% s %]
   [% END %]

Also it is possible to call C<get> method:

   [% keys = [ 'foo', 'bar' ];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]
   [% END %]

Called with no args, returns all keys values.

=head2 set(hash)

Set session values 

   [% my_sess.set('foo' => 10, 'bar' => 20, ...) %]

Called with no args, has no effects.

=head2 delete(array)

Delete session values 

   [% my_sess.delete('foo', 'bar', ...) %]

Also it is possible to call C<delete> method:

   [% keys = [ 'foo', 'bar' ];
      my_sess.delete(keys) %]

Called with no args, has no effects.

=head2 destroy

Destroy current session

   [% my_sess.destroy %]

=head1 WHAT DOES Apache::SessionManager DO

L<Apache::SessionManager|Apache::SessionManager> is a HTTP session manager wrapper around 
L<Apache::Session|Apache::Session> (it provides a persistence 
mechanism for data associated with a session between a client and the server).

L<Apache::SessionManager|Apache::SessionManager> allows you to integrate a transparent session 
management into your web application (it handles for you the cookie/URI session tracking management).

A session is a set of interactions (HTTP transactions). 
For example, a visitor may add items to be purchased to a shopping cart and the 
contents of the cart may be made visible by several different pages the visitor views 
during the purchase process.

=head1 USING Apache::Template

This section illustrates how to use session manager TT2 plugin for use within
L<Apache::Template|Apache::Template> mod_perl extension.

The L<Apache::Template|Apache::Template> module provides a simple interface to the Template Toolkit 
allowing Apache to serve directly TT2 files.

=head2 CONFIGURATION VIA I<httpd.conf>

In I<httpd.conf> (or any files included by the C<Include> directive):

   <IfModule mod_perl.c>
      PerlModule Apache::Template

      TT2Trim             On
      TT2PostChomp        On
      TT2EvalPerl         On
      TT2Params           uri env params
      TT2IncludePath      /usr/local/apache/htdocs/tt2/includes
      TT2PreProcess       config header
      TT2PostProcess      footer

      PerlModule Apache::SessionManager
      PerlTransHandler Apache::SessionManager

      <LocationMatch "\.tt2$">

         SetHandler perl-script
         PerlHandler Apache::Template

         PerlSetVar SessionManagerTracking On
         PerlSetVar SessionManagerExpire 600
         PerlSetVar SessionManagerInactivity 60
         PerlSetVar SessionManagerName TT2SESSIONID
         PerlSetVar SessionManagerDebug 5
         PerlSetVar SessionManagerStore File
         PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_session_data"

      </LocationMatch>
   </IfModule>   

=head2 CONFIGURATION VIA I<.htaccess>

In the case you don't have access to I<httpd.conf>, you can put similar directives 
directly into an I<.htaccess> file:

   <IfModule mod_perl.c>
      PerlModule Apache::Template
      <FilesMatch "\.tt2$">

         SetHandler perl-script
         PerlHandler Apache::Template

         PerlHeaderParserHandler Apache::SessionManager
         PerlSetVar SessionManagerTracking On
         PerlSetVar SessionManagerExpire 600
         PerlSetVar SessionManagerInactivity 60
         PerlSetVar SessionManagerName TT2SESSIONID
         PerlSetVar SessionManagerDebug 5
         PerlSetVar SessionManagerStore File
         PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_session_data"

      </FilesMatch>
   </IfModule>   

The only difference is that you cannot use C<Location> directive (I used C<FilesMatch>)
and you must install L<Apache::SessionManager|Apache::SessionManager> in 
C<Header parsing> phase of Apache request instead of C<URI translation> phase.

Now you can use C<Template:Plugin::Apache::SessionManager> plugin by
'USE' it in TT2 template file. This is a I<session.tt2> TT2 template: 

   [% USE my_sess = Apache.SessionManager %]
   <HTML>
   <HEAD>
   <TITLE>Session management with Apache::Template</TITLE>
   <BODY>

   The Session Dump
   [% USE dumper %]
   <PRE>
   [% dumper.dump(my_sess.session) %]
   </PRE>

   <H3>Getting session values</H3>
   Sigle session value<BR>
   ID is [% my_sess.get('_session_id') %]<P>

   Multiple session values<BR>
   [% FOREACH s = my_sess.get('_session_id','_session_timestamp') %]
   * [% s %]<BR>
   [% END %]<P>

   Multiple values by array ref<BR>
   [% keys = [ '_session_id', '_session_start' ];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]<BR>
   [% END %]

   All session values<BR>
   [% FOREACH s = my_sess.get %]
   * [% s %]<BR>
   [% END %]

   <H3>Setting session values:</H3>
   ID: [% my_sess.set('foo' => 10, 'bar' => 20, '_session_test' => 'test') %]<BR>

   </BODY>
   </HTML>   

Save it under the root web directory and launch it with http://localhost/session.tt2

This is an example of deleting session keys and destroying session itself:

   [% USE my_sess = Apache.SessionManager %]
   <HTML>
   <HEAD>
   <TITLE>Session management with Apache::Template</TITLE>
   <BODY>
   <PRE>
   [% USE dumper %]
   [% dumper.dump(my_sess.session) %]
   </PRE>

   <H3>Delete session values:</H3>
   [% my_sess.delete('foo','bar','_session_id') %]<BR>

   Delete session values by array ref:
   [% keys = ['foo','bar','_session_id'];
      my_sess.delete(keys) %]<BR>

   <H3>Destroy session</H3>
   [% my_sess.destroy %]<BR>

   </BODY>
   </HTML>   

=head2 NOTES ON USING I<.htaccess> INSTEAD OF I<httpd.conf>

=over 4

=item *

In this cases it is necessary to install L<Apache::SessionManager|Apache::SessionManager> 
in C<Header parsing> phase and not into C<URI translation> phase (in this phase, I<.htaccess> 
hasn't yet been processed).

=item *

Using I<.htaccess>, it is possible to use only cookies for the session tracking.

=back

=head1 USING CGI scripts 

This section illustrates how to use session manager TT2 plugin for use in CGI scripts
under L<Apache::Registry|Apache::Registry> or L<Apache::PerlRun|Apache::PerlRun> environment. 

=head2 CONFIGURATION VIA I<httpd.conf>

This example assumes that you can access to I<httpd.conf>. If not, you must
see the C<NOTES ON USING .htaccess INSTEAD OF httpd.conf> on previous section
about configuring it via I<.htaccess>.

   <IfModule mod_perl.c>
      Alias /perl/ /usr/local/apache/perl-scripts/ 
      PerlModule Apache::SessionManager
      PerlTransHandler Apache::SessionManager
      <Location /perl> 
         SetHandler perl-script
         PerlHandler Apache::Registry
         PerlSendHeader On
         PerlSetupEnv   On
         Options ExecCGI 

         PerlSetVar SessionManagerTracking On
         PerlSetVar SessionManagerExpire 600
         PerlSetVar SessionManagerInactivity 60
         PerlSetVar SessionManagerName TT2SESSIONID
         PerlSetVar SessionManagerDebug 5
         PerlSetVar SessionManagerStore File
         PerlSetVar SessionManagerStoreArgs "Directory => /tmp/apache_session_data"
      </Location>
   </IfModule>   

This is the simple CGI script I<session.cgi>:

   #!/usr/bin/perl

   use strict;
   use Template;

   my $file = 'session.tt2';
   my $vars = {
      title  => "Session management in a CGI Apache::Registry environment\n"
   };

   my $template = Template->new();
   $template->process($file, $vars)
      || die "Template process failed: ", $template->error(), "\n";

and this is a I<session.tt2> TT2 template (it's the same than the L<Apache::Template|Apache::Template> 
version!)

   [% USE my_sess = Apache.SessionManager %]
   <HTML>
   <HEAD>
   <TITLE>[% title %]</TITLE>
   <BODY>

   The session dump
   [% USE dumper %]
   <PRE>
   [% dumper.dump(my_sess.session) %]
   </PRE>

   <H3>Getting session values</H3>
   Sigle session value<BR>
   ID is [% my_sess.get('_session_id') %]<P>

   Multiple session values<BR>
   [% FOREACH s = my_sess.get('_session_id','_session_timestamp') %]
   * [% s %]<BR>
   [% END %]<P>

   Multiple values by array ref<BR>
   [% keys = [ '_session_id', '_session_start' ];
      FOREACH s = my_sess.get(keys) %]
   * [% s %]<BR>
   [% END %]

   All session values<BR>
   [% FOREACH s = my_sess.get %]
   * [% s %]<BR>
   [% END %]

   <H3>Setting session values:</H3>
   ID: [% my_sess.set('foo' => 10, 'bar' => 20, '_session_test' => 'test') %]<BR>

   </BODY>
   </HTML>  

Save both into the I</usr/local/apache/perl-scripts> directory and launch
http://localhost/perl/session.cgi

=head1 AUTHORS

Enrico Sorcinelli <enrico@sorcinelli.it>

=head1 BUGS 

This library has been tested by the author with Perl versions 5.005,
5.6.0 and 5.6.1 on different platforms: Linux 2.2 and 2.4, Solaris 2.6
and 2.7.

Send bug reports and comments to: enrico@sorcinelli.it.
In each report please include the version module, the Perl version,
the Apache, the mod_perl version and your SO. If the problem is 
browser dependent please include also browser name and
version.
Patches are welcome and I'll update the module if any problems 
will be found.

=head1 VERSION

Version 0.02

=head1 SEE ALSO

Apache::SessionManager, Template, Apache::Template, Apache::Registry, 
Apache::PerlRun, Apache, perl

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001-2003 Enrico Sorcinelli. All rights reserved.
This program is free software; you can redistribute it 
and/or modify it under the same terms as Perl itself. 

=cut
