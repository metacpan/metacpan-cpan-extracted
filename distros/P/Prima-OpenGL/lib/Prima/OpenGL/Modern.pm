package Prima::OpenGL::Modern;

use strict;
use warnings;
use Prima qw(OpenGL GLWidget);
use OpenGL::Modern qw(glewInit glewGetErrorString GLEW_OK);

my $glew_initialized;

sub glew_init
{
	return unless $glew_initialized;
	$glew_initialized++;

	my $ret = undef;
	my $err = glewInit;
	$ret = glewGetErrorString($err) unless $err == GLEW_OK;
	return $ret;
}

sub paint_hook {
	my $err = glew_init();
	warn $err if defined $err;
	@Prima::GLWidget::paint_hooks = grep { $_ != \&paint_hook } @Prima::GLWidget::paint_hooks;
}

push @Prima::GLWidget::paint_hooks, \&paint_hook;

1;

=pod

=head1 NAME

Prima::OpenGL::Modern - Prima support for GLEW library

=head1 DESCRIPTION

Warning: OpenGL::Modern is highly experimental between versions, and might not work with this code.

It is therefore the module is not a prerequisite, so if you need it you need to install it yourself.
The GLEW library is automatically initialized on a first paint event of a GLWidget. If you don't use
that, you need to initialize the library yourself using its only C<glew_init> function

=head1 SYNOPSIS

   use Prima qw(Application OpenGL::Modern);

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=head1 SEE ALSO

L<OpenGL::Modern>

=head1 LICENSE

This software is distributed under the BSD License.

=cut
