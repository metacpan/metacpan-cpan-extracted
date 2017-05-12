package PHP::Session::DB;

use strict;
use DBI;
use URI::Escape;
use vars qw($VERSION);
$VERSION = 0.2;

use vars qw(%SerialImpl);
%SerialImpl = (
    php => 'PHP::Session::Serializer::PHP',
);

use UNIVERSAL::require;

sub _croak { require Carp; Carp::croak(@_) }
sub _carp  { require Carp; Carp::carp(@_) }

sub new {
  my($class, $sid, $opt) = @_;
  my %default = (
      serialize_handler => 'php',
      create            => 0,
      auto_save         => 0,
      DBTABLE => 'sessions',
      DBHOST => 'localhost',
      DBTYPE => 'mysql',
      DBPORT => 3306,
  );
  $opt ||= {};
  my $self = bless {
    %default,
    _dbh => undef,
    %$opt,
    _sid  => $sid,
    _data => {},
    _changed => 0,
  }, $class;
  $self->_db_connection;
  $self->_validate_sid;
  $self->_parse_session;
  return $self;
}

# accessors, public methods

sub id { shift->{_sid} }

sub get {
    my($self, $key) = @_;
    return $self->{_data}->{$key};
}

sub set {
    my($self, $key, $value) = @_;
    $self->{_changed}++;
    $self->{_data}->{$key} = $value;
}

sub unregister {
    my($self, $key) = @_;
    delete $self->{_data}->{$key};
}

sub unset {
    my $self = shift;
    $self->{_data} = {};
}

sub is_registered {
    my($self, $key) = @_;
    return exists $self->{_data}->{$key};
}

sub decode {
    my($self, $data) = @_;
    $self->serializer->decode($data);
}

sub encode {
    my($self, $data) = @_;
    $self->serializer->encode($data);
}

sub save {
    my $self = shift;
    if($self->{create}) {
      # First check if the session exists
      my $sth = $self->{_dbh}->prepare("SELECT SESSKEY FROM ".$self->{DBTABLE}." WHERE SESSKEY = '".$self->id."'");
      $sth->execute;
      my($sesskey) = $sth->fetchrow_array;
      if($sesskey eq $self->id) {
	_croak("There is a session with id ".$self->id." already");
      } else {
	$self->{_dbh}->do("INSERT INTO ".$self->{DBTABLE}." (SESSKEY,DATA) VALUES ('".$self->id."','".$self->encode($self->{_data})."')");
      }
    } else {
      $self->{_dbh}->do("UPDATE ".$self->{DBTABLE}." SET DATA = '".$self->encode($self->{_data})."' WHERE SESSKEY = '".$self->id."'");
    }
    $self->{_changed} = 0;  # init
}

sub destroy {
    my $self = shift;
    unlink $self->_file_path;
}

sub DESTROY {
    my $self = shift;
    if ($self->{_changed}) {
  if ($self->{auto_save}) {
      $self->save;
  } else {
      _carp("PHP::Session::DB: some keys are changed but not saved.") if $^W;
  }
    }
}

# private methods

sub _db_connection {
  my $self = shift;

  if(!exists $self->{DBNAME} || !exists $self->{DBTABLE} || !exists $self->{DBHOST} || !exists $self->{DBTYPE} || !exists $self->{DBUSER} || !exists $self->{DBPASSWD} || !exists $self->{DBPORT}) {
    _croak("There's a missing database argument");
  } elsif($self->{DBNAME} eq '' || $self->{DBTABLE} eq '' || $self->{DBHOST} eq '' || $self->{DBTYPE} eq '' || $self->{DBUSER} eq '' || $self->{DBPASSWD} eq '') {
    _croak("There's a missing database argument");
  }

  # Make database connection
  # DBType must be a valid DBI database driver
  my $dsn = "DBI:".$self->{DBTYPE}.":database=".$self->{DBNAME}.";host=".$self->{DBHOST}.";port=".$self->{DBPORT};
  my $dbh = DBI->connect($dsn, $self->{DBUSER}, $self->{DBPASSWD});
  _croak("Can't open database connection") unless $dbh;

  $self->{_dbh} = $dbh;
}

sub _validate_sid {
    my $self = shift;
    my($id) = $self->id =~ /^([0-9a-zA-Z]*)$/; # untaint
    defined $id or _croak("Invalid session id: ", $self->id);
    $self->{_sid} = $id;
}

sub _parse_session {
    my $self = shift;
    my $cont = $self->_slurp_content;
    if (!$cont && !$self->{create}) {
      _croak("Unknown session id");
    }
    $self->{_data} = $self->decode($cont);
}

