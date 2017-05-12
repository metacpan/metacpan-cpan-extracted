package Sledge::Plugin::Prototype;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use HTML::Prototype;

sub import {
    my $class = shift;
    my $pkg = caller;
    no strict 'refs';
    *{"$pkg\::prototype"} = sub { $_[0]->{__prototype} ||= HTML::Prototype->new };
    *{"$pkg\::show_prototype_js"} = sub {
        my $self = shift;

        $self->r->content_type('text/javascript');
        $self->r->send_http_header;
        $self->r->print($HTML::Prototype::prototype);
        $self->finished(1);
    };
    $pkg->register_hook(
        BEFORE_DISPATCH => sub {
            my $self = shift;
            $self->tmpl->param(prototype=>$self->prototype)
                if ref ($self->tmpl) =~ /^Sledge::Template::TT/;
        } );
}

1;
__END__

=head1 NAME

Sledge::Plugin::Prototype - Sledge plugin which implements wrapper arround HTML::Prototype module

=head1 SYNOPSIS

  package Foo::Pages::Bar;
  use Sledge::Plugin::Prototype; # just use

  # you can use parameter 'prototype' if template engine is tt
  [% prototype.define_javascript_functions %]

  # or in your dispatcher
  sub dispatch_prototype_js {
    shift->show_prototype_js;
  }

  # use the helper methods
  <div id="view"></div>
  <textarea id="editor" cols="80" rows="24"></textarea>
  [% prototype.observe_field( 'editor', 'http://foo.bar/baz', { 'update' => 'view' } ) %]

=head1 DESCRIPTION

C<Sledge::Plugin::Prototype> is Sledge plugin which implements wrapper arround HTML::Prototype module.
use Sledge::Plugin::Prototype in your Pages class, then C<prototype> method is imported in it.
if you chose C<Sledge::Template::TT> as template engine, parameter prototype is set in your template.

=head1 AUTHOR

Yasuhiro Horiuchi E<lt>yasuhiro@hori-uchi.comE<gt>

=head1 SEE ALSO

L<HTML::Prototype>

=cut
