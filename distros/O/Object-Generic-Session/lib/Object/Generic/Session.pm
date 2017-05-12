package Object::Generic::Session;
#
# Object::Generic::Session is session object for
# web applications that defines a get/set interface
# consistent with Object::Generic and Class::DBI.
#
# See the end of this file for the documentation.
#  
# $Id: Session.pm 404 2005-11-29 19:53:19Z mahoney $    

use strict;
use warnings;
use base qw( Session Object::Generic );
use Object::Generic::False qw(false);
use Apache::Cookie;

our $VERSION = 0.12;

#
# Usage:  $session = new Object::Generic::Session(
#   session_config  => 
#      { Store      => 'MySQL', # SQLite, here, but it still wants this.
#        DataSource => "dbi:SQLite:dbname=$databasefile",
#        Lock       => 'Null',
#        Generate   => 'MD5',
#        Serialize  => 'Base64',
#      },
#   expires     => '+8h',
#   cookie_name => 'put some sort of site identifier here'
# )
sub new {
  my $class = shift;
  my %args  = @_;
  my $session_config = $args{session_config}
    or return "Oops - no session_config given.";
  my $cookie_name    = $args{cookie_name}
    or return "Oops - 'cookie_name' not defined.";
  my $expires        = $args{expires}         || '+8h';
  my $path           = $args{path}            || '/';
  my $r = Apache->request;  # See Apache::Cookie docs.

  # If the browser sent a cookie, get the session ID from it, and
  # use that ID to fetch the session data from the database.
  # If we didn't get a cookie, or if the matching session 
  # can't be found in the database, start a new session.
  # Tell Apache to set a cookie in the HTTPD headers with 
  # the session ID regardless.
  my $cookies      = Apache::Cookie->fetch;
  my $cookie       = $cookies ? $cookies->{$cookie_name} : undef;
  my $cookie_value = $cookie  ? $cookie->value           : undef;
  my $self         = Session->new($cookie_value, %$session_config)
                     || Session->new(undef, %$session_config);
  if (not $self){
    return 'Oops: unable to create a session with given session_config.';
  }
  ## May be used to count invocations for debuggin.
  # if ($self->get('__access_count'){
  #   $self->set('__access_count' => 1+$self->get('__access_count'))
  # }
  # else {
  #   $self->set('__access__count' => 0);
  # }
  Apache::Cookie->new($r,
       -name    =>  $cookie_name,
       -value   =>  $self->session_id,
       -expires =>  $expires,
       -path    =>  $path,
     )->bake;
  return bless $self, $class;
}

# Session has its own 'get' and 'exists' methods, 
# which are the ones found first in the inheritance chain.
# Here the behavior is changed slightly by returning
# an Object::Generic::False when the key doesn't exist.
sub get {
  my $self = shift;
  my ($key) = @_;
  return false unless $self->exists($key);
  return $self->SUPER::get($key);
}

# This fixes what seemed like a bug to me in how sessions were handled.
#
# If data within the session, say $session->foo->bar->baz 
# change without anything in $session->{} itself changing, 
# Session.pm won't know that the session needs to be written
# back out to the database, and thus the changes may not be saved.
#
# So, I force any 'set' operation to mark this session as modified.
# I'm not sure why this isn't the default.
# See Apache::Session's code for this make_modified routine.
sub set {
  my $self = shift;
  $self->make_modified();
  return $self->SUPER::set(@_);
}

1;

__END__

=head1 NAME

Object::Generic::Session - an apache session with an interface like Class::DBI.

=head1 SYNOPSIS

 # This example stores user data in a $session global
 # in an HTML::Mason web application framework.

 # -- file httpd.conf --          (Define the session global.)
 PerlAddVar MasonAllowGlobals $session

 # -- file htdocs/autohandler -   (Retrieve the session; process webpage.)
 % $session = new Object::Session::Generic( 
 %             session_config => { Store=>'MySQL', ... }, # See Session.pm
 %             cookie_name    => 'your cookie name here',
 %             expires        => '+8h',
 %            );
 % $m->call_next;
 % $session = undef;
 
 # -- file htdocs/file.html --    (Use the session to access key/value pairs.)
 <html>
 % if ($session->user){
    Hi <% $session->user->name %>.  Welcome back.
 % } else { 
    <form>
      Please log in: <input type="text" name="username" />
    </form>
 % }
 </html>
 <%args>
   $username => ''
 </%args>
 <%init>
   if ($username){
      $session->user( new Object::Generic( name => $username ));
   }
 </%init>

=head1 DESCRIPTION

Object::Generic::Session implements a perl object that 
inherits from both Session.pm (a variation on Apache::Session)
and Object::Generic.  

A Session.pm object allows you to get and set persistent key/value 
pairs with a syntax like $session->get($key) 
and $session->set(key => $value).

This package adds Object::Generic's other interfaces to the key/value
pairs, namely $session->key (equivalent to get($key)), 
$session->get_key, $session->key($value) (equivalent to set(key=>$value)),
and $session->set_key($value).  In addition, keys which aren't 
defined return an Object::Generic::False which allow method chaining
even if the key isn't defined.  Thus an expression like
$session->user->name won't crash even if $session->user is not defined.

Apache::Session, Apache::Cookie, Session.pm, and Object::Generic
are prerequisites for this package.  It has not been tested 
with Apache 2.x.

=head1 SEE ALSO

Object::Generic, Class::DBI, Apache::Session, Session, Apache::Cookie

=head1 AUTHOR

Jim Mahoney, Marlboro College E<lt>mahoney@marlboro.edu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Jim Mahoney

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


