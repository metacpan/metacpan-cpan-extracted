#############################################################################
## Name:        HtmlEasy.pm
## Purpose:     Pod::HtmlEasy
## Author:      Graciliano M. P.
## Modified by: Geoffrey Leach
## Created:     2004-01-11
## Updated:	    2011-08-13
## Copyright:   (c) 2004 Graciliano M. P. (c) 2007 - 2013 Geoffrey Leach
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package Pod::HtmlEasy;
use 5.006003;

use strict;
use warnings;

use Pod::HtmlEasy::Parser;
use Pod::HtmlEasy::Data
    qw( EMPTY NL NUL TRUE FALSE body css gen head headend title top toc toc_tag podon podoff );
use Carp;
use English qw{ -no_match_vars };
use File::Slurp;
use Pod::Parser; # Just for its VERSION
use Readonly;
use Regexp::Common qw{ whitespace };

use version;
our $VERSION = version->declare("v1.1.11");    # Also appears in "=head1 VERSION" in the POD below

########
# VARS #
########

Readonly::Scalar my $NUL                  => NUL;
Readonly::Scalar my $TITLE_TEXT_LOC       => -2;
Readonly::Scalar my $DEFAULT_INDEX_LENGTH => 60;

# This keeps track of valid options
Readonly::Hash my %OPTS => (
    body         => 1,
    css          => 1,
    index        => 1,
    index_item   => 1,
    index_length => 1,
    output       => 1,
    no_css       => 1,
    no_generator => 1,
    no_index     => 1,
    only_content => 1,
    parserwarn   => 1,
    title        => 1,
    top          => 1,
);

#######################
# _ORGANIZE_CALLBACKS #
#######################

sub _organize_callbacks {
    my $this = shift;

    $this->{ON_B} = \&evt_on_b;
    $this->{ON_C} = \&evt_on_c;
    $this->{ON_E} = \&evt_on_e;
    $this->{ON_F} = \&evt_on_f;
    $this->{ON_I} = \&evt_on_i;
    $this->{ON_L} = \&evt_on_l;
    $this->{ON_S} = \&evt_on_s;
    $this->{ON_X} = \&evt_on_x;    # [20078]
    $this->{ON_Z} = \&evt_on_z;

    $this->{ON_HEAD1} = \&evt_on_head1;
    $this->{ON_HEAD2} = \&evt_on_head2;
    $this->{ON_HEAD3} = \&evt_on_head3;
    $this->{ON_HEAD4} = \&evt_on_head4;

    $this->{ON_VERBATIM}  = \&evt_on_verbatim;
    $this->{ON_TEXTBLOCK} = \&evt_on_textblock;

    $this->{ON_OVER} = \&evt_on_over;
    $this->{ON_ITEM} = \&evt_on_item;
    $this->{ON_BACK} = \&evt_on_back;

    $this->{ON_FOR}   = \&evt_on_for;
    $this->{ON_BEGIN} = \&evt_on_begin;
    $this->{ON_END}   = \&evt_on_end;

    $this->{ON_URI} = \&evt_on_uri;

    $this->{ON_ERROR} = \&evt_on_error;

    return;
}

#######
# NEW #
#######

sub new {
    my ( $this, %args ) = @_;
    return $this if ref $this;
    my $class = $this || __PACKAGE__;
    $this = bless {}, $class;

    _organize_callbacks($this);

    foreach my $key ( keys %args ) {

        # Add in any ON_ callbacks
        if ( $key =~ m{^on_(\w+)$}ismx ) {
            my $cmd = uc $1;
            $this->{qq{ON_$cmd}} = $args{$key};
        }
        elsif ( $key =~ m{^(?:=(\w+)|(\w)<>)$}smx ) {
            my $cmd = uc $1 || $2;
            $this->{$cmd} = $args{$key};
        }
    }

    return $this;
}

############
# POD2HTML #
############