sub serializer {
    my $self = shift;
    my $impl = $SerialImpl{$self->{serialize_handler}};
    $impl->require;
    return $impl->new;
}

sub _file_path {
    my $self = shift;
    #return File::Spec->catfile($self->{save_path}, 'sess_' . $self->id);
}

sub _slurp_content {
    my $self = shift;
    my $data = '';
    if(!$self->{create}) {
      my $sth = $self->{_dbh}->prepare("SELECT DATA FROM ".$self->{DBTABLE}." WHERE SESSKEY = '".$self->id."'");
      $sth->execute;
      $data = $sth->fetchrow_array;
      $data = uri_unescape($data);
      local $/ = undef;
    }
    return $data;
}

1;
__END__

=head1 NAME

PHP::Session::DB - read / write PHP sessions stored in data bases

=head1 SYNOPSIS

  use PHP::Session::DB;

  my $session = PHP::Session::DB->new($id, { DBUSER => $dbuser, DBPASSWD => $dbpasswd, DBNAME => $dbname });

  # session id
  my $id = $session->id;

  # get/set session data
  my $foo = $session->get('foo');
  $session->set(bar => $bar);

  # remove session data
  $session->unregister('foo');

  # remove all session data
  $session->unset;

  # check if data is registered
  $session->is_registered('bar');

  # save session data
  $session->save;

  # destroy session
  $session->destroy;

  # create a new session, if not existent
  $session = PHP::Session->new($new_sid, { %dbvars, create => 1 });

=head1 DESCRIPTION

PHP::Session::DB provides a way to read / write PHP4 sessions stored
on databases, with which you can make your Perl application session 
shared with PHP4.

=head1 OPTIONS

Constructor C<new> takes some options as hashref.

=over 4

=item DBTYPE

this is the type of database that will be used. It must be a valid DBI driver.
default: mysql.

=item DBNAME

this is the database name that will store the sessions table. This is a 
mandatory argument

=item DBTABLE

this is the table that stores the sessions data. default: sessions.

=item DBUSER

this is the username that will be used to connect to the data base.
This is a mandatory argument

=item DBPASSWD

DBUSER password. This is a mandatory argument

=item DBHOST

Database host. default: localhost.

=item DBPORT

Database port. default: 3306 (mysql default port).

=item serialize_handler

type of serialization handler. Currently only PHP default
serialization is supported.

=item create

whether to create session file, if it's not existent yet. default: 0

=item auto_save

whether to save modification to session file automatically. default: 0

Consider cases like this:

  my $session = PHP::Session->new($sid, { auto_save => 1 });
  $session->set(foo => 'bar');

  # Oops, you forgot save() method!

If you set C<auto_save> to true value and when you forget to call
C<save> method after parameter modification, this module would save
session file automatically when session object goes out of scope.

If you set it to 0 (default) and turn warnings on, this module would
give you a warning like:

  PHP::Session: some keys are changed but not modified.

=back

=head1 EXAMPLE

  use strict;
  use PHP::Session::DB;
  use CGI::Lite;
  my $session_name = 'PHPSESSID'; # change this if needed

  print "Content-type: text/plain\n\n";
  
  my $cgi = new CGI::Lite;
  
  my $cookies = $cgi->parse_cookies;
  if ($cookies->{$session_name}) {
     my $session = PHP::Session->new($cookies->{$session_name}, {DBUSER => 'uname, DBPASSWD => '123', DBNAME => 'dunno');
     # now, try to print uid variable from PHP session
     print "uid:",Dumper($session->get('uid'));
  } else {
     print "can't find session cookie $session_name";
  }


=head1 NOTES

=over 4

=item *

If you are using PHP::Session and want to swith to PHP::Session::DB, the only thing
you need to change is the way you call the C<new> method. It is necessary that you add the
C<DB> arguments (at least DBUSER, DBPASSWD and DBNAME) in order to get the module work
properly. 

=item *

Array in PHP is hash in Perl.

=item *

Objects in PHP are restored as objects blessed into
PHP::Session::Object (Null class) and original class name is stored in
C<_class> key.

=item *

Locking when save()ing data is acquired via exclusive C<flock>, same as
PHP implementation.

=item *

I have tested PHP::Session::DB only in MySQL databases, but you should not have
any kind of problem to get it work with another databases. If you have any problem
just send me an email.

=back

=head1 TODO

=over 4

=item *

Testing in databases such as PostgreSQL, Oracle, MSQL and others.

=back

=head1 AUTHOR

Roberto Alamos Moreno E<lt>ralamosm@cpan.orgE<gt>

based on PHP::Session written by 

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<PHP::Session>, L<Apache::Session::PHP>, L<WDDX>, L<Apache::Session>, L<CGI::kSession>

=cut
