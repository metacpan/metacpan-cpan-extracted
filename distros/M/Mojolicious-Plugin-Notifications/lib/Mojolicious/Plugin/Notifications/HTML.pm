package Mojolicious::Plugin::Notifications::HTML;
use Mojo::Base 'Mojolicious::Plugin::Notifications::Engine';
use Mojo::Util qw/xml_escape/;

# Notification method
sub notifications {
  my ($self, $c, $notify_array) = @_;

  my $html = '';
  foreach (@$notify_array) {
    $html .= qq{<div class="notify notify-} . $_->[0] . '">' .
      xml_escape($_->[-1]) .
	"</div>\n";
  };

  return $c->b($html);
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

Will render each notification as text in a C<E<lt>div /E<gt>> element
with the class C<notify> and the class C<notify-$type>, where C<$type> is
the notification type you passed.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Notifications


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2015, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the terms of the Artistic License version 2.0.

=cut
