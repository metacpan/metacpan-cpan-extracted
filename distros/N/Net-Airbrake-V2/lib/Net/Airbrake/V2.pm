# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Net-Airbrake-V2
#
# This software is copyright (c) 2015 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Net::Airbrake::V2;
# git description: v0.02-4-g4971881

our $AUTHORITY = 'cpan:RWSTAUNER';
$Net::Airbrake::V2::VERSION = '0.03';
# ABSTRACT: Airbrake Notifier API V2 Client

use Net::Airbrake 0.02;
use JSON::MaybeXS qw(encode_json decode_json);
use XML::Simple   qw(xml_in xml_out);

our @ISA = 'Net::Airbrake';

# Net::Airbrake uses Class::Tiny.
sub BUILD {
  my $self = shift;

  # Pass simple args to avoid circular references.
  $self->{_ua} = Net::Airbrake::V2::UserAgent->new({
    mod     => ref $self,
    api_key => $self->api_key,
  });

  return;
}

# Change uri suffix for v2.
sub _url {
  my ($self) = @_;
  $self->base_url . '/notifier_api/v2/notices';
}

# helper
sub _make_vars {
  my ($self, $parent, $vars) = @_;
  $vars ||= {};

  return () if !keys %$vars;

  return ($parent => [
    {
      $self->_var_content($vars),
    }
  ]);
}

sub _var_content {
  my ($self, $v) = @_;

  return (content => ref($v) ? $self->stringify_ref($v) : $v)
    unless ref($v) eq 'HASH';

  return (
    var => [
      map {
        {
          key     => $_,
          $self->_var_content($v->{$_}),
        }
      } keys %$v
    ]
  );
}


our $Dumper;
sub stringify_ref {
  my ($self, $value) = @_;
  ($Dumper ||= do {
    require Data::Dumper;
    Data::Dumper->new([])
      ->Indent(0)
      ->Useqq(1)
      ->Terse(1)
      ->Sortkeys(1)
  })
    ->Values([$value])
    ->Dump;
}


sub convert_request {
  my ($self, $req, $opts) = @_;

  my $string = !ref $req;
  $req = decode_json($req) if $string;

  $opts ||= {};

  my $mod     = $opts->{mod} || ref($self) || $self;
  my $api_key = $opts->{api_key} || $self->api_key;

  my $notice = {
    notice => {
      version => '2.3',
      'api-key' => [ $api_key ],
      notifier  => [
        {
          name    => [ $mod ],
          version => [ $mod->VERSION ],
          url     => [ "https://metacpan.org/pod/$mod" ],
        },
      ],
      error => [
        map {
          {
            class     => [ $_->{type} ],
            message   => [ $_->{message} ],
            backtrace => {
              line => [
                map {
                  +{
                    number => $_->{line},
                    file   => $_->{file},
                    method => $_->{function},
                  }
                }
                  @{ $_->{backtrace} }
              ]
            }
          }
        }
          @{ $req->{errors} || [] }
      ],
      request => {
        url        => [ $req->{context}{url} ],
        component  => [ $req->{context}{component} ],
        action     => [ $req->{context}{action}    ],
        $self->_make_vars(params     => $req->{params}),
        $self->_make_vars(session    => $req->{session}),
        $self->_make_vars('cgi-data' => $req->{environment}),
      },
      'server-environment' => {
        # Errbit accepts 'hostname' however it's not listed in the spec.
        'project-root'     => [ $req->{context}{rootDirectory} ],
        'app-version'      => [ $req->{context}{version} ],
        'environment-name' => [ $req->{context}{environment} ],
      },
      # Errbit accepts 'framework'.
    }
  };

  return $notice if !$string;
  return $self->_xml_encode($notice);
}

sub _xml_encode {
  my ($self, $notice) = @_;

  my $xml = xml_out($notice,
    RootName => undef,
    NoIndent => 1,
    SuppressEmpty => 1,
    XMLDecl  => q[<?xml version="1.0" encoding="utf-8"?>],
  );

  # decode_json should return a structure with character strings,
  # and XML::Simple doesn't encode until writing to a file handle.
  utf8::encode($xml);

  return $xml;
}


