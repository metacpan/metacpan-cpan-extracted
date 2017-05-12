package Pod::Advent;

use strict;
use warnings;
use base qw(Pod::Simple);
use Perl::Tidy;
use Cwd;
use File::Basename();
use HTML::Entities();

our $VERSION = '0.24';

our @mode;
our $section;
our %data;
our %blocks;
our %M_values_seen;
our $BODY_ONLY;
our $speller;
our @misspelled;
our %footnotes;
our @PERLTIDY_ARGV = qw/ -npro -html -pre /;

__PACKAGE__->__reset();

sub __reset(){
  my $self = shift;

  @mode = ();
  $section = '';
  %data = (
    title => undef,
    author => undef,
    year => (localtime)[5]+1900,
    day => 0,
    body => '',
    file => undef,
    css_url => '../style.css',
    isAdvent => 1,
  );
  %blocks = (
    code => '',
    codeNNN => '',
    pre => '',
    sourced_file => '',
    sourced_desc => '',
  );
  %M_values_seen = ();
  $BODY_ONLY = 0;
  $speller = undef;
  eval {
    require Text::Aspell;
    $speller = Text::Aspell->new;
    $speller->set_option('lang','en_US');
  };
  $self->spellcheck_enabled or warn "Couldn't load Text::Aspell -- spellchecking disabled.";
  @misspelled = ();
  %footnotes = ();
}

sub spellcheck_enabled {
  my $self = shift;
  return ref($speller) eq 'Text::Aspell' ? 1 : 0;
}

sub new {
  my $self = shift;
  $self = $self->SUPER::new(@_);
  $self->accept_codes( qw/A D M N P/ );
  $self->accept_targets_as_text( qw/advent_title advent_author advent_year advent_day/ );
  $self->accept_targets( qw/code codeNNN pre/ );
  $self->accept_targets_as_text( qw/quote eds footnote/ );
  $self->accept_directive_as_data('sourcedcode');
  $self->__reset();
  return $self;
}

sub css_url {
  my $self = shift;
  if( scalar @_ ){
    $data{css_url} = $_[0];
  }
  return $data{css_url};
}

sub parse_file {
  my $self = shift;
  my $filename = shift;
  my $cwd = getcwd();
  if( ! ref($filename) ){ # if it's a scalar, meaning a filename
    my( $f, $d) = File::Basename::fileparse($filename);
    $data{file} = $f;
    $filename = $f;
    chdir $d;
  }
  $self = $self->SUPER::parse_file($filename, @_);
  chdir $cwd;
}

sub add {
  my $self = shift;
  my $s = shift;
  $data{body} .= $s;
}

sub nl {
  my $self = shift;
  $self->add("\n");
}

sub _handle_element_start {
  my($parser, $element_name, $attr_hash_r) = @_;
  push @mode, $element_name;
  if( $element_name eq 'Document' ){
  }elsif( $element_name eq 'head1' ){
    $parser->add('<h1>');
  }elsif( $element_name eq 'head2' ){
    $parser->add('<h2>');
  }elsif( $element_name eq 'head3' ){
    $parser->add('<h3>');
  }elsif( $element_name eq 'head4' ){
    $parser->add('<h4>');
  }elsif( $element_name eq 'Para' && $mode[-2] eq 'footnote' ){
    # nothing
  }elsif( $element_name eq 'Para' && $mode[-2] ne 'for' ){
    $parser->add('<p>');
  }elsif( $element_name eq 'L' ){
    $parser->add( sprintf('<a href="%s">',$attr_hash_r->{to}) );
  }elsif( $element_name eq 'A' ){
  }elsif( $element_name eq 'M' ){
    $parser->add('<tt>');
  }elsif( $element_name eq 'F' ){
    $parser->add('<tt>');
  }elsif( $element_name eq 'C' ){
    $parser->add('<tt>');
  }elsif( $element_name eq 'I' ){
    $parser->add('<span style="font-style: italic">');
  }elsif( $element_name eq 'B' ){
    $parser->add('<span style="font-weight: bold">');
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} =~ /^advent_(\w+)$/ ){
    $section = $1;
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'footnote' ){
    $mode[-1] = $attr_hash_r->{target};
    $section = $attr_hash_r->{title};
    my $n = delete $footnotes{$section} or die "footnote '$section' is not referenced.";
    $parser->add( sprintf '<p><a name="footnote_%s" id="footnote_%s"></a>%d. ', $section, $section, $n);
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'quote' ){
    $mode[-1] = $attr_hash_r->{target};
    $parser->add('<blockquote>');
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'eds' ){
    $mode[-1] = $attr_hash_r->{target};
    $parser->add('<blockquote>');
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'code' ){
    $section = $attr_hash_r->{target};
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'codeNNN' ){
    $section = $attr_hash_r->{target};
  }elsif( $element_name eq 'for' && $attr_hash_r->{target} eq 'pre' ){
    $mode[-1] = $attr_hash_r->{target};
    $section = $attr_hash_r->{title} || 'normal';
  }
}

