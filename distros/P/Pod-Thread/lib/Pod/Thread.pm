# Convert POD data to the HTML macro language thread.
#
# This module converts POD to the HTML macro language thread.  It's intended
# for use with the spin program to include POD documentation in a
# spin-generated web page complex.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package Pod::Thread 3.00;

use 5.024;
use strict;
use warnings;

use base qw(Pod::Simple);

use Carp qw(croak);
use Encode qw(encode);
use Text::Balanced qw(extract_bracketed);
use Text::Wrap qw(wrap);

# Pod::Simple uses subroutines named as if they're private for subclassing,
# and we dynamically construct method names on the fly.
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

##############################################################################
# Internal constants
##############################################################################

# Regex matching a manpage-style entry in the NAME header.  $1 is set to the
# list of things documented by the man page, and $2 is set to the description.
my $NAME_REGEX = qr{ \A ( \S+ (?:,\s*\S+)* ) [ ] - [ ] (.*) }xms;

# Maximum length of each line when constructing a navbar.
my $NAVBAR_LENGTH = 65;

# Margin at which to wrap thread output.
my $WRAP_MARGIN = 75;

##############################################################################
# Initialization
##############################################################################

# Initialize the object and set various Pod::Simple options that we need.
# Here, we also process any additional options passed to the constructor or
# set up defaults if none were given.  Note that all internal object keys are
# in all-caps, reserving all lower-case object keys for Pod::Simple and user
# arguments.  User options are rewritten to start with opt_ to avoid conflicts
# with Pod::Simple.
#
# %opts - Our options as key/value pairs
#
# Returns: Newly constructed Pod::Thread object
#  Throws: Whatever Pod::Simple's constructor might throw
sub new {
    my ($class, %opts) = @_;
    my $self = $class->SUPER::new;

    # Tell Pod::Simple to handle S<> by automatically inserting E<nbsp>.
    $self->nbsp_for_S(1);

    # The =for and =begin targets that we accept.
    $self->accept_targets('thread');

    # Ensure that contiguous blocks of code are merged together.
    $self->merge_text(1);

    # Preserve whitespace whenever possible to make debugging easier.
    $self->preserve_whitespace(1);

    # Always send errors to standard error.
    $self->no_errata_section(1);
    $self->complain_stderr(1);

    # Pod::Simple doesn't do anything useful with our arguments, but we want
    # to put them in our object as hash keys and values.  This could cause
    # problems if we ever clash with Pod::Simple's own internal class
    # variables, so rename them with an opt_ prefix.
    my @opts = map { ("opt_$_", $opts{$_}) } keys %opts;
    %{$self} = (%{$self}, @opts);

    return $self;
}

##############################################################################
# Core parsing
##############################################################################

# This is the glue that connects the code below with Pod::Simple itself.  The
# goal is to convert the event stream coming from the POD parser into method
# calls to handlers once the complete content of a tag has been seen.  Each
# paragraph or POD command will have textual content associated with it, and
# as soon as all of a paragraph or POD command has been seen, that content
# will be passed in to the corresponding method for handling that type of
# object.  The exceptions are handlers for lists, which have opening tag
# handlers and closing tag handlers that will be called right away.
#
# The internal hash key PENDING is used to store the contents of a tag until
# all of it has been seen.  It holds a stack of open tags, each one
# represented by a tuple of the attributes hash for the tag and the contents
# of the tag.

# Add a block of text to the contents of the current node, protecting any
# thread metacharacters unless we're in a literal (=for or =begin) block.
#
# $text - A block of ordinary text seen in the POD
sub _handle_text {
    my ($self, $text) = @_;
    if (!$self->{LITERAL}) {
        $text =~ s{ \\ }{\\\\}xmsg;
        $text =~ s{ ([\[\]]) }{'\\entity[' . ord($1) . ']'}xmseg;
    }
    my $tag = $self->{PENDING}[-1];
    $tag->[1] .= $text;
    return;
}

# Given an element name, get the corresponding portion of a method name.  The
# real methods will be formed by prepending cmd_, start_, or end_.
#
# $element - Name of the POD element by Pod::Simple's naming scheme.
#
# Returns: The element transformed into part of a method name.
sub _method_for_element {
    my ($self, $element) = @_;
    $element =~ tr{-}{_};
    $element =~ tr{A-Z}{a-z};
    $element =~ tr{_a-z0-9}{}cd;
    return $element;
}

