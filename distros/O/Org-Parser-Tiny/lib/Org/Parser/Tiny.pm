## no critic: Modules::RequireExplicitPackage

use 5.010001;
use strict;
use warnings;

package Org::Parser::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-07'; # DATE
our $DIST = 'Org-Parser-Tiny'; # DIST
our $VERSION = '0.005'; # VERSION

sub new {
    my $class = shift;
    bless {}, $class;
}

sub _parse {
    my ($self, $lines, $opts) = @_;

    # stage 1: get todo keywords

    my @undone_keywords;
    my @done_keywords;
    my $linenum = 0;
    while ($linenum < @$lines) {
        my $line = $lines->[$linenum];
        $linenum++;
        if ($line =~ s/^#\+TODO:\s*//) {
            my ($undone_keywords, $done_keywords) =
                $line =~ /^\s*(.*?)\s*\|\s*(.*?)\s*$/
                or die "Line $linenum: Invalid #+TODO: please use ... | ...";
            while ($undone_keywords =~ /(\w+)/g) {
                push @undone_keywords, $1;
            }
            while ($done_keywords =~ /(\w+)/g) {
                push @done_keywords, $1;
            }
        }
    }
    @undone_keywords = ("TODO") unless @undone_keywords;
    @done_keywords   = ("DONE") unless @done_keywords;
    my $undone_re = join("|", @undone_keywords); $undone_re= qr/(?:$undone_re)/;
    my $done_re   = join("|", @done_keywords  ); $done_re  = qr/(?:$done_re)/;

    # stage 2: build nodes

    # a linear list of nodes
    my @nodes = (
        Org::Parser::Tiny::Node::Document->new(),
    );

    $linenum = 0;
    while ($linenum < @$lines) {
        my $line = $lines->[$linenum];
        $linenum++;
        if ($line =~ /^(\*+) (.*)/) {
            #say "D: got headline $line";
            my $level = length($1);
            my $title = $2;
            my $node = Org::Parser::Tiny::Node::Headline->new(
                _str  => $line,
                level => $level,
            );

            # extract todo state
            if ($title =~ s/\s*($undone_re)\s+//) {
                $node->{is_todo} = 1;
                $node->{is_done} = 0;
                $node->{todo_state} = $1;
            } elsif ($title =~ s/\s*($done_re)\s+//) {
                $node->{is_todo} = 1;
                $node->{is_done} = 1;
                $node->{todo_state} = $1;
            } else {
                $node->{is_todo} = 0;
                $node->{is_done} = 0;
                $node->{todo_state} = "";
            }

            # extract tags
            if ($title =~ s/\s+:((?:\w+:)+)$//) {
                my $tags = $1;
                my @tags;
                while ($tags =~ /(\w+)/g) {
                    push @tags, $1;
                }
                $node->{tags} = \@tags;
            }

            $node->{title} = $title;

            # find the first node which has the lower level (or the root node)
            # as the parent node
            my $i = $#nodes;
            while ($i >= 0) {
                if ($i == 0 || $nodes[$i]{level} < $level) {
                    $node->{parent} = $nodes[$i];
                    push @{ $nodes[$i]{children} }, $node;
                    last;
                }
                $i--;
            }
            push @nodes, $node;
        } else {
            $nodes[-1]{preamble} .= $line;
        }
    }

    $nodes[0];
}

sub parse {
    my ($self, $arg, $opts) = @_;
    die "Please specify a defined argument to parse()\n" unless defined($arg);

    $opts ||= {};

    my $lines;
    my $r = ref($arg);
    if (!$r) {
        $lines = [split /^/, $arg];
    } elsif ($r eq 'ARRAY') {
        $lines = [@$arg];
    } elsif ($r eq 'GLOB' || blessed($arg) && $arg->isa('IO::Handle')) {
        #$lines = split(/^/, join("", <$arg>));
        $lines = [<$arg>];
    } elsif ($r eq 'CODE') {
        my @chunks;
        while (defined(my $chunk = $arg->())) {
            push @chunks, $chunk;
        }
        $lines = [split /^/, (join "", @chunks)];
    } else {
        die "Invalid argument, please supply a ".
            "string|arrayref|coderef|filehandle\n";
    }
    $self->_parse($lines, $opts);
}

