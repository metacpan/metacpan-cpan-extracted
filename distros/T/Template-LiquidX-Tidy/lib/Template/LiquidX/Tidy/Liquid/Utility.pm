package Template::LiquidX::Tidy::Liquid::Utility;
use strict;
use warnings;
use Template::Liquid::Utility;

our $VERSION = '1.0.10';
$Template::Liquid::Utility::FilterSeparator = qr[\s*\|\s*]o;
my $ArgumentSeparator = qr[,]o;
$Template::Liquid::Utility::FilterArgumentSeparator    = qr[\s*:\s*]o;
$Template::Liquid::Utility::VariableAttributeSeparator = qr[\.]o;
$Template::Liquid::Utility::TagStart                   = qr[{%-?\s*]o;
$Template::Liquid::Utility::TagEnd                     = qr[\s*-?%}]o;
$Template::Liquid::Utility::VariableSignature          = qr{\(?[\w\-\.\[\]]\)?}o;
my $VariableSegment = qr[[\w\-]\??]ox;
$Template::Liquid::Utility::VariableStart = qr[\{\{\s*]o;
$Template::Liquid::Utility::VariableEnd   = qr[\s*}}]o;
my $VariableIncompleteEnd = qr[}}?];
my $QuotedString          = qr/"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/o;
my $QuotedFragment = qr/${QuotedString}|(?:[^\s,\|'"]|${QuotedString})+/o;
my $StrictQuotedFragment = qr/"[^"]+"|'[^']+'|[^\s,\|,\:,\,]+/o;
my $FirstFilterArgument
    = qr/${Template::Liquid::Utility::FilterArgumentSeparator}(?:${StrictQuotedFragment})/o;
my $OtherFilterArgument
    = qr/${ArgumentSeparator}(?:${StrictQuotedFragment})/o;
my $SpacelessFilter
    = qr/${Template::Liquid::Utility::FilterSeparator}(?:${StrictQuotedFragment})(?:${FirstFilterArgument}(?:${OtherFilterArgument})*)?/o;
$Template::Liquid::Utility::Expression    = qr/(?:${QuotedFragment}(?:${SpacelessFilter})*)/o;
$Template::Liquid::Utility::TagAttributes = qr[(\w+)(?:\s*\:\s*(${QuotedFragment}))?]o;
my $AnyStartingTag = qr[\{\{|\{\%]o;
my $PartialTemplateParser
    = qr[${Template::Liquid::Utility::TagStart}.*?${Template::Liquid::Utility::TagEnd}|${Template::Liquid::Utility::VariableStart}.*?${VariableIncompleteEnd}]so;
my $TemplateParser = qr[(${PartialTemplateParser}|${AnyStartingTag})]o;
$Template::Liquid::Utility::VariableParser = qr[^
                            ${Template::Liquid::Utility::VariableStart}                        # {{
                                ([\w\.]+)    #   name
                                (?:\s*\|\s*(.+)\s*)?                 #   filters
                            ${Template::Liquid::Utility::VariableEnd}                          # }}
                            $]ox;
$Template::Liquid::Utility::VariableFilterArgumentParser
    = qr[\s*,\s*(?=(?:[^\']*\'[^\']*\')*(?![^\']*\'))]o;
$Template::Liquid::Utility::TagMatch = qr[^${Template::Liquid::Utility::TagStart}   # {%
                                (.+?)                              # etc
                              ${Template::Liquid::Utility::TagEnd} # %}
                             $]sox;
$Template::Liquid::Utility::VarMatch = qr[^
                    ${Template::Liquid::Utility::VariableStart} # {{
                        (.+?)                           #  stuff + filters?
                    ${Template::Liquid::Utility::VariableEnd}   # }}
                $]sox;
no warnings 'redefine';
sub Template::Liquid::Utility::tokenize {
    map { $_ ? $_ : () } split $TemplateParser, shift || '';
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Utility - Utility stuff. Watch your step.

=head1 Description

It's best to just forget this package exists. It's messy but seems to work.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Create your own filters">'s docs on
custom filter creation

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

The original Liquid template system was developed by jadedPixel
(http://jadedpixel.com/) and Tobias Lütke (http://blog.leetsoft.com/).

=head1 License and Legal

Copyright (C) 2009-2012 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