# Handle the start of a new element.  If cmd_element is defined, assume that
# we need to collect the entire tree for this element before passing it to the
# element method, and create a new tree into which we'll collect blocks of
# text and nested elements.  Otherwise, if start_element is defined, call it.
#
# $element - The name of the POD element that was started
# $attrs   - The attribute hash for that POD element.
sub _handle_element_start {
    my ($self, $element, $attrs) = @_;
    my $method = $self->_method_for_element($element);

    # If we have a command handler, we need to accumulate the contents of the
    # tag before calling it.  If we have a start handler, call it immediately.
    if ($self->can("_cmd_$method")) {
        push($self->{PENDING}->@*, [$attrs, q{}]);
    } elsif ($self->can("_start_$method")) {
        $method = '_start_' . $method;
        $self->$method($attrs, q{});
    }
    return;
}

# Handle the end of an element.  If we had a cmd_ method for this element,
# this is where we pass along the text that we've accumulated.  Otherwise, if
# we have an end_ method for the element, call that.
#
# $element - The name of the POD element that was started
sub _handle_element_end {
    my ($self, $element) = @_;
    my $method = $self->_method_for_element($element);

    # If we have a command handler, pull off the pending text and pass it to
    # the handler along with the saved attribute hash.  Otherwise, if we have
    # an end method, call it.
    if ($self->can("_cmd_$method")) {
        my $tag_ref = pop($self->{PENDING}->@*);
        $method = '_cmd_' . $method;
        my $text = $self->$method($tag_ref->@*);

        # If the command returned some text, check if the element stack is
        # non-empty.  If so, add that text to the next open element.
        # Otherwise, we're at the top level and can output the text directly.
        if (defined($text)) {
            if ($self->{PENDING}->@* > 1) {
                $self->{PENDING}[-1][1] .= $text;
            } else {
                $self->_output($text);
            }
        }
        return;
    } elsif ($self->can("_end_$method")) {
        $method = '_end_' . $method;
        return $self->$method();
    } else {
        return;
    }
}

##############################################################################
# Output formatting
##############################################################################

# Ensure text ends in two newlines.
#
# $text - Text to reformat
#
# Returns: Text with whitespace fixed
sub _reformat {
    my ($self, $text) = @_;
    $text =~ s{ \s* \z }{\n\n}xms;
    return $text;
}

# Accumulate output text.  We may have some accumulated whitespace in the
# SPACE internal variable; if so, add that after any closing bracket at the
# start of our output.  Then, save any whitespace at the end of our output and
# defer it for next time.  (This creates much nicer association of closing
# brackets.)
#
# $text - Text to output
sub _output {
    my ($self, $text) = @_;

    # If we have deferred whitespace, output it before the text, but after any
    # closing bracket at the start of the text.
    if ($self->{SPACE}) {
        if ($text =~ s{ \A \] \s* \n }{}xms) {
            $self->{OUTPUT} .= "]\n";
        }
        $self->{OUTPUT} .= $self->{SPACE};
        undef $self->{SPACE};
    }

    # Defer any trailing newlines beyond a single newline.
    if ($text =~ s{ \n (\n+) \z }{\n}xms) {
        $self->{SPACE} = $1;
    }

    # Append the text to the output.
    $self->{OUTPUT} .= $text;
    return;
}

# Flush the output at the end of a document by sending it to the correct
# output file handle.  Force the encoding to UTF-8 unless we've found that we
# already have a UTF-8 encoding layer.
sub _flush_output {
    my ($self) = @_;
    my $output = $self->{OUTPUT};

    # Encode if necessary and then output.
    if ($self->{ENCODE}) {
        $output = encode('UTF-8', $output);
    }
    print { $self->{output_fh} } $output
      or die "Cannot write to output: $!\n";

    # Clear the output to avoid sending it twice.
    $self->{OUTPUT} = q{};
    return;
}

##############################################################################
# Document start and finish
##############################################################################

# Construct a table of contents from the headings seen throughout the
# document.
#
# Returns: The thread code for the table of contents
sub _contents {
    my ($self) = @_;
    return q{} if !$self->{HEADINGS}->@*;

    # Construct and return the table of contents.
    my $output = "\\h2[Table of Contents]\n\n";
    for my $i (0 .. $self->{HEADINGS}->$#*) {
        my $tag     = 'S' . ($i + 1);
        my $section = $self->{HEADINGS}[$i];
        $output .= "\\number(packed)[\\link[#$tag][$section]]\n";
    }
    $output .= "\n";
    return $output;
}