sub convert_response {
  my ($self, $res) = @_;

  # For consistnecy with convert_request.
  return $res if ref $res;

  return encode_json( xml_in($res) );
}

{
  package # no_index
    Net::Airbrake::V2::UserAgent;

  sub new {
    bless $_[1], $_[0];
  }

  sub ua {
    $_[0]->{ua} ||= do {
      my $mod = $_[0]->{mod};
      HTTP::Tiny->new(
        agent   => join('/', $mod, $mod->VERSION || 0),
        timeout => 5,
      );
    };
  }

  sub _convert_request {
    my ($self, $msg) = @_;
    $msg->{content} = $self->{mod}->convert_request($msg->{content}, { api_key => $self->{api_key} });
    $self->_change_content_type($msg, 'application/xml');
  }

  sub _convert_response {
    my ($self, $msg) = @_;
    $msg->{content} = $self->{mod}->convert_response($msg->{content});
    $self->_change_content_type($msg, 'application/json');
  }

  # Find and update the content type regardless of capitalization/punctuation.
  sub _change_content_type {
    my ($self, $msg, $val) = @_;
    my $headers = $msg->{headers};
    foreach my $h ( keys %$headers ){
      $headers->{ $h } = $val
        if $h =~ /^content.type$/i;
    }
  }

  sub request {
    my ($self, $method, $url, $req) = @_;

    $self->_convert_request($req);

    my $res = $self->ua->request($method, $url, $req);

    # TODO: catch xml parse error.
    # TODO: check content type?

    $self->_convert_response($res);

    return $res;
  }
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS Errbit cpan testmatrix url annocpan anno
bugtracker rt cpants kwalitee diff irc mailto metadata placeholders
metacpan

=head1 NAME

Net::Airbrake::V2 - Airbrake Notifier API V2 Client

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Net::Airbrake::V2;

  my $airbrake = Net::Airbrake::V2->new(
      api_key    => 'xxxxxxx',
      # project_id is not used.
  );

  eval { die 'Oops' };
  $airbrake->notify($@);

=head1 DESCRIPTION

API Compatible with L<Net::Airbrake> but converts v3 requests to v2 and then converts the response back.

This makes it usable with L<Errbit|https://errbit.github.io/errbit/> C<< <= v0.3 >>.

B<Note>: This is currently based heavily on the internals of L<Net::Airbrake> (as of C<0.02>).
This enables laziness at the cost of fragility.
As such the implementation is subject to change.

See L<Net::Airbrake> for descriptions of methods and arguments.

=head1 METHODS

=head2 stringify_ref

The values of the the "var" hashes ("params", "session", and "environment")
that are references (other than hashes) will stringified.

This is currently done with C<Data::Dumper>
which is similar to the way the ruby gem dumps structures.
The format is subject to change.

=head2 convert_request

  $client->convert_request(\%v3_request);
  Net::Airbrake::V2->convert_request(\%v3_request, \%config);

Convert a v3 request (JSON) to v2 (XML).
This rearranges the data structure as best it can.

This can also be called as a class method
if a config hash is passed, containing:

=over 4

=item *

api_key

=back

=head2 convert_response

Convert v2 response (XML) to v3 response (JSON).

=for Pod::Coverage BUILD

=head1 VERSION DIFFERENCES

Some data may be lost converting from v3 to v2.
Specifically v2 does not have explicit places for:

  errors/{i}/backtrace/{i}/column
  context/os
  context/language
  context/userAgent
  context/userId
  context/userName
  context/userEmail

=head1 SEE ALSO

=over 4

=item *

L<Net::Airbrake>

=item *

L<Airbrake|https://airbrake.io>

=item *

L<Airbrake Notifier API v2|https://help.airbrake.io/kb/api-2/notifier-api-v23>

=item *

L<Errbit|https://errbit.github.io/errbit/>

=back

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Net::Airbrake::V2

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Net-Airbrake-V2>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-net-airbrake-v2 at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Net-Airbrake-V2>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code


L<https://github.com/rwstauner/Net-Airbrake-V2>

  git clone https://github.com/rwstauner/Net-Airbrake-V2.git

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