sub pod2html {    ## no critic (ProhibitExcessComplexity)
    my @args = @_;
    my $this = shift @args;

    # The first argument is either the input file or an option,
    # In the latter case, input must be coming from STDIN
    my $pod = shift @args;
    if ( exists $OPTS{$pod} ) {

        # Oops, its an arg;
        unshift @args, $pod;
        $pod = q{-};
    }

    # If the following assignment is to work, we must have pairs in @args
    if ( @args & 1 ) {
        carp q{All options must be paired with values};
        exit 1;
    }
    my %args = @args;

    # Check options for validity
    foreach my $key ( keys %args ) {
        if ( not exists $OPTS{$key} ) {
            carp qq{option $key is not supported};
        }
    }

    my $save;
    if ( exists $args{output} ) { $save = $args{output}; }

   # Personal pecularity: I hate double negatives, and perlcritic hates unless
    my ( $do_css, $do_generator, $do_index, $do_content );
    if ( not exists $args{no_css} )       { $do_css       = 1; }
    if ( not exists $args{no_generator} ) { $do_generator = 1; }
    if ( not exists $args{no_index} )     { $do_index     = 1; }
    if ( not exists $args{only_content} ) { $do_content   = 1; }

    # This will fall through to Pod::Parser::new
    # which is the base for Pod::HtmlEasy::Parser.
    # Pod::HtmlEasy::Parser does not implement new()
    my $parser = Pod::HtmlEasy::Parser->new();

    $parser->errorsub(
        sub {    ## no critic (ProtectPrivateSubs)
            Pod::HtmlEasy::Parser::_errors( $parser, @_ );
        }
    );

 # Pod::Parser wiii complain about multiple blank lines in INDEX_ITEM,
 # which is moderately annoying
    if ( exists $args{parserwarn} ) { $parser->parseopts( -warnings => 1 ); }

    # This allows us to search for non-POD stuff is preprocess_paragraph
    # my $VERSION ..., for example
    $parser->parseopts( -want_nonPODs => 1 );

    # This puts a subsection in the $parser hash that will record data
    # that is "local" to this code.  Throughout, $parser will refer to
    # Pod::Parser and $this to Pod::HtmlEasy
    $parser->{POD_HTMLEASY} = $this;

    if ( exists $args{index_item} ) {
        $parser->{INDEX_ITEM} = 1;
        $parser->{INDEX_LENGTH}
            = exists $args{index_length}
            ? $args{index_length}
            : $DEFAULT_INDEX_LENGTH;
    }

    # This is where we accumulate the results of Pod::Parser
    my @output;
    $parser->{POD_HTMLEASY}->{HTML} = \@output;

    my $title = $args{title};

    if ( ref $pod eq q{GLOB} ) {    # $pod is an open file handle
        if ( not defined $title ) { $title = q{<DATA>}; }
    }
    else {
        if ( ( !-e $pod ) && ( $pod ne q{-} ) ) {
            carp qq{No file $pod};
            exit 1;
        }
        if ( not defined $title ) {
            $title = defined $save ? $save : $pod eq q{-} ? q{STDIN} : $pod;
        }
    }

    # Build the header to the HTML file
    my ( @html, $title_line_ref );
    if ( defined $do_content ) {    # [31784]
        push @html, head();

        # We assume here that Pod::Parser is always at the same level as the main
        if ( defined $do_generator ) {
            push @html, gen( $VERSION,  $Pod::Parser::VERSION );
        }

        push @html, title($title);

        # Save  pointer for later, in case title gets replaced
        # NB: index depends on the structure of the returned HTML
        $title_line_ref = \$html[$TITLE_TEXT_LOC];

        if ( defined $do_css ) { push @html, css( $args{css} ); }

        push @html, headend;

        push @html, body( $args{body} );
    }

    delete $this->{UPARROW};
    delete $this->{UPARROW_FILE};
    if ( exists $args{top} ) {
        push @html, top;

        # Checking for the file is the only way I know of to distinguish
        if   ( -e $args{top} ) { $this->{UPARROW_FILE} = $args{top}; }
        else                   { $this->{UPARROW}      = $args{top}; }
    }

    # Avoid carry-over on multiple files
    delete $this->{IN_BEGIN};
    delete $this->{PACKAGE};
    delete $this->{TITLE};
    delete $this->{VERSION};
    $this->{INFO_COUNT} = 0;

    $parser->parse_from_file($pod);

    # If there's a head1 NAME, we've picked this up during processing
    # BUT, let the caller force override of NAME content
    if (   exists $this->{TITLE}
        && length $this->{TITLE} > 0
        && !exists $args{title}
        && defined $title_line_ref )
    {
        ${$title_line_ref} = $this->{TITLE};
    }

    if ( defined $do_index ) {
        push @html, $this->_do_index( $args{index} );
    }

    push @html, podon;
    push @html, @output;    # The pod converted to HTML
    push @html, podoff( defined $args{only_content} ? 1 : undef );   # [31784]

    # Add newlines to the HTML
    @html = map { $_ . NL } @html;

    if ( defined $save ) {
        open my $out, q{>}, $save or carp qq{Unable to open $save - $ERRNO};
        print {$out} @html or carp qq{Could not write to $out};
        close $out or carp qq{Could not close $out};
    }
    else {
        if ( $pod eq q{-} ) { print @html or carp q{Could not print}; }
    }

    return wantarray ? @html : join EMPTY, @html;
}

