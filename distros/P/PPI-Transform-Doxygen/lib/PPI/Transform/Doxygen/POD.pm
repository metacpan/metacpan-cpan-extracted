package PPI::Transform::Doxygen::POD;

use 5.010001;
use strict;
use warnings;
use parent qw(Pod::POM::View::HTML);

our $VERSION = '0.33';

our $PREFIX = '';

sub view_pod {
    my ($self, $pod) = @_;
    return $pod->content->present($self);
}

sub view_head1 {
    my ($self, $head1) = @_;
    my $title = $head1->title->present($self);
    (my $name = $title) =~ s/\s/_/g;
    return "\n\@section ${PREFIX}_$name $title\n" . $head1->content->present($self);
}

sub view_head2 {
    my ($self, $head2) = @_;
    my $title = $head2->title->present($self);
    (my $name = $title) =~ s/\s/_/g;
    my $sect = $title =~ /[\w:]+\s*\(.*\)/
             ? "\n"
             : "\n\@subsection $name $title\n";
    return $sect . $head2->content->present($self);
}

sub view_seq_code {
    my ($self, $text) = @_;
    return qq(<span style="background-color:#eee;padding-left:0.5em;padding-right:0.5em;font-family:Monospace;font-weight: bold;">$text</span>);
}

sub view_verbatim {
    my ($self, $text) = @_;
    _unescape($text);
    return "\n\@code\n$text\n\@endcode\n";
}

sub view_seq_link {
    my ($self, $link) = @_;
    my($title, $pre) = split(/\|/, $link);
    my $url = $pre && $pre =~ m(^\w+://)
            ? qq(<a href="$pre">$title</a>)
            : $self->SUPER::view_seq_link($link);
    return $url;
}

my %XML_TO = (
  '&'  => '&amp;',
  '<'  => '&lt;',
  '>'  => '&gt;',
  '"'  => '&quot;',
  '\'' => '&#39;'
);
my %XML_FROM = reverse %XML_TO;

sub _unescape {
    $_[0] =~ s!\Q$_!$XML_FROM{$_}!g for keys %XML_FROM;
    $_[0] =~ s!\\(\@|\\|\%|#)!$1!g;
}

sub _escape {
    $_[0] =~ s!\Q$_!$XML_TO{$_}!g for keys %XML_TO;
}


1;

__END__

=head1 NAME

PPI::Transform::Doxygen::POD - Convert POD to Doxygen compatible HTML

=head1 DESCRIPTION

This is a shameless copy of Doxygen::Filter::Perl::POD.

It is a helper module for use with PPI::Transform::Doxygen and should not be
called directly. This class actually overloads some of the methods found in
Pod::POM::View::HTML and converts their output to be in a Doxygen style that
PPI::Transform::Doxygen can use.

=head1 AUTHOR

B<Bret Jordan> (author of Doxygen::Filter::Perl::POD)

B<Thomas Kratz> <TOMK@cpan.org> Modifications

=cut