# Capitalize a heading for the navigation bar.  Normally we want to use
# title case, but don't lowercase elements containing an underscore.
#
# $heading - The heading to capitalize
#
# Returns: The properly capitalized heading.
sub _capitalize_for_navbar {
    my ($self, $heading) = @_;
    my @words = split(m{ (\s+) }xms, $heading);
    for my $word (@words) {
        if ($word !~ m{ _ }xms && $word !~ m{ \A \\ }xms) {
            $word = lc($word);
            if ($word ne 'and') {
                $word = ucfirst($word);
            }
        }
    }
    return join(q{}, @words);
}

# Construct a navigation bar.  This is like a table of contents, but lists the
# sections separated by vertical bars and tries to limit the number of
# sections per line.  The navbar will be presented in the sorted order of the
# tags.
#
# Returns: The thread code for the navbar
sub _navbar {
    my ($self) = @_;
    return if !$self->{HEADINGS}->@*;

    # Build the start of the navbar.
    my $output = "\\class(navbar)[\n  ";

    # Format the navigation bar, accumulating each line in $output.  Store the
    # formatted length in $length.  We can't use length($output) because that
    # would count all the thread commands.  This won't be quite right if
    # headings contain formatting.
    my $pending = q{};
    my $length  = 0;
    for my $i (0 .. scalar($self->{HEADINGS}->$#*)) {
        my $tag     = 'S' . ($i + 1);
        my $section = $self->{HEADINGS}[$i];

        # If adding this section would put us over 60 characters, output the
        # current line with a line break.
        if ($length > 0 && $length + length($section) > $NAVBAR_LENGTH) {
            $output .= "$pending\\break\n  ";
            $pending = q{};
            $length  = 0;
        }

        # If this isn't the first thing on a line, add the separator.
        if (length($pending) != 0) {
            $pending .= q{  | };
            $length += length(q{ | });
        }

        # Convert the section names to titlecase.
        my $name = $self->_capitalize_for_navbar($section);

        # Add it to the current line.
        $pending .= "\\link[#$tag][$name]\n";
        $length += length($name);
    }

    # Collect any remaining partial line and the end of the navbar.
    if (length($pending) > 0) {
        $output .= $pending;
    }
    $output .= "]\n\n";
    return $output;
}

# Construct the header and title of the document, including any navigation bar
# and contents section if we have any.
#
# $title      - Document title
# $subheading - Document subheading (may be undef)
#
# Returns: The thread source for the document heading
sub _header {
    my ($self) = @_;
    my $style  = $self->{opt_style} || q{};
    my $output = q{};

    # Add the basic title, page heading, and style if we saw a title.
    if ($self->{TITLE}) {
        $output .= "\\heading[$self->{TITLE}][$style]\n\n";
        $output .= "\\h1[$self->{TITLE}]\n\n";
    }

    # If there is a subheading, add it.
    if (defined($self->{SUBHEADING})) {
        $output .= "\\class(subhead)[($self->{SUBHEADING})]\n\n";
    }

    # If a navbar or table of contents was requested, add it.
    if ($self->{opt_navbar}) {
        $output .= $self->_navbar();
    }
    if ($self->{opt_contents}) {
        $output .= $self->_contents();
    }

    # Return the results.
    return $output;
}

# Handle the beginning of a POD file.  We only output something if title is
# set, in which case we output the title and other header information at the
# beginning of the resulting output file.
#
# $attrs - Attributes of the start document tag
sub _start_document {
    my ($self, $attrs) = @_;

    # If the document has no content, set the appropriate internal flag.
    if ($attrs->{contentless}) {
        $self->{CONTENTLESS} = 1;
    } else {
        delete $self->{CONTENTLESS};
    }

    # Initialize per-document variables.
    $self->{HEADINGS}     = [];
    $self->{IN_NAME}      = 0;
    $self->{ITEM_OPEN}    = 0;
    $self->{ITEM_PENDING} = 0;
    $self->{ITEMS}        = [];
    $self->{LITERAL}      = 0;
    $self->{OUTPUT}       = q{};
    $self->{PENDING}      = [[]];
    $self->{SUBHEADING}   = undef;
    $self->{TITLE}        = $self->{opt_title} // q{};

    # Check whether our output file handle already has a PerlIO encoding layer
    # set.  If it does not, we'll need to encode our output before printing
    # it.  Wrap the check in an eval to handle versions of Perl without
    # PerlIO.
    $self->{ENCODE} = 1;
    eval {
        my @options = (output => 1, details => 1);
        my @layers  = PerlIO::get_layers($self->{output_fh}->**, @options);
        if ($layers[-1] && ($layers[-1] & PerlIO::F_UTF8())) {
            $self->{ENCODE} = 0;
        }
    };
    return;
}

# Canonicalize a heading for internal links.  We run both the anchor text and
# the heading itself through this function so that whitespace differences
# don't cause us to fail to create the link.
#
# Note that this affects only the end-of-document rewriting, not the links we
# create as we go, because this case is rare and doing it as we go would
# require more state tracking.
#
# $heading - Text of heading
#
# Returns: Canonicalized heading text
sub _canonicalize_heading {
    my ($self, $heading) = @_;
    $heading =~ s{ \s+ }{ }xmsg;
    return $heading;
}

# Handle the end of the document.  Tack \signature onto the end, output the
# header and the accumulated output, and die if we saw any errors.
#
# Throws: Text exception if there were any errata
sub _end_document {
    my ($self) = @_;

    # Output the \signature command if we saw any content.
    if (!$self->{CONTENTLESS}) {
        $self->_output("\\signature\n");
    }

    # Search for any unresolved links and try to fix their anchors.  If we
    # never saw the heading in question, remove the \link command.  We have to
    # use Text::Balanced and substr surgery to extract the anchor text since
    # it may contain arbitrary markup.
    #
    # This is very inefficient for large documents, but I doubt anything
    # processed by this module will be large enough to matter.
    my $i        = 1;
    my $search   = '\\link[#PLACEHOLDER]';
    my $start    = 0;
    my %headings = map { ('[' . $self->_canonicalize_heading($_) . ']', $i++) }
      $self->{HEADINGS}->@*;
    while (($start = index($self->{OUTPUT}, $search, $start)) != -1) {
        my $text = substr($self->{OUTPUT}, $start + length($search));
        my ($anchor) = extract_bracketed($text, '[]', undef);
        my $heading;
        if ($anchor) {
            $heading = $self->_canonicalize_heading($anchor);
        }

        # If this is a known heading, replace #PLACEHOLDER with the link to
        # that heading and continue processing with the anchor text.
        # Otherwise, replace the entire \link command with the anchor text and
        # continue processing after it.
        if (defined($anchor) && defined($headings{$heading})) {
            $start += length('\\link[');
            my $link = "#S$headings{$heading}";
            substr($self->{OUTPUT}, $start, length('#PLACEHOLDER'), $link);
        } else {
            my $length = length('\\link[#PLACEHOLDER]') + length($anchor);
            $anchor = substr($anchor, 1, -1);
            substr($self->{OUTPUT}, $start, $length, $anchor);
            $start += length($anchor);
        }
    }

    # Output the header.
    my $header = $self->_header();
    if ($self->{ENCODE}) {
        $header = encode('UTF-8', $header);
    }
    print { $self->{output_fh} } $header
      or die "Cannot write to output: $!\n";

    # Flush the rest of the output.
    $self->_flush_output();

    # Die if we saw any errors.
    if ($self->any_errata_seen()) {
        croak('POD document had syntax errors');
    }
    return;
}

##############################################################################
# Text blocks
##############################################################################

# Called for a regular text block.  There are two tricky parts here.  One is
# that if there is a pending item tag, we need to format this as an item
# paragraph.  The second is that if we're in the NAME section and see the name
# and description of the page, we should print out the header.
#
# $attrs - Attributes for this command
# $text  - The text of the block
sub _cmd_para {
    my ($self, $attrs, $text) = @_;

    # Ensure the text block ends with a single newline.
    $text =~ s{ \s+ \z }{\n}xms;

    # If we're inside an item block, handle this as an item.
    if (@{ $self->{ITEMS} } > 0) {
        $self->_item($self->_reformat($text));
    }

    # If we're in the NAME section and see a line that looks like the special
    # NAME section of a man page, stash that information for the page heading.
    elsif ($self->{IN_NAME} && $text =~ $NAME_REGEX) {
        my ($name, $description) = ($1, $2);
        $self->{TITLE}      = $name;
        $self->{SUBHEADING} = $description;
    }

    # Otherwise, this is a regular text block, so just output it with a
    # trailing blank line.
    else {
        $self->_output($self->_reformat($text . "\n"));
    }
    return;
}

# Called for a verbatim paragraph.  The only trick is knowing whether to use
# the item method to handle it or just print it out directly.
#
# $attrs - Attributes for this command
# $text  - The text of the block
sub _cmd_verbatim {
    my ($self, $attrs, $text) = @_;

    # Ignore empty verbatim paragraphs.
    if ($text =~ m{ \A \s* \z }xms) {
        return;
    }

    # Ensure the paragraph ends in a bracket and two newlines.
    $text =~ s{ \s* \z }{\]\n\n}xms;

    # Pass the text to either item or output.
    if (@{ $self->{ITEMS} } > 0) {
        $self->_item("\\pre\n[$text");
    } else {
        $self->_output("\\pre\n[$text");
    }
    return;
}

