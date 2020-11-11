package Tables::WordList;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-10'; # DATE
our $DIST = 'Tables-WordList'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Role::Tiny::With;
with 'TablesRole::Source::Iterator';

sub new {
    require Module::Load::Util;

    my ($class, %args) = @_;
    defined $args{wordlist} or die "Please specify 'wordlist' argument";
    $class->_new(
        gen_iterator => sub {
            my $wl = Module::Load::Util::instantiate_class_with_optional_args(
                {ns_prefix=>'WordList'}, $args{wordlist});
            sub {
                my $w = $wl->next_word;
                return undef unless defined $w;
                {word=>$w};
            },
        },
    );
}

1;
# ABSTRACT: Table from a WordList module

__END__

=pod

=encoding UTF-8

=head1 NAME

Tables::WordList - Table from a WordList module

=head1 VERSION

This document describes version 0.001 of Tables::WordList (from Perl distribution Tables-WordList), released on 2020-11-10.

=head1 SYNOPSIS

From perl code:

 use Tables::WordList;

 my $table = Tables::WordList->new(wordlist => 'ID::BIP39');

From command-line (using L<tables> CLI):

 % tables show WordList=wordlist,ID::BIP39

=head1 METHODS

=head2 new

Arguments:

=over

=item * wordlist

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Tables-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Tables-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Tables-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Tables>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
