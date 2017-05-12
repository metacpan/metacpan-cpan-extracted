use 5.014;
use strict;
use warnings;

use HTML::HTML5::Parser ();
use Pod::Simple ();
use XML::LibXML::QuerySelector ();

{
	package TOBYINK::Pod::HTML::Helper;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	
	use parent "Pod::Simple::HTML";
	
	sub new
	{
		my $class = shift;
		my $self  = $class->SUPER::new(@_);
		$self->perldoc_url_prefix("https://metacpan.org/pod/");
		return $self;
	}
	
	sub _get_titled_section
	{
		my $self = shift;
		my @r;
		$self->{_in_get_titled_section} = 1;
		wantarray
			? (@r    = $self->SUPER::_get_titled_section(@_))
			: ($r[0] = $self->SUPER::_get_titled_section(@_));
		delete $self->{_in_get_titled_section};
		wantarray ? @r : $r[0];
	}
	
	sub get_token
	{
		my $self = shift;
		my $tok = $self->SUPER::get_token;
		
		if (!$self->{_in_get_titled_section} and defined $tok and $tok->[0] eq 'start' and $tok->[1] eq 'for')
		{
			my $target = $tok->[2]{"target"};
			my $data;
			until ($tok->[0] eq 'end' and $tok->[1] eq 'for')
			{
				$data .= $tok->[1] if $tok->[0] eq 'text';
				$tok = $self->SUPER::get_token;
			}
			${$self->output_string} .= "<!-- for $target $data -->\n";
			$tok = $self->SUPER::get_token;
		}
		
		return $tok;
	}
}

