package Terse::Controller::Static;

use base 'Terse::Controller';

sub static :get :view(static) :delayed :path(static/(.*\.js)$) :captured(1) :content_type(application/javascript);

sub static_png :get(static) :view(static) :delayed :path(static/(.*\.png)$) :captured(1) :content_type(image/png);

sub static_svg :get(static) :view(static) :delayed :path(static/(.*\.svg)$) :captured(1) :content_type(image/svg);

sub static_jpeg :get(static) :view(static) :delayed :path(static/(.*\.jpeg)$) :captured(1) :content_type(image/jpeg);

sub static_gif :get(static) :view(static) :delayed :path(static/(.*\.gif)$) :captured(1) :content_type(image/gif);

sub static_json :get(static) :view(static) :delayed :path(static/(.*\.json)$) :captured(1) :content_type(application/json);

sub static_html :get(static) :view(static) :delayed :path(static/(.*\.html)$) :captured(1) :content_type(text/html);

sub static_plain :get(static) :view(static) :delayed :path(static/(.*\.txt)$) :captured(1) :content_type(text/plain);

sub static_css :get(static) :view(static) :delayed :path(static/(.*\.css)$) :captured(1) :content_type(text/css);

1;

__END__;

=head1 NAME

Terse::Controller::Static - Serve static resources controller

=cut

=head1 VERSION

Version 0.08

=cut

=head1 SYNOPSIS

	package MyApp::Controller::Static;

	use base 'Terse::Controller::Static';

	1;

=cut

=head1 LICENSE AND COPYRIGHT

L<Terse::Static>.

=cut
