package Perl::LineNumber::Comment;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-28'; # DATE
our $DIST = 'Perl-LineNumber-Comment'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use warnings;
use strict;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Add line number to Perl source as comment',
};

sub _line_has {
    my ($line, $children, $sub) = @_;
    for my $child (@$children) {
        my $location = $child->location;
        next unless $location->[0] == $line;
        next unless $sub->($child);
        return 1;
    }
    0;
}

sub _line_has_class {
    my ($line, $children, $class) = @_;
    _line_has($line, $children, sub { ref($_[0]) eq $class });
}

sub _line_has_END {
    my ($line, $children) = @_;
    _line_has($line, $children, sub { ref($_[0]) eq 'PPI::Token::Separator' && $_[0]->content eq '__END__' });
}

sub _process_children {
    my ($level, $args, $node) = @_;
    return unless $node->can("children");

    my $every     = $args->{every};
    my $linum_col = $args->{column};
    my $fmt       = $args->{format};

    my @children = $node->children;
    my $i = 0;
    while ($i < @children) {
        my $child = $children[$i];

        my $location = $child->location;
        my ($line, undef, $col) = @$location;
        {
            my $class = ref($child);
            my $content = $child->content;
            #use DD; dd (("  " x $level) . "D: [$location->[0], $location->[1], $location->[2]] $i $class <$content>");

            # only insert comment after $EVERY line
            last unless $line % $every == 0;

            # insert after newline
            last unless $class eq 'PPI::Token::Whitespace' && $content =~ /\A\R\z/;

            # BUG HereDoc doesn't print content?

            # don't insert at __END__ line
            last if _line_has_END($line, \@children);

            # don't insert width excess $COLUMN setting
            my $col_after_child = $col + length($content); # XXX use visual width
            next if $col_after_child >= $linum_col;

            # don't insert after a comment
            next if $i && ref($children[$i-1]) eq 'PPI::Token::Comment' && $children[$i-1]->content !~ /\R/;

            #say "  <-- insert ($col_after_child)";

            # we want to vertically align line number comment; but PPI reports
            # column that are not reset after \n, so that's useless.

            #my $el_ws = bless {
            #    _location => [$line, $col_after_child, $col_after_child, $location->[3], undef],
            #    content => (" " x ($linum_col - $col_after_child)),
            #}, 'PPI::Token::Whitespace';
            my $el_comment = bless {
                _location => [$line, $linum_col, $linum_col, $location->[3], undef],
                content => sprintf($fmt, $line) . "\n",
            }, 'PPI::Token::Comment';

            #splice @{ $node->{children} }, $i, 1, $el_ws, $el_comment;
            #$i += 1;
            splice @{ $node->{children} }, $i, 1, $el_comment;
        }

        _process_children($level+1, $args, $child);
        $i++;
    }
}

$SPEC{add_line_number_comments_to_perl_source} = {
    v => 1.1,
    args => {
        source => {
            schema => 'str*',
            cmdline_src => 'stdin_or_file',
            req => 1,
            pos => 0,
        },
        format => {
            schema => 'str*',
            default => ' # line %d',
        },
        column => {
            schema => 'posint*',
            description => 'Currently not implemented',
            default => 80,
        },
        every => {
            schema => 'posint*',
            default => 5,
        },
    },
    result_naked => 1,
};
sub add_line_number_comments_to_perl_source {
    my %args = @_;
    $args{every}  //= 5;
    $args{column} //= 80;
    $args{format} //= ' # line %d';

    require PPI::Document;
    my $doc = PPI::Document->new(\$args{source});

    # $doc->find stops after some nodes?
    _process_children(0, \%args, $doc);

    #require PPI::Dumper; PPI::Dumper->new($doc)->print;
    "$doc";
}

1;
# ABSTRACT: Add line number to Perl source as comment

__END__

=pod

=encoding UTF-8

=head1 NAME

Perl::LineNumber::Comment - Add line number to Perl source as comment

=head1 VERSION

This document describes version 0.002 of Perl::LineNumber::Comment (from Perl distribution Perl-LineNumber-Comment), released on 2020-11-28.

=head1 SYNOPSIS

In your code:

 use File::Slurper qw(read_text);
 use Perl::LineNumber::Comment qw(add_line_number_comments_to_perl_source);

 my $source = read_text('sample.pl');
 print add_line_number_comments_to_perl_source(source => $source);

Content of F<sample.pl>:

 #!/usr/bin/env perl

 use 5.010001;
 use strict;
 use warnings;

 print "Hello, world 1!";
 print "Hello, world 2!";                   # a comment
 print "A multiline
 string";

 print <<EOF;
 A heredoc (not shown in node->content).

 Line three.
 EOF

 exit 0;

 __END__
 one
 two
 three

Output of code:

 #!/usr/bin/env perl

 use 5.010001;
 use strict;
 use warnings; # line 5

 print "Hello, world 1!";
 print "Hello, world 2!";                   # a comment
 print "A multiline
 string"; # line 10

 print <<EOF;

 exit 0;

 __END__
 one
 two
 three

=for Pod::Coverage ^(.+)$

=head1 FUNCTIONS


=head2 add_line_number_comments_to_perl_source

Usage:

 add_line_number_comments_to_perl_source(%args) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<column> => I<posint> (default: 80)

Currently not implemented

=item * B<every> => I<posint> (default: 5)

=item * B<format> => I<str> (default: " # line %d")

=item * B<source>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perl-LineNumber-Comment>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perl-LineNumber-Comment>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perl-LineNumber-Comment>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
