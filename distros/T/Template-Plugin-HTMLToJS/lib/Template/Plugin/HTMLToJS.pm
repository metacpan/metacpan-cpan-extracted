#
# This file is part of Template-Plugin-HTMLToJS
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Template::Plugin::HTMLToJS;

# ABSTRACT: Convert HTML To JS

use strict;
use warnings;

our $VERSION = '0.5';    # VERSION

use parent 'Template::Plugin::Filter';

sub filter {
    my ( $self, $text ) = @_;
    $text =~ s/\n/ /gx;
    $text =~ s/'/'+"'"+'/gx;
    $text =~ s/\//'+"\/"+'/gx;
    $text =~ s/<(\/|)\bscript\b/<$1scr'+'ipt/gx;
    return 'document.write(\'' . $text . '\');';
}

1;

__END__

=pod

=head1 NAME

Template::Plugin::HTMLToJS - Convert HTML To JS

=head1 VERSION

version 0.5

=head1 SYNOPSIS

    my $tt = Template->new;
    $tt->process('htmltojs-template.tt');

    # htmltojs-template.tt
    [% USE HTMLToJS %]
    [% FILTER $HTMLToJS %]
    <a href="http://www.test.com">Test</a>
    <script src="/test.js"></script>
    [% END %]

    #Will produce
    document.write('<a href="http://www.test.com">Test</a>\n    <scr'+'ipt> src="/test.js"></scr'+'ipt>');

    #could be use easily with on distant site
    <script src="http://www.test.com/yourhtmltojstemplate"></script>

=head1 DESCRIPTION

I have made this module to give an easy way to send html formated content to a javascript call.

For ex: you have a distant web site, and you want to display a top10 with all information,

on distant : <script src="http://yousite.com/top10"></script>

on yoursite : top10.tt :

    [% USE HTMLToJS %]
    [%FILTER $HTMLToJS %]
    <ul>
    <li><b>Rank 1 :</b> Test1</li>
    <li>...</li>
    </ul>
    [%END%]

This will convert it in a proper document.write form will al escape you need.

=head1 METHODS

=head2 filter

Convert html into javascript

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/Template-Plugin-HTMLToJS/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