sub parse_file {
    my ($self, $filename, $opts) = @_;
    $opts ||= {};

    my $content = do {
        open my($fh), "<", $filename or die "Can't open $filename: $!\n";
        local $/;
        scalar(<$fh>);
    };

    $self->parse($content, $opts);
}


# abstract class: Org::Parser::Tiny::Node
package Org::Parser::Tiny::Node;

sub new {
    my ($class, %args) = @_;
    $args{children} //= [];
    bless \%args, $class;
}

sub parent {
    if (@_ > 1) {
        $_[0]{parent} = $_[1];
    }
    $_[0]{parent};
}

sub children {
    if (@_ > 1) {
        $_[0]{children} = $_[1];
    }
    $_[0]{children} || [];
}

sub as_string { $_[0]{_str} }

sub children_as_string { join("", map { $_->as_string } @{ $_[0]->children }) }

# abstract class: Org::Parser::Tiny::HasPreamble
package Org::Parser::Tiny::Node::HasPreamble;

our @ISA = qw(Org::Parser::Tiny::Node);

sub new {
    my ($class, %args) = @_;
    $args{preamble} //= "";
    $class->SUPER::new(%args);
}


# class: Org::Parser::Tiny::Document: top level node
package Org::Parser::Tiny::Node::Document;

our @ISA = qw(Org::Parser::Tiny::Node::HasPreamble);

sub as_string {
    $_[0]->{preamble} . $_[0]->children_as_string;
}


# class: Org::Parser::Tiny::Node::Headline: headline with its content
package Org::Parser::Tiny::Node::Headline;

our @ISA = qw(Org::Parser::Tiny::Node::HasPreamble);

sub level {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{level} = $_[1] }
    $_[0]{level};
}

sub title {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{title} = $_[1] }
    $_[0]{title};
}

sub is_todo {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{is_todo} = $_[1] }
    $_[0]{is_todo};
}

sub is_done {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{is_done} = $_[1] }
    $_[0]{is_done};
}

sub todo_state {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{todo_state} = $_[1] }
    $_[0]{todo_state};
}

sub tags {
    if (@_ > 1) { undef $_[0]{_str}; $_[0]{tags} = $_[1] }
    $_[0]{tags} || [];
}

sub header_as_string {
    ($_[0]->{_str} //
         join('',
              "*" x $_[0]{level},
              " ",
              (length $_[0]{todo_state} ? "$_[0]{todo_state} " : ""),
              "$_[0]{title}",
              (defined $_[0]{tags} ? " :".join(":", @{ $_[0]{tags} }).":" : ""),
              "\n",
          ));
}

sub as_string {
    $_[0]->header_as_string .
        $_[0]->{preamble} .
        $_[0]->children_as_string;
}

1;
# ABSTRACT: Parse Org documents with as little code (and no non-core deps) as possible

__END__

=pod

=encoding UTF-8

=head1 NAME

Org::Parser::Tiny - Parse Org documents with as little code (and no non-core deps) as possible

=head1 VERSION

This document describes version 0.005 of Org::Parser::Tiny (from Perl distribution Org-Parser-Tiny), released on 2020-02-07.

=head1 SYNOPSIS

 use Org::Parser::Tiny;
 my $orgp = Org::Parser::Tiny->new();

 # parse a file
 my $doc = $orgp->parse_file("$ENV{HOME}/todo.org");

 # parse a string
 $doc = $orgp->parse(<<EOF);
 * this is a headline
 * this is another headline
 ** this is yet another headline
 EOF

Dump document structure using L<Tree::Dump>:

 use Tree::Dump;
 td($doc);

Select document nodes using L<Data::CSel>:

 use Data::CSel qw(csel);

 # select headlines with "foo" in their title
 my @nodes = csel(
     {class_prefixes => ["Org::Parser::Tiny::Node"]},
     "Headline[title =~ /foo/]"
 );

