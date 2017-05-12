package Template::Plugin::Haml;
use 5.006;
use strict;
use warnings;
BEGIN {
	our $VERSION = '0.1.2'; # VERSION
}

use parent 'Template::Plugin::Filter';
use Text::Haml;

sub init {
	my $self = shift;
	$self->{_DYNAMIC} = 1;
	$self->install_filter( $self->{_ARGS}->[0] || 'haml');
	return $self;
}

sub filter {
	my ( $self, $text ) = @_;

	my $haml = Text::Haml->new;
	return $haml->render($text);
}
1;
# ABSTRACT: Haml plugin for Template Toolkit

__END__
=pod

=head1 NAME

Template::Plugin::Haml - Haml plugin for Template Toolkit

=head1 VERSION

version 0.1.2

=head1 SYNOPSIS

	[%- USE Haml -%]
	[%- FILTER haml -%]
	%p Hello World
	[%- END -%]

	<p>Hello World</p>

=head1 DESCRIPTION

A thin wrapper around L<Text::Haml> when you load the plugin it creates a
filter called haml that you can use in a normal way. A full description of
the Haml language can be found on L<the haml site|http://haml-lang.com>. Haml
is a terse and whitespace sensitive html, xhtml, and xml templating system.
Compared to Template Toolkit however it is relatively limited in what you can
do. It by itself contains no includes, conditionals, or loop constructs. So
I've combined it here with TT to make writing those kinds of templates with
even less code easier.

=head2 EXAMPLE

=head3 input template

B<wrapper.tt>

	!!! 5
	%html
	[% content %]

B<hello.tt>

	[%- message='Hello World' %]
	[%- USE Haml -%]
	[%- WRAPPER wrapper.tt | haml -%]
	[%- FILTER haml -%]
	 %head
	  %meta{:charset => "utf-8"}
	  %title hello
	 %body
	  %p [% message %]
	  %ul
	  [%- total=0; WHILE total < 5 %]
	   %li [% total=total+1 %][% total %]
	  [%- END -%]
	[%- END -%]

I'd like to draw some attention to the while loop here you have to have the
-'s in just the right spots to make it work because of Haml's whitespace
sensitivity.

It's also important to note that <tags> will be </closed> in the templates
they're in. If you used PROCESS instead of WRAPPER above your template would
be output like

	...
	<html></html>
	 <head>
	...

instead of...

=head3 Output

	<!DOCTYPE html>
	<html>
	 <head>
	  <meta charset='utf-8' />
	  <title>hello</title>
	 </head>
	 <body>
	  <p>hello world</p>
	  <ul>
	   <li>1</li>
	   <li>2</li>
	   <li>3</li>
	   <li>4</li>
	   <li>5</li>
	  </ul>
	 </body>
	</html>

=head2 Methods

=over

=item init

initializes the the filter object

=item filter

method that actually does the transformation

=back

=head1 ACKNOWLEDGEMENTS

Thanks to kd, mst, Khisanth, aef on L<#tt on
irc.perl.org|irc://irc.perl.org/tt> for helping me
figure out why my first try didn't work

=head1 BUGS

=over

=item Haml variables don't work

use TT style variables instead

=back

=head1 AUTHOR

Caleb Cushing <xenoterracide@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Caleb Cushing.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

