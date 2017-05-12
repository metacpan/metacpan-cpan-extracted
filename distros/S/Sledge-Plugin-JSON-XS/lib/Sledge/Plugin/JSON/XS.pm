package Sledge::Plugin::JSON::XS;
use strict;
use warnings;
use 5.00800;
use JSON::XS;
use Encode ();

our $VERSION = '0.05';
our $ConformToRFC4627 = 0;
our $ENCODING = 'utf-8';

sub import {
    my $pkg = caller(0);

    no strict 'refs'; ## no critic.
    *{"$pkg\::output_json_xs"} = \&_output_json_xs;
}

sub _output_json_xs {
    my ($self, $src) = @_;

    my $content_type =
        ( $self->debug_level && $self->r->param('debug') )
        ? "text/plain; charset=$ENCODING"
        : _content_type($self, $ENCODING );

    my $json = encode_json($src);
    my $output = _add_callback($self, _validate_callback_param($self, ($self->r->param('callback') || '')), $json );
    $self->r->content_type($content_type);
    $self->set_content_length(length $output);
    $self->send_http_header;
    $self->r->print($output);
    $self->invoke_hook('AFTER_OUTPUT');
    $self->finished(1);
}

sub _content_type {
    my ($self, $encoding) = @_;

    my $user_agent = $self->r->header_in('User-Agent');

    if ( $ConformToRFC4627 ) {
        return "application/json; charset=$encoding";
    } elsif (($user_agent || '') =~ /Opera/) {
        return "application/x-javascript; charset=$encoding";
    } else {
        return "application/javascript; charset=$encoding";
    }
}

sub _add_callback {
    my ($self, $cb, $json) = @_;

    if (Encode::is_utf8($cb)) {
        $cb = Encode::encode('utf8', $cb);
    }

    my $output;
    $output .= "$cb(" if $cb;
    $output .= $json;
    $output .= ");"   if $cb;

    return $output;
}

sub _validate_callback_param {
   my ($self, $param) = @_;
   return ( $param =~ /^[a-zA-Z0-9\.\_\[\]]+$/ ) ? $param : undef;
}

1;
__END__

=encoding utf8

=head1 NAME

Sledge::Plugin::JSON::XS - JSON::XS wrapper for Sledge

=head1 SYNOPSIS

  package Your::Pages;
  use Sledge::Plugin::JSON::XS;

  sub dispatch_foo {
    my $self = shift;
    $self->output_json_xs({foo => 'bar'});
  }

=head1 DESCRIPTION

Sledge::Plugin::JSON::XS is JSON::XS wrapper for Sledge.

Sledge::Plugin::JSON is wrapper for JSON::Syck. but this module uses JSON::XS.

=head1 CODE COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    .../Sledge/Plugin/JSON/XS.pm  100.0  100.0  100.0  100.0    n/a  100.0  100.0
    Total                         100.0  100.0  100.0  100.0    n/a  100.0  100.0
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Sledge::Plugin::JSON>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