# Called for literal text produced by =for and similar constructs.  Just
# output the text verbatim with cleaned-up whitespace.
#
# $attrs - Attributes for this command
# $text  - The text of the block
sub _cmd_data {
    my ($self, $attrs, $text) = @_;
    $text =~ s{ \A (\s*\n)+ }{}xms;
    $text =~ s{ \s* \z }{\n\n}xms;
    $self->_output($text);
    return;
}

# Called when =for and similar constructs are started or ended.  Set or clear
# the literal flag so that we won't escape the text on the way in.
sub _start_for { my ($self) = @_; $self->{LITERAL} = 1; return; }
sub _end_for   { my ($self) = @_; $self->{LITERAL} = 0; return; }

##############################################################################
# Headings
##############################################################################

# The common code for handling all headings.  Take care of any pending items
# or lists and then output the thread code for the heading.
#
# $text  - The text of the heading itself
# $level - The level of the heading as a number (2..5)
# $tag   - An optional tag for the heading
sub _heading {
    my ($self, $text, $level, $tag) = @_;

    # If there is a waiting item or a pending close bracket, output it now.
    $self->_finish_item();

    # Strip any trailing whitespace.
    $text =~ s{ \s+ \z }{}xms;

    # Output the heading thread.
    if (defined $tag) {
        $self->_output("\\h$level($tag)[$text]\n\n");
    } else {
        $self->_output("\\h$level" . "[$text]\n\n");
    }
    return;
}

