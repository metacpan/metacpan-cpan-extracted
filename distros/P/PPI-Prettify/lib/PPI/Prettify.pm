package PPI::Prettify;
use strict;
use warnings;
use PPI::Document;
use Carp 'croak';
use HTML::Entities;
use Perl::Critic::Utils
  qw/is_method_call is_subroutine_name is_package_declaration/;
use B::Keywords;
use List::MoreUtils 'any';

# ABSTRACT: A Perl HTML pretty printer to use with Google prettify CSS skins, no JavaScript required!

BEGIN {
    require Exporter;
    use base qw(Exporter);
    our @EXPORT    = qw(prettify $MARKUP_RULES);
    our @EXPORT_OK = ('getExampleHTML');
}

# The mapping of PPI::Token class to span attribute type. Is exported and overridable
our $MARKUP_RULES = {
    'PPI::Token::ArrayIndex'            => 'var',
    'PPI::Token::Attribute'             => 'atn',
    'PPI::Token::BOM'                   => 'pln',
    'PPI::Token::Cast'                  => 'var',
    'PPI::Token::Comment'               => 'com',
    'PPI::Token::DashedWord'            => 'pln',
    'PPI::Token::Data'                  => 'com',
    'PPI::Token::End'                   => 'com',
    'PPI::Token::Function'              => 'kwd',
    'PPI::Token::HereDoc'               => 'str',
    'PPI::Token::Keyword'               => 'lit',
    'PPI::Token::KeywordFunction'       => 'kwd',
    'PPI::Token::Label'                 => 'lit',
    'PPI::Token::Magic'                 => 'typ',
    'PPI::Token::Number'                => 'atv',
    'PPI::Token::Number::Binary'        => 'atv',
    'PPI::Token::Number::Exp'           => 'atv',
    'PPI::Token::Number::Float'         => 'atv',
    'PPI::Token::Number::Hex'           => 'atv',
    'PPI::Token::Number::Octal'         => 'atv',
    'PPI::Token::Number::Version'       => 'atv',
    'PPI::Token::Operator'              => 'pun',
    'PPI::Token::Pod'                   => 'com',
    'PPI::Token::Pragma'                => 'kwd',
    'PPI::Token::Prototype'             => 'var',
    'PPI::Token::Quote'                 => 'str',
    'PPI::Token::Quote::Double'         => 'str',
    'PPI::Token::Quote::Interpolate'    => 'str',
    'PPI::Token::Quote::Literal'        => 'str',
    'PPI::Token::Quote::Single'         => 'str',
    'PPI::Token::QuoteLike'             => 'str',
    'PPI::Token::QuoteLike::Backtick'   => 'fun',
    'PPI::Token::QuoteLike::Command'    => 'fun',
    'PPI::Token::QuoteLike::Readline'   => 'str',
    'PPI::Token::QuoteLike::Regexp'     => 'str',
    'PPI::Token::QuoteLike::Words'      => 'str',
    'PPI::Token::Regexp'                => 'str',
    'PPI::Token::Regexp::Match'         => 'str',
    'PPI::Token::Regexp::Substitute'    => 'str',
    'PPI::Token::Regexp::Transliterate' => 'str',
    'PPI::Token::Separator'             => 'kwd',
    'PPI::Token::Structure'             => 'pun',
    'PPI::Token::Symbol'                => 'typ',
    'PPI::Token::Unknown'               => 'pln',
    'PPI::Token::Whitespace'            => 'pln',
    'PPI::Token::Word'                  => 'pln',
    'PPI::Token::Word::Package'         => 'atn',
};

sub prettify {
    my ($args) = @_;
    croak "Missing mandatory code argument in args passed to prettify()."
      unless exists $args->{code} and defined $args->{code};
    my $doc = eval { return PPI::Document->new( \$args->{code} ) };
    croak "Error creating PPI::Document" unless $doc or $@;
    return _decorate( $doc, $args->{debug} || 0 );
}

