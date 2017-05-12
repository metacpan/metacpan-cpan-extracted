# PurpleWiki::Parser::MoinMoin.pm
# vi:ai:sm:et:sw=4:ts=4
#
# $Id: MoinMoin.pm 381 2004-05-31 19:21:37Z eekim $
#
# Copyright (c) Blue Oxen Associates 2002-2004.  All rights reserved.
#
# This file is part of PurpleWiki.  PurpleWiki is derived from:
#
#   UseModWiki v0.92          (c) Clifford A. Adams 2000-2001
#   AtisWiki v0.3             (c) Markus Denker 1998
#   CVWiki CVS-patches        (c) Peter Merel 1997
#   The Original WikiWikiWeb  (c) Ward Cunningham
#
# PurpleWiki is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
#    Free Software Foundation, Inc.
#    59 Temple Place, Suite 330
#    Boston, MA 02111-1307 USA

package PurpleWiki::Parser::MoinMoin;

use 5.005;
use strict;
vuse PurpleWiki::Config;
use PurpleWiki::InlineNode;
use PurpleWiki::StructuralNode;
use PurpleWiki::Tree;
use PurpleWiki::Sequence;
use PurpleWiki::Page;

our $VERSION;
$VERSION = sprintf("%d", q$Id: MoinMoin.pm 381 2004-05-31 19:21:37Z eekim $ =~ /\s(\d+)\s/);

my $sequence;
my $url;

### markup regular expressions
my $rxNowiki = '<nowiki>.*?<\/nowiki>';
my $rxTt = '<tt>.*?<\/tt>|\{\{\{.*?\}\}\}';
my $rxFippleQuotes = "'''''.*?'''''";
my $rxB = '<b>.*?<\/b>';
my $rxTripleQuotes = "'''.*?'''";
my $rxI = '<i>.*?<\/i>';
my $rxDoubleQuotes = "''.*?''";

### link regular expressions
my $rxAddress = '[^]\s]*[\w/]';
my $rxProtocols = '(?i:http|https|ftp|afs|news|mid|cid|nntp|mailto|wais):';
my $rxWikiWord = '[A-Z]+[a-z]+[A-Z]\w*';
my $rxSubpage = '[A-Z]+[a-z]+\w*';
my $rxQuoteDelim = '(?:"")?';
my $rxFreeLink = '\["[\w\/][\w\/\s]+"\]';
my $rxTransclusion = '\[t [A-Z0-9]+\]';

### constructor

sub new {
    my $this = shift;
    my $self = {};

    bless($self, $this);
    return $self;
}

### methods

