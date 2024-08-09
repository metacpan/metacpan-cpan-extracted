package Mojolicious::Plugin::Ical;
use Mojo::Base 'Mojolicious::Plugin';

use POSIX         ();
use Sys::Hostname ();
use Text::vFile::asData;

our $VERSION = '1.00';

sub register {
  my ($self, $app, $config) = @_;

  $config->{handler} //= 'ical';

  $self->{properties} = $config->{properties} || {};
  $self->{properties}{calscale}      ||= 'GREGORIAN';
  $self->{properties}{method}        ||= 'PUBLISH';
  $self->{properties}{prodid}        ||= sprintf '-//%s//NONSGML %s//EN', Sys::Hostname::hostname, $app->moniker;
  $self->{properties}{version}       ||= '2.0';
  $self->{properties}{x_wr_caldesc}  ||= '';
  $self->{properties}{x_wr_calname}  ||= $app->moniker;
  $self->{properties}{x_wr_timezone} ||= POSIX::strftime('%Z', localtime);

  $self->{vfile} ||= Text::vFile::asData->new;

  $app->helper('reply.ical' => sub { $self->_reply_ical(@_) });
  $app->types->type(ical => 'text/calendar');

  if ($config->{handler}) {
    $app->renderer->add_handler(
      $config->{handler},
      sub {
        my ($renderer, $c, $output, $options) = @_;
        return undef unless my $ical = $c->stash('ical');
        $$output = join '', map {"$_\n"} $self->_render_ical($c, $ical);
        return 1;
      }
    );
  }
}

sub _event_to_properties {
  my ($event, $defaults) = @_;
  my $properties = {};

  for my $k (keys %$event) {
    my $v = $event->{$k} //= '';
    my $p = _vkey($k);
    if (UNIVERSAL::isa($v, 'Mojo::Date')) {
      $v = $v->to_datetime;
      $v =~ s![:-]!!g;    # 1994-11-06T08:49:37Z => 19941106T084937Z
    }
    $properties->{$p} = [{value => $v}];
  }

  $properties->{DTSTAMP}  ||= [{value => $defaults->{now}}];
  $properties->{SEQUENCE} ||= [{value => 0}];
  $properties->{STATUS}   ||= [{value => 'CONFIRMED'}];
  $properties->{TRANSP}   ||= [{value => 'OPAQUE'}];
  $properties->{UID}      ||= [{value => sprintf '%s@%s', _md5($event), $defaults->{hostname}}];
  $properties;
}

sub _render_ical {
  my ($self, $c, $data) = @_;
  my %properties = %{$data->{properties} || {}};
  my $ical       = {};
  my %defaults;

  $ical->{objects}    = [];
  $ical->{properties} = {};
  $ical->{type}       = 'VCALENDAR';

  $properties{calscale}      ||= $self->{properties}{calscale};
  $properties{method}        ||= $self->{properties}{method};
  $properties{prodid}        ||= $self->{properties}{prodid};
  $properties{version}       ||= $self->{properties}{version};
  $properties{x_wr_caldesc}  ||= $self->{properties}{x_wr_caldesc};
  $properties{x_wr_calname}  ||= $self->{properties}{x_wr_calname};
  $properties{x_wr_timezone} ||= $self->{properties}{x_wr_timezone};

  for my $k (keys %properties) {
    my $p = _vkey($k);
    $ical->{properties}{$p} = [{value => $properties{$k}}];
  }

  $defaults{hostname} = Sys::Hostname::hostname;
  $defaults{now}      = Mojo::Date->new->to_datetime;
  $defaults{now} =~ s![:-]!!g;    # 1994-11-06T08:49:37Z => 19941106T084937Z

  for my $event (@{$data->{events} || []}) {
    push @{$ical->{objects}}, {properties => _event_to_properties($event, \%defaults), type => 'VEVENT'};
  }

  return $self->{vfile}->generate_lines($ical);
}

sub _reply_ical {
  my ($self, $c, $data) = @_;
  $c->res->headers->content_type('text/calendar');
  $c->render(text => join '', map {"$_\n"} $self->_render_ical($c, $data));
}

sub _md5 {
  my $data = $_[0];
  Mojo::Util::md5_sum(join ':', map {"$_=$data->{$_}"} grep { $_ ne 'dtstamp' } sort keys %$data);
}

sub _vkey {
  return $_[0] if $_[0] =~ /^[A-Z]/;
  local $_ = uc $_[0];
  s!_!-!g;
  $_;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Ical - Generate .ical documents

=head1 VERSION

0.05

=head1 SYNOPSIS

=head2 Application

  use Mojolicious::Lite;
  plugin ical => {
    properties => {
      calscale      => "GREGORIAN"         # default GREGORIAN
      method        => "REQUEST",          # default PUBLISH
      prodid        => "-//ABC Corporation//NONSGML My Product//EN",
      version       => "1.0",              # default to 2.0
      x_wr_caldesc  => "Some description",
      x_wr_calname  => "My calender",
      x_wr_timezone => "EDT",              # default to timezone for localhost
    }
  };

  get '/calendar' => sub {
    my $c = shift;
    $c->reply->ical({
      events => [
        {
          created       => $date,
          description   => $str,   # http://www.kanzaki.com/docs/ical/description.html
          dtend         => $date,
          dtstamp       => $date,  # UTC time format, defaults to "now"
          dtstart       => $date,
          last_modified => $date,  # defaults to "now"
          location      => $str,   # http://www.kanzaki.com/docs/ical/location.html
          sequence      => $int,   # default 0
          status        => $str,   # default CONFIRMED
          summary       => $str,   # http://www.kanzaki.com/docs/ical/summary.html
          transp        => $str,   # default OPAQUE
          uid           => $str,   # default to md5 of the values @hostname
        },
        ...
      ],
    });
  };

  # or using respond_to()
  get '/events' => sub {
    my $c = shift;
    my $ical = { events => [...] };
    $c->respond_to(
      ical => {handler => 'ical', ical => $ical},
      json => {json => $ical}
    );
  };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Ical> is a L<Mojolicious> plugin for generating
L<iCalendar|http://www.kanzaki.com/docs/ical/> documents.

This plugin will...

=over 4

=item *

Add the helper L</reply.ical>.

=item *

Add ".ical" type to L<Mojolicious/types>.

=item *

Add a handler "ical" to L<Mojolicious/renderer>.

=back

=head1 HELPERS

=head2 reply.ical

  $c = $c->reply->ical({ events => [...], properties => {...} });

Will render a iCal document with the Content-Type "text/calender".

C<events> is an array ref of calendar events.
C<properties> will override the defaults given to L</register>.

See L</SYNOPSIS> for more details.

=head1 METHODS

=head2 register

  plugin ical => {properties => {...}};

Register L</reply.ical> helper.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=cut
