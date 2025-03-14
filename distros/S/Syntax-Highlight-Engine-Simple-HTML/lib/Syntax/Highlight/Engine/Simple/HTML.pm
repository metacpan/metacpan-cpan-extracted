package Syntax::Highlight::Engine::Simple::HTML;
use strict;
use warnings;
use base qw(Syntax::Highlight::Engine::Simple);
our $VERSION = '0.051';

### ----------------------------------------------------------------------------
### set syntax
### ----------------------------------------------------------------------------
sub setSyntax {
	
	shift->{syntax} =
		[
			{
				class => 'tag',
				regexp => q!(?s)(?<=<).+?(?=>)!,
			},
			{
				class => 'quote',
				regexp => q!(?s)'.*?'!,
				container => 'tag',
			},
			{
				class => 'wquote',
				regexp => q!(?s)".*?"!,
				container => 'tag',
			},
			{
				class => 'number',
				regexp => '\b\d+\b',
				container => 'tag',
			},	
			{
				class => 'comment',
				regexp => '(?s)<!--.*?-->',
			},
			{
				class => 'url',
				regexp => q!s?https?://[-_.\!~*'()a-zA-Z0-9;/?:@&=+$,%#]+!,
			},
		];
}

return 1;

__END__

=head1 NAME

Syntax::Highlight::Engine::Simple::HTML - (EXPERIMENTAL)HTML code highlighting class

=head1 VERSION

This document describes Syntax::Highlight::Engine::Simple::HTML

=head1 SYNOPSIS

Constructor

	use Syntax::Highlight::Engine::Simple::HTML;
	
	$highlighter =
		Syntax::Highlight::Engine::Simple::HTML->new();
		
	or
	
	use Syntax::Highlight::Engine::Simple;
	
	$highlighter =
		Syntax::Highlight::Engine::Simple->new(type => 'HTML');

Highlighting stage

	$highlighter->doStr(
		str => $str,
		tab_width => 4);
	
	$highlighter->doFile(
		str => $str,
		tab_width => 4,
		encode => 'utf8');

=head1 DESCRIPTION

This is a sub class of Syntax::Highlight::Engine::Simple.

A working example of This module is at bellow.

http://jamadam.com/dev/cpan/demo/Syntax/Highlight/Engine/Simple/

=head1 INTERFACE 

=head2 new

=over

=item type

File type. This argument causes specific sub class to be loaded.

=back

=head2 setParams

=over

=item html_escape_code_ref

HTML escape code ref. Default subroutine escapes 3 characters '&', '<' and '>'.

=back

=head2 appendSyntax

Append syntax by giving a hash.

=over

	$highlighter->setSyntax(
	    syntax => {
	        class => 'quote',
	        regexp => "'.*?'",
	        container => 'comment',
	    }
	);

=back

=head2 doStr

Highlighting strings.

	$highlighter->doStr(
	    str => $str,
	    tab_width => 4
	);

=over

=item str

String.

=item tab_width

Tab width for tab-space conversion. -1 for disable it. -1 is the default.

=back

=head2 doFile

Highlighting files.

	$highlighter->doStr(
	    str => $str,
	    tab_width => 4,
	    encode => 'utf8'
	);

=over

=item file

File name.

=item tab_width

Tab width for tab-space conversion. -1 for disable it. -1 is the default.

=item encode

Set the encode of file. utf8 is the default.

=back

=head2 array2regexp

This is a utility method for converting string array to regular expression.

=over

=back

=head2 getClassNames

Returns the class names in array.

=over

=back

=head2 setSyntax

This is a method for initializing the syntax. It is called by constructor so
you may not have to call it manually.

=head1 Example

Here is a sample of CSS.

	pre.program_code span.keyword {color: #00f}
	pre.program_code span.keyword2 {color: #808}
	pre.program_code span.number {color: #f00}
	pre.program_code span.identifier {color: #a66}
	pre.program_code span.function {color: #a66; text-decoration: underline}
	pre.program_code span.method {color: #a66; text-decoration: underline}
	pre.program_code span.variable {color: #f80}
	pre.program_code span.statement {color: #00f}
	pre.program_code span.comment {color: #080}
	pre.program_code span.perlpod {color: #080}
	pre.program_code span.quote {color: #a66}
	pre.program_code span.wquote {color: #600}
	pre.program_code span.value {color: #a66}
	pre.program_code span.regexp_statement {background: #ffa}
	pre.program_code span.tag {color: #00f}
	pre.program_code span.url {color: #00f; text-decoration: underline}

=head1 DIAGNOSTICS

=over

=item C<< doStr method got undefined value >>

=item C<< File open failed >>

=back

=head1 CONFIGURATION AND ENVIRONMENT

Syntax::Highlight::Engine::Simple::HTML requires no configuration files or environment variables. Specific language syntax can be defined with sub classes and loaded in constructor if you give it the type argument.

=head1 DEPENDENCIES

=over

=item UNIVERSAL::require

=item Syntax::Highlight::Engine::Simple

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-syntax-highlight-engine-Simple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 SEE ALSO

=over

=item L<Syntax::Highlight::Engine::Simple>

=back

=head1 AUTHOR

Sugama Keita  C<< <sugama@jamadam.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Sugama Keita C<< <sugama@jamadam.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See I<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
