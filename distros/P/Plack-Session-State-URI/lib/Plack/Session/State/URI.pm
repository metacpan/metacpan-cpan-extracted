package Plack::Session::State::URI;
use strict;
use warnings;
our $VERSION = '0.06';

use parent 'Plack::Session::State';
use Plack::Request;
use Plack::Util;
use Encode ();
use HTML::StickyQuery;

sub get_session_id {
    my ($self, $env) = @_;
    Plack::Request->new($env)->param($self->session_key);
}

sub finalize {
    my ($self, $id, $res) = @_;

    return unless $id;

    if ($res->[0] == 200) {
        $self->html_filter($id, $res);
    } elsif ($res->[0] == 302) {
        $self->redirect_filter($id, $res);
    }
}

sub html_filter {
    my ($self, $id, $res) = @_;

    return if (ref $res->[2]) ne 'ARRAY';

    my $encode = 'utf8';
    my $h = Plack::Util::headers($res->[1]);
    if ($h->get('Content-Type')=~m|^text/\w+;\s*charset="?([^"]+)"?|i) {
        $encode = $1;
    }
    my $name = $self->session_key;
    my $body = '';
    for my $line (@{ $res->[2] }) {
        $body .= $line if length $line;
    }
    $body = Encode::decode($encode, $body);
    $body =~ s{(<form\s*.*?>)}{$1\n<input type="hidden" name="$name" value="$id" />}isg;
    my $sticky = HTML::StickyQuery->new;
    $body = $sticky->sticky(
        scalarref => \$body,
        param     => { $name => $id }
    );
    $res->[2] = [ Encode::encode($encode, $body) ];
}

sub redirect_filter {
    my ($self, $id, $res) = @_;

    my $h = Plack::Util::headers($res->[1]);
    my $path = $h->get('Location');
    my $uri = URI->new($path);
    $uri->query_form( $uri->query_form, $self->session_key, $id );
    $h->set('Location', $uri->as_string);
}

1;
__END__

=head1 NAME

Plack::Session::State::URI - uri-based session state

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Session::Store::File;
  use Plack::Session::State::URI;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable 'Plack::Middleware::Session',
          store => Plack::Session::Store::File->new(
              dir => File::Temp->tempdir( 'XXXXXXXX', TMPDIR => 1, CLEANUP => 1 )
          ),
          state => Plack::Session::State::URI->new(
              session_key => 'sid'
          );
      $app;
  };

=head1 DESCRIPTION

Plack::Session::State::URI is uri-based session state

=head1 AUTHOR

Shinichiro Aska E<lt>s.aska.org {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