sub _handle_element_end {
  my($parser, $element_name) = @_;
  my $mode = pop @mode;
  if( $element_name eq 'Document' ){
    die "footnote '$_' is not defined" for keys %footnotes;
    my ($htmlTitle, $pageTitle) = $data{isAdvent}
	? ( sprintf('%d Perl Advent Calendar: %s',map {defined($_)?$_:''} @data{qw/year title/}),
		sprintf('<h1><a href="../">Perl Advent Calendar %d-12</a>-%02d</h1>'."\n".'<h2 align="center">%s</h2>',,map {defined($_)?$_:''} @data{qw/year day title/})  )
	: ( $data{title}||'',
		sprintf('<h1>%s</h1>',$data{title}||'')  )
    ;
    my $fmt = <<'EOF';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<!-- Generated by Pod::Advent %s (Pod::Simple %s, Perl::Tidy %s) on %04d-%02d-%02d %02d:%02d:%02d -->
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>%s</title>
<link rel="stylesheet" href="%s" type="text/css" />
%s
</head>
<body>
%s
%s
EOF
    my @d = (localtime)[5,4,3,2,1,0]; $d[1]++; $d[0]+=1900;
    my $fh = $parser->output_fh() || \*STDOUT;
    printf( $fh $fmt,
	$Pod::Advent::VERSION, $Pod::Simple::VERSION, $Perl::Tidy::VERSION,
	@d[0..5],
	$htmlTitle,
	$data{css_url},
	$data{file} ? qq{<link rel="alternate" type="text/plain" href="$data{file}" />} : "",
	$pageTitle,
	$data{author} ? qq{<h3 align="center">by $data{author}</h3>} : '',
    ) unless $BODY_ONLY;
    print $fh $data{body};
    if( $data{file} ){
      printf $fh '<div style="float: right; font-size: 10pt"><a href="%s">View Source (POD)</a></div><br />'."\n", $data{file};
    }
    print $fh <<'EOF' unless $BODY_ONLY;
</body>
</html>
EOF
  }elsif( $element_name eq 'head1' ){
    $parser->add('</h1>');
    $parser->nl;
  }elsif( $element_name eq 'head2' ){
    $parser->add('</h2>');
    $parser->nl;
  }elsif( $element_name eq 'head3' ){
    $parser->add('</h3>');
    $parser->nl;
  }elsif( $element_name eq 'head4' ){
    $parser->add('</h4>');
    $parser->nl;
  }elsif( $element_name eq 'Para' && $mode[-1] eq 'footnote' ){
    $parser->add('<br>');
    $parser->nl;
  }elsif( $element_name eq 'Para' && $mode[-1] ne 'for' ){
    $parser->add('</p>');
    $parser->nl;
  }elsif( $element_name eq 'for' && $mode eq 'quote' ){
    $parser->add('</blockquote>');
    $parser->nl;
  }elsif( $element_name eq 'for' && $mode eq 'eds' ){
    $parser->add('</blockquote>');
    $parser->nl;
  }elsif( $element_name eq 'for' && $mode eq 'footnote' ){
    $parser->add('</p>');
    $parser->nl;
  }elsif( $element_name eq 'for' && ($section eq 'code' || $section eq 'codeNNN') ){
    my $s;
    $blocks{$section} =~ s/\s+$//;
    Perl::Tidy::perltidy(
        source            => \$blocks{$section},
        destination       => \$s,
        argv              => [ @PERLTIDY_ARGV, ($section=~/NNN/?'-nnn':()) ],
    );
    $parser->add($s);
    $parser->nl;
    $blocks{$section} = '';
    $section = '';
  }elsif( $element_name eq 'for' && $mode eq 'pre' ){
    $blocks{$section} =~ s/\s+$//s;
    $parser->add('<pre><span class="c">');
    my $s = $blocks{$section};
    $s = HTML::Entities::encode_entities($s) if $section eq 'encode_entities';
    $parser->add( $s );
    $parser->add('</span></pre>');
    $parser->nl;
    $blocks{$section} = '';
    $section = '';
  }elsif( $element_name eq 'L' ){
    $parser->add('</a>');
  }elsif( $element_name eq 'M' ){
    $parser->add('</tt>');
  }elsif( $element_name eq 'A' ){
  }elsif( $element_name eq 'F' ){
    $parser->add('</tt>');
  }elsif( $element_name eq 'C' ){
    $parser->add('</tt>');
  }elsif( $element_name eq 'I' ){
    $parser->add('</span>');
  }elsif( $element_name eq 'B' ){
    $parser->add('</span>');
  }
}