sub get_example_html {
    my $htmlStart = <<'EOF';
<!DOCTYPE html>
<html>
<head><title>Example PPI::Prettify Output using the vim Desert scheme</title></head>
<body>
<style>
/* desert scheme ported from vim to google prettify */
pre.prettyprint { display: block; background-color: #333; color: #fff }
pre .str { color: #ffa0a0 } /* string  - pink */
pre .kwd { color: #f0e68c; font-weight: bold }
pre .com { color: #87ceeb } /* comment - skyblue */
pre .typ { color: #98fb98 } /* type    - lightgreen */
pre .lit { color: #cd5c5c } /* literal - darkred */
pre .pun { color: #fff }    /* punctuation */
pre .pln { color: #fff }    /* plaintext */
pre .tag { color: #f0e68c; font-weight: bold } /* html/xml tag    - lightyellow */
pre .atn { color: #bdb76b; font-weight: bold } /* attribute name  - khaki */
pre .atv { color: #ffa0a0 } /* attribute value - pink */
pre .dec { color: #98fb98 } /* decimal         - lightgreen */

pre.prettyprint {
    -moz-border-radius: 8px;
    -webkit-border-radius: 8px;
    -o-border-radius: 8px;
    -ms-border-radius: 8px;
    -khtml-border-radius: 8px;
    border-radius: 8px;
    width: 95%;
    margin: 0 auto 10px;
    padding: 1em;
    white-space: pre-wrap;
    border: 0px solid #888;
}

</style>
<body>
EOF
    my $htmlEnd = <<'EOF';
</body></html>
EOF

    my $code = <<'EOF';
package Test::Package;
use strict;
use warnings;
use feature 'say';
use Example::Module;

BEGIN {
    require Exporter;
    use base qw(Exporter);
    our @EXPORT = ('example_sub');
}

sub example_sub {
    my $self = shift;
    $self->length;
    return $self->do_something;
}

# this is a comment for do_something, an example method

sub do_something {
    my ($self) = @_;
    if ('dog' eq "cat") {
        say 1 * 564;
    }
    else {
        say 100 % 101;
    }
    return 'a string';
}

# example variables
my @array = qw/1 2 3/;
my $scalar = 'a plain string';

print STDOUT $scalar;
example_sub({ uc => 'test uc is string not BIF'});
1;
__END__
This is just sample code to demo the markup
EOF
    my $markup = prettify( { code => $code, debug => 1 } );
    return $htmlStart . $markup . $htmlEnd;
}

sub _decorate {
    my $prettyPrintedCode = '<pre class="prettyprint">';
    foreach my $token ( $_[0]->tokens ) {
        $prettyPrintedCode .= _to_html( $token, $_[1] );
    }
    return $prettyPrintedCode .= '</pre>';
}

sub _to_html {
    my ( $token, $debug ) = @_;
    my $type  = _determine_token($token);
    my $title = "";
    $title = qq( title="$type") if $debug;
    return
        qq(<span class="$MARKUP_RULES->{$type}"$title>)
      . encode_entities( $token->content )
      . qq(</span>);
}

# code adapted from PPI::HTML and Perl::Critic::Utils

sub _determine_token {
    my ($token) = @_;
    if ( ref($token) eq 'PPI::Token::Word' ) {
        if ( $token->snext_sibling and $token->snext_sibling->content eq '=>' )
        {
            return 'PPI::Token::Quote';
        }
        my $parent  = $token->parent;
        my $content = $token->content;
        if ( $parent->isa('PPI::Statement::Include') ) {
            return 'PPI::Token::Pragma' if $content eq $parent->pragma;
        }
        elsif ( $parent->isa('PPI::Statement::Variable') ) {
            if ( $content =~ /^(?:my|local|our)$/ ) {
                return 'PPI::Token::KeywordFunction';
            }
        }
        elsif ( $parent->isa('PPI::Statement::Compound') ) {
            if ( $content =~ /^(?:if|else|elsif|unless|for|foreach|while|my)$/ )
            {
                return 'PPI::Token::KeywordFunction';
            }
        }
        elsif ( $parent->isa('PPI::Statement::Given') ) {
            if ( $content eq 'given' ) {
                return 'PPI::Token::KeywordFunction';
            }
        }
        elsif ( $parent->isa('PPI::Statement::When') ) {
            if ( $content =~ /^(?:when|default)$/ ) {
                return 'PPI::Token::KeywordFunction';
            }
        }
        elsif ( $parent->isa('PPI::Statement::Scheduled') ) {
            return 'PPI::Token::KeywordFunction';
        }
        return 'PPI::Token::Symbol' if is_method_call($token);
        return 'PPI::Token::Symbol' if is_subroutine_name($token);
        return 'PPI::Token::Keyword'
          if grep /^$token$/, @B::Keywords::Barewords;
        return 'PPI::Token::Symbol'
          if grep /^$token$/, @B::Keywords::Filehandles;
        return 'PPI::Token::Word::Package' if is_package_declaration($token);

        # get next significant token
        if ( $token->next_token ) {
            my $next_token = $token->next_token;
            while ( !$next_token->significant and $next_token->next_token ) {
                $next_token = $next_token->next_token;
            }
            return 'PPI::Token::Quote'
              if $next_token->content eq '}' and !$token->sprevious_sibling;
        }
        return 'PPI::Token::Function'
          if grep /^$token$/, @B::Keywords::Functions;
    }
    return ref($token);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PPI::Prettify - A Perl HTML pretty printer to use with Google prettify CSS
skins, no JavaScript required!

=head1 VERSION

version 0.07

=head1 SYNOPSIS

    use PPI::Prettify 'prettify';

    my $codeSample = q! # get todays date in Perl
                        use Time::Piece;
                        print Time::Piece->new;
                      !;

    my $html = prettify({ code => $codeSample });

    # every Perl token wrapped in a span e.g. for "use PPI::Prettify;":
        <span class="kwd">use</span>
        <span class="pln"> </span>
        <span class="atn">PPI::Prettify</span>
        <span class="pln">;</span>

    my $htmlDebug = prettify({ code => $codeSample, debug => 1 });
    # with PPI::Token class, e.g. for "use PPI::Prettify;":
        <span class="kwd" title="PPI::Token::Function">use</span>
        <span class="pln" title="PPI::Token::Whitespace"> </span>
        <span class="atn" title="PPI::Token::Word">PPI::Prettify</span>
        <span class="pln" title="PPI::Token::Structure">;</span>

=head1 DESCRIPTION

This module takes a string Perl code sample and returns the tokens of the code
surrounded with <span> tags. The class attributes are the same used by the
L<prettify.js|https://code.google.com/p/google-code-prettify/>. Using
L<PPI::Prettify> you can generate the prettified code for use in webpages
without using JavaScript but you can use all L<the CSS
skins|https://google-code-prettify.googlecode.com/svn/trunk/styles/index.html>
developed for prettify.js. Also, because this module uses L<PPI::Document> to
tokenize the code, it's more accurate than prettify.js.

L<PPI::Prettify> exports prettify() and the $MARKUP_RULES hashref which is used
to match PPI::Token classes to the class attribute given to that token's <span>
tag. You can modify $MARKUP_RULES to tweak the mapping if you require it.

I wrote an article with more detail about the module for:
L<PerlTricks.com|http://perltricks.com/article/60/2014/1/13/Display-beautiful-Perl-code-in-HTML-without-JavaScript>.

=head1 MOTIVATION

I wanted to generate marked-up Perl code without using JavaScript for
L<PerlTricks.com|http://perltricks.com>. I was dissatisfied with prettify.js as
it doesn't always tokenize Perl correctly and won't run if the user has
disabled JavaScript. I considered L<PPI::HTML> but it embeds the CSS in the
generated code, and I wanted to use the same markup class attributes as
prettify.js so I could reuse the existing CSS developed for it.

=head1 BUGS AND LIMITATIONS

=over

=item *

What constitutes a function and a keyword is somewhat arbitrary in Perl.
L<PPI::Prettify> mostly uses L<B::Keywords> to help distinguish functions and
keywords. However, some words such as "if", "my" and "BEGIN" are given a
special class of "PPI::Token::KeywordFunction" which can be overridden in
$MARKUP_RULES, should you wish to display these as keywords instead of
functions.

=item *

This module does not yet process Perl code samples with heredocs correctly.

=item *

Line numbering needs to be added.

=back

=head1 SUBROUTINES/METHODS

=head2 prettify

Takes a hashref consisting of $code and an optional debug flag. Every Perl code
token is given a <span> tag that corresponds to the tags used by Google's
prettify.js library. If debug => 1, then every token's span tag will be given a
title attribute with the value of the originating PPI::Token class. This can
help if you want to override the mappings in $MARKUP_RULES. See L</SYNOPSIS>
for examples.

=head2 getExampleHTML

Returns an HTML document as a string with built-in CSS to demo the syntax
highlighting capabilites of PPI::Prettify. At the command line:

    $ perl -MPPI::Prettify -e 'print PPI::Prettify::getExampleHTML()' > example.html

=head1 INTERNAL FUNCTIONS

=head2 _decorate

Iterates through the tokens of a L<PPI::Document>, marking up each token with a
<span> tag.

=head2 _to_html

Marks up a token with a span tag with the appropriate class attribute and the
PPI::Token class.

=head2 _determine_token

Determines the PPI::Token type.

=head1 REPOSITORY

L<https://github.com/sillymoose/ppi-prettify>

=head1 SEE ALSO

L<PPI::HTML> is another prettifier for Perl code samples that allows the
embedding of CSS directly into the HTML generation.

=head1 THANKS

Thanks to Adam Kennedy for developing L<PPI::Document>, without which this
module would not be possible.

=head1 AUTHOR

David Farrell <sillymoos@cpan.org> L<PerlTricks.com|http://perltricks.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by David Farrell.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
