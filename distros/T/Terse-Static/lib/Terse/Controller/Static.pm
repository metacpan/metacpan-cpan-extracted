package Terse::Controller::Static;

use base 'Terse::Controller';

sub static :get :view(static) :delayed :path(static/(.*\.js)$) :captued(1) :content_type(application/javascript);

sub static_png :get(static) :view(static) :delayed :path(static/(.*\.png)$) :captued(1) :content_type(image/png);

sub static_svg :get(static) :view(static) :delayed :path(static/(.*\.svg)$) :captued(1) :content_type(image/svg);

sub static_jpeg :get(static) :view(static) :delayed :path(static/(.*\.jpeg)$) :captued(1) :content_type(image/jpeg);

sub static_gif :get(static) :view(static) :delayed :path(static/(.*\.gif)$) :captued(1) :content_type(image/gif);

sub static_json :get(static) :view(static) :delayed :path(static/(.*\.json)$) :captued(1) :content_type(application/json);

sub static_html :get(static) :view(static) :delayed :path(static/(.*\.html)$) :captued(1) :content_type(text/html);

sub static_plain :get(static) :view(static) :delayed :path(static/(.*\.txt)$) :captued(1) :content_type(text/plain);

1;

__END__;

=head1 NAME

Terse::Controller::Static - Serve static resources controller

=cut

=head1 VERSION

Version 0.04

=cut

=head1 SYNOPSIS

	package MyApp::Controller::Static;

	use base 'Terse::Controller::Static';

	1;

=cut

=head1 LICENSE AND COPYRIGHT

L<Terse::Static>.

=cut
