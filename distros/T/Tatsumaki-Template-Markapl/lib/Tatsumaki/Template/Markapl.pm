# ABSTRACT: Use Markapl as Tatsumaki's template system.

package Tatsumaki::Template::Markapl;
BEGIN {
  $Tatsumaki::Template::Markapl::VERSION = '0.3';
}
use strict;
use warnings;

=head1 NAME

Tatsumaki::Template::Markapl - Use Markapl as L<Tatsumaki>'s template system.

=head1 VERSION

version 0.3

=head1 DESCRIPTION

This module will use L<Markapl> as L<Tatsumaki>'s template system.

L<Tatsumaki> do not support custom template engine currently, so we use L<Sub::Install> to rewrite L<Template::Application::_build_template>.

=head1 SYNOPSIS

    # This usually is in app.psgi
    use Tatsumaki::Template::Markapl;

    # Install the template system
    Tatsumaki::Template::Markapl->rewrite('MyProj::View');

And then in C<MyProj::View>:

    # MyProj::View
    package MyProj::View;
    use Markapl;

    template '/' => sub {
	my $self = shift;

	html {
	    head {
		title { 'My Title' };
	    };

	    body {
		div('#bd') {
		    outs('Hello, ');
		    outs($self->get('name'));
		};
	    };
	};
    };

Now you can use it in handler:

    # MyProj::Handler::Index
    package MyProj::Handler::Index;
    use parent 'Tatsumaki::Handler';

    sub get {
	shift->render('/', {name => 'perl'});
    };

=cut

use Any::Moose;
extends 'Tatsumaki::Template';

has 'view_class_name' => (is => 'rw');
has 'view_class' => (is => 'rw', lazy_build => 1);

use Plack::Util;
use Sub::Install;

sub _build_view_class {
    Plack::Util::load_class(shift->view_class_name);
}

sub render_file {
    my $self = shift;

    my $str = $self->view_class->render(@_);
    Plack::Util::inline_object(as_string => sub { $str });
};

sub rewrite {
    my ($self, $view_class_name) = @_;

    Sub::Install::reinstall_sub({
	code => sub { Tatsumaki::Template::Markapl->new(view_class_name => $view_class_name); },
	into => 'Tatsumaki::Application',
	as => '_build_template',
    });
}

use namespace::autoclean;

=head1 AUTHOR

Gea-Suan Lin, C<< <gslin at gslin.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Gea-Suan Lin.

This software is released under 3-clause BSD license. See
L<http://www.opensource.org/licenses/bsd-license.php> for more
information.

=cut

1;