package Mojolicious::Plugin::Notifications::HTML;
use Mojo::Base 'Mojolicious::Plugin::Notifications::Engine';
use Exporter 'import';
use Mojo::Util qw/xml_escape/;
use Scalar::Util qw/blessed/;
use Mojo::ByteStream 'b';

our @EXPORT_OK = ('notify_html');

# TODO:
#   Make the form have a class instead of the button!

# TODO:
#   Maybe make the buttons be part of a single form.

# TODO:
#   Add a redirect URL with ClosedRedirect, so it's ensured
#   a redirect won't be misused.

# Exportable function
sub notify_html {
  my $c = shift if blessed $_[0] && $_[0]->isa('Mojolicious::Controller');
  my $type = shift;
  my $param = shift if ref $_[0] && ref $_[0] eq 'HASH';
  my $msg = pop;

  my $str = qq{<div class="notify notify-$type">};
  $str .= blessed $msg && $msg->isa('Mojo::ByteStream') ? $msg : xml_escape($msg);

  # Check for confirmation
  if ($param) {

    # Okay path is defined
    if ($param->{ok}) {
      $str .= '<form action="' . $param->{ok} . '" method="post">';
      $str .= $c->csrf_field if $c;
      $str .= '<button class="ok">' . ($param->{ok_label} // 'OK') . '</button>';
      $str .= '</form>';
    };

    # Cancel path is defined
    if ($param->{cancel}) {
      $str .= '<form action="' . $param->{cancel} . '" method="post">';
      $str .= $c->csrf_field if $c;
      $str .= '<button class="cancel">' . ($param->{cancel_label} // 'Cancel') . '</button>';
      $str .= '</form>';
    };
  };
  return $str . "</div>\n";
};


# Notification method
sub notifications {
  my ($self, $c, $notify_array) = @_;

  my $html = '';
  foreach (@$notify_array) {
    $html .= notify_html($c, @{$_});
  };

  return b($html);
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Notifications::HTML - Event Notifications using HTML


=head1 SYNOPSIS

  # Register the engine
  plugin Notifications => {
    HTML => 1
  };

  # In the template
  %= notifications 'html'


=head1 DESCRIPTION

This plugin is a simple notification engine for HTML.

If it does not suit your needs, you can easily
L<write your own engine|Mojolicious::Plugin::Notifications::Engine>.


=head1 HELPERS

=head2 notify

See the base L<notify|Mojolicious::Plugin::Notifications/notify> helper.


=head2 notifications

  $c->notify(warn => 'wrong');
  $c->notify(success => 'right');

  %= notifications 'html';
  # <div class="notify notify-warn">wrong</div>
  # <div class="notify notify-success">right</div>

Will render each notification using
L<notify_html|Mojolicious::Plugin::Notifications::HTML/notify_html>.


=head1 EXPORTABLE FUNCTIONS

=head2 notify_html

  use Mojolicious::Plugin::Notifications::HTML qw/notify_html/;

  notify_html(warn => 'This is a warning')
  # <div class="notify notify-warn">This is a warning</div>

  notify_html(announce => {
    ok => 'http://example.com/ok',
    ok_label => 'Okay!'
  # }, 'Confirm, please!')
  # <div class="notify notify-announce">
  #   Confirm, please!
  #   <form action="http://example.com/ok" method="post">
  #     <button>Okay!</button>
  #   </form>
  # </div>

Returns the formatted text in a C<E<lt>div /E<gt>> element
with the class C<notify> and the class C<notify-$type>, where C<$type> is
the notification type you passed.
In case an C<ok> parameter is passed, this will add a POST form
for confirmation. In case an C<ok_label> is passed, this will be the label
for the confirmation button.
In case a C<cancel> parameter is passed, this will add a POST form
for cancelation. In case a C<cancel_label> is passed, this will be the label
for the cancelation button.

If the first parameter is a L<Mojolicious::Controller> object,
the button will have a
L<csrf_token|Mojolicious::Plugin::TagHelpers/csrf_token>
parameter to validate.

This is meant to be used by other engines as a fallback.

B<Confirmation is EXPERIMENTAL!>


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2020, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
