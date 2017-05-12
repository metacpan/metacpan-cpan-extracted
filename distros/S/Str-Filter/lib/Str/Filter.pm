package Str::Filter;

use strict;
use warnings;

our $VERSION = '0.01';

use base qw(Exporter);

use HTML::Strip;

our (@EXPORT_OK, %EXPORT_TAGS);

@EXPORT_OK = qw(
    filter_leading_whitespace
    filter_trailing_whitespace
    filter_collapse_whitespace
    filter_control_characters
    filter_ascii_only
    filter_escape_pipes
    filter_end_brackets
    filter_html
    filter_style_tags
); # on demand

%EXPORT_TAGS = (
    ALL => [ @EXPORT_OK ],
);

my $stripper = HTML::Strip->new();

#-------------------------------------------------------------------------------
sub filter_leading_whitespace {
    return unless $_[0];
    $_[0] =~ s/\A\s+//msx;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_trailing_whitespace {
    return unless $_[0];
    $_[0] =~ s/\s+\Z//msx;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_collapse_whitespace {
    return unless $_[0];
    $_[0] =~ s/\s+/ /msxg;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_control_characters {
    return unless $_[0];
    $_[0] =~ s/[[:cntrl:]]//msxg;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_ascii_only {
    return unless $_[0];
    # substitute non-ascii characters with nuthin
    $_[0] =~ s/[^[:ascii:]]//msxg;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_escape_pipes {
    return unless $_[0];
    ## no critic qw(ProhibitEscapedMetacharacters)
    $_[0] =~ s{\|}{\\|}msxg;
    ## use critic
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_end_brackets {
    return unless $_[0];
    $_[0] =~ s/\]\]//msxg;
    return 1;
}

#-------------------------------------------------------------------------------
sub filter_html {
    return unless $_[0];
    $_[0] = $stripper->parse($_[0]);
    $stripper->eof();
    return 1;
}

#-------------------------------------------------------------------------------
# this is not full|fool proof. The match between the tags could fail
sub filter_style_tags {
    return unless $_[0];
    ## no critic qw(ProhibitUnusualDelimiters)
    $_[0] =~ s!<\s*(style)("[^"]*"|'[^']*'|[^'">])*>[^<]+</\s*\1\s*>!!msxig;
    ## use critic
    return 1;
}

1;

__END__

=pod

=head1 NAME

Str::Filter - Garbage in, goodness out

=head1 VERSION

This documentation refers to Str::Filter version 0.01.

=head1 SYNOPSIS

    use Str::Filter qw(:ALL);

    sub filtration {
        filter_leading_whitespace( $_[0] );
        filter_trailing_whitespace( $_[0] );
        filter_collapse_whitespace( $_[0] );
    }

    filtration($input);

    # cleansed, no more whitespace
    print "input\n";

=head1 DESCRIPTION

Str::Filter is a collection of common routines for processing mainly input data but also works to filter outbound data. These filters are intended to be called in high volume environments so, there is not a lot of handing data back and forth. These subs work on the actual value passed so, beware, your data WILL be transformed.

=head1 SUBROUTINES/METHODS

=over

=item filter_leading_whitespace()

Removes leading whitespace.

=item filter_trailing_whitespace()

Removes trailing whitespace.

=item filter_collapse_whitespace()

Collapses multiple contiguous whitespace to one.

=item filter_control_characters()

Removes nasty control characters.

=item filter_ascii_only()

Ensures you only have ascii characters in your string.

=item filter_escape_pipes()

Escape pipes, to preserve pipe delimted strings in certain parsing situations.

=item filter_end_brackets()

This is useful in XML environments where you want to output data in an XML CDATA container. In order for that to work, you must filter out ]] from the data or the XML processor won't know where your CDATA ends.

=item filter_html()

Strips ALL HTML from the input.

Filters style tags.

=item filter_style_tags()

Filters ALL style tags from text.

=back

=head1 EXAMPLES

Combine a bunch of filters into one operation.

    sub filtrate {
        filter_leading_whitespace($_[0]);
        filter_trailing_whitespace($_[0]);
        filter_collapse_whitespace($_[0]);
        filter_control_characters($_[0]);
        filter_ascii_only($_[0]);
        filter_end_brackets($_[0]);
    }

    # and then...

    filtrate($my_data);

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

Str::Filter requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item * HTML::Strip

=item * Exporter

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any issues or feature requests to L<https://github.com/tscornpropst/Str-Filter/issues>. Patches are welcome.

=head1 AUTHOR

Trevor S. Cornpropst <tscornpropst@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005 - 2014, Trevor Cornpropst <tscornpropst@gmail.com>. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

