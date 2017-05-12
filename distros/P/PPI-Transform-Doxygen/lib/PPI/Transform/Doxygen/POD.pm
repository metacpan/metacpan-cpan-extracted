package PPI::Transform::Doxygen::POD;

use 5.010001;
use strict;
use warnings;
use parent qw(Pod::POM::View::HTML);

our $VERSION = '0.1';

sub view_pod {
    my ($self, $pod) = @_;
    return $pod->content->present($self);
}

sub view_head1 {
    my ($self, $head1) = @_;
    my $title = $head1->title->present($self);
    my $name = $title;
    $name =~ s/\s/_/g;
    return "\n\@section $name $title\n" . $head1->content->present($self);
}

sub view_head2 {
    my ($self, $head2) = @_;
    my $title = $head2->title->present($self);
    my $name = $title;
    $name =~ s/\s/_/g;
    return "\n\@subsection $name $title\n" . $head2->content->present($self);
}

sub view_seq_code {
    my ($self, $text) = @_;
    return "\n\@code\n$text\n\@endcode\n";
}

sub view_verbatim {
    my ($self, $text) = @_;
    return "<pre>$text</pre>\n\n";
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