# First level heading.  This requires some special handling to update the
# IN_NAME setting based on whether we're currently in the NAME section.  Also
# add a tag to the heading if we have section information.
#
# $attrs - Attributes for this command
# $text  - The text of the block
#
# Returns: The result of the heading method
sub _cmd_head1 {
    my ($self, $attrs, $text) = @_;

    # Strip whitespace from the text since we're going to compare it to other
    # things.
    $text =~ s{ \s+ \z }{}xms;

    # If we're in the NAME section and no title was explicitly set, set the
    # flag used in cmd_para to parse the NAME text specially and then do
    # nothing else (since we won't print out the NAME section as itself.
    if ($text eq 'NAME' && !exists($self->{opt_title})) {
        $self->{IN_NAME} = 1;
        return;
    }
    $self->{IN_NAME} = 0;

    # Not in the name section.  Record the heading and a tag to the header.
    push($self->{HEADINGS}->@*, $text);
    my $tag = 'S' . scalar($self->{HEADINGS}->@*);
    return $self->_heading($text, 2, "#$tag");
}

# All the other headings, which just hand off to the heading method.
sub _cmd_head2 { my ($self, $j, $text) = @_; return $self->_heading($text, 3) }
sub _cmd_head3 { my ($self, $j, $text) = @_; return $self->_heading($text, 4) }
sub _cmd_head4 { my ($self, $j, $text) = @_; return $self->_heading($text, 5) }

##############################################################################
# List handling
##############################################################################

