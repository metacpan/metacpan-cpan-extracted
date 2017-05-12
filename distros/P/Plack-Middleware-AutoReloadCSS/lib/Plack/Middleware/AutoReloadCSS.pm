package Plack::Middleware::AutoReloadCSS;
use 5.008;
use strict;
use warnings;

use Plack::Util ();
use Plack::Util::Accessor qw(interval);

use parent qw(Plack::Middleware);
our $VERSION = '0.02';

sub call {
    my($self, $env) = @_;

    $self->response_cb($self->app->($env), sub {
        my $res          = shift;
        my $content_type = Plack::Util::header_get($res->[1], 'Content-Type');

        if (!Plack::Util::status_with_no_entity_body($res->[0]) &&
            (($content_type || '') =~ m{^(?:text/html|application/xhtml\+xml)})) {
            return sub {
                my $chunk = shift;
                return if !defined $chunk;

                $chunk =~ s{</body>}{$self->auto_reload_script . '</body>'}ei;
                $chunk;
            }
        }
    });
}

sub auto_reload_script {
    my $self     = shift;
    my $interval = defined $self->interval ? $self->interval : 1000;

    return <<"SCRIPT";
<script type="text/javascript">

// CSS auto-reload (c) Nikita Vasilyev
// http://nv.github.com/css_auto-reload/

CSSStyleSheet.prototype.reload = function reload(){
  // Reload one stylesheet
  // usage: document.styleSheets[0].reload()
  // return: URI of stylesheet if it could be reloaded, overwise undefined
  if (this.href) {
    var href = this.href;
    var i = href.indexOf('?'),
        last_reload = 'last_reload=' + (new Date).getTime();
    if (i < 0) {
      href += '?' + last_reload;
    } else if (href.indexOf('last_reload=', i) < 0) {
      href += '&' + last_reload;
    } else {
      href = href.replace(/last_reload=\\d+/, last_reload);
    }
    return this.ownerNode.href = href;
  }
};

StyleSheetList.prototype.reload = function reload(){
  // Reload all stylesheets
  // usage: document.styleSheets.reload()
  for (var i=0; i<this.length; i++) {
    this[i].reload()
  }
};

StyleSheetList.prototype.start_autoreload = function start_autoreload(miliseconds /*Number*/){
  // usage: document.styleSheets.start_autoreload()
  if (!start_autoreload.running) {
    var styles = this;
    start_autoreload.running = setInterval(function reloading(){
      styles.reload();
    }, miliseconds || this.reload_interval);
  }
  return start_autoreload.running;
};

StyleSheetList.prototype.stop_autoreload = function stop_autoreload(){
  // usage: document.styleSheets.stop_autoreload()
  clearInterval(this.start_autoreload.running);
  this.start_autoreload.running = null;
};

StyleSheetList.prototype.toggle_autoreload = function toggle_autoreload(){
  // usage: document.styleSheets.toggle_autoreload()
  return this.start_autoreload.running ? this.stop_autoreload() : this.start_autoreload();
};

document.styleSheets.start_autoreload($interval);
</script>
SCRIPT
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::AutoReloadCSS - Enables CSS Refreshing without
Reloading Whole Page

=head1 SYNOPSIS

  # in your app.psgi
  enable 'AutoReloadCSS', interval => 1000;

=head1 DESCRIPTION

Plack::Middleware::AutoReloadCSS automatically inserts some JavaScript
snippets to enable CSS refreshing feature without reloading whole
page.

=head1 AUTHOR

=over 4

=item * Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=item * Nikita Vasilyev

CSS auto-reload is borrowed from
L<http://nv.github.com/css_auto-reload/>

=back

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
