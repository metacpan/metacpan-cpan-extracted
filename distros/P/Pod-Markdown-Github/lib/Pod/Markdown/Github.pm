package Pod::Markdown::Github;

use strict;
use warnings;
use parent 'Pod::Markdown';

our $VERSION = '0.03';

sub syntax {
    my ( $self, $paragraph ) = @_;
    return ( $paragraph =~ /(sub|my|use|shift|\$self|\=\>|\$_|\@_)/ )
      ? 'perl'
      : '';
}

sub _indent_verbatim {
    my ( $self, $paragraph ) = @_;
    $paragraph = $self->SUPER::_indent_verbatim($paragraph);

    # Remove the leading 4 spaces because we'll escape via ```language
    $paragraph = join "\n", map { s/^\s{4}//; $_ } split /\n/, $paragraph;

    # Enclose the paragraph in ``` and specify the language
    return sprintf( "```%s\n%s\n```", $self->syntax($paragraph), $paragraph );
}

1;

__END__

=pod

=head1 NAME

Pod::Markdown::Github - Convert POD to Github's specific markdown

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    perl -MPod::Markdown::Github -e "Pod::Markdown::Github->filter('file.pod')"

=head1 DESCRIPTION

Github flavored markdown allows for syntax highlighting using three
backticks.

This module inherits from L<Pod::Markdown> and adds those backticks and
an optional language identifier.

=head1 SUBCLASSING

This module performs a very simple linguistic check to identify if it's
dealing with Perl code. To expand on this logic, or to add other languages
one may subclass this module and overwrite the C<syntax> method.

    package Pod::Markdown::Github::More;

    sub syntax {
        my ( $self, $paragraph ) = @_;

        # analyze $paragraph and return language identifier
        return 'c' if $paragraph =~ /\#include/;
    }

Github uses L<Liguist|https://github.com/github/linguist> to perform language
detection and syntax highlighting, so the above may not be needed after all.

=head1 AUTHOR

Stefan G. (minimal)

Ben Kaufman (whosgonna)

Nikolay Mishin (mishin)

=head1 LICENCE

Perl

=cut

