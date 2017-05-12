package Pandoc::Filter;
use strict;
use warnings;
use 5.010;

our $VERSION = '0.27';

use JSON;
use Carp;
use Scalar::Util 'reftype';
use List::Util;
use Pandoc::Walker;
use Pandoc::Elements qw(Image Str);

use parent 'Exporter';
our @EXPORT = qw(pandoc_filter pandoc_filter_document pandoc_walk stringify);

# FUNCTIONS

sub stringify {

    # warning added in version 0.18 (04/2016)
    warn "Pandoc::Filter::stringify deprecated => Pandoc::Element::stringify\n";
    $_[0]->string;
}

# TODO: deprecate this function
sub pandoc_walk(@) {    ## no critic
    my $filter = Pandoc::Filter->new(@_);
    my $ast    = Pandoc::Elements::pandoc_json(<STDIN>);
    binmode STDOUT, ':encoding(UTF-8)';
    $filter->apply( $ast->content, @ARGV ? $ARGV[0] : '', $ast->meta );
    return $ast;
}

sub _pod2usage_if_help {
    require Getopt::Long;
    require Pandoc::Filter::Usage;
    my %opt;
    Getopt::Long::GetOptions(\%opt, 'help|?');
    Pandoc::Filter::Usage::pod2usage() if $opt{help};
}

sub pandoc_filter(@) {    ## no critic
    _pod2usage_if_help();
    
    my $ast = pandoc_walk(@_);    # implies binmode STDOUT UTF-8
    my $json = JSON->new->allow_blessed->convert_blessed->encode($ast);

    #my $json = $ast->to_json;  # does not want binmode STDOUT UTF-8
    say STDOUT $json;
}

sub pandoc_filter_document($) {    ## no critic
    _pod2usage_if_help();

    my $filter = shift;
    my $doc = Pandoc::Elements::pandoc_json(<STDIN>);
    $filter->apply( $doc, $ARGV[0] );

    say $doc->to_json;
}

# METHODS

sub new {
    my $class = shift;
    my $action = (@_ < 2 or @_ % 2 or ref $_[0])
        ? Pandoc::Walker::action(@_)        # @actions
        : Pandoc::Walker::action({ @_ });   # %actions
    bless {
        action => $action,
        error  => '',
    }, $class;
}

sub action {
    $_[0]->{action};
}

sub apply {
    my ( $self, $ast, $format, $meta ) = @_;
    $format ||= '';
    $meta ||= eval { $ast->meta } || {};

    Pandoc::Walker::transform( $ast, $self->action, $format, $meta );

    $ast;
}

1;
__END__

=encoding utf-8

=head1 NAME

Pandoc::Filter - process Pandoc abstract syntax tree 

=head1 SYNOPSIS

Filter C<flatten.pl>, adopted from L<pandoc scripting
documentation|http://pandoc.org/scripting.html>, converts level 2+ headers to
regular paragraphs:

    use Pandoc::Filter;
    use Pandoc::Elements;

    pandoc_filter Header => sub {
        return unless $_->level >= 2;       # keep
        return Para [ Emph $_->content ];   # replace
    };

Apply this filter on a Markdown file like this:

    pandoc --filter flatten.pl -t markdown < input.md

See L<https://metacpan.org/pod/distribution/Pandoc-Elements/examples/> for more 
examples of filters.

=head1 DESCRIPTION

Pandoc::Filter provides tools to modify the abstract syntax tree (AST) of
L<Pandoc|http://pandoc.org/> documents. See L<Pandoc::Elements> for AST
elements that can be modified by filters.

The function interface (see L</FUNCTIONS>) directly reads AST and format from
STDIN and ARGV and prints the transformed AST to STDOUT. 

The object oriented interface (see L</METHODS>) requires to:

    my $filter = Pandoc::Filter->new( ... );  # create a filter object
    $filter->apply( $ast, $format );          # pass it an AST for processing

If you don't need the C<format> parameter, consider using the interface
provided by module L<Pandoc::Walker> instead. It can be used both:

    transform $ast, ...;        # as function
    $ast->transform( ... );     # or as method

=head1 ACTIONS

An action is a code reference that is executed on matching document elements of
an AST. The action is passed a reference to the current element, the output
format (the empty string by default), and the document metadata (an empty hash
by default).  The current element is also given in the special variable C<$_>
for convenience.

The action is expected to return an element, an empty array reference, or
C<undef> to modify, remove, or keep a traversed element in the AST. 

=head1 METHODS

=head2 new( @actions | %actions )

Create a new filter object with one or more actions (see L</ACTIONS>). If
actions are given as hash, key values are used to check which elements to apply
for, e.g. 

    Pandoc::Filter->new( 
        Header                 => sub { ... }, 
        'Suscript|Superscript' => sub { ... }
    )

=head2 apply( $ast [, $format [, $metadata ] ] )

Apply all actions to a given abstract syntax tree (AST). The AST is modified in
place and also returned for convenience. Additional argument format and
metadata are also passed to the action function. Metadata is taken from the
Document by default (if the AST is a Document root).

=head2 action

Return a code reference to call all actions.

=head1 FUNCTIONS

The following functions are exported by default.

=head2 pandoc_filter( @actions | %actions )

Read a single line of JSON from STDIN, apply actions on the document content
and print the resulting AST as single line of JSON. L<Pandoc::Filter::Usage>
is used to print filter documentation if called with command line argument
C<--help>, C<-h>, or C<-?>.

=head1 FILTER MODULES

=over

=item L<Pandoc::Filter::HeaderIdentifiers>

=item L<Pandoc::Filter::Multifilter>

=item L<Pandoc::Filter::ImagesFromCode>

=back

=head1 SEE ALSO

This module is a port of L<pandocfilters|https://github.com/jgm/pandocfilters>
from Python to modern Perl.  

=head1 COPYRIGHT AND LICENSE

Copyright 2014- Jakob Voß

GNU General Public License, Version 2

This module is heavily based on Pandoc by John MacFarlane.

=cut