sub parse {
    my $this = shift;
    my $wikiContent = shift;
    my %params = @_;

    $params{config} = PurpleWiki::Config->instance();

    $url = $params{url};
    $sequence = new PurpleWiki::Sequence($params{config}->LocalSequenceDir,
        $params{config}->RemoteSequenceURL);

    # set default parameters
    $params{wikiword} = $params{config}->WikiLinks
        if (!defined $params{wikiword});
    $params{freelink} = $params{config}->FreeLinks
        if (!defined $params{freelink});

    my $tree = PurpleWiki::Tree->new;
    my ($currentNode, @sectionState, $nodeContent);
    my ($listLength, $sectionLength, $indentLength);
    my ($line, $listType, $currentNid);
    my (@authors);

    # @whiteSpace is used to keep track of indentations before lists
    # and indented text.
    my @whiteSpace;

    my %listMap = ('ul' => '(\*)\s*(.*)',
                   'ol' => '([1ia]\.)\s*(.*)',
                   'dl' => '([^\:]+)\:\:\s+(.*)',
                  );

    my $aggregateListRegExp = join('|', values(%listMap));

    # The parsing strategy is as follows.  First, process the text
    # line-by-line, updating state variables as we go.  At certain
    # termination points, we update the data structure based on the
    # state variables.
    #
    # The top of the text is parsed differently from the rest of the
    # text.  If there is metadata (delimited by braces), then the
    # metadata is parsed; otherwise, the parser begins parsing for
    # WikiText.  Once it reaches this latter stage, it will treat
    # metadata as WikiText according to the basic parsing rules.
    #
    # STATE VARIABLES
    #
    # The state variables we care about and why are:
    #
    #   $isStart -- Determines whether we're at the top of the text
    #     (and should be parsing metadata) or not.
    #
    #   @authors -- List of authors (defined in the metadata).  This
    #     list is added to the tree structure's metadata once parsing
    #     is complete.
    #
    #   $listDepth -- The depth of the current list (unordered,
    #     ordered, or definition) being parsed.  Starts at 0.
    #
    #   $indentDepth -- The depth of the current indented text (begins
    #     with a colon) being parsed.  Starts at 0.
    #
    #   $sectionDepth -- Depth of the current section.  We start with
    #     a depth of 1, because we assume that the body text begins
    #     with a section.  (See below for more detailed explanation.)
    #
    #   $nodeContent -- Textual content of current node.
    #
    #   $currentNode -- The current node.  The initial node when we
    #     start parsing is the first section node.
    #
    # SECTIONS
    #
    # A document consists of sections.  Each section may consist of
    # subsections, ad infinitum.
    #
    # New sections are delimited by header markup (equal signs) and
    # hard rules (four dashes).  The depth of the header markup
    # determines whether or not the section is a new section, a
    # subsection, or in some cases, a supersection (e.g. a two equal
    # sign header following a three equal sign header).
    #
    # A hard rule indicates a new section.  Ideally, I'd like to make
    # it so that the hard rule is ignored if it is directly followed
    # by a header.  If users want to have hard rules separating
    # sections (i.e. separating headers), they should define that in
    # the stylesheet instead of using hard rules.  Expecting this
    # behavior from users is probably a bit too draconian, however,
    # and there may in fact be times when this is indeed the desired
    # behavior (for example, as a placeholder for future content).
    # The resulting data structure from a series of hard rules
    # followed by headers won't be "clean," but it shouldn't be
    # harmful either.

    my $isStart = 1;
    my $isBracePre = 0;
    my $prevIndentType;
    my $isPrevBlank = 0;
    my @authors = ();
    my $listDepth = 0;
    my $indentDepth = 0;
    my $sectionDepth = 1;

    $currentNode = $tree->root->insertChild('type' => 'section');

    foreach $line (split(/\n/, $wikiContent)) { # Process lines one-at-a-time
        chomp $line;
        if ($isStart && $line =~ /^\{title (.+)\}$/) {
            # The metadata below is not (currently) used by the
            # Wiki.  It's here to so that this parser can be used
            # as a general documentation formatting system.
            $tree->title($1);
        }
        elsif ($isStart && $line =~ /^\{subtitle (.+)\}$/) {
            # See above.
            $tree->subtitle($1);
        }
        elsif ($isStart && $line =~ /^\{docid (.+)\}$/) {
            # See above.
            $tree->id($1);
        }
        elsif ($isStart && $line =~ /^\{date (.+)\}$/) {
            # See above.
            $tree->date($1);
        }
        elsif ($isStart && $line =~ /^\{version (.+)\}$/) {
            # See above.
            $tree->version($1);
        }
        elsif ($isStart && $line =~ /^\{author (.+)\}$/) {
            # See above.
            my $authorString = $1;
            $authorString =~ s/\s+(\S+\@\S+)$//;
            my $authorEmail = $1 if ($1 ne $authorString);
            if ($authorEmail) {
                push @authors, [$authorString, $authorEmail];
            }
            else {
                push @authors, [$authorString];
            }
        }
        elsif ($line =~ /^\{sketch\}$/) {  # WikiWhiteboard
            $currentNode->insertChild(type=>'sketch');
        }
        elsif ($line =~ /^----*$/) {   # new section
            $currentNode = &_terminateNode($currentNode, \$nodeContent,
                                                %params);
            $currentNode = &_resetList($currentNode, \$listDepth, undef);
            @whiteSpace = ();
            $prevIndentType = undef;
            $currentNode = $currentNode->parent;
            $currentNode = $currentNode->insertChild(type=>'section');
            $isPrevBlank = 0;
        }
        elsif ($line =~ /^(\=+)\s+(.+)\s+\=+/) {  # header/section
            $currentNode = &_terminateNode($currentNode, \$nodeContent,
                                                %params);
            $currentNode = &_resetList($currentNode, \$listDepth, \$indentDepth);
            @whiteSpace = ();
            $prevIndentType = undef;
            $sectionLength = length $1;
            $nodeContent = $2;
            if ($sectionLength > $sectionDepth) {
                while ($sectionLength > $sectionDepth) {
                    $currentNode = $currentNode->insertChild(type=>'section');
                    $sectionDepth++;
                }
            }
            else {
                while ($sectionLength < $sectionDepth) {
                    $currentNode = $currentNode->parent;
                    $sectionDepth--;
                }
                if ( !$isStart && ($sectionLength == $sectionDepth) ) {
                    $currentNode = $currentNode->parent;
                    $currentNode = $currentNode->insertChild(type=>'section');
                }
            }
            $nodeContent =~  s/\s+\{nid ([A-Z0-9]+)\}$//s;
            $currentNid = $1;
            $currentNode = $currentNode->insertChild('type'=>'h',
                'content'=>&_parseInlineNode($nodeContent, %params));
            if (defined $currentNid && ($currentNid =~ /^[A-Z0-9]+$/)) {
                $currentNode->id($currentNid);
            }
            $currentNode = $currentNode->parent;
            undef $nodeContent;
            $isPrevBlank = 0;
            $isStart = 0 if ($isStart);
        }
        elsif ($line =~ /^(\s+)(\S.*)$/) {  # list or indentation
            my $wsLen = length $1;
            my $string = $2;

            if ($isBracePre) {
                $nodeContent .= "$line\n";
            }
            elsif ( ($string =~ /^[\*]/) || ($string =~ /^[1ia]\./) ||
                    ($string =~ /^[^\:]+\:\:\s+/) ) {  # new list item
                foreach $listType (keys(%listMap)) {
                    if ($string =~ /^$listMap{$listType}$/x) {
                        $currentNode = &_terminateNode($currentNode,
                                                       \$nodeContent,
                                                       %params);
                        if ($isPrevBlank && $prevIndentType ne $listType) {
                            $currentNode = &_resetList($currentNode, \$listDepth, undef);
                            @whiteSpace = ();
                            $prevIndentType = $listType;
                        }
                        while ($indentDepth > 0) {
                            $currentNode = $currentNode->parent;
                            $indentDepth--;
                        }
                        my @listContents;
                        if ($listType eq 'dl') {
                            @listContents = ($1, $2);
                        }
                        else {
                            @listContents = ($2);
                        }
                        if ( (scalar @whiteSpace &&
                              $wsLen > $whiteSpace[$#whiteSpace]) ||
                             !(scalar @whiteSpace) ) {
                            push @whiteSpace, $wsLen;
                        }
                        else {
                            while (scalar @whiteSpace &&
                                   $wsLen < $whiteSpace[$#whiteSpace]) {
                                pop @whiteSpace;
                            }
                            push @whiteSpace, $wsLen
                                if (!scalar @whiteSpace);
                        }
                        $listLength = scalar @whiteSpace;
                        $currentNode = &_parseList($listType, $listLength,
                                                   \$listDepth,
                                                   $currentNode,
                                                   \%params, \$nodeContent,
                                                   @listContents);
                    }
                }
            }
            else { # indented paragraph or li/p continuation
                if ($wsLen == $whiteSpace[$#whiteSpace] && !$isPrevBlank) { # li/p continuation
                    $nodeContent .= "$string\n";
                }
                else {
                    $currentNode = &_terminateNode($currentNode, \$nodeContent,
                                                   %params);
                    if ($prevIndentType ne 'indent') {
                        $currentNode = &_resetList($currentNode, \$listDepth, undef);
                        @whiteSpace = ();
                        $prevIndentType = 'indent';
                    }
                    if ( (scalar @whiteSpace &&
                          $wsLen > $whiteSpace[$#whiteSpace]) ||
                         !(scalar @whiteSpace) ) {
                        push @whiteSpace, $wsLen;
                    }
                    else {
                        while (scalar @whiteSpace &&
                               $wsLen < $whiteSpace[$#whiteSpace]) {
                            pop @whiteSpace;
                        }
                        push @whiteSpace, $wsLen
                            if (!scalar @whiteSpace);
                    }
                    $listLength = scalar @whiteSpace;
                    while ($listLength > $indentDepth) {
                        $currentNode = $currentNode->insertChild('type'=>'indent');
                        $indentDepth++;
                    }
                    while ($listLength < $indentDepth) {
                        $currentNode = $currentNode->parent;
                        $indentDepth--;
                    }
                    $currentNode = $currentNode->insertChild('type'=>'p');
                    if ($string =~ /\s*\{\{\{\s*$/) {
                        $string =~ s/\s*\{\{\{\s*$//;
                        $nodeContent .= "$string\n";
                        $currentNode = &_terminateNode($currentNode,
                                                       \$nodeContent,
                                                       %params);
                        $currentNode = &_resetList($currentNode, \$listDepth, \$indentDepth);
                        @whiteSpace = ();
                        $prevIndentType = undef;
                        $isBracePre = 1;
                        $currentNode = $currentNode->insertChild(type => 'pre');
                    }
                    else {
                        $nodeContent .= "$string\n";
                    }
                }
            }
            $isPrevBlank = 0;
            $isStart = 0 if ($isStart);
        }
        elsif ($line =~ /^\{\{\{\s*$/) {  # MoinMoin-style pre

            # If there's already a pre, this has the effect of closing
            # the previous one and starting a new one.  For example:
            #
            #   = Header =
            #
            #     indented (hence preformatted)
            #   {{{
            #   hello world!
            #   }}}
            #
            # will result in:
            #
            #   section:
            #     h:Header
            #     pre:  indented (hence preformatted)
            #     pre:hello world!
            #
            # This also creates an unusual side-effect:
            #
            #   {{{
            #   hello world!
            #   {{{
            #   hello again.
            #   }}}
            #
            # which results in:
            #
            #   section:
            #     h:Header
            #     pre:hello world!
            #     pre:hello again.
            #
            # In other words, the first {{{ did not need closing.

            $currentNode = &_resetList($currentNode, \$listDepth, \$indentDepth);
            @whiteSpace = ();
            $prevIndentType = undef;
            $currentNode = &_terminateNode($currentNode,
                                           \$nodeContent,
                                           %params);
            $currentNode = $currentNode->insertChild('type'=>'pre');
            $isStart = 0 if ($isStart);
            $isPrevBlank = 0;
            $isBracePre = 1;
        }
        elsif ($line =~ /^\s*\}\}\}\s*$/) {  # close MoinMoin pre
            if ($currentNode->type eq 'pre') {
                $currentNode = &_terminateNode($currentNode,
                                               \$nodeContent,
                                               %params);
                $nodeContent = $1;
                $isBracePre = 0;
            }
            else {
                # just make it part of the text
                $nodeContent .= $line;
            }
            $isPrevBlank = 0;
            $isStart = 0 if ($isStart);
        }
        elsif ($line =~ /^\s*$/) {  # blank line
            if ($isBracePre) {
                $nodeContent .= "\n";
            }
            else {
                $currentNode = &_terminateNode($currentNode, \$nodeContent,
                                               %params);
                $isPrevBlank = 1;
            }
        }
        else {
            if (!($currentNode->type eq 'p' && $indentDepth == 0) &&
                (!$isBracePre)) {
                $currentNode = &_terminateNode($currentNode,
                                               \$nodeContent,
                                               %params);
                $currentNode = &_resetList($currentNode, \$listDepth, \$indentDepth);
                @whiteSpace = ();
                $prevIndentType = undef;
                $currentNode = $currentNode->insertChild('type'=>'p');
            }
            if ($line =~ /\s*\{\{\{\s*$/) {
                $line =~ s/\s*\{\{\{\s*$//;
                $nodeContent .= "$line\n";
                $currentNode = &_terminateNode($currentNode,
                                               \$nodeContent,
                                               %params);
                $currentNode = &_resetList($currentNode, \$listDepth, \$indentDepth);
                @whiteSpace = ();
                $prevIndentType = undef;
                $isBracePre = 1;
                $currentNode = $currentNode->insertChild(type => 'pre');
            }
            else {
                $nodeContent .= "$line\n";
            }
            $isPrevBlank = 0;
            $isStart = 0 if ($isStart);
        }
    }
    $currentNode = &_terminateNode($currentNode, \$nodeContent,
                                        %params);
    if (scalar @authors > 0) {
        $tree->authors(\@authors);
    }

    if ($params{'add_node_ids'}) {
        &_addNodeIds($tree->root);
    }
    return $tree;
}

### private

sub _resetList {
    # "Resets" lists.  When a new node is about to be created, this
    # routine makes sure that any previous lists or indentations are
    # reset to the correct nesting depth.

    my ($currentNode, $listDepthRef, $indentDepthRef) = @_;

    if ($listDepthRef && ${$listDepthRef}) {
        while (${$listDepthRef} > 1) {
            $currentNode = $currentNode->parent->parent;
            ${$listDepthRef}--;
        }
        $currentNode = $currentNode->parent;
        ${$listDepthRef} = 0;
    }
    if ($indentDepthRef) {
        while (${$indentDepthRef} > 0) {
            $currentNode = $currentNode->parent;
            ${$indentDepthRef}--;
        }
    }
    return $currentNode;
}

sub _terminateNode {
    # "Closes" nodes.  When the parser knows that it is ready to add
    # content to the node (i.e. when it sees a blank line), this
    # routine does the adding.

    my ($currentNode, $nodeContentRef, %params) = @_;
    my ($currentNid);

    if (($currentNode->type eq 'p') || ($currentNode->type eq 'pre') ||
        ($currentNode->type eq 'li') || ($currentNode->type eq 'dd')) {
        chomp ${$nodeContentRef};
        ${$nodeContentRef} =~ s/\s+\{nid ([A-Z0-9]+)\}$//s;
        $currentNid = $1;
        if (defined $currentNid && ($currentNid =~ /^[A-Z0-9]+$/)) {
            $currentNode->id($currentNid);
        }
        if ($currentNode->type eq 'pre') {
            ${$nodeContentRef} = '<nowiki>' . ${$nodeContentRef} . '</nowiki>';
        }
        $currentNode->content(&_parseInlineNode(${$nodeContentRef}, %params));
        undef ${$nodeContentRef};
        return $currentNode->parent;
    }
    return $currentNode;
}

sub _parseList {
    # List parsing is mostly handled the same, which is why it gets
    # its own subroutine.  The main thing this routine does is handle
    # the nesting properly.

    my ($listType, $listLength, $listDepthRef,
        $currentNode, $paramRef, $nodeContentRef,
        @nodeContents) = @_;

    while ($listLength > ${$listDepthRef}) {
        # Nested lists are children of list items, not of other lists.
        # We need to find the last list item (if it exists) and
        # create a sublist there; otherwise, we need to create a list
        # item and give it a sublist.
        if ($currentNode->type eq 'ul' || $currentNode->type eq 'ol' ||
            $currentNode->type eq 'dl') {
            my $kidsRef = $currentNode->children;
            if ($kidsRef) {
                $currentNode = $kidsRef->[scalar @{$kidsRef} - 1];
            }
            else {
                if ($listType eq 'dl') {
                    $currentNode = $currentNode->insertChild(type=>'dd');
                }
                else {
                    $currentNode = $currentNode->insertChild(type=>'li');
                }
            }
        }
        $currentNode = $currentNode->insertChild(type=>$listType);
        ${$listDepthRef}++;
    }
    while ($listLength < ${$listDepthRef}) {  # assert($listLength != 0)
        $currentNode = $currentNode->parent->parent;
        ${$listDepthRef}--;
    }
    if ($listType eq 'dl') {
        $nodeContents[0] =~  s/\s+\{nid ([A-Z0-9]+)\}$//s;
        my $currentNid = $1;
        $currentNode = $currentNode->insertChild(type=>'dt',
            content=>&_parseInlineNode($nodeContents[0], %{$paramRef}));
        if (defined $currentNid && ($currentNid =~ /^[A-Z0-9]+$/)) {
            $currentNode->id($currentNid);
        }
        $currentNode = $currentNode->parent;
        ${$nodeContentRef} = $nodeContents[1] . "\n";
        $currentNode = $currentNode->insertChild('type'=>'dd');
    }
    else {
        ${$nodeContentRef} = $nodeContents[0] . "\n";
        $currentNode = $currentNode->insertChild('type'=>'li');
    }
    return $currentNode;
}

sub _parseInlineNode {
    my ($text, %params) = @_;
    my (@inlineNodes);

    # This used to be an extended regular expression, but it wasn't
    # working in some cases.
    my $rx = qq{$rxNowiki|$rxTransclusion|$rxTt|$rxFippleQuotes|$rxB|};
    $rx .= qq{$rxTripleQuotes|$rxI|$rxDoubleQuotes|};
    $rx .= qq{\\\[$rxProtocols$rxAddress\\s+.+?\\\]|$rxProtocols$rxAddress};
    if ($params{wikiword}) {
        $rx .= qq{|(?:$rxWikiWord)?\\\/$rxSubpage(?:\\\#[A-Z0-9]+)?};
        $rx .= qq{$rxQuoteDelim|[A-Z]\\w+:[^\\\]\\\#\\s"<>\:]+};
        $rx .= qq{(?:\\\#[A-Z0-9]+)?$rxQuoteDelim|$rxWikiWord};
        $rx .= qq{(?:\\\#[A-Z0-9]+)?$rxQuoteDelim};
    }
    if ($params{freelink}) {
        $rx .= qq{|$rxFreeLink};
    }
    my @nodes = split(/($rx)/s, $text);
    foreach my $node (@nodes) {
        if ($node =~ /^$rxNowiki$/s) {
            $node =~ s/^<nowiki>//;
            $node =~ s/<\/nowiki>$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'nowiki',
                                                           'content'=>$node);
        }
        elsif ($node =~ /^$rxTransclusion$/s) {
            # transclusion
            my ($content) = ($node =~ /([A-Z0-9]+)/);
            push @inlineNodes, PurpleWiki::InlineNode->new(
                'type' => 'transclusion',
                'content' => $content);
        }
        elsif ($node =~ /^$rxTt$/s) {
            $node =~ s/^<tt>//;
            $node =~ s/<\/tt>$//;
            $node =~ s/^\{\{\{//;
            $node =~ s/\}\}\}$//;
            $node = "<nowiki>$node</nowiki>";
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'tt',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^$rxFippleQuotes$/s) {
            $node =~ s/^'''//;
            $node =~ s/'''$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'b',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^$rxB$/s) {
            $node =~ s/^<b>//;
            $node =~ s/<\/b>$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'b',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^$rxTripleQuotes$/s) {
            $node =~ s/^'''//;
            $node =~ s/'''$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'b',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^$rxI$/s) {
            $node =~ s/^<i>//;
            $node =~ s/<\/i>$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'i',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^$rxDoubleQuotes$/s) {
            $node =~ s/^''//;
            $node =~ s/''$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'i',
                'children'=>&_parseInlineNode($node, %params));
        }
        elsif ($node =~ /^\[($rxProtocols$rxAddress)\s*(.*?)\]$/s) {
            # bracketed link
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'link',
                                                           'href'=>$1,
                                                           'content'=>$2);
        }
        elsif ($node =~ /^$rxProtocols$rxAddress$/s) {
            # URL
            if ($node =~ /\.(?:jpg|gif|png|bmp|jpeg)$/i) {
                push @inlineNodes,
                    PurpleWiki::InlineNode->new('type'=>'image',
                                                'href'=>$node,
                                                'content'=>$node);
            }
            else {
                push @inlineNodes,
                    PurpleWiki::InlineNode->new('type'=>'url',
                                                'href'=>$node,
                                                'content'=>$node);
            }
        }
        elsif ($params{freelink} && ($node =~ /$rxFreeLink/s)) {
            $node =~ s/^\[\"//;
            $node =~ s/\"\]$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'freelink',
                                                           'content'=>$node);
        }
        elsif ($params{wikiword} &&
               ($node =~ /^(?:$rxWikiWord)?\/$rxSubpage(?:\#[A-Z0-9]+)?$rxQuoteDelim$/s)) {
            $node =~ s/""$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                           'content'=>$node);
        }
        elsif ($params{wikiword} &&
               ($node =~ /^([A-Z]\w+):([^\]\#\:\s"<>]+(?:\#[A-Z0-9]+)?)$rxQuoteDelim$/s)) {
            my $site = $1;
            my $page = $2;
            if (&PurpleWiki::Page::siteExists($site)) {
                $node =~ s/""$//;
                push @inlineNodes,
                    PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                'content'=>$node);
            }
            else {
                if ($site =~ /^$rxWikiWord$/) {
                    push @inlineNodes,
                        PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                    'content'=>$site);
                    if ( ($page =~ /^$rxWikiWord(?:\#[A-Z0-9]+)?$/) ||
                         ($page =~ /^$rxWikiWord\/$rxSubpage(?:\#[A-Z0-9]+)?$/) ) {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>':');
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                        'content'=>$page);
                    }
                    elsif ($page =~ /(.*)(\/$rxSubpage(?:\#[A-Z0-9]+)?)$/) {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>":$1");
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                        'content'=>$2);
                    }
                    else {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>":$page");
                    }
                }
                else {
                    if ( ($page =~ /^$rxWikiWord(?:\#[A-Z0-9]+)?$/) ||
                         ($page =~ /^$rxWikiWord\/$rxSubpage(?:\#[A-Z0-9]+)?$/) ) {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>"$site:");
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                        'content'=>$page);
                    }
                    elsif ($page =~ /(.*)(\/$rxSubpage(?:\#[A-Z0-9]+)?)$/) {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>"$site:$1");
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                        'content'=>$2);
                    }
                    else {
                        push @inlineNodes,
                            PurpleWiki::InlineNode->new('type'=>'text',
                                                        'content'=>"$site:$page");
                    }
                }
            }
        }
        elsif ($params{wikiword} &&
               ($node =~ /$rxWikiWord(?:\#[A-Z0-9]+)?$rxQuoteDelim/s)) {
            $node =~ s/""$//;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'wikiword',
                                                           'content'=>$node);
        }
        elsif ($node ne '') {
            # FIXME: For now, substitute MoinMoin macros with something else
            $node =~ s/\[\[/\[macro\[/g;
            push @inlineNodes, PurpleWiki::InlineNode->new('type'=>'text',
                                                           'content'=>$node);
        }
    }
    return \@inlineNodes;
}

sub _addNodeIds {
    my ($rootNode) = @_;

    &_traverseAndAddNids($rootNode->children)
        if ($rootNode->children);
}

sub _traverseAndAddNids {
    my ($nodeListRef) = @_;

    foreach my $node (@{$nodeListRef}) {
        if (($node->type eq 'h' || $node->type eq 'p' ||
             $node->type eq 'li' || $node->type eq 'pre' ||
             $node->type eq 'dt' || $node->type eq 'dd') &&
            !$node->id) {
            $node->id($sequence->getNext($url));
        }
        my $childrenRef = $node->children;
        &_traverseAndAddNids($childrenRef)
            if ($childrenRef);
    }
}

1;
__END__

=head1 NAME

PurpleWiki::Parser::MoinMoin - MoinMoin parser.

=head1 SYNOPSIS

  use PurpleWiki::Parser::MoinMoin;

  my $parser = PurpleWiki::Parser::MoinMoin->new;
  my $wikiTree = $parser->parse($wikiText);

=head1 DESCRIPTION

Parses a MoinMoinWiki text file, and returns a PurpleWiki::Tree.

=head1 STATUS

This is not a complete MoinMoin parser, but it's good enough for most
conversion jobs.  The formatting rules are very close.  MoinMoin is
richer, in that it supports some additional formatting functions
(superscript, underline, tables) and functionality (plugins).

The primary difference is in how MoinMoin handles lists and
indentations.  True to its Pythonic origins, it uses whitespace.  The
whitespace rules are funky, and because of the complexity required to
implement them exactly the same, I didn't account for certain special
cases.  For example:

      1. Hello.
      1. There.
    1. Should be a new list

would actually be parsed to:

  ol:
    li:Hello.
    li:Hello.
    li:Should be a new list

I also didn't account for all of the pre special cases, namely:

  This is a paragraph.  {{{This should be the start of a pre.
  But it's not.
  }}}

will parse to:

  p:This is a paragraph.  {{{This should be the start of a pre.
  But it's not.
  }}}

For the sake of conversion, most of these special cases can be grepped
for and fixed manually.

=head1 METHODS

=head2 new()

Constructor.

=head2 parse($wikiContent, %params)

Parses $wikiContent into a PurpleWiki::Tree.  The following parameters
are supported:

  add_node_ids -- Add IDs to structural nodes that do not already
                  have them.

  wikiword     -- Parse WikiWords.
  freelink     -- Parse free links (e.g. [[free link]]).

=head1 AUTHORS

Eugene Eric Kim, E<lt>eekim@blueoxen.orgE<gt>

=head1 SEE ALSO

L<PurpleWiki::Parser::WikiText>, L<PurpleWiki::Tree>.

=cut
