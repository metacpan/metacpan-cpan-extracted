package Template::Plugin::Tooltip;

=pod

=head1 NAME

Template::Plugin::Tooltip - Template Toolkit plugin for HTML::Tooltip::JavaScript

=head1 SYNOPSIS

  Load the tooltip generator.
  Params are passed straight to to HTML::Tooltip::JavaScript->new
  [% USE Tooltip( 'javascript_dir', '../../../static/js/', 'options',
	bordercolor => "#000000",
	title       => '',
	) %]
  
  Add a tooltip to a link
  <a href="foo" [% Tooltip(
      html_tooltip_content,
      param, value,
      param, value,
      %]>Link content</a>

=head1 DESCRIPTION

Template::Plugin::Tooltip is a Template Toolkit hook to the marvelous
L<HTML::Tooltip::Javascript> module.

The first version was written in 30 minutes following the talk on
HTML::Tooltip::Javascript at the Open Source Developers Conference,
just after its initial release.

=head2 API Overview

This module is very much just a thin layer over the top of the
HTML::Tooltip::JavaScript API, and you should probably go read and
understand its API before using this module.

To summarise VERY briefly, when you load in the plugin, the params go as
params to the H::T::Javascript C<new> constructor, with the new Tooltip
object stored internally. When you create a tooltip, the HTML content and
parameters are passed directly to H::T::Javascript C<tooltip> method.

=head2 Loading the Tooltip Generator

To load the tooltip generator with the default options, you can simple do
the following.

  [% USE Tooltip %]

In the same way you pass params to the HTML::Tooltip::Javascript
constructor, you can also pass params when loading in the Tooltip plugin.

  [% USE Tooltip('param', 'value') %]

=head2 Using the Tooltip Generator

L<HTML::Tooltip::Javascript> provides one simple method through which
you generate all the different tooltips.

In Template::Plugin::Tooltip, you just use the loaded plugin directly.

  [% Tooltip( 'This is my plain tooltip' ) %]

This only generates the Javascript tag properties, so this needs to be used
within a tag, like an anchor tag.

  <a href="#item" [% Tooltip('A tooltip') %]>item</a>

The first param is literal HTML content, and you can provide any additional
parameters you want for the tooltip, as you would do create the tooltip
directly.

  <a href="#item" [% Tooltip('A tooltip', 'bgcolor', 'pink') %]>item</a>

=head2 Initialising the Tooltip Library

The one additional step you will need to do is load in the tooltip
JavaScript library that drives the whole thing.

To do this, simple add the following to the end of the page, or to the
E<lt>headE<gt> section of your HTML document.

  [% Tooltip() %]

=head2 Use as a Filter

TO BE COMPLETED

=cut

use 5.005;
use strict;
use Scalar::Util              ();
use Template::Plugin          ();
use HTML::Tooltip::Javascript ();

use vars qw{$VERSION @ISA};
BEGIN {
	$VERSION = '1.08';
	@ISA     = 'Template::Plugin';
}

# Inlined copy of Params::Util::_INSTANCE
sub _INSTANCE ($$) {
	(Scalar::Util::blessed($_[0]) and $_[0]->isa($_[1])) ? $_[0] : undef;
}





#####################################################################
# Constructor

sub new {
	my $class   = ref $_[0] ? ref shift : shift;
	my $Context = _INSTANCE(shift, 'Template::Context')
		or $class->error('Tooltip constructor called without Template::Context');

	# Create a new ::Tooltip object, passing on params
	my $Tooltip = HTML::Tooltip::Javascript->new( @_ )
		or $class->error('Bad params to Tooltip generator constructor');

	# Create our TT interface object
	my $self = bless {
		Tooltip => $Tooltip,
		}, $class;

	# Wrap in the closure subroutine
	sub { defined $_[0] ? $self->tooltip(@_) : $self->head };
}

sub tooltip {
	my $self = shift;

	# If we don't get any parameters, we want a direct handle to the
	# object so that we can call init.
	return $self unless @_;

	# Pass everything straight through to the HTML::Tooltip::JavaScript
	# object we created earlier.
	my ($html, %params) = @_;
	$self->{Tooltip}->tooltip( $html, \%params );
}

sub head {
	$_[0]->at_end;
}

sub at_end {
	$_[0]->{Tooltip}->at_end;
}

1;

=pod

=head1 SUPPORT

Bugs should be submitted via the CPAN bug tracker, located at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plugin-Tooltip>

For other issues, or commercial enhancement or support, contact the author..

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 ACKOWLEDGEMENTS

Thank you to Phase N Australia for permitting the open sourcing and release
of this distribution as a spin-off from a commercial project.

=head1 COPYRIGHT

Copyright 2004 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
