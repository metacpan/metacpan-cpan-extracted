package Pod::Cookbook;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-14'; # DATE
our $DIST = 'Pod-Cookbook'; # DIST
our $VERSION = '0.001'; # VERSION

1;
# ABSTRACT: Recipes for working with POD

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Cookbook - Recipes for working with POD

=head1 VERSION

This document describes version 0.001 of Pod::Cookbook (from Perl distribution Pod-Cookbook), released on 2020-04-14.

=head1 CONVERTING POD TO HTML

=head1 CONVERTING POD TO MARKDOWN

=head1 CONVERTING MARKDOWN TO POD

=head1 GETTING THE PATH OF A LOCALLY INSTALLED POD PAGE

=head1 LISTING LOCALLY INSTALLED POD PAGES

You can use L<podlist>. Examples:

List top-level POD namespaces:

 % podlist

List all POD pages:

 % podlist -R

=head1 MODIFYING POD ELEMENTS

To reverse the order of POD sections, you can use L<reverse-pod-headings>.

To sort POD sections by some criteria, you can use L<sort-pod-headings>.

=head1 SELECTING POD ELEMENTS

L<Pod::Elemental> is a system for treating a Pod (plain old documentation)
documents as trees of elements. L<podsel> uses Pod::Elemental to select the tree
nodes using a CSS-like expression (see L<Data::CSel>). Examples below.

Note that L<pmpath> is a CLI utility to return the path of a locally installed
Perl module (or POD).

To list all head1 commands of the L<strict>.pm documentation:

 % podsel `pmpath strict` 'Command[command=head1]'
 =head1 NAME

 =head1 SYNOPSIS

 =head1 DESCRIPTION

 =head1 HISTORY

To list all head1 commands that contain "SYN" in them:

 % podsel `pmpath strict` 'Command[command=head1][content =~ /synopsis/i]'
 =head1 SYNOPSIS

To show the contents of strict.pm's Synopsis:

 % podsel -5 `pmpath strict` 'Nested[command=head1][content =~ /synopsis/i]'
 =head1 SYNOPSIS

     use strict;

     use strict "vars";
     use strict "refs";
     use strict "subs";

     use strict;
     no strict "vars";

To show the contents of strict.pm's Synopsis without the head1 command itself:

 % podsel -5 `pmpath strict` 'Nested[command=head1][content =~ /synopsis/i] > *'
     use strict;

     use strict "vars";
     use strict "refs";
     use strict "subs";

     use strict;
     no strict "vars";

To list of head commands in POD of L<List::Util>:

    % podsel `pmpath List::Util` 'Command[command =~ /head/]'
    =head1 NAME

    =head1 SYNOPSIS

    =head1 DESCRIPTION

    =head1 LIST-REDUCTION FUNCTIONS

    =head2 reduce

    =head2 reductions

    ...

    =head1 KEY/VALUE PAIR LIST FUNCTIONS

    =head2 pairs

    =head2 unpairs

    =head2 pairkeys

    =head2 pairvalues

    ...

To list only key/value pair list functions and not list-reduction ones in
L<List::Util>:

    % podsel -5 `pmpath List::Util` 'Nested[command=head1][content =~ /pair/i] Nested[command=head2]' --print-method content
    pairs
    unpairs
    pairkeys
    pairvalues
    pairgrep
    pairfirst
    pairmap

=head1 VIEWING POD IN THE TERMINAL

=head1 VIEWING POD IN THE WEB BROWSER

Converting the POD to HTML would be the first step. See L</CONVERTING POD TO
HTML>.

L<podtohtml> has a C<--browser> (C<-b>) option to open web browser and display
the generated HTML:

 % podtohtml some.pod -b

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Cookbook>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Cookbook>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Cookbook>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