Manipulate tree nodes with path-like semantic using L<Tree::FSMethods::Org>:

Sample F<sample.org>:

 some text before the first headline.

 * header1                                                               :tag:
 contains an internal link to another part of the document [[blah]]
 * header2 [#A] [20%]
 - contains priority and progress cookie (percent-style)
 * header3 [1/10]
 - contains progress cookie (fraction-style)
 ** header3.1
 ** header3.2
 ** header3.3
 * header4
 blah blah.
 * blah

Using Tree::FSMethods::Org:

 use Tree::FSMethods::Org;
 my $fs = Tree::FSMethods::Org->new(
     org_file => "sample.org",
 );

 # list nodes right above the root node
 my %nodes = $fs->ls; # (header1=>{...}, header2=>{...}, header3=>{...}, header4=>{})

 # list nodes below header3
 $fs->cd("header3");
 %nodes = $fs->ls; # ("header3.1"=>{...}, "header3.2"=>{...}, "header3.3"=>{...})

 # die, path not found
 $fs->cd("/header5");

 # remove top-level headlines which have "3"
 $fs->rm("*3*");

=head1 DESCRIPTION

This module is a more lightweight alternative to L<Org:Parser>. Currently it is
very simple and only parses headlines; thus it is several times faster than
Org::Parser. I use this to write utilities like L<sort-org-headlines-tiny> or to
use it with L<Tree::FSMethods>.

=for Pod::Coverage ^(.+)$

=head1 NODE CLASSES

=head2 Org::Parser::Tiny::Node

Base class.

Methods:

=over

=item * parent

=item * children

=item * as_string

=back

=head2 Org::Parser::Tiny::Node::Document

Root node.

Methods:

=over

=back

=head2 Org::Parser::Tiny::Node::Headline

Root node.

Methods:

=over

=item * level

Integer.

=item * title

Str.

=item * is_todo

Whether headline has a done or undone todo state. For example, the following
headlines will have their is_todo() return true:

 * TODO foo
 * DONE bar

=item * is_done

Whether headline has a done todo state. For example, the following
headlines will have their is_done() return true:

 * DONE bar

=item * todo_state

Todo state or empty string. For example, this headline:

 * TODO foo

will have "TODO" as the todo_state, while:

 * foo

will have "".

=item * tags

Array of strings. For example, this headline:

 * foo    :tag1:tag2:

will have its C<tags()> return C<< ["tag1","tag2"] >>, while this headline:

 * foo

will have its C<tags()> return C<< [] >>.

=item * header_as_string

First line of headline (the header) as string, without the preamble and
children.

=back

=head1 ATTRIBUTES

=head1 METHODS

=head2 new

Usage:

 my $orgp = Org::Parser::Tiny->new;

Constructor. Create a new parser instance.

=head2 parse

Usage:

 my $doc = $orgp->parse($str | $arrayref | $coderef | $filehandle, \%opts);

Parse document (which can be contained in a $str, an array of lines $arrayref, a
$coderef which will be called for chunks until it returns undef, or a
$filehandle.

Returns a tree of node objects (of class C<Org::Parser::Tiny::Node> and its
subclasses C<Org::Parser::Tiny::Node::Document> and
C<Org::Parser::Tiny::Node::Headline>). The tree node complies to
L<Role::TinyCommons::Tree::Node> role, so these tools are available:
L<Data::CSel>, L<Tree::Dump>, L<Tree::FSMethods>, etc.

Will die if there are syntax errors in documents.

Known options:

=over

=back

=head2 parse_file

Usage:

 my $doc = $orgp->parse_file($filename, \%opts);

Just like L</parse>, but will load document from file instead.

Known options (aside from those known by parse()):

=over

=back

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Org-Parser-Tiny>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Org-Parser-Tiny>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Org-Parser-Tiny>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Org::Parser>, the more fully featured Org parser.

L<https://orgmode.org>.

L<Tree::FSMethods::Org> and L<Tree::FSMethods>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