sub _handle_text {
  my($parser, $text) = @_;
  my $mode = $mode[-1];
  my $out = '';
  if( $mode eq 'Verbatim' ){
    my $s;
    Perl::Tidy::perltidy(
        source            => \$text,
        destination       => \$s,
        argv              => [ @PERLTIDY_ARGV ],
    );
    $out .= $s;
  }elsif( $mode eq 'C' ){
    my $s;
    Perl::Tidy::perltidy(
        source            => \$text,
        destination       => \$s,
        argv              => [ @PERLTIDY_ARGV ],
    );
    $s =~ s#^<pre>\s*(.*?)\s*</pre>\s*$#$1#si;
    $out .= $s;
  }elsif( $mode eq 'N' ){
    die "footnote '$text' is already referenced" if exists $footnotes{$text};
    $footnotes{$text} = 1 + scalar keys %footnotes;
    $out .= sprintf '<sup><a href="#footnote_%s">%s</a></sup>', $text, $footnotes{$text};
  }elsif( $mode eq 'P' ){
    my ($year, $day, $label) = $text =~ m/^(\d{4})-(?:12-)?(\d{1,2})(?:\|(.+))?$/;
    my $CURYEAR = (localtime)[5] + 1900;
    die "invalid date from P<$text>" unless $year && 2000 <= $year && $year <= $CURYEAR && 1 <= $day && $day <= 25;
    $out .= sprintf '<a href="../../%d/%d/">%s</a>',
	$year, $day, ($label ? $label : sprintf '%d/%d', $year, $day);

  }elsif( $mode eq 'sourcedcode' ){
    die "bad filename '$text'" unless -r $text;
    $blocks{sourced_file} = $text;
    $out .= sprintf '<a name="%s" id="%s"></a><h2><a href="%s">%s</a></h2>', ($text)x4;
    my $s;
    Perl::Tidy::perltidy(
        source            => $text,
        destination       => \$s,
        argv              => [ @PERLTIDY_ARGV, '-nnn' ],
#	formatter         => bless( {file=>$text, dest => \$s}, 'Pod::Advent::Tidy' ),
    );
    $s =~ s#^\s*(\d+) #<a name="$text.$1"></a>$&#mg;
    $out .= $s;
  }elsif( $mode eq 'Para' && $section ){
    $data{$section} = $text;
    $section = '';
    $parser->__spellcheck($text);
    $out .= $text if $mode[-2] eq 'footnote';
  }elsif( $mode eq 'A' ){
    my $href;
    ($href, $text) = split /\|/, $text, 2;
    $text = $href unless defined $text;
    $parser->__spellcheck($text) unless $text =~ /^http/;
    $parser->add( sprintf('<a href="%s">%s</a>',$href,$text) );
  }elsif( $mode eq 'M' ){
    my($real, $alt);
    unless( ($real, $alt) = split /\|/, $text, 2 ){
	$real = $text;
    }
    $alt = $real if !defined $alt;
    if( $M_values_seen{$real}++ ){
      $parser->add( sprintf('<span title="%s">%s</span>', $real, $alt) );
    }else{
      $parser->add( sprintf('<a href="http://search.cpan.org/perldoc?%s" title="%s">%s</a>',$real,$real, $alt) );
    }
  }elsif( $mode eq 'Data' && $section ){
    $blocks{$section} .= $text . "\n\n";
  }elsif( $mode eq 'F' ){
    $out .= $text;
  }elsif( $mode eq 'L' ){
    $out .= $text;
  }elsif( $mode eq 'D' ){
    $out .= $text;
  }else{
    $parser->__spellcheck($text);
    $out .= $text;
  }
  $parser->add( $out, undef );
}

