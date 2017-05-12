# Template::Plugin::HTML::2Text
#
# DESCRIPTION
#   Wrapper around HTML::FormatText::Html2text module
#
# AUTHOR
#   Dalibor Horinek <dal@travelcook.com> 
#   http://www.travelcook.com/
#
# COPYRIGHT
#   Copyright (C) 2012 Dalibor Horinek. All Rights Reserved.
#
#   This module is free software; you can redistribute it and/or
#   modify it under the same terms as Perl itself.
#
package Template::Plugin::HTML::2Text;

use strict;
use vars qw( $VERSION );
use Template::Plugin::Filter;
use base qw( Template::Plugin::Filter );
use HTML::FormatText::Html2text;

our $VERSION = '0.1'; 
my $parser = new HTML::FormatText::Html2text;

sub init {
	my $self = shift;
	$self->{_DYNAMIC} = 1;
	$self->install_filter( "html2text" );
	return $self;
}

sub filter {
	my ( $self, $text ) = @_;

	return $parser->format_string($text)
}

1;

__END__

=head1 NAME

Template::Plugin::HTML::2Text - Template Toolkit plugin to transfor HTML into plain text
It simply wraps html2text using HTML::FormatText::Html2text 

=head1 SYNOPSIS

  [% FILTER 2Text %]
	<h1> Hello </h1>

	<h3> Bold, Italic and Underline </h3>
	<b>Bold</b>
	<b>Italic</b>
	<b>Underline</b>

	<h3> List </h3>
	<ul>
	<li> Test </li>
	<li> Test II </li>
	</ul>

	<h3> Table </h3>
	<table>
	<tr>
	<th> Col 1 </th>
	<th> Col 2 </th>
	</tr>
	<tr>
	<td> Val 1 </td>
	<td> Val 2 </td>
	</tr>
	</table>
  [% END %]

  Produces 

  ****** Hello ******
  **** Bold, Italic and Underline ****
  Bold Italic Underline
  **** List ****
      * Test
      * Test II
  **** Table ****
  Col 1 Col 2
  Val 1 Val 2

=head1 DESCRIPTION

Template::Plugin::HTML::2Text - Template Toolkit plugin to transfer HTML into plain text

See L<HTML::FormatText::Html2text|HTML::FormatText::Html2text> for more details.

=head1 SEE ALSO

L<Template|Template>, L<HTML::FormatText::Html2text>

=head1 AUTHOR

Dalibor Horinek, E<lt>dal@horinek.netE<gt>

L<http://www.travelcook.com/>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 Dalibor Horinek. All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
