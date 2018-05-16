package Pod::Simple::Pandoc;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.346.0';

use Pod::Simple::SimpleTree;
use Pod::Perldoc;
use Pandoc::Elements;
use Pandoc::Filter::HeaderIdentifiers;
use Pod::Pandoc::Modules;
use Pandoc;
use File::Find ();
use File::Spec;
use Carp;
use utf8;

sub new {
    my ( $class, %opt ) = @_;

    $opt{parse} ||= [];
    if ( $opt{parse} eq '*' ) {
        $opt{parse} = [ pandoc->require('1.12')->input_formats ];
    }

    $opt{podurl} //= 'https://metacpan.org/pod/';

    bless \%opt, $class;
}

sub _parser {
    my $self = shift;

    my $parser = Pod::Simple::SimpleTree->new;
    $parser->nix_X_codes(1);         # ignore X<...> codes
    $parser->nbsp_for_S(1);          # map S<...> to U+00A0 (non-breaking space)
    $parser->merge_text(1);          # emit text nodes combined
    $parser->no_errata_section(1);   # omit errata section
    $parser->complain_stderr(1);     # TODO: configure
    $parser->accept_target('*');     # include all data sections

    # remove shortest leading whitespace string from verbatim sections
    $parser->strip_verbatim_indent(
        sub {
            my $indent = length $_[0][1];
            for ( @{ $_[0] } ) {
                $_ =~ /^(\s*)/;
                $indent = length($1) if length($1) < $indent;
            }
            ' ' x $indent;
        }
    );

    return $parser;
}

sub parse_file {
    my ( $self, $file ) = @_;

    # Pod::Simple::parse_file does not detect this
    croak "Can't use directory as a source for parse_file" if -d $file;

    my $doc = $self->parse_tree( $self->_parser->parse_file($file)->root );

    if ( !ref $file and $file ne '-' ) {
        $doc->meta->{file} = MetaString($file);
    }

    $doc;
}

sub parse_module {
    my ( $self, $name ) = @_;

    my ($file) = Pod::Perldoc->new->grand_search_init( [$name] );

    $self->parse_file($file);
}

sub parse_string {
    my ( $self, $string ) = @_;
    $self->parse_tree( $self->_parser->parse_string_document($string)->root );
}

sub parse_tree {
    my $doc = Pandoc::Filter::HeaderIdentifiers->new->apply( _pod_element(@_) );

    my $sections = $doc->outline(1)->{sections};
    if ( my ($name) = grep { $_->{header}->string eq 'NAME' } @$sections ) {

        # TODO: support formatting
        my $text = $name->{blocks}->[0]->string;
        my ( $title, $subtitle ) = $text =~ m{^\s*([^ ]+)\s*[:-]*\s*(.+)};
        $doc->meta->{title}    = MetaString($title)    if $title;
        $doc->meta->{subtitle} = MetaString($subtitle) if $subtitle;
    }

    # remove header sections (TODO: move into Pandoc::Elements range filter)
    unless ( ref $_[0] and $_[0]->{name} ) {
        my $skip;
        $doc->content(
            [
                map {
                    if ( defined $skip ) {
                        if ( $_->name eq 'Header' && $_->level <= $skip ) {
                            $skip = 0;
                        }
                        $skip ? () : $_;
                    }
                    else {
                        if ( $_->name eq 'Header' && $_->string eq 'NAME' ) {
                            $skip = $_->level;
                            ();
                        }
                        else {
                            $_;
                        }
                    }
                } @{ $doc->content }
            ]
        );
    }

    $doc;
}

sub parse_and_merge {
    my ( $self, @input ) = @_;

    my $doc;

    foreach my $file (@input) {

        my $cur =
          ( $file ne '-' and not -e $file )
          ? $self->parse_module($file)
          : $self->parse_file($file);

        if ($doc) {
            push @{ $doc->content }, @{ $cur->content };
        }
        else {
            $doc = $cur;
        }
    }

    return unless $doc;

    if ( @input > 1 ) {
        $doc->meta->{file} = MetaList [ map { MetaString $_ } @input ];
    }

    return $doc;
}