#############
# _DO_INDEX #
#############

sub _do_index {
    my ( $this, $add ) = @_;

    if ( defined $add )             { return toc($add); }
    if ( @{ $this->{INDEX} } == 0 ) { return toc(); }

    my @index;
    my $index_ref  = $this->{INDEX};
    my $cur_level  = 1;
    my $doing_item = FALSE;
    while ( my $index_element = shift @{$index_ref} ) {
        my ( $level, $txt ) = @{$index_element};

       # Eliminate http references. This is in aid of persons who use =item to
       # list URLs.
        my $tag = toc_tag($txt);

   # =item lists are level 0 and generate a level change wherever they show up
   # so, when we get a non-zero level we're indexing a non-item
        if ($level) {
            if ($doing_item) {
                push @index, q{</ul>};
                $cur_level--;
                $doing_item = FALSE;
            }

            while ( $level > $cur_level ) {
                $cur_level++;
                push @index, q{<ul>};
            }

            while ( $level < $cur_level ) {
                $cur_level--;
                push @index, q{</ul>};
            }
        }
        else {

            # Indexing an =item
            if ( not $doing_item ) {
                push @index, q{<ul>};
                $cur_level++;
                $doing_item = TRUE;
            }

            # Strip http to conform to =item
            $txt =~ s{\Ahttps?://}{}gmsx;
            $tag = toc_tag($txt);
        }

        push @index, qq{<li><a href='#$tag'>$txt</a></li>};
    }

    while ( $cur_level > 1 ) {
        $cur_level--;

        # =item without an enclosing =head will get duplicate <ul> and </ul>s.
        # That's OK, because its supposed to be illegal POD.
        push @index, q{</ul>};
    }

    # Note LIST return. Result is pushed onto @html
    return ( toc(@index) );
}

#############
# _DO_TITLE #
#############

sub _do_title {
    my ( $this, $txt ) = @_;

    # This happens only on the _first_ head1 NAME
    if ( ( not exists $this->{TITLE} ) and ( $txt =~ m{\ANAME}smx ) ) {
        my ($title) = $txt =~ m{\ANAME\s+(.*)}smx;
        if ( defined $title ) {

            # Oh, goody
            $title =~ s{$RE{ws}{crop}}{}gsmx;  # delete surrounding whitespace
            $this->{TITLE} = $title;
        }
        else {

# If we don't get anything off of NAME, it will be filled in by preprocess_paragraph()
            $this->{TITLE} = undef;
        }
    }
    return;
}

##################
# DEFAULT EVENTS #
##################

sub evt_on_head1 {
    my ( $this, $txt ) = @_;

    if ( not defined $txt ) { $txt = EMPTY; }

    my $tag = toc_tag($txt);

    _do_title( $this, $txt );

    # "Go to top" is attached to =head1 if selected.
    if ( exists $this->{UPARROW} ) {
        return
              q{<h1><a href='#_top'} 
            . NL
            . q{title='click to go to top of document'}
            . NL
            . qq{name='$tag'>$txt&$this->{UPARROW};</a></h1>};
    }

    if ( exists $this->{UPARROW_FILE} ) {
        return
              q{<h1><a href='#_top'} 
            . NL
            . q{title='click to go to top of document'}
            . NL
            . qq{name='$tag'>$txt<img src='$this->{UPARROW_FILE}'}
            . NL
            . q{alt=&uArr;></a></h1>};
    }

    return qq{<a name='$tag'></a><h1>$txt</h1>};
}

sub evt_on_head2 {
    my ( $this, $txt ) = @_;

    my $tag = toc_tag($txt);

    return qq{<a name='$tag'></a><h2>$txt</h2>};
}

sub evt_on_head3 {
    my ( $this, $txt ) = @_;

    my $tag = toc_tag($txt);

    return qq{<a name='$tag'></a><h3>$txt</h3>};
}

sub evt_on_head4 {
    my ( $this, $txt ) = @_;

    my $tag = toc_tag($txt);

    return qq{<a name='$tag'></a><h4>$txt</h4>};
}

sub evt_on_begin {
    my ( $this, $txt ) = @_;

    # We don't do any processing for =begin/=end other than ignore
    # However, without a command, the construct is illegal
    # Embedded =head, etc are also illegal, but we don't check
    if ( length $txt == 0 ) { $this->{IN_BEGIN} = 1; }
    return EMPTY;
}

sub evt_on_end {
    my ( $this, $txt ) = @_;

    # Ignore any commands
    delete $this->{IN_BEGIN};
    return EMPTY;
}

# See perlpodsec for details on interpreting the items
sub evt_on_l {    ## no critic (ProhibitManyArgs)
    my ( $this, $text, $inferred, $name, $section, $type ) = @_;

    if ( $type eq q{pod} ) {
        $section = defined $section ? qq{#$section} : EMPTY;    # [6062]
            # Corrupt the href to avoid having it recognized (and converted) by _add_uri_href
        $inferred =~ s{\A(.)}{$1$NUL}smx;
        my $toc_tag = toc_tag($section);

        if ( defined $name ) {
            return qq{<i><a href='h${NUL}ttp://search.cpan.org/perldoc?}
                . qq{$name$section'>$inferred</a></i>};
        }
        return qq{<i><a href='$toc_tag'>$inferred</a></i>};
    }

    if ( $type eq q{man} ) {

 # $name probably looks like "foo(1)", and the () are interpreted as metachars
        if ( $inferred !~ m{\Q$name\E}msx ) { $inferred .= qq{ in $name}; }
        return qq{<i>$inferred</i>};
    }
    if ( $type eq q{url} ) {

        # We'll let _add_uri_href handle this.
        return $name;
    }

    # Unknown type
    return $inferred;
}

sub evt_on_b {
    my ( $this, $txt ) = @_;
    return qq{<b>$txt</b>};
}

sub evt_on_i {
    my ( $this, $txt ) = @_;
    return qq{<i>$txt</i>};
}

sub evt_on_c {
    my ( $this, $txt ) = @_;
    return qq{<code>$txt</code>};
}

sub evt_on_e {
    my ( $this, $txt ) = @_;

    $txt =~ s{^&}{}smx;
    $txt =~ s{;$}{}smx;
    if ( $txt =~ m{^\d+$}smx ) { $txt = qq{#$txt}; }
    return qq{&$txt;};
}

sub evt_on_f {
    my ( $this, $txt ) = @_;
    return qq{<b><i>$txt</i></b>};
}

sub evt_on_s {
    my ( $this, $txt ) = @_;

    # Eliminate newlines; dos files use \r\n
    # \r\n is said to be not portable
    $txt =~ s{[\cM\cJ]}{}gsmx;
    return $txt;
}

sub evt_on_x { return EMPTY; }    # [20078]

sub evt_on_z { return EMPTY; }

sub evt_on_verbatim {
    my ( $this, $txt ) = @_;

    return if exists $this->{IN_BEGIN};

    # Multiple empty lines are parsed as verbatim text by Pod::Parser
    # And will show up as empty <pre> blocks, which is mucho messy
    {
        local $RS = EMPTY;
        chomp $txt;
    }

    if ( not length $txt ) { return EMPTY; }
    if ( exists $this->{IN_ITEM} ) {
        delete $this->{IN_ITEM};
        return evt_on_item( $this, $txt );
    }
    return qq{<pre>$txt</pre>};
}

sub evt_on_textblock {
    my ( $this, $txt ) = @_;
    if ( exists $this->{IN_BEGIN} ) { return; }
    if ( exists $this->{IN_ITEM} ) {
        delete $this->{IN_ITEM};
        return evt_on_item( $this, $txt );
    }
    return qq{<p>$txt</p>};
}

sub evt_on_over {
    my ( $this, $txt ) = @_;

    # Note that level is ignored
    return q{<ul>};
}

sub evt_on_item {
    my ( $this, $txt ) = @_;

    if ( ( length($txt) == 1 ) && ( $txt !~ m{\d}msx ) ) {

        # Use the content for the tag
        $this->{IN_ITEM} = 1;
        return EMPTY;
    }

    my $tag = toc_tag($txt);
    return qq{<li><a name='$tag'></a>$txt</li>};
}

sub evt_on_back { return q{</ul>}; }

sub evt_on_for { return EMPTY; }

sub evt_on_error {
    my ( $this, $txt ) = @_;
    return qq{<!-- POD_ERROR: $txt -->};
}

sub evt_on_uri {
    my ( $this, $uri ) = @_;
    my $target
        = $uri !~ m{^(?:mailto|telnet|ssh|irc):}ismx
        ? q{ target='_blank'}
        : EMPTY;    # [6062]
    my $txt = $uri;
    $txt =~ s{^mailto:}{}ismx;
    return qq{<a href='$uri'$target>$txt</a>};
}

##############
# PM_VERSION #
##############

sub pm_version {
    my $this = shift;
    if ( not defined $this ) {
        carp q{pm_version must be referenced through Pod::HtmlEasy};
        return;
    }

    return $this->{VERSION};
}

##############
# PM_PACKAGE #
##############

sub pm_package {
    my $this = shift;
    if ( not defined $this ) {
        carp q{pm_package must be referenced through Pod::HtmlEasy};
        return;
    }

    return $this->{PACKAGE};
}

###########
# PM_NAME #
###########

sub pm_name {
    my $this = shift;
    if ( not defined $this ) {
        carp q{pm_name must be referenced through Pod::HtmlEasy};
        return;
    }
    return $this->{TITLE};
}

###########################
# PM_PACKAGE_VERSION_NAME #
###########################

sub pm_package_version_name {
    my $this = shift;
    if ( not defined $this ) {
        carp
            q{pm_package_version_name must be referenced through Pod::HtmlEasy};
        return;
    }

    return ( $this->pm_package(), $this->pm_version(), $this->pm_name() );
}

################
# DEFAULOT_CSS #
################

sub default_css { return css(); }

1;

__END__

=pod

=begin stopwords

PODs
CPAN
html
FILEHANDLE
STDIN
STDOUT
pre
css
HREF
intex
DOCTYPE
outptut
parserwarn
backend
Regretably
uArr
CSS
undef
avalable
nonblank
automagically
encodings
URIs
http
https
mailto
Firefox
mis
HtmlEasy
Graciliano
Tubert
Brohman
Nobuaki
Whitcomb
Wieselquist

=end stopwords

=head1 NAME

Pod::HtmlEasy - Generate personalized HTML from PODs.

=head1 VERSION

This documentation refers to Pod::HtmlEasy version 1.1.11.

=head1 DESCRIPTION

The purpose of this module is to generate HTML data from POD in a easy and personalized mode.
By default the HTML generated is similar to the CPAN site style for module documentation.

=head1 SYNOPSIS

  use Pod::HtmlEasy;
  my $podhtml = Pod::HtmlEasy->new ( optional local event subs );
  my $html = $podhtml->pod2html( 'test.pod' );
  print $html;

=head2 pod2html ( POD_FILE|FILEHANDLE, HTML_FILE, %OPTIONS )

Convert a POD to HTML. Returns the HTML data generated, as a string or as a
list, according to context.

=over

=item POD_FILE|GLOB

The POD file (file path) or FILEHANDLE (GLOB, opened).
The special file handle, DATA is, of course, supported.

If the POD file is "-", or is omitted altogether, input from STDIN is expected, and HTML is written
to STDOUT, unless an output file name has been given.

This command shows how to convert POD to HTML on the command line:

 C<perl -MPod::HtmlEasy -e'Pod::HtmlEasy->new->pod2html(title,"test.html")' < test.pod > test.html>

or

 C<perl -MPod::HtmlEasy -e'Pod::HtmlEasy->new->pod2html("-",title,"test.html")' < test.pod > test.html>

The "title,test" shows how to set parameters to pod2html in this context.
Note that there is no "-" preceding the title; if you use one, Perl will complain about
an odd number of values in an hash assignment.

=item HTML_FILE

The default is to use the POD_FILE parameter, replacing the extension with "html"
in the current directory. If you want to name the output file differently, use the I<-output>
option. B<Note that this is an incompatible change from pre-1.0 versions. Sorry 'bout that.>

=item %OPTIONS I<(optional)>

Note that B<all> options have values. Omit the value and you'll get dumped.

=over

=item body

The body values.

Examples:

  ## Specify a complete body spec
  body => q{alink="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066"} ,

  or:

  ## This will overwrite only these 2 values. You may also add new key-value combos.
  body => { bgcolor => "#CCCCCC" , link => "#0000FF" } ,


Default: 

  link="#FF0000" bgcolor="#FFFFFF" link="#000000" text="#000000" vlink="#000066"

=item css

Can be a css file HREF or the css data.
The file is distinguished by the fact that the value does not have a newline.

Examples:

  css => 'test.css',

  ## Or:

  css => q`
    BODY {
      background: white;
      color: black;
      font-family: arial,sans-serif;
      margin: 0;
      padding: 1ex;
    } ...` , 

=item index

Define the index data. If not set the index will be generated automatically, calling the event subs
I<on_index_node_start> and I<on_index_node_end>.
Otherwise, the I<entire> index will be defined by the value of the option, with the exception of
the required HTML glue.

=item index_item

If set (1), =items will be added in the index. =item *, followed by a paragraph can produce some
strange indexes. See index_length.

If the =item line ("foo" in =item foo) is an URL (https?://...), whether or not its enclosed
in LZ<>E<lt>E<gt>, the http?// is stripped, and a HTML link is created.

=item index_length

If set (some value) I<and> index_item is set, then the intex line will be restricted to the
first space following this
number of characters, followed by "..." if appropriate. Default 60 characters.

=item no_css

If set do not use css.

=item no_index

If set, do not build and insert the index.

=item no_generator

If set, the meta GENERATOR tag won't be added.

=item only_content

If set generate only the HTML content. This I<implies> no_generator and no_css,
produces no <body> or <title>, and no DOCTYPE as well, so its really not very good HTML.

=item output

The file (and path, if desired) to be used to write the outptut HTML.

=item parserwarn

The backend we use is Pod::Parser. This module generates warnings when it detects
badly-formed POD. Regretably, it also generates warnings about multiple blank lines,
which can be annoying. Thus, it's disabled by default.

=item title

The title of the HTML.
I<Default: content of the first =head1 NAME, or, failing that the file path of the 
output file (if given) or the input file>.

=item top

Set TOP data. The HTML I<_top> will be added just before the I<index>.
If there is a value associated with -top (as in -top uArr)
That value will be added to to the head1 text. The value should be
either a literal character, a representation of a extended HTML character,
(as in uArr) or an I<existing> file.

=back

=back

=head2 Local Event Subs

So, what are these optional local event subroutines? You have the ability to specify
when creating an instance of Pod::HtmlEasy replacements for the subroutines that process
the single-letter commands embedded in POD text, such as  I<"B>I<<...>I<>>I<">, or the = commands,
such as =head1. You may also defined new single-letter commands by providing an event subroutine.
Of course, all of the defined commands have implementations. See L<Extending POD>.

=head1 Utility Functions

=head2 default_css

Returns the default CSS. To augment, remove the last line, add your changes, and replace
the last line.

=head2 pm_version ( pod2html )

Return the version of a Perl module file or I<undef>.
This is extracted from a statement that looks like "VERSION = 5.0008"
Needless to say, this is only avalable I<after> the POD is processed.

=head2 pm_package ( pod2html )

Return the package name of the module from which the POD was extracted or I<undef>.
Needless to say, this is only avalable I<after> the POD is processed.

=head2 pm_name ( pod2html )

Returns what follows the first instance of 
C<=head1 NAME description> or I<undef>.
The description is picked up from what follows NAME on the same line, 
I<or> from the first nonblank line following the C<=head1 NAME>.

Needless to say, this is only avalable I<after> the POD is processed.

=head2 pm_package_version_name ( pod2html )

Returns a list: ( pm_package, pm_version,  pm_name )
Needless to say, this is only avalable I<after> the POD is processed.

=head1 CHARACTER SET

In compliance with L<HTML 4.01 specification|http://www.w3.org/TR/html4/>, Pod::HtmlEasy supports
the ISO 8859-1 character set (also known as Latin-1). In essence, this means that the full
8-bit character set is supported.

HTML provides an escape mechanism that allows characters to be specified by name; this kind of
specification is called an I<entity>.

Some characters must be converted to entities to avoid confusing user agents. This happens 
automagically. These characters are: &, <, >, "

HTML (via its relationship with SGML) supports a large number of characters that are 
outside the set supported by ISO 8859-1. These can be specified in the text by using
the E&ls;...&gt; construct. These encodings are defined by ISO 10646, which is semi-informally
known as L<UNICODE|http://www.unicode.org/Public/5.0.0/ucd/UCD.html>.  For example, 
the "heart" symbol E&l;dhearts&gt;.
These are listed in section 24.3.1,
L<The list of characters|http://www.w3.org/TR/html4/sgml/entities.html#h-24.4.1>
of the HTML 4.01 specification.

=head1 EMBEDDED URIs

Pod::HtmlEasy scans text (but not verbatim text!) for embedded URIs, such as C<http://foo.bar.com>
that are I<not> embedded in L <...>. Schemes detected are http, https, file and ftp. References
of the form foo@bar.com are treated as mailto references and are translated accordingly.

Previous versions handled a more extensive list of URIs. It was thought that the overhead for
processing these other schemes was not justified by their utility. That is, not supported by
the Firefox browser. YMMV if you're using Internet Explorer!

=head1 EXTENDING POD

You can extend POD defining non-standard events.  

For example, to enable the command I<"=hr">:

  my $podhtml = Pod::HtmlEasy->new(
  on_hr => sub {
            my ( $this , $txt ) = @_ ;
            return "<hr>" ;
           }
  ) ;

To define a new formatting code, do the same thing, but the code must be a single letter.

So, to enable I<"G>I<<...>I<>>I<">:

  my $podhtml = Pod::HtmlEasy->new(
  on_G => sub {
            my ( $this , $txt ) = @_ ;
            return "<img src='$txt' border=0>" ;
          }
  ) ;

=head1 DEPENDENCIES

This script requires the following modules:

L<Pod::Parser>
L<Pod::ParseLink>

L<Pod::HtmlEasy::Parser>
L<Pod::HtmlEasy::Data>

L<Carp>
L<English>
L<English>
L<File::Slurp>
L<Regexp::Common>
L<Readonly>
L<Switch>
L<version>

=head1 DEFAULT CSS

This is the default CSS added to the HTML.

I<If you want to do your own CSS, use this as base.>

  BODY {
    background: white;
    color: black;
    font-family: arial,sans-serif;
    margin: 0;
    padding: 1ex;
  }
  TABLE {
    border-collapse: collapse;
    border-spacing: 0;
    border-width: 0;
    color: inherit;
  }
  IMG { border: 0; }
  FORM { margin: 0; }
  input { margin: 2px; }
  A.fred {
    text-decoration: none;
  }
  A:link, A:visited {
    background: transparent;
    color: #006699;
  }
  TD {
    margin: 0;
    padding: 0;
  }
  DIV {
    border-width: 0;
  }
  DT {
    margin-top: 1em;
  }
  TH {
    background: #bbbbbb;
    color: inherit;
    padding: 0.4ex 1ex;
    text-align: left;
  }
  TH A:link, TH A:visited {
    background: transparent;
    color: black;
  }
  A.m:link, A.m:visited {
    background: #006699;
    color: white;
    font: bold 10pt Arial,Helvetica,sans-serif;
    text-decoration: none;
  }
  A.o:link, A.o:visited {
    background: #006699;
    color: #ccffcc;
    font: bold 10pt Arial,Helvetica,sans-serif;
    text-decoration: none;
  }
  A.o:hover {
    background: transparent;
    color: #ff6600;
    text-decoration: underline;
  }
  A.m:hover {
    background: transparent;
    color: #ff6600;
    text-decoration: underline;
  }
  table.dlsip     {
    background: #dddddd;
    border: 0.4ex solid #dddddd;
  }
  .pod PRE     {
    background: #eeeeee;
    border: 1px solid #888888;
    color: black;
    padding-top: 1em;
    white-space: pre;
  }
  .pod H1      {
    background: transparent;
    color: #006699;
    font-size: large;
  }
  .pod H2      {
    background: transparent;
    color: #006699;
    font-size: medium;
  }
  .pod IMG     {
    vertical-align: top;
  }
  .pod .toc A  {
    text-decoration: none;
  }
  .pod .toc LI {
    line-height: 1.2em;
    list-style-type: none;
  }

=head1 DIAGNOSTICS

=over

=item All options must be paired with values

Your argument list (excluding the .pod file if specified) has an odd number of items.

=item option I<key> is not supported

You've used (mis-spelled?) an unrecognized option.

=item No file I<file>

We couldn't find that (input) file.

=item pm_I<whatever> must be referenced through Pod::HtmlEasy

The various pm_ functions are referenced through the module.

The maintainer would appreciate hearing about
any messages I<other> than those that result from
the C<use warnings> specified for each module.

HtmlEasy uses Pod::Parser, which may produce error messages concerning malformed
HTML.

=back

=head1 SEE ALSO

L<Pod::Parser> L<perlpod>, L<perlpodspec>.

=head1 CONFIGURATION AND ENVIRONMENT

Neither is relevant.

=head1 INCOMPATIBILITIES

As of version 1.1, the use of an optional output file as the second parameter,
has been replaced with an explicit
I<output> option.

=head1 BUGS AND LIMITATIONS

Please report problems at RT: L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Pod-HtmlEasy>

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

=head1 THANKS

Thanks to Ivan Tubert-Brohman <itub@cpan.org> that suggested to add the basic_entities
and common_entities options and for tests. [These options have been removed. As "modern"
browsers don't need all that encoding. See L<CHARACTER SET> above.]. 

Thanks to ITO Nobuaki for the patches for [31784].

Thanks to David Whitcomb for pointing out an error in HTML generation.

Thanks to William Wieselquist for [58274], in which he pointed out an error in the
parsing of dotted user names in mail address syntax.

Thanks to Zefram for providing patches for using native switch if available. [82400]

=head1 MAINTENANCE
 
Updates for version 0.0803 and subsequent by Geoffrey Leach <gleach@cpan.org>

=head1 LICENSE AND COPYRIGHT

 Copyright 2004-2006 by M. P. Graciliano
 Copyright 2007-2013 by Geoffrey Leach

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

