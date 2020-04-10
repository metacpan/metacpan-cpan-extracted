package Perl::Tidy::Sweetened::Keyword::Block;

# ABSTRACT: Perl::Tidy::Sweetened filter plugin to define new subroutine and class keywords

use 5.010;    # Needed for balanced parens matching with qr/(?-1)/
use strict;
use warnings;
use Carp;
$|++;

our $VERSION = '1.16';

# Regex to match balanced params. Reproduced from Regexp::Common to avoid
# adding a non-core dependency.
#   $RE{balanced}{-parens=>'()'};
# The (?-1) construct requires 5.010
our $Paren = '(?:((?:\((?:(?>[^\(\)]+)|(?-1))*\))))';

sub new {
    my ( $class, %args ) = @_;
    croak 'keyword not specified'     if not exists $args{keyword};
    croak 'marker not specified'      if not exists $args{marker};
    croak 'replacement not specified' if not exists $args{replacement};
    $args{clauses} = [] unless exists $args{clauses};
    return bless {%args}, $class;
}

sub keyword     { return $_[0]->{keyword} }
sub marker      { return $_[0]->{marker} }
sub replacement { return $_[0]->{replacement} }

sub emit_placeholder {
    my ( $self, $subname, $brace, $clauses ) = @_;

    # Store the signature and returns() for later use
    my $id = $self->{counter}++;
    $self->{store_clause}->{$id} = $clauses;
    $self->{store_sub}->{$id}    = $subname;

    # Turns 'my_method_name' into 'SUB4ethod_name'
    my $marker = $self->marker . $id;
    substr( $subname, 0, length($marker), $marker );

    return sprintf '%s %s %s', $self->replacement, $marker, $brace;
}

sub emit_keyword {
    my ( $self, $brace, $id ) = @_;

    # Get the signature and returns() from store
    my $clauses = $self->{store_clause}->{$id};

    my $subname = $self->{store_sub}->{$id};

    # Combine clauses (parameter list, returns(), etc) into a string separate
    # each with a space and lead with a space if there are any
    my $clause = join ' ', grep { length $_ } @$clauses;
    $clause = ' ' . $clause if length $clause;

    return sprintf '%s %s%s%s', $self->keyword, $subname, $clause, $brace;
}

sub emit_csc {
    my ( $self, $id ) = @_;
    return sprintf "## tidy end: %s %s", $self->keyword, $self->{store_sub}->{$_};
}

sub clauses {
    my $self = shift;

    # Create a regex (as a string) for all the clauses (ie, parameter list,
    # returns(), etc).
    my $clause_re = '';
    my $i         = 0;
    for my $clause ( @{ $self->{clauses} } ) {
        $clause =~ s{PAREN}{$Paren}g;

        $clause_re .= "(?<clause_$i>  $clause ) \\s* \n";
        $i++;
    }

    return $clause_re;
}

sub identifier {    # method or package identifier
    my $self = shift;

    return '\w+ (?: ::\w+ )*';    # words, possibly separated by ::
}

sub prefilter {
    my ( $self, $code ) = @_;
    my $keyword = $self->keyword;
    my $subname = $self->identifier;

    $code =~ s{
        ^\s*\K                    # okay to have leading whitespace (preserve)
        $keyword             \s+  # the "func/method" keyword
        (?<subname> $subname)     # the function name or class name (needs ::)
        (?!\w|\s*=>) \s*          # check to make sure this isn't a sub call with params
        @{[ $self->clauses ]}     # any clauses defined (ie, a parameter list)
        (?<brace> .*?)            # anything else (ie, comments) including brace
        $
    }{
        my $i = 0;
        my $clauses = [];
        while( exists $+{"clause_$i"} ){
            ## warn "# clause_$i: " . $+{"clause_$i"} . "\n";
            push @$clauses, $+{"clause_$i"};
            $i++;
        }
        $self->emit_placeholder( $+{subname}, $+{brace}, $clauses )
    }egmx;

    return $code;
}

sub postfilter {
    my ( $self, $code ) = @_;
    my $marker      = $self->marker;
    my $replacement = $self->replacement;
    my $subname     = $self->identifier;
    my @ids;

    # Convert back to method
    $code =~ s{
        ^\s*\K                     # preserve leading whitespace
        $replacement          \s+  # keyword was converted to sub/package
        $marker                    #
        (?<id> \d+)                # the identifier
        [\w:]* \b                  # the rest of the orignal sub/package name
        (?<newline> \n? \s* )      # possible newline and indentation
        (?<brace>   .*?     ) [ ]* # opening brace on followed orig comments
        [ ]*                       # trailing spaces (not all whitespace)
    }{
        push @ids, $+{id};
        $self->emit_keyword( $+{newline} . $+{brace}, $+{id} );
    }egmx;

    # Restore the orig sub name when inserted via the -csc flag
    $code =~ s{
        \#\# \s tidy \s end: \s sub \s ${marker} $_
    }{
        $self->emit_csc( $_ );
    }egx for @ids;

    return $code;
}

1;

__END__

=pod

=head1 NAME

Perl::Tidy::Sweetened::Keyword::Block - Perl::Tidy::Sweetened filter plugin to define new subroutine and class keywords

=head1 VERSION

version 1.16

=head1 SYNOPSIS

    our $plugins = Perl::Tidy::Sweetened::Pluggable->new();

    $plugins->add_filter(
        Perl::Tidy::Sweetened::Keyword::Block->new(
            keyword     => 'method',
            marker      => 'METHOD',
            replacement => 'sub',
            clauses     => [ 'PAREN?', '(returns \s* PAREN)?' ],
        ) );

=head1 DESCRIPTION

This is a Perl::Tidy::Sweetened filter which enables the definition of
arbitrary keywords for subroutines with any number of potential signature
definitions. New accepts:

=over 4

=item keyword

    keyword => 'method'

Declares a new keyword (in this example the "method" keyword).

=item marker

    marker => 'METHOD'

Provides a text marker to be used to flag the new keywords during
C<prefilter>. The source code will be filtered prior to formatting by
Perl::Tidy such that:

    method foo {
    }

is turned into:

    sub foo { # __METHOD 1
    }

=item replacement

    replacement => 'sub'

Will convert the keyword to a C<sub> as shown above.

=item clauses

    clauses => [ 'PAREN?' ]

Provides a list of strings which will be turned into a regex to capture
additional clauses. The regex will include the 'xm' flags (so be sure to escape
spaces).  The clause can be marked optional with '?'. The special text "PAREN"
can be used to capture a balanced parenthetical.

This example will capture a parameter list enclosed by parenthesis, ie:

    method foo (Int $i) {
    }

No formatting is done on the clauses at this time. The order of declaration
is significant.

=back

=head1 AUTHOR

Mark Grimes E<lt>mgrimes@cpan.orgE<gt>

=head1 SOURCE

Source repository is at L<https://github.com/mvgrimes/Perl-Tidy-Sweetened>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<http://github.com/mvgrimes/Perl-Tidy-Sweetened/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Mark Grimes E<lt>mgrimes@cpan.orgE<gt>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
