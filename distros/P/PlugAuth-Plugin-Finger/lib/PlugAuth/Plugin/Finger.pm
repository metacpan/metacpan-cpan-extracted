package PlugAuth::Plugin::Finger;

use strict;
use warnings;
use 5.010001;
use Role::Tiny::With;
use AnyEvent::Finger::Server;
use Log::Log4perl qw( :easy );

with 'PlugAuth::Role::Plugin';

# ABSTRACT: (Deprecated) Add a finger protocol interface to your PlugAuth server
our $VERSION = '0.03'; # VERSION


sub init
{
  my($self) = @_;
  
  my $port = $self->plugin_config->port(
    default => $> && $^O !~ /^(cygwin|MSWin32)$/ ? 8079 : 79,
  );
  
  INFO "finger binding to port $port";
  
  my $server = $self->{server} = AnyEvent::Finger::Server->new(
    port         => $port,
    forward_deny => 1,
  );
  
  $server->start(sub {
    my $tx = shift;
    $self->app->refresh;
    if($tx->req->listing_request)
    {
      $tx->res->say("users:");
      $tx->res->say("  $_") for $self->app->auth->all_users;
      $tx->res->say("groups:");
      $tx->res->say("  $_") for $self->app->authz->all_groups;
      if($tx->req->verbose)
      {
        $tx->res->say("grants:");
        $tx->res->say("  $_") for @{ $self->app->authz->granted };
      }
    }
    else
    {
      my $name = lc $tx->req->as_string; # stringifying gets the user and the hostname, but not the verbosity
      my $found = 0;
      if(my $groups = $self->app->authz->groups_for_user($name))
      {
        $tx->res->say("user:" . $name);
        $tx->res->say("belongs to:");
        $tx->res->say("  " . join(', ', sort @$groups));
        $found = 1;
      }
      elsif(my $users = $self->app->authz->users_in_group($name))
      {
        $tx->res->say("group:" . $name);
        $tx->res->say("members:");
        $tx->res->say("  " . join(', ', sort @$users));
        $found = 1;
      }
      else
      {
        $tx->res->say("no such user or group");
      }
      if($tx->req->verbose && $found)
      {
        $tx->res->say("granted:");
        foreach my $grant (@{ $self->app->authz->granted })
        {
          $tx->res->say("  $grant") 
            if $grant =~ /:(.*)$/ && grep { $name eq lc $_ || $_ eq '#u' } map { s/^\s+//; s/\s+$//; $_ } split /,/, $1;
        }
      }
    }
    $tx->res->done;
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::Finger - (Deprecated) Add a finger protocol interface to your PlugAuth server

=head1 VERSION

version 0.03

=head1 SYNOPSIS

In your PlugAuth.conf:

 plugins:
   - PlugAuth::Plugin::Finger:
       port: 8079

Then from the command line, to list all users/groups:

 % finger @localhost

and from the command line, to query a user or group:

 % finger foo@localhost

and to see the granted permissions:

 % finger -l foo@localhost

=head1 DESCRIPTION

B<NOTE>: This module has been deprecated, and may be removed on or after 31 December 2018.
Please see L<https://github.com/clustericious/Clustericious/issues/46>.

This plugin provides a finger protocol interface to PlugAuth.  Through
it you can see the users, groups and their permissions through the finger
interface.

By default this plugin will listen to port 79 on Windows, or when the user
is privileged under Unix.  Otherwise it will listen to port 8079.  Many
finger clients cannot be configured to connect to a different port, but
you can use C<iptables> on Linux, or use an equivalent tool on other operating
systems to forward port 79 to port 8079.

=head1 PLUGIN OPTIONS

=head2 port

Specify the port.  This is will default to 79 or 8079 if you do not specify it.

=head1 CAVEATS

This plugin won't work as currently implemented if you are using a start_mode
which forks, such as hypnotoad.  Until that is solved this plugin will probably
prevent you from scaling your PlugAuth deployment.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