sub __spellcheck {
  my $parser = shift;
  my $text = shift;
  return unless $parser->spellcheck_enabled;
  my $bad_ct = 0;
  foreach my $word (  split /\W+/, $text ){
    next if $speller->check( $word ) || $word =~ /^\d+$/;
    push @misspelled, $word;
    $bad_ct++;
  }
  return $bad_ct;
}

sub spelling_errors {
  my $self = shift;
  return @misspelled;
}

sub num_spelling_errors {
  my $self = shift;
  return scalar @misspelled;
}

1; # End of Pod::Advent

#package Pod::Advent::Tidy;
#sub write_line {
#  my ( $self, $line_of_tokens ) = @_;
#  ${ $self->{dest} } .= sprintf q{<a name="%s.%s"></a>%4d %s},
#	$self->{file},
#	$line_of_tokens->{_line_number},
#	$line_of_tokens->{_line_number},
#	$line_of_tokens->{_line_text},
#  ;
#}
#1;

__END__

=pod

=head1 NAME

Pod::Advent - POD Formatter for The Perl Advent Calendar

=head1 VERSION

Version 0.24

=head1 GETTING STARTED

Most likely, the included I<pod2advent> script is all you will need:

  pod2advent entry.pod > entry.html

Where the .pod is written using the tags described below.  There is also a quick start at L<http://search.cpan.org/dist/Pod-Advent/ex/getting_started.html>.

=head1 SYNOPSIS

Using this module directly:

  use Pod::Advent;
  my $pod = shift @ARGV or die "need pod filename";
  my $advent = Pod::Advent->new;
  $advent->parse_file( \*STDIN );

Example POD:

  =for advent_year 2009

  =for advent_day 32

  =for advent_title This is a sample

  =for advent_author Your Name Here

  Today's module M<My::Example> is featured on
  the A<http://example.com|Example Place> web site
  and is I<very> B<special>.

  =sourcedcode example.pl

B<Getting Started:>
See F<ex/getting_started.pod> and F<ex/getting_started.html> in the distribution for an initial template.

=head1 DESCRIPTION

