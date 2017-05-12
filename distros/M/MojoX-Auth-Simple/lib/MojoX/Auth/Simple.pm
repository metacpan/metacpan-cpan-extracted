package MojoX::Auth::Simple;

use strict;
use warnings;
use base 'Mojo::Base';
use MojoX::Session;

our $VERSION = '0.04.02';

__PACKAGE__->attr(logged_in => 0);
__PACKAGE__->attr(loader    => sub { Mojo::Loader->new });
__PACKAGE__->attr(qw/session/);

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = $class->SUPER::new(%args);

    return $self;
}

sub log_in {
    my $self  = shift;
    my $uid   = shift;
    my $token = shift;

    die "self undefined" unless defined $self;
    die "session undefined" unless defined $self->session;
    _authenticate($self, $uid, $token) unless 'true' eq $self->session->data->{logged_in};
}

sub log_out {
    my $self = shift;
    
    if (is_logged_in($self)) {
	$self->session->data('logged_in' => 'false', 'uid' => '');
    }
}

sub is_logged_in {
    my $self = shift;

    if ($self->session->data->{logged_in}) {
        return $self->session->data->{uid};
    }
    return "";
}

sub load {
    my $self   = shift;
    my $session = shift || $self->session;

    die "session undefined" unless defined $session;
    die "session data undefined" unless defined $session->data;
    
    if ($session->load) {
        if ($session->is_expired) {
	    # purge old session
	    $session->clear;
	    $session->flush;
	    # make a new session
            $session->create;
	    $session->data('logged_in' => 'false');
        } else {
	    $session->extend_expires;
        }
    } else {
        $session->create;
        $session->data('logged_in' => 'false');
    }
    return $self->{session} = $session;
}

sub _authenticate {
    my ($self, $uid, $token) = @_;

    if ('guest' eq $uid ) {
	#warn "uid match";
	if ('guest' eq $token){
	    #warn "token match";
	    $self->session->data('logged_in' => 'true', 'uid' => $uid);
	    return 1;
	} else {
	    #warn "token match fails";
	}
    } else {
	#warn "uid match fails";
    }
    return 0;
}

=head1 NAME

MojoX::Auth::Simple - Perl extension for login authentication for Mojolicious

=head1 VERSION

Version 0.04.02

=head1 SYNOPSIS

    use MojoX::Auth::Simple;
    use Mojolicious::Lite;
    use MojoX::Session;
    use DBI;

    # fill in you $dbh details here...
    my $db_host = "...";
    my $db_name = "...";
    my $dsn     = "DBI:mysql:database=$db_name;host=$db_host;";
    my $user    = "...";
    my $pass    = "...";
    my $dbh     = DBI->connect($dsn, $user, $pass, {'RaiseError' => '1'});

    plugin session => {
      stash_key => 'session',
      transport => MojoX::Session::Transport::Cookie->new,
      store => MojoX::Session::Store::Dbi->new(dbh  => $dbh),
      expires_delta => 900,
    };

    any [qw/get post/] => '/' => sub {
      my $self       = shift;
      my $page_title = "Index - not logged in";
      my $template   = "index";
      my $layout     = "default";
      my $session    = $self->stash('session');
      my $auth       = MojoX::Auth::Simple->new();
      $auth->load($session);
      $page_title = 'Index - logged in' if $auth->is_logged_in();
      $self->stash(date => $date,
                   page_title => $page_title,
                   logged_in  => $auth->session->data->{logged_in},
                   template   => $template,
                   layout     => $layout,
          );
    } => 'index';

    @@ index.html.ep
    <h2>My appliction content goes here</h2><br>
    <h3><a href="<%= url_for 'index' %><%="?from_url=$this_url" %>">Index</a></h3>
    <h3><a href="<%= url_for 'edit' %><%="?from_url=$this_url" %>">Edit</a></h3>

    @@ layouts/default.html.ep
    <html>
      <head>
        <title>My Application - <%= $page_title %> - Default layout</title>
      </head>
      <body>
        <!-- Header region begin -->
        <% if('true' eq $logged_in) { %>
        <div>
          <div>Logged in; <form action="<%= url_for 'logout' %>" method="POST">
            <input type="submit" value="Logout"></form></div>
        <% } else { %>
          <div>Not logged in; <form action="<%= url_for 'login' %>" method="POST">
            <input type="submit" value="Login"></form></div>
        <% } %>
        </div>
        <!-- Content region begin -->
        <%= content %>
        <!-- Content region end -->
      </body>
    </html>

=head1 DESCRIPTION

The aim of this mobule is to provide a framework to allow a simple 
authentication model for Mojolicious.

This module will change and become a plugin like MojoX::Session.

=head2 EXPORT

None by default.

=head1 SUBROUTINES/METHODS

L<MojoX::Auth::Simple> inherits all methods from L<Mojo::Base> and implements the following new ones.

=head2 C<new>

    my $auth = MojoX::Auth::Simple->new();

Returns new L<MojoX::Auth> object.

=head2 C<log_in>

    my $auth = MojoX::Auth::Simple->new();
    $auth->log_in();

Sets the logged_in key in the session store to 'true' and adds the uid key
in the session store to the uid of the logged in user.

=head2 C<log_out>

    $auth->load($session);
    $auth->log_out();

Sets the logged_in key in the session store to 'false'.

=head2 C<is_logged_in>

    $auth->load($session);
    $name = $auth->is_logged_in();

Returns the name or uid of the user that is logged in, or an empty string if they are not.

=head2 C<load>

    $auth->load($session);

Adds the current session to the auth object to use it as a persistant store.

=head1 SEE ALSO

Please read the man pages for MojoX::Session to see how we are storing
the basic auth info in the session hash in the stash.

=head1 AUTHOR

Kim Hawtin

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-auth-simple at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Auth-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MojoX::Auth::Simple

=head1 ACKNOWLEDGEMENTS

Thanks to Justin Hawkins for help with the building module and
to Andy Kirkpatrick for debugging.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Kim Hawtin

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

=cut

1; # End of MojoX::Auth::Simple