{
	package TOBYINK::Pod::HTML;
	
	our $AUTHORITY = 'cpan:TOBYINK';
	our $VERSION   = '0.005';
	
	use Moo;
	use Carp;
	
	has pretty => (
		is      => 'ro',
		default => sub { 0 },
	);
	
	has code_highlighting => (
		is      => 'ro',
		default => sub { 0 },
	);
	
	has code_styles => (
		is      => 'ro',
		default => sub {
			return +{
				symbol        => 'color:#333;background-color:#fcc',
				pod           => 'color:#060',
				comment       => 'color:#060;font-style:italic',
				operator      => 'color:#000;font-weight:bold',
				single        => 'color:#909',
				double        => 'color:#909',
				literal       => 'color:#909',
				interpolate   => 'color:#909',
				words         => 'color:#333;background-color:#ffc',
				regex         => 'color:#333;background-color:#9f9',
				match         => 'color:#333;background-color:#9f9',
				substitute    => 'color:#333;background-color:#f90',
				transliterate => 'color:#333;background-color:#f90',
				number        => 'color:#39C',
				magic         => 'color:#900;font-weight:bold',
				cast          => 'color:#f00;font-weight:bold',
				pragma        => 'color:#009',
				keyword       => 'color:#009;font-weight:bold',
				core          => 'color:#009;font-weight:bold',
				line_number   => 'color:#666',
				# for non-Perl code
				alert         => 'color:#f00;background-color:#ff0',
				warning       => 'color:#f00;background-color:#ff0;font-style:italic',
				error         => 'color:#f00;background-color:#ff0;font-style:italic;font-weight:bold',
				bstring       => '',
				function      => '',
				regionmarker  => '',
				others        => '',
			}
		},
	);
	
	# tri-state (0, 1, undef)
	has code_line_numbers => (
		is      => 'ro',
		default => sub { +undef },
	);
	
	sub BUILD
	{
		my $self = shift;
		croak "code_line_numbers without code_highlighting will not work"
			if $self->code_line_numbers && !$self->code_highlighting;
	}
	
	sub file_to_dom
	{
		my $self = shift;
		$self->_pod_to_dom(parse_file => @_);
	}
	
	sub string_to_dom
	{
		my $self = shift;
		$self->_pod_to_dom(parse_string_document => @_);
	}
	
	sub file_to_html
	{
		my $self = shift;
		$self->_dom_to_html($self->file_to_dom(@_));
	}
	
	sub string_to_html
	{
		my $self = shift;
		$self->_dom_to_html($self->string_to_dom(@_));
	}
	
	sub file_to_xhtml
	{
		my $self = shift;
		$self->file_to_dom(@_)->toString;
	}
	
	sub string_to_xhtml
	{
		my $self = shift;
		$self->string_to_dom(@_)->toString;
	}
	
	sub _pull_code_styles
	{
		my $css  = shift->code_styles;
		my %pull = @_;
		$css->{$_} = $pull{$_} for grep !exists($css->{$_}), keys %pull;
	}
	
	sub _pod_to_dom
	{
		my $self = shift;
		my $dom  = $self->_make_dom( $self->_make_markup(@_) );
		$self->_dom_cleanups($dom);
		$self->_syntax_highlighting($dom) if $self->code_highlighting;
		if ($self->pretty)
		{
			require XML::LibXML::PrettyPrint;
			"XML::LibXML::PrettyPrint"->new_for_html->pretty_print($dom);
		}
		return $dom;
	}
	
	sub _make_markup
	{
		my $self = shift;
		my ($method, $input) = @_;
		
		my $tmp;
		my $p = (__PACKAGE__."::Helper")->new;
		$p->accept_targets(qw/ highlighter /);
		$p->output_string(\$tmp);
		$p->$method($input);
		return $tmp;
	}
	
	sub _make_dom
	{
		my $self = shift;
		my ($markup) = @_;
		my $dom = "HTML::HTML5::Parser"->load_html(string => $markup);
	}
	
	sub _dom_cleanups
	{
		my $self = shift;
		my ($dom) = @_;
		
		# My pod is always utf-8 or a subset thereof
		%{ $dom->querySelector('head meta') } = (charset => 'utf-8');
		
		# Non-useful comments
		$_->parentNode->removeChild($_) for
			grep { not /for (highlighter)/ }
			$dom->findnodes('//comment()');
		
		# Drop these <a name> elements
		$dom->querySelectorAll('a[name]')->foreach(sub
		{
			$_->setNodeName('span');
			%$_ = (id => $_->{name});
		});
	}
	
	sub _syntax_highlighting
	{
		my $self = shift;
		my ($dom) = @_;
		
		my $opt = {
			line_numbers => $self->code_line_numbers,
			language     => "perl",
		};
		
		$dom->findnodes('//comment() | //*[local-name()="pre"]')->foreach(sub
		{
			if ($_->nodeName eq '#comment')
			{
				my $data = $_->data;
				while ($data =~ m{\b(\w+?)=(\S+)}g)
				{
					my ($k, $v) = ($1, $2);
					$opt->{$k} = $v;
				}
				return;
			}
			
			$self->_syntax_highlighting_for_element($_ => $opt);
		});
	}
	
	sub _syntax_highlighting_for_element
	{
		my $self = shift;
		my ($pre, $opt) = @_;
		
		my $out = $self->_syntax_highlighting_for_text($pre->textContent, $opt);
		$out =~ s/<br>//g;  # already in <pre>!
		
		# Replace original <pre> contents with new stuff.
		$pre->removeChild($_) for $pre->childNodes;
		$pre->appendWellBalancedChunk($out);
		
		# Adjust CSS
		my $CSS = $self->code_styles;
		$pre->findnodes('.//*[@class]')->foreach(sub
		{
			$_->{style} = $CSS->{$_->{class}} if $CSS->{$_->{class}};
		});
		
		# Add @class to <pre> itself
		$pre->{class} = sprintf("highlighting-%s", lc $opt->{language});
	}
	
	sub _syntax_highlighting_for_text
	{
		my $self = shift;
		my ($txt, $opt) = @_;
		
		return $txt
			if $opt->{language} =~ /^(text)$/i;
		
		return $self->_syntax_highlighting_for_text_via_ppi(@_)
			if $opt->{language} =~ /^(perl)$/i;
		
		return $self->_syntax_highlighting_for_text_via_shrdf(@_)
			if $opt->{language} =~ /^(turtle|n.?triples|n.?quads|trig|n3|notation.?3|pret|pretdsl|sparql|sparql.?(update|query)|json|xml)$/i;
		
		return $self->_syntax_highlighting_for_text_via_kate(@_);
	}
	
	sub _syntax_highlighting_for_text_via_ppi
	{
		my $self = shift;
		my ($txt, $opt) = @_;
		
		require PPI::Document;
		require PPI::HTML;
		
		my $hlt = "PPI::HTML"->new(
			line_numbers => ($opt->{line_numbers} // scalar($txt =~ m{^\s+#!/}s)),
		);
		return $hlt->html("PPI::Document"->new(\$txt));
	}

	sub _syntax_highlighting_for_text_via_shrdf
	{
		my $self = shift;
		my ($txt, $opt) = @_;
		
		require Syntax::Highlight::RDF;
		require Syntax::Highlight::XML;
		require Syntax::Highlight::JSON2;
		
		# Syntax::Highlight::RDF uses different CSS classes
		my $css = $self->code_styles;
		$self->_pull_code_styles(%Syntax::Highlight::RDF::STYLE)
			unless $css->{rdf_comment};
		$self->_pull_code_styles(%Syntax::Highlight::XML::STYLE)
			unless $css->{xml_tag_is_doctype};
		$self->_pull_code_styles(%Syntax::Highlight::JSON2::STYLE)
			unless $css->{json_boolean};
		
		my $hlt = "Syntax::Highlight::RDF"->highlighter($opt->{language});
		return $hlt->highlight(\$txt);
	}

	# Does not support line numbers
	sub _syntax_highlighting_for_text_via_kate
	{
		my $self = shift;
		my ($txt, $opt) = @_;
		
		require Syntax::Highlight::Engine::Kate;
		
		my $hl = "Syntax::Highlight::Engine::Kate"->new(
			language      => $opt->{language},
			substitutions => {
				"<" => "&lt;",
				">" => "&gt;",
				"&" => "&amp;",
				"\n" => "\n",
			},
			format_table  => {
				Normal       => ["", ""],
				Keyword      => [q[<span class="keyword">],  q[</span>]],
				DataType     => [q[<span class="cast">],     q[</span>]],
				DecVal       => [q[<span class="number">],   q[</span>]],
				BaseN        => [q[<span class="number">],   q[</span>]],
				Float        => [q[<span class="number">],   q[</span>]],
				Char         => [q[<span class="single">],   q[</span>]],
				String       => [q[<span class="single">],   q[</span>]],
				IString      => [q[<span class="double">],   q[</span>]],
				Comment      => [q[<span class="comment">],  q[</span>]],
				Others       => [q[<span class="others">],   q[</span>]],
				Alert        => [q[<span class="alert">],    q[</span>]],
				Function     => [q[<span class="function">], q[</span>]],
				RegionMarker => [q[<span class="regionmarker">], q[</span>]],
				Error        => [q[<span class="error">],    q[</span>]],
				Operator     => [q[<span class="operator">], q[</span>]],
				Reserved     => [q[<span class="core">],     q[</span>]],
				Variable     => [q[<span class="symbol">],   q[</span>]],
				Warning      => [q[<span class="warning">],  q[</span>]],
				BString      => [q[<span class="bstring">],  q[</span>]],
			},
		);
		return $hl->highlightText($txt);
	}

	sub _dom_to_html
	{
		require HTML::HTML5::Writer;
		
		my $self = shift;
		return "HTML::HTML5::Writer"->new(polyglot => 1)->document(@_);
	}
}

__FILE__
__END__

=head1 NAME

TOBYINK::Pod::HTML - convert Pod to HTML like TOBYINK

=head1 SYNOPSIS

   #!/usr/bin/perl
   
   use strict;
   use warnings;
   use TOBYINK::Pod::HTML;
   
   my $pod2html = "TOBYINK::Pod::HTML"->new(
      pretty             => 1,       # nicely indented HTML
      code_highlighting  => 1,       # use PPI::HTML
      code_line_numbers  => undef,
      code_styles        => {        # some CSS
         comment   => 'color:green',
         keyword   => 'font-weight:bold',
      }
   );
   
   print $pod2html->file_to_html(__FILE__);

=head1 DESCRIPTION

Yet another pod2html converter.

Note that this module requires Perl 5.14, and I have no interest in
supporting legacy versions of Perl.

=head2 Constructor

=over

=item C<< new(%attrs) >>

Moose-style constructor.

=back

=head2 Attributes

=over

=item C<< pretty >>

If true, will output pretty-printed (nicely indented) HTML. This doesn't make
any difference to the appearance of the HTML in a browser.

This feature requires L<XML::LibXML::PrettyPrint>.

Defaults to false.

=item C<< code_highlighting >>

If true, source code samples within pod will be syntax highlighted as Perl 5.

This feature requires L<PPI::HTML> and L<PPI::Document>.

Defaults to false.

=item C<< code_line_numbers >>

If undef, source code samples within pod will have line numbers, but only if
they begin with C<< "#!" >>.

If true, all source code samples within pod will have line numbers.

This feature only works in conjunction with C<< code_highlighting >>.

Defaults to undef.

=item C<< code_styles >>

A hashref of CSS styles to assign to highlighted code. The defaults are:

   +{
      symbol        => 'color:#333;background-color:#fcc',
      pod           => 'color:#060',
      comment       => 'color:#060;font-style:italic',
      operator      => 'color:#000;font-weight:bold',
      single        => 'color:#909',
      double        => 'color:#909',
      literal       => 'color:#909',
      interpolate   => 'color:#909',
      words         => 'color:#333;background-color:#ffc',
      regex         => 'color:#333;background-color:#9f9',
      match         => 'color:#333;background-color:#9f9',
      substitute    => 'color:#333;background-color:#f90',
      transliterate => 'color:#333;background-color:#f90',
      number        => 'color:#39C',
      magic         => 'color:#900;font-weight:bold',
      cast          => 'color:#f00;font-weight:bold',
      pragma        => 'color:#009',
      keyword       => 'color:#009;font-weight:bold',
      core          => 'color:#009;font-weight:bold',
      line_number   => 'color:#666',
      # for non-Perl code
      alert         => 'color:#f00;background-color:#ff0',
      warning       => 'color:#f00;background-color:#ff0;font-style:italic',
      error         => 'color:#f00;background-color:#ff0;font-style:italic;font-weight:bold',
      bstring       => '',
      function      => '',
      regionmarker  => '',
      others        => '',
   }

Which looks kind of like the Perl highlighting from SciTE.

=back

=head2 Methods

=over

=item C<< file_to_dom($filename) >>

Convert pod from file to a L<XML::LibXML::Document> object.

=item C<< string_to_dom($document) >>

Convert pod from string to a L<XML::LibXML::Document> object.

=item C<< file_to_xhtml($filename) >>

Convert pod from file to an XHTML string.

=item C<< string_to_xhtml($document) >>

Convert pod from string to an XHTML string.

=item C<< file_to_html($filename) >>

Convert pod from file to an HTML5 string.

This feature requires L<HTML::HTML5::Writer>.

=item C<< string_to_html($document) >>

Convert pod from string to an HTML5 string.

This feature requires L<HTML::HTML5::Writer>.

=back

=begin trustme

=item C<< BUILD >>

=end trustme

=head2 Alternative Syntax Highlighting

=for highlighter language=Text

This module defines an additional Pod command to change the language for
syntax highlighting. To tell TOBYINK::Pod::HTML to switch to, say, Haskell
instead of the default (Perl), just use:

   =for highlighter language=Haskell

Then all subsequent code samples will be highlighted as Haskell, until
another such command is seen.

While syntax highlighting for Perl uses L<PPI::HTML>, syntax highlighting
for other languages uses either L<Syntax::Highlight::RDF> or
L<Syntax::Highlight::Engine::Kate> as appropriate, so you need to have
them installed if you want this feature.

Note that the language names defined by Syntax::Highlight::Engine::Kate
are case-sensitive, and TOBYINK::Pod::HTML makes no attempt at case-folding,
so you must use the correct case!

Note that only the PPI highlighter supports line numbering.

The following command can be used to switch to plain text syntax highlighting
(i.e. no highlighting at all):

   =for highlighter language=Text

=for highlighter language=Perl

=head1 SEE ALSO

L<Pod::Simple>, L<PPI::HTML>, etc.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