This module provides a POD formatter that is designed to facilitate the create of submissions for The Perl Advent Calendar (L<http://perladvent.pm.org>) by providing authors with simple markup that will be automatically transformed to full-fill the specific formatting guidelines. This makes it easier for authors to provide calendar-ready submissions, and for the editors to save lots of time in editting submissions.

For example, 'file-, module and program names should be wrapped in <tt>,' and 'the code sample should be appended to the document from the results of a perltidy -nnn -html'. Both of these can be trivially accomplished:

  This entry is for M<Foo::Bar> and the F<script.pl> program.

  =sourcedcode mod0.pl

The meta-data of title, date (year & day), and author is now easy to specify as well, and is used to automatically generate the full HTML header (including style) that the calendar entries require before being posted.

See F<ex/sample.pod> and F<ex/sample.html> in the distribution for a fuller example.

=head1 SUPPORTED POD

General note: HTML code in the pod source will be left alone, so it's effectively passed through. For example, these two lines are identical:

    B<blah>
    <b>blah</b>

This being POD, the former should be used.
Where the html is useful is more for things w/o POD equivalents,
like HTML encoding and writing C<&amp;>, C<&hellip;>, C<&mdash;>, etc
or using E<lt>BRE<gt>'s, E<lt>HRE<gt>'s, etc,
or including images, comments, etc.
Be aware that you may need to use the C<ZE<lt>E<gt>> pod code to prevent some cases of html use from being interpreted as POD.

=head2 Custom Codes

=head3 AE<lt>E<gt>

This is because POD doesn't support the case of LE<lt>http://example.com|ExampleE<gt>, so we introduce this AE<lt>E<gt> code for that exact purpose -- to generate E<lt>a href="URL"E<gt>TEXTE<lt>/aE<gt> hyperlinks.

  A<http://perladvent.pm.org|The Perl Advent Calendar>
  A<http://perladvent.pm.org>

=head3 ME<lt>E<gt>

This is intended for module names. The first instance, it will <tt> it and hyperlink it to a F<http://search.cpan.org/perldoc?> url. All following instances will just <tt> it. Being just for module searches, any other searches can simply use the AE<lt>E<gt> code instead.

  M<Pod::Simple>
  M<Pod::Simple|PS>
  A<http://search.cpan.org/search?query=Pod::Simple::Subclassing|Pod::Simple::Subclassing>
  A<http://search.cpan.org/search?dist=TimeDate|TimeDate>

=head3 NE<lt>E<gt>

Insert a superscript footnote reference. See L<"Footnotes">.

=head3 PE<lt>E<gt>

Link to a B<P>ast Advent Calendar entry.  Syntax is I<E<lt>YYYY-DE<gt>>. I<YYYY-12-D> may also be used, as can I<E<lt>YYYY-D|labelE<gt>> (or both).

=head3 DE<lt>E<gt>

B<D>isables spellchecking for the contents, which can be a single word or a phrase (including other pod formatting).


=head2 Custom Directives

=head3 sourcedcode

Include the contents of a file formatted with Perl::Tidy (including line numbers).

  =sourcedcode foo.pl

The line numbers are anchored, so you can refer to them with links:

  A<#foo.pl.3|third line>

=head2 Custom Info Targets

=head3 advent_title

Specify the title of the submission.

  =for advent_title Your Entry Title

=head3 advent_author

Specify the author of the submission.

  =for advent_author Your Name Here

=head3 advent_year

Specify the year of the submission (defaults to current year).

  =for advent_year 2009

=head3 advent_day

Specify the day of the submission (if currently known).

  =for advent_day 99

=head2 Custom Block Targets

=head3 code

Display a code snippet (sends it through Perl::Tidy).

  =begin code
  my $foo = Bar->new();
  $foo->do_it;
  =end code

=head3 codeNNN

Same as L<code>, but with line numbers.

  =begin codeNNN
  my $foo = Bar->new();
  $foo->do_it;
  =end codeNNN

=head3 pre [encode_entities]

Display a snippet (e.g. data, output, etc) as E<lt>PREE<gt>-formatted text (does not use Perl::Tidy).

  =begin pre
  x,y,z
  1,2,3
  2,4,9
  3,8,27
  =end pre

If C<encode_entities> parameter is specified, then the text will be processed by L<HTML::Entities>C<::encode_entities()>.  This is especially handy/necessary if your text contains E<lt>'s or E<gt>'s.

=head3 quote

Processes POD and wraps it in a E<lt>BLOCKQUOTEE<gt> section.

  =begin quote
  "Ho-Ho-Ho!"
    -- S.C.
  =end quote

=head3 eds

Currently behaves exactly the same as L<quote>.

  =begin eds
  The editors requested
  this directive.
    -- the management
  =end eds

=head3 footnote

Define a footnote's content. See L<"Footnotes">.

=head2 Footnotes

A footnote consists of a pair of elements -- one is the L<"NE<lt>E<gt>"> code and one is the L<"footnote"> target. They are each pass a common identifier for the footnote.  This way the author doesn't have to keep track of the numbering.

  In this entry we talk about XYZ.N<foo>

  ...

  =begin footnote foo

  The interesting thing about this is B<bar>.

  =end footnote

Note that the identifier is used for an anchor name (C<#footnote_foo>), so it must be C</^\w+$/>.

The reference will appear as a superscript number.  The first instance of L<"NE<lt>E<gt>"> will be C<1>, the next C<2>, and so on.

=head2 Standard Codes

=head3 LE<lt>E<gt>

Normal behavior.

=head3 FE<lt>E<gt>

Normal behavior.  Uses E<lt>ttE<gt>

=head3 CE<lt>E<gt>

Uses E<lt>ttE<gt>. Sends text through Perl::Tidy.

=head3 IE<lt>E<gt>

Normal behavior: uses E<lt>IE<gt>

=head3 BE<lt>E<gt>

Normal behavior: uses E<lt>BE<gt>

=head2 Standard Directives

=head3 headN

Expected behavior (N=1..4): uses E<lt>headNE<gt>

=head1 METHODS

See L<Pod::Simple> for all of the inherited methods.  Also see L<Pod::Simple::Subclassing> for more information.

=head2 new

Constructor.  See L<Pod::Simple>.

=head2 parse_file

Overloaded from Pod::Simple -- if input is a filename, will add a link to it at the bottom of the generated HTML.

Also, if input is a filename, it will chdir to the filename's directory before parsing the file.  Thus any files referenced (e.g. in a L<"sourcedcode"> tag) are expected to be relative to the .pod file itself.

=head2 css_url

Accessor/mutator for the stylesheet to use.  Defaults to F<../style.css>

=head2 spellcheck_enabled

Returns a boolean of whether or not spellchecking will be done (depends on presence of L<Text::Aspell>).

=head2 num_spelling_errors

Returns the number of (possible) spelling errors found while parsing.

=head2 spelling_errors

Returns an array of the (possible) spelling errors found while parsing.


=head1 INTERNAL METHODS

=head2 add

Appends text to the output buffer.

=head2 nl

Appends a newline onto the output buffer.

=head2 _handle_element_start

Overload of method to process start of an element.

=head2 _handle_element_end

Overload of method to process end of an element.

=head2 _handle_text

Overload of method to process handling of text.

=head2 __reset

Resets all of the internal (package) variables.

=head2 __spellcheck

Splits a chunk of text into words and runs it through Text::Aspell.

=head1 AUTHOR

David Westbrook (CPAN: davidrw), C<< <dwestbrook at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-advent at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Advent>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Advent

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Advent>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Advent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Advent>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-Advent>

=back

=head1 SEE ALSO

=over 4

=item *

L<http://perladvent.pm.org> - The Perl Advent Calendar

=item *

L<http://perladvent.pm.org/2007/17> - The 2007-12-17 submission that discussed this application of Pod::Simple

=item *

L<Pod::Simple> - The base class for Pod::Advent

=item *

L<Pod::Simple::Subclassing> - Discusses the techniques that Pod::Advent is based on

=item *

L<perlpod> - POD documentation

=item *

L<Perl::Tidy> - used for formatting code

=item *

L<Text::Aspell> - used for spellchecking

=back

=head1 ACKNOWLEDGEMENTS

The maintainers of The Perl Advent Calendar at L<http://perladvent.pm.org>.

The 2007 editors, Bill Ricker & Jerrad Pierce, for reviewing and providing feedback on this concept.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2011 David Westbrook, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
