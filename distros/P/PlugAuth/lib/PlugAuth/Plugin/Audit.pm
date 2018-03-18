package PlugAuth::Plugin::Audit;

use strict;
use warnings;
use 5.010001;
use Role::Tiny::With;
use Path::Class::Dir;
use Path::Class::File;
use File::Glob qw( bsd_glob );
use YAML::XS qw( Dump LoadFile );
use DateTime;

with 'PlugAuth::Role::Plugin';

# ABSTRACT: Audit log for authentication/authorization
our $VERSION = '0.39'; # VERSION


with 'PlugAuth::Role::Plugin';

sub init
{
  my($self) = @_;
  
  $self->app->routes->route('/audit')->name('audit_check')->get(sub {
    my($c) = @_;
    my ($day,$month,$year) = (localtime(time))[3,4,5];
    $year+=1900;
    $month++;
    $c->stash->{autodata} = {
      today   => join('-', $year, sprintf("%02d", $month), sprintf("%02d", $day)),
      version => $PlugAuth::Plugin::Audit::VERSION // 'dev',
    };
  });
  
  $self->app->routes->route('/audit/today')->name('audit_today')->get(sub {
    my($c) = @_;
    my ($day,$month,$year) = (localtime(time))[3,4,5];
    $year+=1900;
    $month++;
    $c->redirect_to($c->url_for('audit', year => $year, month => sprintf("%02d", $month), day => sprintf("%02d", $day)));
  });
  
  # TODO: provide an interface for this
  # in Clustericious
  my $auth = sub {
    my $c = shift;
    my $plugin = $self->_self_auth_plugin;
    return 1 unless defined $plugin;
    return 0 unless $plugin->authenticate($c, 'ACPS');
    return 0 unless $plugin->authorize($c, 'accounts', $c->req->url->path);
    return 1;
  };
  
  my $authz = sub {
  };
  
  $self->app->routes->under->to({ cb => $auth })->route('/audit/:year/:month/:day')->name('audit')->get(sub {
    my($c) = @_;
    my $year  = $c->stash('year');
    my $month = $c->stash('month');
    my $day   = $c->stash('day');
    return $c->render_message('not ok', 404)
      unless $year  =~ /^\d\d\d\d$/
      &&     $month =~ /^\d\d?$/
      &&     $day   =~ /^\d\d?$/;
    my $filename = $self->log_filename({ year => $year, month => $month, day => $day });
    return $c->render_message('not ok', 404)
      unless -r $filename;
    my(@events) = map {
      my $event = $_;
      my $dt = DateTime->from_epoch( epoch => $event->{time} );
      $dt->set_time_zone('local');
      $event->{time_epoch}    = delete $event->{time};
      $event->{time_human}    = $dt->strftime("%a, %d %b %Y %H:%M:%S %z");
      $event->{time_computer} = $dt->strftime("%Y-%m-%dT%H:%M:%S%z");
      $event;
    } LoadFile($filename->stringify);
    $c->stash->{autodata} = \@events;
  });
  
  my @event_names = qw(
    create_user 
    delete_user
    create_group
    delete_group
    update_group
    grant
    revoke
    change_password
  );
  
  foreach my $event_name (@event_names)
  {
    $self->app->on($event_name => sub {
      my($app, $args) = @_;
      
      my %info = %$args;
      $info{time} = time;
      $info{event} = $event_name;
      my $filename = $self->log_filename($info{time});
      open(my $fh, '>>', $filename->stringify);
      print $fh Dump(\%info);
      close $fh;
    });
  }
}

sub log_filename
{
  my($self, $time) = @_;
  
  my($day, $month, $year);
  
  if(ref $time)
  {
    $day   = $time->{day};
    $month = $time->{month};
    $year  = $time->{year};
  }
  else
  {
    ($day,$month,$year) = (localtime($time))[3,4,5];
    $year += 1900;
    $month++;
  }
  
  my $filename = Path::Class::File->new(
    bsd_glob('~/.plugauth_plugin_audit'),
    sprintf("%04d", $year),
    sprintf("%02d", $month),
    sprintf("%02d", $day),
    'audit.log',
  );
  $filename->dir->mkpath(0,0700);
  $filename;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::Audit - Audit log for authentication/authorization

=head1 VERSION

version 0.39

=head1 SYNOPSIS

PlugAuth.conf:

 ---
 plugins:
   - PlugAuth::Plugin::Audit: {}

=head1 ROUTES

=head2 Public routes

These routes work for unauthenticated and unauthorized users.

=head3 GET /audit

You can do a simple GET on this route to see if the plugin is loaded.
It will return a JSON string with the version of the plugin as the body
and 200 if the plugin is available, if not L<PlugAuth> will return 404.

=head2 Accounts Routes

These routes are available to users authenticates and authorized to perform
the 'accounts' action.

=head3 GET /audit/:year/:month/:day

Return the audit entries for the given day.

=head3 GET /audit/today

Redirects to the appropriate URL for today's audit log.

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
