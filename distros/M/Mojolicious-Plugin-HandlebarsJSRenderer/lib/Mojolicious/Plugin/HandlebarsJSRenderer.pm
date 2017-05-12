package Mojolicious::Plugin::HandlebarsJSRenderer;

use 5.006;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/slurp dumper/;

use JavaScript::V8::Handlebars;

our $VERSION = '0.06';

has 'wrapper';

sub register {
	my( $self, $app, $conf ) = @_;
	my $hbjs = JavaScript::V8::Handlebars->new;

	#TODO Clean this up
	if( $conf->{wrapper} ) { 
		for( @{ $app->renderer->paths } ) {
			if( -r "$_/$conf->{wrapper}" ) {
				$self->wrapper( "$_/$conf->{wrapper}" );
				last;
			}
		}

		if( $self->wrapper ) {
			$self->wrapper( $hbjs->compile_file( $self->wrapper ) );
		}
		else {
			die "Failed to find/read $conf->{wrapper} in @{$app->renderer->paths}";
		}
	}

	if( $conf->{helpers} ) {

		my $helper_path;
		for( @{ $app->renderer->paths } ) {
			if( -r "$_/$conf->{helpers}" ) {
				$helper_path = "$_/$conf->{helpers}";
				last;
			}
		}

		die unless $helper_path;

		$hbjs->eval_file($helper_path);
	}

	for( @{ $app->renderer->paths } ) {
		next unless -d $_;
		# Magically picks up partials as well
		$hbjs->add_template_dir( $_ );
	}


	$app->renderer->add_handler( hbs => sub {
		my( $r, $c, $output, $options ) = @_;

		return unless $r->template_path($options) or length $options->{inline};

		if( length $options->{inline} ) {
			$$output = $hbjs->render_string( $options->{inline}, $c->stash );
		}
		elsif( $options->{template} ) {
			$$output = $hbjs->execute_template( $options->{template}, $c->stash );
		}
		elsif( my $template = $r->template_for($c) ) {
			$$output = $hbjs->execute_template( $template, $c->stash );
		}
		else {
			#TODO should this die?
			return;
		}

		if( $self->wrapper ) {
			$$output = $self->wrapper->({ %{$c->stash}, content => $$output });
		}

		return 1;
	} );
}



=head1 NAME

Mojolicious::Plugin::HandlebarsJSRenderer - Render Handlebars inside Mojolicious

=head1 SYNOPSIS

This is a plugin for adding the Handlebars templating language to Mojolicious as a renderer.

	sub startup {
		my $self = shift;
		...

		$self->plugin('HandlebarsJSRenderer', { [wrapper => "wrapper.hbs"], [helpers => "helpers.js"] });
		$self->renderer->default_handler('hbs') #default to hbs templates instead of epl
		...
	}

Note that by default when this plugin is initialized it attempts to cache every .hbs file inside your templates directory, which includes registering any files under a directory named 'partials' as a partial with the same name as the file. You can also pass a wrapper file which is executed after any render call and passed the results of the first render as the variable 'content'. 

Specifying a helpers.js file allow you to execute Handlebars.registerHelper() statements to provide functions to your templates. Or really, any other code you want. Any JS in this file is executed in the same global context that contains the Handlebars object that containers registeredHelpers, stored templates and is invokved to compile and execute new templates.

Automatically found parsers are stored as 'partial/partialname'; for example: ./templates/partials/things/myfoo.hbs; may be accessed as C<< {{>partials/things/myfoo}} >>

=head1 AUTHOR

Robert Grimes, C<< <rmzgrimes at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mojolicious-plugin-handlebarsjsrenderer at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mojolicious-Plugin-HandlebarsJSRenderer>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mojolicious::Plugin::HandlebarsJSRenderer


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mojolicious-Plugin-HandlebarsJSRenderer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Mojolicious-Plugin-HandlebarsJSRenderer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Mojolicious-Plugin-HandlebarsJSRenderer>

=item * Search CPAN

L<http://search.cpan.org/dist/Mojolicious-Plugin-HandlebarsJSRenderer/>

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

1; # End of Mojolicious::Plugin::HandlebarsJSRenderer
