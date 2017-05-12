package MojoX::Renderer::Handlebars;

use strict;
use warnings;

use File::Spec ();
use Mojo::Base -base;
use Mojo::Loader qw(data_section);
use Text::Handlebars ();

our $VERSION = '0.04';


has 'handlebars';

sub build {
	my $self = shift->SUPER::new(@_);
	$self->_init(@_);
	return sub { $self->_render(@_) };
}

sub _init {
	my ($self, %args) = @_;

	my $app = $args{mojo} || $args{app};
	my $cache_dir;
	my @path = $app->home->rel_dir('templates');

	if ($app) {
		$cache_dir = $app->home->rel_dir('tmp/compiled_templates');
		push @path, data_section( $app->renderer->classes->[0] );
	}
	else {
		$cache_dir = File::Spec->tmpdir;
	}

	my %config = (
			cache_dir    => $cache_dir,
			path         => \@path,
			warn_handler => sub { },
			die_handler  => sub { },
			%{$args{template_options} || {}},
			);

	$self->handlebars(Text::Handlebars->new(\%config));

	return $self;
}

sub _render {
	my ($self, $renderer, $c, $output, $options) = @_;

	my $name = $c->stash->{'template_name'}
	|| $renderer->template_name($options);
	my %params = (%{$c->stash}, c => $c);

	local $@;
	if (defined(my $inline = $options->{inline})) {
		$$output = $self->handlebars->render_string($inline, \%params);
	}
	else {
		$$output = $self->handlebars->render($name, \%params);
	}
	die $@ if $@;

	return 1;
}

1;


__END__
=head1 NAME

MojoX::Renderer::Handlebars - Text::Handlebars renderer for Mojo

=head1 SYNOPSIS

	sub startup {
		....

	# Via mojolicious plugin
			$self->plugin('handlebars_renderer');

	# or manually
		use MojoX::Renderer::Handlebars;
		my $handlebars = MojoX::Renderer::Handlebars->build(
				mojo             => $self,
				template_options => { },
				);
		$self->renderer->add_handler(hbs => $handlebars);
	}

=head1 DESCRIPTION

The C<MojoX::Renderer::Handlebars> module is called by C<Mojo::Renderer> for
any matching template.

=head1 METHODS

=head2 build

$renderer = MojoX::Renderer::Handlebars->build(...)

This method returns a handler for the Mojo renderer.

Supported parameters are:

=over

=item mojo

C<build> currently uses a C<mojo> parameter pointing to the base class
object (C<Mojo>).

=item template_options

A hash reference of options that are passed to Text::Handlebars->new().

=back

=head1 SEE ALSO

L<Text::Handlebars>, L<MojoX::Renderer>, L<MojoX::Renderer::Xslate>

=head1 AUTHOR

Robert Grimes, C<< <rmzgrimes at gmail.com> >>

This code is heavily based on the module L<MojoX::Renderer::Xslate> by "gray <gray at cpan.org>"
since the Text::Handlebars module inherits from Text::Xslate. All bugs are mine.


=head1 BUGS

Please report any bugs or feature requests to C<bug-mojox-renderer-handlebars at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MojoX-Renderer-Handlebars>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc MojoX::Renderer::Handlebars


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MojoX-Renderer-Handlebars>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MojoX-Renderer-Handlebars>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MojoX-Renderer-Handlebars>

=item * Search CPAN

L<http://search.cpan.org/dist/MojoX-Renderer-Handlebars/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Robert Grimes.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
		counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
