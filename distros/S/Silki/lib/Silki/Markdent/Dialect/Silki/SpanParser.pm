package Silki::Markdent::Dialect::Silki::SpanParser;
{
  $Silki::Markdent::Dialect::Silki::SpanParser::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use List::AllUtils qw( insert_after_string );
use Silki::Markdent::Event::FileLink;
use Silki::Markdent::Event::ImageLink;
use Silki::Markdent::Event::WikiLink;

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Markdent::Dialect::Theory::SpanParser';

sub _possible_span_matches {
    my $self = shift;

    my @look_for = $self->SUPER::_possible_span_matches(@_);

    # inside code span
    return @look_for if @look_for == 1;

    for my $val (qw( image_link file_link wiki_link )) {
        insert_after_string 'code_start', $val, @look_for;
    }

    return @look_for;
}

# More or less stolen from Text::Markdown
my $nested_brackets;
$nested_brackets = qr{
    (?>                                 # Atomic matching
       [^\[\]]+                           # Anything other than brackets
       |
       \[
         (??{ $nested_brackets })        # Recursive set of nested curlies
       \]
    )*
}x;

sub _match_wiki_link {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                (?:
                                  \[
                                  ($nested_brackets)
                                  \]
                                )?
                                \(\(
                                (.+?)
                                \)\)
                              /xmgc;

    my %p = ( link_text => $2 );
    $p{display_text} = $1
        if defined $1;

    my $event
        = $self->_make_event( 'Silki::Markdent::Event::WikiLink' => %p );

    $self->_markup_event($event);

    return 1;
}

sub _match_file_link {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                (?:
                                  \[
                                  ($nested_brackets)
                                  \]
                                )?
                                {{
                                \s*
                                file:
                                \s*
                                ([^}]+)
                                \s*
                                }}
                              /xmgc;

    my %p = ( link_text => $2 );
    $p{display_text} = $1 if defined $1;

    my $event
        = $self->_make_event( 'Silki::Markdent::Event::FileLink' => %p );

    $self->_markup_event($event);

    return 1;
}

sub _match_image_link {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                {{
                                \s*
                                image:
                                \s*
                                ([^}]+)
                                \s*
                                }}
                              /xmgc;

    my %p = ( link_text => $1 );

    my $event
        = $self->_make_event( 'Silki::Markdent::Event::ImageLink' => %p );

    $self->_markup_event($event);

    return 1;
}

sub _match_plain_text {
    my $self = shift;
    my $text = shift;

    my $escape_re = $self->_escape_re();

    # Note that we're careful not to consume any of the characters marking the
    # (possible) end of the plain text. If those things turn out to _not_ be
    # markup, we'll get them on the next pass, because we always match at
    # least one character, so we should never get stuck in a loop.
    return
        unless ${$text} =~ /\G
                     ( .+? )              # at least one character followed by ...
                     (?=
                       $escape_re
                       |
                       \*                 #   possible span markup
                       |
                       _
                       |
                       \p{SpaceSeparator}* \`
                       |
                       \(\(               #   possible wiki link
                       |
                       \{\{               #   possible wiki command
                       |
                       !?\[               #   possible image or link
                       |
                       < [^>]+ >          #   an HTML tag
                       |
                       &\S+;              #   an HTML entity
                       |
                       \z                 #   or the end of the string
                     )
                    /xgcs;

    $self->_print_debug("Interpreting as plain text\n\n[$1]\n")
        if $self->debug();

    $self->_save_span_text($1);

    return 1;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Parses span-level markup for the Silki Markdown dialect

__END__
=pod

=head1 NAME

Silki::Markdent::Dialect::Silki::SpanParser - Parses span-level markup for the Silki Markdown dialect

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

