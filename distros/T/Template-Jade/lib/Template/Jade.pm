package Template::Jade;

use 5.006;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.05';

use Moose;
use Template::Jade::Document;
use Sub::Exporter -setup => {
	exports => [qw(render_file render compile)]
};

my %valid_options;
for (qw/ compile_debug fh_output /) {
	$valid_options{$_} = undef;
}

sub render_file {
	my ( $filename, $opts, $cb ) = @_;

	die "No filename provided to render_file\n"
		unless defined $filename;


	my %tj_args = %{$opts//{}};
	for my $key ( keys %tj_args ) {
		delete $tj_args{$key} unless exists $valid_options{$key};
	}

	$tj_args{filename} = $filename;

	my $sub = Template::Jade::Document->new( \%tj_args )->process;
	$sub->($opts);
}

sub render {
	my ( $source, $opts ) = @_;
	
	die "No source provided to render"
		unless defined $source;

	open(my $fh_input, '<', \$source) or die $!;
	
	my %tj_args = %{$opts//{}};
	for my $key ( keys %tj_args ) {
		delete $tj_args{$key} unless exists $valid_options{$key};
	}
	
	$tj_args{fh_input} = $fh_input;

	my $sub = Template::Jade::Document->new( \%tj_args )->process;
	return $sub->($opts);

}

sub compile {
	my ( $source, $opts ) = @_;
	
	die "No source provided to compile"
		unless defined $source;
	
	open(my $fh_input, '<', \$source) or die $!;
	
	my %tj_args = %{$opts//{}};
	for my $key ( keys %tj_args ) {
		delete $tj_args{$key} unless exists $valid_options{$key};
	}
	
	$tj_args{fh_input} = $fh_input;
	
	my $sub = Template::Jade::Document->new( \%tj_args )->process;
	return $sub;
}

1;

__END__

=head1 NAME

Template::Jade - A port of Jade to Perl

=head1 SYNOPSIS

Parse Jade Markup L<http://jade-lang.com/>

		use Template::Jade qw(:all);
		
		my $html = render_file(
			'file.jade'
			, { TEMPLATE => { pageTitle => 'foo' }
		};

		my $html = render(
			$jade_string
			, { TEMPLATE => { pageTitle => 'foo' }
		);

		my $compiled_sub = compile(
			$jade_string
		);
		$compiled_sub->( { TEMPLATE => { pageTitle => 'foo' } );

Want an example of Jade Markup?

	doctype html
	html(lang="en")
		head
			script(type='text/javascript').
				if (foo) {
					bar(1 + 5)
				}
		body
			h1 Jade - node template engine
			#container.col
				if youAreUsingJade
					p You are amazing
				else
					p Get on it!
				p.
					Jade is a terse and simple
					templating language with a
					strong focus on performance
					and powerful features.

=head1 EXPORT

To sent a variable to the template, write to the hash B<$options-E<gt>{TEMPLATE}>

=head2 compile( $source, $options )

Compiles and returns a subroutine, called with options.

=head2 render( $source, $options )

Renders from scalar returning the markup.

=head2 render_file( $filename, $options )

Renders from file returning the markup.

=head1 DOCUMENTATION

Please view L<http://jade-lang.com/> for the official documentation.

Most of Jade is working: includes, blocks, conditionals, extends, inline tags,
implicit divs, comments (buffered and unbuffered), etc.

=head1 SUPPORTED OPTIONS

In calls to L<render_file>, L<render>, and L<compile> the following options are
always valid,

=over 4

=item compile_debug

Outputs the body of the function to be compiled, pre-compilation.

=item fh_output

Alternatively feed a filehandle and Template::Jade will write directly to it.

=back

=head1 CAVEATS

There are a few things not yet implimented.

=over 4

=item * Native Jade looping constructs

=item * Prepend/append block constructs

=item * Mixins -- compiled subroutines in the context of the parent.

=item * Non :markdown filters

=item * Array-set attributes a(href=@classes)

=item * Only supports HTML5

=back

Also, all code constructs (starting with '-' executes Perl not JavaScript). 

=head1 AUTHOR

Evan Carroll, C<< <me at evancarroll.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-jade at rt.cpan.org>, or through
the web interface at L<https://github.com/EvanCarroll/perl-template-jade/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Jade


You can also look for information at:

=over 4

=item * GitHub: CPAN's Real request tracker (unless you're delusional) (report bugs here)

L<https://github.com/EvanCarroll/perl-template-jade/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Jade>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Jade>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Jade/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Evan Carroll.

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

