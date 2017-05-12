use strict;
use warnings;
package Net::Finger::Server;
{
  $Net::Finger::Server::VERSION = '0.004';
}
# ABSTRACT: a simple finger server

use Package::Generator;
use Sub::Exporter -setup => {
  collectors => [ '-run' => \'_run_server' ]
};

my %already;
sub _run_server {
  my ($class, $value) = @_;
  $value ||= {};

  my %config = %$value;

  $config{port} ||= 79;

  my $pkg = $class;
  if (my $isa = delete $config{isa}) {
    eval "require $isa; 1" or die;
    $pkg = $already{ $class, $isa } ||= Package::Generator->new_package({
      base => $class,
      isa  => [ $class, $isa ],
    });
  }

  my $server = $pkg->new(%config);
  $server->run;
}


#  {Q1}    ::= [{W}|{W}{S}{U}]{C}
#  {Q2}    ::= [{W}{S}][{U}]{H}{C}
#  {U}     ::= username
#  {H}     ::= @hostname | @hostname{H}
#  {W}     ::= /W
#  {S}     ::= <SP> | <SP>{S}
#  {C}     ::= <CRLF>


sub username_regex { qr{[a-z0-9.]+}i   }
sub hostname_regex { qr{[-_a-z0-9.]+}i }


sub listing_reply { return "listing of users rejected\n"; }


sub user_reply {
  my ($self, $username, $arg) = @_;
  return "query for information on alleged user <$username> rejected\n";
}


sub forward_reply {
  my ($self, $arg) = @_;
  return "finger forwarding service denied\n";
}


sub unknown_reply {
  my ($self, $query) = @_;
  return "could not understand query\n";
}

sub _read_input_line { return scalar <STDIN> }

sub _reply { print $_[1] }

sub process_request {
  my ($self) = @_;
  my $query = $self->_read_input_line;

  $query =~ s/[\x0d|\x0a]+\z//g;

  my $original = $query;

  my $verbose = $query =~ s{\A/W\s*}{};
  my $u_regex = $self->username_regex;
  my $h_regex = $self->hostname_regex;
  
  if ($query eq '') {
    $self->_reply( $self->listing_reply({ verbose => $verbose }));
    return;
  } elsif ($query =~ /\A$u_regex\z/) {
    $self->_reply($self->user_reply($query, { verbose => $verbose }));
    return;
  } elsif ($query =~ /\A($u_regex)?((?:\@$h_regex)+)\z/) {
    my ($username, $host_string) = ($1, $2);
    my @hosts = split /@/, $host_string;
    shift @hosts;

    $self->_reply(
      $self->forward_reply({
        username => $username,
        hosts    => \@hosts,
        verbose  => $verbose,
      }),
    );
    return;
  }

  $self->_reply( $self->unknown_reply($original) );
  return;
}

1;

__END__

=pod

=head1 NAME

Net::Finger::Server - a simple finger server

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Net::Finger::Server -run;

That's it!  You might need to run with privs, since by default it will bind to
port 79.

You can also:

  use Net::Finger::Server -run => { port => 1179 };

...if you want.

Actually, both of these are sort of moot unless you also provide an C<isa>
argument, which sets the base class for the created server.
Net::Finger::Server is, for now, written to work as a Net::Server subclass.

=head1 DESCRIPTION

How can there be no F<finger> servers on the CPAN in 2008?  Probably because
there weren't any in 1999, and by then it was already too late.  Finger might
be dead, but it's fun for playing around.

Right now Net::Finger::Server uses L<Net::Server|Net::Server>, but that might
not last.  Stick to the documented interface.

Speaking of the documented interface, you'll almost certainly want to subclass
Net::Finger::Server to make it do something useful.

=head1 METHODS

=head2 username_regex

=head2 hostname_regex

The C<username_regex> and C<hostname_regex> methods return regex used to match
usernames and hostnames in query strings.  They're fairly reasonable, and
suggestions for change are welcome.  You can replace them, though, without
breaking compliance with RFC 1288, since it doesn't define what a hostname or
username is.

=head2 listing_reply

This method is called when a C<{C}> query is received -- in other words, an
empty query, used to request a listing of all users.  It is passed a hashref of
arguments, of where there is only one right now:

  verbose - boolean; did client request a verbose reply?

The default reply is a rejection notice.

=head2 user_reply

This method is called when a C<{Q1}> query is received -- in other words, a
request for information about a named user.  It is passed the username and a
hashref of arguments, of where there is only one right now:

  verbose - boolean; did client request a verbose reply?

The default reply is a rejection notice.

=head2 forward_reply

This method is called when a C<{Q2}> query is received -- in other words, a
request for the server to relay a request to another host.  It is passed a
hashref of arguments:

  username - the user named in the query (if any)
  hosts    - an arrayref of the hosts in the query, left to right
  verbose  - boolean; did client request a verbose reply?

The default reply is a rejection notice.

=head2 unknown_reply

This method is called when the request can't be understood.  It is passed the
query string.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