# Called for each paragraph of text that we see inside an item.  It's also
# called with no text when it's time to start an item even though there wasn't
# any text associated with it (which happens for description lists).  The top
# of the ITEMS stack will hold the command that should be used to open the
# item block in thread.
#
# $text - Contents of the text block inside =item
sub _item {
    my ($self, $text) = @_;

    # If there wasn't anything waiting, we're in the second or subsequent
    # paragraph of the item text.  Just output it.
    if (!$self->{ITEM_PENDING}) {
        $self->_output($text);
        return;
    }

    # We're starting a new item.  Close any pending =item block.
    if ($self->{ITEM_OPEN}) {
        $self->_output("]\n");
        $self->{ITEM_OPEN} = 0;
    }

    # Now, output the start of the item tag plus the text, if any.
    my $tag = $self->{ITEMS}[-1];
    $self->_output($tag . "\n[" . ($text // q{}));
    $self->{ITEM_OPEN}    = 1;
    $self->{ITEM_PENDING} = 0;
    return;
}

# Output any waiting items and close any pending blocks.
sub _finish_item {
    my ($self) = @_;
    if ($self->{ITEM_PENDING}) {
        $self->_item();
    }
    if ($self->{ITEM_OPEN}) {
        $self->_output("]\n");
        $self->{ITEM_OPEN} = 0;
    }
    return;
}

# Handle the beginning of an =over block.  This is called by the handlers for
# the four different types of lists (bullet, number, desc, and block).  Update
# our internal tracking for =over blocks.
sub _over_start {
    my ($self) = @_;

    # If an item was already pending, we have nested =over blocks.  Open the
    # outer block here before we start processing items for the inside block.
    if ($self->{ITEM_PENDING}) {
        $self->_item();
    }

    # Start a new block.
    $self->{ITEM_OPEN} = 0;
    push($self->{ITEMS}->@*, q{});
    return;
}

# Handle the end of a list.  Output any waiting items, close any pending
# blocks, and pop one level of item off the item stack.
sub _over_end {
    my ($self) = @_;

    # If there is a waiting item or a pending close bracket, output it now.
    $self->_finish_item();

    # Pop the item off the stack.
    pop($self->{ITEMS}->@*);

    # Set pending based on whether there's still another level of item open.
    if ($self->{ITEMS}->@* > 0) {
        $self->{ITEM_OPEN} = 1;
    }
    return;
}

# All the individual start commands for the specific types of lists.  These
# are all dispatched to the relevant common routine except for block.
# Pod::Simple gives us the type information on both the =over and the =item.
# We ignore it here and use it when we see the =item.
sub _start_over_bullet { my ($self) = @_; return $self->_over_start() }
sub _start_over_number { my ($self) = @_; return $self->_over_start() }
sub _start_over_text   { my ($self) = @_; return $self->_over_start() }

# Over of type block (which is =over without any =item) has to be handled
# specially, since normally we defer issuing the tag until we see the first
# =item and that won't happen here.
sub _start_over_block {
    my ($self) = @_;
    $self->_over_start();
    $self->{ITEMS}[-1] = '\\block';
    $self->{ITEM_PENDING} = 1;
    $self->_item();
    return;
}

# Likewise for the end commands.
sub _end_over_block  { my ($self) = @_; return $self->_over_end() }
sub _end_over_bullet { my ($self) = @_; return $self->_over_end() }
sub _end_over_number { my ($self) = @_; return $self->_over_end() }
sub _end_over_text   { my ($self) = @_; return $self->_over_end() }

# An individual list item command.  Note that this fires when the =item
# command is seen, not when we've accumulated all the text that's part of that
# item.  We may have some body text and we may not, but we have to defer the
# end of the item until the surrounding =over is closed.
#
# $type  - The type of the item
# $attrs - Attributes for this command
# $text  - The text of the block
sub _item_common {
    my ($self, $type, $attrs, $text) = @_;

    # If we saw an =item command, any previous item block is finished, so
    # output that now.
    if ($self->{ITEM_PENDING}) {
        $self->_item();
    }

    # The top of the stack should now contain our new type of item.
    $self->{ITEMS}[-1] = "\\$type";

    # We now have an item waiting for output.
    $self->{ITEM_PENDING} = 1;

    # If the type is desc, anything in $text is the description title and
    # needs to be appended to our ITEM.
    if ($self->{ITEMS}[-1] eq '\\desc') {
        $text =~ s{ \s+ \z }{}xms;
        $self->{ITEMS}[-1] .= "[$text]";
    }

    # Otherwise, anything in $text is body text.  Handle that now.
    else {
        $self->_item($self->_reformat($text));
    }

    return;
}

# All the various item commands just call item_common.
## no critic (Subroutines::RequireArgUnpacking)
sub _cmd_item_bullet { my $s = shift; return $s->_item_common('bullet', @_) }
sub _cmd_item_number { my $s = shift; return $s->_item_common('number', @_) }
sub _cmd_item_text   { my $s = shift; return $s->_item_common('desc',   @_) }
## use critic
## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)

##############################################################################
# Formatting codes
##############################################################################

# The simple ones.  These are here mostly so that subclasses can override them
# and do more complicated things.
#
# $attrs - Attributes for this command
# $text  - The text of the block
#
# Returns: The formatted text
sub _cmd_b { my ($self, $attrs, $text) = @_; return "\\bold[$text]" }
sub _cmd_c { my ($self, $attrs, $text) = @_; return "\\code[$text]" }
sub _cmd_f { my ($self, $attrs, $text) = @_; return "\\italic(file)[$text]" }
sub _cmd_i { my ($self, $attrs, $text) = @_; return "\\italic[$text]" }
sub _cmd_x { return q{} }

# Format a link.  Don't try to generate hyperlinks for anything other than
# normal URLs and section links within our same document.  For the latter, we
# can only do that for sections we've already seen; for everything else, use a
# PLACEHOLDER tag that we'll try to replace with a real link as the last step
# of formatting the document.
#
# $attrs - Attributes for this command
# $text  - The text of the block
#
# Returns: The formatted link
sub _cmd_l {
    my ($self, $attrs, $text) = @_;
    if ($attrs->{type} eq 'url') {
        if (!defined($attrs->{to}) || $attrs->{to} eq $text) {
            return "<\\link[$text][$text]>";
        } else {
            return "\\link[$attrs->{to}][$text]";
        }
    } elsif ($attrs->{type} eq 'pod') {
        my $page    = $attrs->{to};
        my $section = $attrs->{section};
        if (!defined($page) && defined($section)) {
            my $tag = 'PLACEHOLDER';
            for my $i (0 .. scalar($self->{HEADINGS}->$#*)) {
                if ($self->{HEADINGS}[$i] eq $section) {
                    $tag = 'S' . ($i + 1);
                    last;
                }
            }
            $text =~ s{ \A \" }{}xms;
            $text =~ s{ \" \z }{}xms;
            return "\\link[#$tag][$text]";
        }
    }

    # Fallthrough just returns the preformatted text from Pod::Simple.
    return $text // q{};
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery CVS STDIN STDOUT navbar podlators MERCHANTABILITY NONINFRINGEMENT
sublicense

=head1 NAME

Pod::Thread - Convert POD data to the HTML macro language thread

=head1 SYNOPSIS

    use Pod::Thread;
    my $parser = Pod::Thread->new;

    # Read POD from STDIN and write to STDOUT.
    $parser->parse_from_filehandle;

    # Read POD from file.pod and write to file.th.
    $parser->parse_from_file ('file.pod', 'file.th');

=head1 DESCRIPTION

Pod::Thread is a module that can convert documentation in the POD format
(the preferred language for documenting Perl) into thread, an HTML macro
language.  It lets the converter from thread to HTML handle some of the
annoying parts of conversion to HTML.

As a derived class from Pod::Simple, Pod::Thread supports the same methods and
interfaces.  See L<Pod::Simple> for all the details; briefly, one creates a
new parser with C<< Pod::Thread->new() >>, sets the output destination with
either output_fh() or output_string(), and then calls one of parse_file(),
parse_string_document(), or parse_lines().

new() can take the following options, in the form of key/value pairs, to
control the behavior of the formatter:

=over 4

=item contents

If set to a true value, output a table of contents section at the beginning of
the document.  Only top-level headings will be shown.

=item id

Sets the CVS Id string for the file.  If this isn't set, Pod::Thread will
try to find it in the file.

=item navbar

If set to a true value, output a navigation bar at the beginning of the
document with links to all top-level headings.

=item style

Sets the name of the style sheet to use.  If not given, no reference to a
style sheet will be included in the generated page.

=item title

The title of the document.  If this is set, it will be used rather than
looking for and parsing a NAME section in the POD file, and NAME sections
will no longer be required or special.

=back

=head1 DIAGNOSTICS

=over 4

=item Cannot write to output: %s

(F) An error occurred while attempting to write the thread result to the
configured output string or file handle.

=item POD document had syntax errors

(F) The POD document being formatted had syntax errors.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>, based heavily on Pod::Text from podlators.

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2008-2009, 2013, 2021 Russ Allbery <rra@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<Pod::Simple>, L<spin(1)>

This module is part of the Pod-Thread distribution.  The current version of
Pod-Thread is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/pod-thread/>.

B<spin> is available from L<https://www.eyrie.org/~eagle/software/web/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
