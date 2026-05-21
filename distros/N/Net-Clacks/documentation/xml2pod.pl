#!/usr/bin/env perl
# xml2pod.pl - Convert xml2rfc XML to POD format for CPAN documentation
#
# Usage: perl xml2pod.pl clacks.xml > ../lib/Net/Clacks/Protocol.pod
#
# This script extracts documentation from the xml2rfc format and converts
# it to POD suitable for MetaCPAN display.

use strict;
use warnings;
use XML::LibXML;

my $file = shift || 'clacks.xml';

my $dom = XML::LibXML->load_xml(location => $file);

# Extract document metadata
my ($title) = $dom->findnodes('//front/title');
my ($abstract) = $dom->findnodes('//front/abstract');
my ($author) = $dom->findnodes('//front/author');
my ($date) = $dom->findnodes('//front/date');

my $title_text = $title ? $title->textContent : 'CLACKS Protocol';
my $author_name = $author ? $author->getAttribute('fullname') : 'Unknown';
my $author_email = '';
if ($author) {
    my ($email) = $author->findnodes('.//email');
    $author_email = $email ? $email->textContent : '';
}
my $year = $date ? $date->getAttribute('year') : '2024';

# Start POD output
print "=encoding utf8\n\n";
print "=head1 NAME\n\n";
print "Net::Clacks::Protocol - $title_text\n\n";

print "=head1 DESCRIPTION\n\n";
if ($abstract) {
    for my $t ($abstract->findnodes('.//t')) {
        my $text = $t->textContent;
        $text =~ s/^\s+//;
        $text =~ s/\s+$//;
        $text =~ s/\s+/ /g;
        print "$text\n\n";
    }
}

# Process sections in middle
my @middle_sections = $dom->findnodes('//middle/section');

for my $section (@middle_sections) {
    process_section($section, 1);
}

print "=head1 REFERENCE IMPLEMENTATION\n\n";
print "An open source reference implementation in Perl called L<Net::Clacks> is available on MetaCPAN.\n\n";

print "=head1 DEDICATION\n\n";
print "The name of the protocol is a direct reference to the Discworld novel \"Going Postal\" by Terry Pratchett. ";
print "In this book, the author describes an interconnected optical telegraph system for passing messages at high speed. ";
print "The command OVERHEAD is named after \"passing names in the overhead\" in the story.\n\n";
print "I<\"Do you not know that a man is not dead while his name is still spoken?\">\n\n";
print "The book mentions that the names are passed with the flags \"GNU\" (send message to next tower, don't log, ";
print "turn around at the end). The clacks protocol offers compatibility with the description in the book:\n\n";
print "    OVERHEAD GNU Terry Pratchett\n\n";

print "=head1 AUTHOR\n\n";
print "$author_name";
print ", E<lt>${author_email}E<gt>" if $author_email;
print "\n\n";

print "=head1 COPYRIGHT AND LICENSE\n\n";
print "Copyright $year $author_name\n\n";
print "This documentation is part of the Net::Clacks distribution and is subject to the same license terms.\n\n";

print "=cut\n";

sub process_section {
    my ($section, $level) = @_;

    my ($name) = $section->findnodes('./name');
    return unless $name;

    my $name_text = $name->textContent;
    return unless $name_text && $name_text =~ /\S/;  # Skip empty names

    # Determine POD heading level
    my $head = $level == 1 ? '=head1' : ($level == 2 ? '=head2' : '=head3');

    # Convert to uppercase for head1
    if ($level == 1) {
        $name_text = uc($name_text);
    }

    print "$head $name_text\n\n";

    # Process text elements
    for my $t ($section->findnodes('./t')) {
        my $text = process_text_node($t);
        print "$text\n\n" if $text;
    }

    # Process lists
    for my $ul ($section->findnodes('./ul')) {
        print "=over 4\n\n";
        for my $li ($ul->findnodes('./li')) {
            my $text = process_text_node($li);
            print "=item *\n\n$text\n\n" if $text;
        }
        print "=back\n\n";
    }

    # Process source code blocks
    for my $code ($section->findnodes('./sourcecode')) {
        my $text = $code->textContent;
        $text =~ s/^\s*\n//;  # Remove leading blank lines
        $text =~ s/\n\s*$//;  # Remove trailing blank lines
        # Indent each line for POD verbatim
        $text =~ s/^/    /gm;
        print "$text\n\n";
    }

    # Process artwork (ASCII diagrams)
    for my $art ($section->findnodes('./artwork')) {
        my $text = $art->textContent;
        $text =~ s/^\s*\n//;
        $text =~ s/\n\s*$//;
        $text =~ s/^/    /gm;
        print "$text\n\n";
    }

    # Recursively process subsections
    for my $subsection ($section->findnodes('./section')) {
        process_section($subsection, $level + 1);
    }
}

sub process_text_node {
    my ($node) = @_;

    my $text = '';

    for my $child ($node->childNodes) {
        if ($child->nodeType == XML_TEXT_NODE) {
            $text .= $child->textContent;
        } elsif ($child->nodeType == XML_ELEMENT_NODE) {
            my $name = $child->nodeName;
            if ($name eq 'bcp14') {
                # RFC requirement keywords - make bold
                $text .= 'B<' . $child->textContent . '>';
            } elsif ($name eq 'xref') {
                # Cross-reference - try to make a link
                my $target = $child->getAttribute('target') || '';
                my $content = $child->textContent || $target;
                if ($target eq 'NetClacks') {
                    $text .= "L<$content|Net::Clacks>";
                } elsif ($target =~ /^RFC/) {
                    $text .= "L<$content|https://www.rfc-editor.org/info/\L$target\E>";
                } else {
                    $text .= $content;
                }
            } elsif ($name eq 'strong') {
                $text .= 'B<' . $child->textContent . '>';
            } elsif ($name eq 'em') {
                $text .= 'I<' . $child->textContent . '>';
            } else {
                $text .= $child->textContent;
            }
        }
    }

    # Clean up whitespace
    $text =~ s/^\s+//;
    $text =~ s/\s+$//;
    $text =~ s/\s+/ /g;

    return $text;
}
