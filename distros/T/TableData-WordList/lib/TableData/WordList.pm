package TableData::WordList;

use 5.010001;
use strict;
use warnings;

use Role::Tiny::With;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-08-27'; # DATE
our $DIST = 'TableData-WordList'; # DIST
our $VERSION = '0.001'; # VERSION

with 'TableDataRole::Spec::Basic';

sub new {
    require Module::Load::Util;

    my ($class, %args) = @_;
    defined $args{wordlist} or die "Please specify 'wordlist' argument";
    bless({
        wordlist => Module::Load::Util::instantiate_class_with_optional_args(
            {ns_prefix=>'WordList'}, $args{wordlist}),
        pos => 0,
    }, $class);
}

sub get_column_count { 1 }

sub get_column_names {
    my $self = shift;
    wantarray ? ('word') : ['word'];
}

sub has_next_item {
    my $self = shift;
    return 1 if defined $self->{_next_word};
    defined($self->{_next_word} = $self->{wordlist}->next_word) ? 1:0;
}

sub get_next_item {
    my $self = shift;
    if (defined $self->{_next_word}) {
        $self->{pos}++;
        return [delete($self->{_next_word})];
    }
    my $word = $self->{wordlist}->next_word;
    die "StopIteration" unless defined $word;
    $self->{pos}++;
    [$word];
}

sub get_next_row_hashref {
    my $self = shift;
    if (defined $self->{_next_word}) {
        $self->{pos}++;
        return {word => delete($self->{_next_word})};
    }
    my $word = $self->{wordlist}->next_word;
    die "StopIteration" unless defined $word;
    $self->{pos}++;
    {word=>$word};
}

sub get_row_count {
    my $self = shift;
    my $n = 0;
    $self->{wordlist}->each_word(sub { $n++ });
    $self->{pos} = 0;
    $n;
}

sub reset_iterator {
    my $self = shift;
    $self->{wordlist}->reset_iterator;
    $self->{pos} = 0;
}

sub get_iterator_pos {
    my $self = shift;
    $self->{pos};
}

1;
# ABSTRACT: List of words from a WordList module

__END__

=pod

=encoding UTF-8

=head1 NAME

TableData::WordList - List of words from a WordList module

=head1 VERSION

This document describes version 0.001 of TableData::WordList (from Perl distribution TableData-WordList), released on 2023-08-27.

=head1 SYNOPSIS

From perl code:

 use TableData::WordList;

 my $table = TableData::WordList->new(wordlist => 'ID::BIP39');

From command-line (using L<tabledata> CLI):

 % tabledata WordList=wordlist,ID::BIP39

=for Pod::Coverage ^(.+)$

=head1 METHODS

=head2 new

Arguments:

=over

=item * wordlist

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/TableData-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-TableData-WordList>.

=head1 SEE ALSO

L<WordList>

L<TableData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=TableData-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
