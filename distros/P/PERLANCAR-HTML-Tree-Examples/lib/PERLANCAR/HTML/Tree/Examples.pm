package PERLANCAR::HTML::Tree::Examples;

our $DATE = '2016-04-07'; # DATE
our $VERSION = '1.0.3'; # VERSION

use 5.010001;
use strict;
use warnings;

use HTML::Tree::Create::Callback::ChildrenPerLevel
    qw(create_html_tree_using_callback);

use Exporter::Rinci qw(import);

our %SPEC;

$SPEC{gen_sample_data} = {
    v => 1.1,
    summary => 'Generate sample HTML document',
    description => <<'_',

This routine can generate some sample HTML document with specified size (total
number of elements and nested level). It is used for testing and benchmarking
HTML::Parser or CSS selector like `Mojo::DOM`.

_
    args => {
        size => {
            summary => 'Which document to generate',
            schema => ['str*', in=>['tiny1', 'small1', 'medium1']],
            description => <<'_',

There are several predefined sizes to choose from. The sizes are roughly
equivalent to sample trees in `PERLANCAR::Tree::Examples`.

`tiny1` is a very tiny document, with only depth of 2 and a total of 3 elements,
including root node.

`small1` is a document of depth 4 and a total of 16 elements, including root
element.

`medium1` is a document of depth 7 and ~20k elements.

_
            req => 1,
            pos => 0,
            tags => ['data-parameter'],
        },
    },
    result => {
        schema => 'str*',
    },
    result_naked => 1,
};
sub gen_sample_data {
    my %args = @_;

    my $size = $args{size} or die "Please specify size";

    my $nums_per_level;
    my $elems_per_level;
    if ($size eq 'tiny1') {
        $nums_per_level = [2];
        $elems_per_level = ['body', 'h1'];
    } elsif ($size eq 'small1') {
        $nums_per_level = [3, 2, 8, 2];
        $elems_per_level = ['body', 'h1'..'h4'];
    } elsif ($size eq 'medium1') {
        $nums_per_level = [100, 3000, 5000, 8000, 3000, 1000, 300];
        $elems_per_level = ['body', 'h1'..'h7'];
    } else {
        die "Unknown size '$size'";
    }

    my $id = 0;
    create_html_tree_using_callback(
        sub {
            my ($level, $seniority) = @_;
            $id++;
            my $elem = $elems_per_level->[$level];
            return ($elem, {id=>$id, 'data-level' => $level}, '', '');
        },
        $nums_per_level,
    );
}

1;
# ABSTRACT: Generate sample HTML document

__END__

=pod

=encoding UTF-8

=head1 NAME

PERLANCAR::HTML::Tree::Examples - Generate sample HTML document

=head1 VERSION

This document describes version 1.0.3 of PERLANCAR::HTML::Tree::Examples (from Perl distribution PERLANCAR-HTML-Tree-Examples), released on 2016-04-07.

=head1 SYNOPSIS

 use PERLANCAR::HTML::Tree::Examples qw(gen_sample_data);

 my $html = gen_sample_data(size => 'medium1');

=head1 DESCRIPTION

=head2 Overview of available sample data

=over

=item * size=tiny1

 <body data-level="0" id="1">
   <h1 data-level="1" id="2">
   </h1>
   <h1 data-level="1" id="3">
   </h1>
 </body>

=item * size=small1

 <body data-level="0" id="1">
   <h1 data-level="1" id="2">
     <h2 data-level="2" id="3">
       <h3 data-level="3" id="4">
       </h3>
       <h3 data-level="3" id="5">
       </h3>
       <h3 data-level="3" id="6">
         <h4 data-level="4" id="7">
         </h4>
       </h3>
       <h3 data-level="3" id="8">
       </h3>
     </h2>
   </h1>
   <h1 data-level="1" id="9">
   </h1>
   <h1 data-level="1" id="10">
     <h2 data-level="2" id="11">
       <h3 data-level="3" id="12">
 (... 12 more line(s) not shown ...)

=item * size=medium1

 <body data-level="0" id="1">
   <h1 data-level="1" id="2">
     <h2 data-level="2" id="3">
       <h3 data-level="3" id="4">
         <h4 data-level="4" id="5">
         </h4>
         <h4 data-level="4" id="6">
           <h5 data-level="5" id="7">
           </h5>
         </h4>
       </h3>
       <h3 data-level="3" id="8">
         <h4 data-level="4" id="9">
         </h4>
       </h3>
     </h2>
     <h2 data-level="2" id="10">
       <h3 data-level="3" id="11">
         <h4 data-level="4" id="12">
           <h5 data-level="5" id="13">
 (... 40782 more line(s) not shown ...)

=back

=head1 FUNCTIONS


=head2 gen_sample_data(%args) -> str

Generate sample HTML document.

This routine can generate some sample HTML document with specified size (total
number of elements and nested level). It is used for testing and benchmarking
HTML::Parser or CSS selector like C<Mojo::DOM>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<size>* => I<str>

Which document to generate.

There are several predefined sizes to choose from. The sizes are roughly
equivalent to sample trees in C<PERLANCAR::Tree::Examples>.

C<tiny1> is a very tiny document, with only depth of 2 and a total of 3 elements,
including root node.

C<small1> is a document of depth 4 and a total of 16 elements, including root
element.

C<medium1> is a document of depth 7 and ~20k elements.

=back

Return value:  (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/PERLANCAR-HTML-Tree-Examples>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-PERLANCAR-HTML-Tree-Examples>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=PERLANCAR-HTML-Tree-Examples>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<show-perlancar-sample-html-tree> (L<App::ShowPERLANCARSampleHTMLTree>), a
simple CLI to conveniently view the sample data.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