sub is_perl_file {
    my $file = shift;
    return 1 if $file =~ /\.(pm|pod)$/;
    if ( -f $file ) {
        open( my $fh, '<', $file ) or return;
        return 1 if $fh and ( <$fh> // '' ) =~ /^#!.*perl/;
    }
    0;
}

sub parse_dir {
    my ( $parser, $directory ) = @_;
    my $files = {};

    File::Find::find(
        {
            no_chdir => 1,
            wanted   => sub {
                my $file = $_;
                return unless is_perl_file($file);
                my $doc = $parser->parse_file($file);
                my $base = File::Spec->abs2rel( $directory, $file );
                $base =~ s/\.\.$//;
                $doc->meta->{base} = MetaString $base;
                $files->{$file} = $doc;
            }
        },
        $directory
    );

    $files;
}

sub parse_modules {
    my ( $parser, $dir, %opt ) = @_;

    my $modules = Pod::Pandoc::Modules->new;
    return $modules unless -d $dir;

    my $files = $parser->parse_dir($dir);
    foreach my $file ( sort keys %$files ) {
        my $doc = $files->{$file};
        my $module = File::Spec->abs2rel( $file, $dir );
        $module =~ s{\.(pm|pod)$}{}g;
        $module =~ s{/}{::}g;
        if ( ( $doc->metavalue('title') // $module ) eq $module ) {
            my $old = $modules->{$module};
            my $skipped = $modules->add( $module => $doc ) ? $old : $doc;
            if ( $skipped and not $opt{quiet} ) {
                warn $skipped->metavalue('file')
                  . " skipped for "
                  . $modules->{$module}->metavalue('file') . "\n";
            }
        }
        else {
            warn "$file NAME does not match module\n" unless $opt{quiet};
        }
    }

    $modules;
}

my %POD_ELEMENT_TYPES = (
    Document => sub {
        Document {}, [ _pod_content(@_) ];
    },
    Para => sub {
        Para [ _pod_content(@_) ];
    },
    I => sub {
        Emph [ _pod_content(@_) ];
    },
    B => sub {
        Strong [ _pod_content(@_) ];
    },
    L => \&_pod_link,
    C => sub {
        Code attributes {}, _pod_flatten(@_);
    },
    F => sub {
        Code attributes { classes => ['filename'] }, _pod_flatten(@_);
    },
    head1 => sub {
        Header 1, attributes {}, [ _pod_content(@_) ];
    },
    head2 => sub {
        Header 2, attributes {}, [ _pod_content(@_) ];
    },
    head3 => sub {
        Header 3, attributes {}, [ _pod_content(@_) ];
    },
    head4 => sub {
        Header 4, attributes {}, [ _pod_content(@_) ];
    },
    Verbatim => sub {
        CodeBlock attributes {}, _pod_flatten(@_);
    },
    'over-bullet' => sub {
        BulletList [ _pod_list(@_) ];
    },
    'over-number' => sub {
        OrderedList [ 1, DefaultStyle, DefaultDelim ], [ _pod_list(@_) ];
    },
    'over-text' => sub {
        DefinitionList [ _pod_list(@_) ];
    },
    'over-block' => sub {
        BlockQuote [ _pod_content(@_) ];
    },
    'for' => \&_pod_data,
);

# option --smart
sub _str {
    my $s = shift;
    $s =~ s/\.\.\./…/g;
    Str $s;
}

# map a single element or text to a list of Pandoc elements
sub _pod_element {
    my ( $self, $element ) = @_;

    if ( ref $element ) {
        my $type = $POD_ELEMENT_TYPES{ $element->[0] } or return;
        $type->( $self, $element );
    }
    else {
        my $n = 0;
        map { $n++ ? ( Space, _str($_) ) : _str($_) }
          split( /\s+/, $element, -1 );
    }
}

# map the content of a Pod element to a list of Pandoc elements
sub _pod_content {
    my ( $self, $element ) = @_;
    my $length = scalar @$element;
    map { _pod_element( $self, $_ ) } @$element[ 2 .. ( $length - 1 ) ];
}

# stringify the content of an element
sub _pod_flatten {
    my $string = '';
    my $walk;
    $walk = sub {
        my ($element) = @_;
        my $n = scalar @$element;
        for ( @$element[ 2 .. $n - 1 ] ) {
            if ( ref $_ ) {
                $walk->($_);
            }
            else {
                $string .= $_;
            }
        }
    };
    $walk->( $_[1] );

    return $string;
}

# map link
sub _pod_link {
    my ( $self, $link ) = @_;
    my $type    = $link->[1]{type};
    my $to      = $link->[1]{to};
    my $section = $link->[1]{section};
    my $url     = '';

    if ( $type eq 'url' ) {
        $url = "$to";
    }
    elsif ( $type eq 'man' ) {
        if ( $to =~ /^([^(]+)(?:[(](\d+)[)])?$/ ) {

            # TODO: configure MAN_URL, e.g.
            # http://man7.org/linux/man-pages/man{section}/{name}.{section}.html
            $url = "http://linux.die.net/man/$2/$1";

            # TODO: add section to URL if given
        }
    }
    elsif ( $type eq 'pod' ) {
        if ( $to && $self->{podurl} ) {
            $url = $self->{podurl} . $to;
        }
        if ($section) {
            $section = header_identifier("$section") unless $to; # internal link
            $url .= "#" . $section;
        }
    }

    my $content = [ _pod_content( $self, $link ) ];
    if ($url) {
        Link attributes { class => 'perl-module' }, $content, [ $url, '' ];
    }
    else {
        Span attributes { class => 'perl-module' }, $content;
    }
}

# map data section
sub _pod_data {
    my ( $self, $element ) = @_;
    my $target = lc( $element->[1]{target} );

    my $length = scalar @$element;
    my $content = join "\n\n", map { $_->[2] }
      grep { $_->[0] eq 'Data' } @$element[ 2 .. $length - 1 ];

    # cleanup HTML and Tex blocks
    if ( $target eq 'html' ) {
        $content = "<div>$content</div>" if $content !~ /^<.+>$/s;
    }
    elsif ( $target =~ /^(la)?tex$/ ) {

        # TODO: more intelligent check & grouping, especiall at the end
        $content = "\\begingroup $content \\endgroup" if $content !~ /^[\\{]/;
        $target = 'tex';
    }

    # parse and insert known formats if requested
    my $format_arg = my $format = $target eq 'tex' ? 'latex' : $target;
    if ( pandoc->version ge 2 ) {
        $format_arg .= '+smart';
    }
    if ( grep { $format eq $_ } @{ $self->{parse} } ) {
        utf8::decode($content);
        my $doc =
          ( pandoc->version ge 2 )
          ? pandoc->parse( $format_arg => $content )
          : pandoc->parse( $format => $content, '--smart' );
        return @{ $doc->content };
    }

    RawBlock( $target, "$content\n" );

    # TODO: add Null element to not merge with following content
}

# map a list (any kind)
sub _pod_list {
    my ( $self, $element ) = @_;
    my $length = scalar @$element;

    my $deflist = $element->[2][0] eq 'item-text';
    my @list;
    my $item = [];

    my $push_item = sub {
        return unless @$item;
        if ($deflist) {
            my $term = shift @$item;
            push @list, [ $term->content, [$item] ];
        }
        else {
            push @list, $item;
        }
    };

    foreach my $e ( @$element[ 2 .. $length - 1 ] ) {
        my $type = $e->[0];
        if ( $type =~ /^item-(number|bullet|text)$/ ) {
            $push_item->();
            $item = [ Plain [ _pod_content( $self, $e ) ] ];
        }
        else {
            if ( @$item == 1 and $item->[0]->name eq 'Plain' ) {

                # first block element in item should better be Paragraph
                $item->[0] = Para $item->[0]->content;
            }
            push @$item, _pod_element( $self, $e );
        }
    }
    $push_item->();

    # BulletList/OrderedList: [ @blocks ], ...
    # DefinitionList: [ [ @inlines ], [ @blocks ] ], ...
    return @list;
}

1;
__END__

=encoding utf-8

=head1 NAME

Pod::Simple::Pandoc - convert Pod to Pandoc document model

=head1 SYNOPSIS

  use Pod::Simple::Pandoc;

  my $parser = Pod::Simple::Pandoc->new( %options );
  my $doc    = $parser->parse_file( $filename );

  # result is a Pandoc::Document object
  my $json = $doc->to_json;
  my $markdown = $doc->to_pandoc( -t => 'markdown' );
  $doc->to_pandoc(qw( -o doc.html --standalone ));

=head1 DESCRIPTION

This module converts Pod format (L<perlpod>) to the document model used by
L<Pandoc|http://pandoc.org/>. The result can be accessed with methods of
L<Pandoc::Elements> and further processed with Pandoc to convert it to other
document formats (HTML, Markdown, LaTeX, PDF, EPUB, docx, ODT, man...).

See L<pod2pandoc> and L<App::pod2pandoc> for a command line script and a
simplified API to this module.

=head1 OPTIONS

=over

=item parse

Parse Pod L<data sections|/Data sections> with L<Pandoc> and merge them into
the document instead of passing them as C<RawBlock>. Use C<*> to parse all
formats supported by pandoc as input format. Expects an array reference
otherwise.

=item podurl

Base URL to link Perl module names to. Set to L<https://metacpan.org/pod/> by
default. A false value disables linking external modules and wraps module names
in C<Span> elements instead. All module names are marked up with class
C<perl-module>.

=back

=head1 METHODS

=head2 parse_file( $filename | *INPUT )

Reads Pod from file or filehandle and convert it to a L<Pandoc::Document>. The
filename is put into document metadata field C<file> and the module name. The
NAME section, if given, is additionally split into metadata fields C<title> and
C<subtitle>.

=head2 parse_module( $module )

Reads Pod from a module given by name such as C<"Pod::Pandoc"> or by URL.

=head2 parse_string( $string )

Reads Pod from string and convert it to a L<Pandoc::Document>. Also sets
metadata fields C<title> and C<subtitle>.

=head2 parse_dir( $directory )

Recursively looks for C<.pm> and C<.pod> files in a given directory and parses
them. Returns a hash reference with filenames mapped to L<Pandoc::Document>
objects. Each document is enriched with metadata fields C<base> (relative path
from each file to the base directory) in addition to C<file>, C<title>, and
C<subtitle>.

=head2 parse_modules( $directory, [ quiet => 0|1 ] )

Same as method C<parse_dir> but returns a L<Pod::Simple::Pandoc::Modules>
instance that maps module names to L<Pandoc::Document> instances. The source
directory can also be specified with option C<source>. Option C<quiet> disables
warnings for skipped files.

=head2 parse_and_merge( @files_or_modules )

Reads Pod from files or modules given by name and merges them into one
L<Pandoc::Document> by concatenation.

=head1 MAPPING

Pod elements are mapped to Pandoc elements as following:

=head2 Formatting codes

L<Formatting codes|perlpod/Formatting Codes> for I<italic text>
(C<IE<lt>...E<gt>>), B<bold text> (C<BE<lt>...E<gt>>), and C<code>
(C<CE<lt>...E<gt>>) are mapped to Emphasized text (C<Emph>), strongly
emphasized text (C<Strong>), and inline code (C<Code>). Formatting code for
F<filenames> (C<FE<lt>...E<gt>>) are mapped to inline code with class
C<filename> (C<`...`{.filename}> in Pandoc Markdown).  Formatting codes inside
code and filenames (e.g. C<code with B<bold>> or F<L<http://example.org/>> as
filename) are stripped to unformatted code.  Character escapes
(C<EE<lt>...E<gt>>) and C<SE<lt>...E<gt>> are directly mapped to Unicode
characters. The special formatting code C<XE<lt>...E<gt>> is ignored.

=head2 Links

Some examples of links of different kinds:

L<http://example.org/>

L<pod2pandoc>

L<pod2pandoc/"OPTIONS">

L<perl(1)>

L<crontab(5)/"ENVIRONMENT">

L<hell itself!|crontab(5)>

Link text can contain formatting codes:

L<the C<pod2pandoc> script|pod2pandoc>

L</"MAPPING">

L<mapping from PoD to Pandoc|/"MAPPING">

=head2 Titles I<may contain formatting C<codes>>!

=head2 Lists

=over

=item 1

Numbered lists are

=item 2

converted to C<NumberedList> and

=over

=item *

Bulleted lists are

=item *

converted to

C<BulletList>

=back

=back

=over

=item Definition

=item Lists

=item are

I<also> supported.

=back

=head2 =over/=back

=over

An C<=over>...C<=back> region containing no C<=item> is mapped to C<BlockQuote>.

=back

=head2 Verbatim sections

  verbatim sections are mapped
    to code blocks

=head2 Data sections

Data sections are passed as C<RawBlock>. C<HTML>, C<LaTeX>, C<TeX>, and C<tex>
are recognized as alias for C<html> and C<tex>.

Option C<parse> can be used to parse data sections with pandoc executable and
merge them into the result document.

=begin markdown

### Examples

=end markdown

=begin html

<p>
  HTML is passed through

  as <i>you can see here</i>.
</p>

=end html

=for html HTML is automatically enclosed in
  <code>&ltdiv>...&lt/div></code> if needed.

=for latex \LaTeX\ is passed through as you can see here.

=begin tex

\LaTeX\ sections should start and end so Pandoc can recognize them.

=end tex

=head1 SEE ALSO

This module is based on L<Pod::Simple> (L<Pod::Simple::SimpleTree>). It makes
obsolete several specialized C<Pod::Simple::...> modules such as
L<Pod::Simple::HTML>, L<Pod::Simple::XHTML>, L<Pod::Simple::LaTeX>,
L<Pod::Simple::RTF> L<Pod::Simple::Text>, L<Pod::Simple::Wiki>, L<Pod::WordML>,
L<Pod::Perldoc::ToToc> etc.

=cut
