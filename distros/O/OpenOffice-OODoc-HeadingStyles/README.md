# NAME

OpenOffice::OODoc::HeadingStyles - utilities for manipulating OpenOffice::OODoc objects

# SYNOPSIS

    my $level = 2;
    my $style_definition = {
        paragraph   => { top    => '0.1390in', bottom => '0.0835in' },
        text        => { size   =>     '115%', weight =>     'bold' },
    };
    my $heading_style = $oodoc_style
        ->establishHeadingStyle( $level, $style_definition );

# DESCRIPTION

This module helps to create Heading Styles in `OpenOfice::OODoc` documents.
Instead of blindly creating new styles at will, one can call
`establishHeadingStyle` that will honour any exisiting style, but will create
a new one if needed.

# LICENCE

This software is distributed, subject to the EUPL. You may not use this file
except in compliance with the License. You may obtain a copy of the License at
[europa.eu EUPL](http://joinup.ec.europa.eu/software/page/eupl)

Software distributed under the License is distributed on an "AS IS" basis,
WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for the
specific language governing rights and limitations under the License.
