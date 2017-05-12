package Pod::From::Acme::CPANLists;

our $DATE = '2015-10-23'; # DATE
our $VERSION = '0.03'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_pod_from_acme_cpanlists);

our %SPEC;

sub _markdown_to_pod {
    require Markdown::To::POD;
    Markdown::To::POD::markdown_to_pod(shift);
}

$SPEC{gen_pod_from_acme_cpanlists} = {
    v => 1.1,
    summary => 'Create "AUTHOR LISTS" and "MODULE LISTS" POD sections from @Author_Lists and @Module_Lists',
    args_rels => {
        req_one => [qw/module author_lists/],
        choose_all => [qw/author_lists module_lists/],
    },
    args => {
        module => {
            name => 'Module name, e.g. Acme::CPANLists::PERLANCAR',
            schema => 'str*',
        },
        author_lists => {
            summary => 'As an alternative to `module`, you can directly supply @Author_Lists here',
            schema => 'array*',
            links => ['module_lists'],
        },
        module_lists => {
            summary => 'As an alternative to `module`, you can directly supply @Module_Lists here',
            schema => 'array*',
            links => ['author_lists'],
        },
    },
    result_naked => 1,
};
sub gen_pod_from_acme_cpanlists {
    my %args = @_;

    my $raw = $args{_raw};
    my $res = $raw ? {} : "";

    my $author_lists = $args{author_lists};
    my $module_lists = $args{module_lists};
    if (my $mod = $args{module}) {
        no strict 'refs';
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        $author_lists = \@{"$mod\::Author_Lists"};
        $module_lists = \@{"$mod\::Module_Lists"};
    }

    if (@$author_lists) {
        if ($raw) {
            $res->{author_lists} = "";
        } else {
            $res .= "=head1 AUTHOR LISTS\n\n";
        }

        for my $list (@$author_lists) {
            my $text = "=head2 $list->{summary}\n\n";
            $text .= _markdown_to_pod($list->{description})."\n\n"
                if $list->{description} && $list->{description} =~ /\S/;
            $text .= "=over\n\n";
            for my $ent (@{ $list->{entries} }) {
                $text .= "=item * L<".($ent->{summary} ? "$ent->{summary}|" : "$ent->{author}|")."https://metacpan.org/author/$ent->{author}>\n\n";
                $text .= _markdown_to_pod($ent->{description})."\n\n"
                    if $ent->{description} && $ent->{description} =~ /\S/;
                $text .= "Rating: $ent->{rating}/10\n\n"
                    if $ent->{rating} && $ent->{rating} =~ /\A[1-9]\z/;
                $text .= "Related authors: ".join(", ", map {"L<$_|https://metacpan.org/author/$_>"} @{ $ent->{related_authors} })."\n\n"
                    if $ent->{related_authors} && @{ $ent->{related_authors} };
                $text .= "Alternate authors: ".join(", ", map {"L<$_|https://metacpan.org/author/$_>"} @{ $ent->{alternate_authors} })."\n\n"
                    if $ent->{alternate_authors} && @{ $ent->{alternate_authors} };
            }
            $text .= "=back\n\n";

            if ($raw) {
                $res->{author_lists} .= $text;
            } else {
                $res .= $text;
            }
        }
    }

    if (@$module_lists) {
        if ($raw) {
            $res->{module_lists} = "";
        } else {
            $res .= "=head1 MODULE LISTS\n\n";
        }

        for my $list (@$module_lists) {
            my $text = "=head2 $list->{summary}\n\n";
            $text .= _markdown_to_pod($list->{description})."\n\n"
                if $list->{description} && $list->{description} =~ /\S/;
            $text .= "=over\n\n";
            for my $ent (@{ $list->{entries} }) {
                $text .= "=item * L<$ent->{module}>".($ent->{summary} ? " - $ent->{summary}" : "")."\n\n";
                $text .= _markdown_to_pod($ent->{description})."\n\n"
                    if $ent->{description} && $ent->{description} =~ /\S/;
                $text .= "Rating: $ent->{rating}/10\n\n"
                    if $ent->{rating} && $ent->{rating} =~ /\A[1-9]\z/;
                $text .= "Related modules: ".join(", ", map {"L<$_>"} @{ $ent->{related_modules} })."\n\n"
                    if $ent->{related_modules} && @{ $ent->{related_modules} };
                $text .= "Alternate modules: ".join(", ", map {"L<$_>"} @{ $ent->{alternate_modules} })."\n\n"
                    if $ent->{alternate_modules} && @{ $ent->{alternate_modules} };
            }
            $text .= "=back\n\n";

            if ($raw) {
                $res->{module_lists} .= $text;
            } else {
                $res .= $text;
            }
        }
    }

    $res;
}

1;
# ABSTRACT: Create "AUTHOR LISTS" and "MODULE LISTS" POD sections from @Author_Lists and @Module_Lists

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::From::Acme::CPANLists - Create "AUTHOR LISTS" and "MODULE LISTS" POD sections from @Author_Lists and @Module_Lists

=head1 VERSION

This document describes version 0.03 of Pod::From::Acme::CPANLists (from Perl distribution Pod-From-Acme-CPANLists), released on 2015-10-23.

=head1 SYNOPSIS

 use Pod::From::Acme::CPANLists qw(gen_pod_from_acme_cpanlists);

 print gen_pod_from_acme_cpanlists(module => 'Acme::CPANLists::PERLANCAR');

=head1 FUNCTIONS


=head2 gen_pod_from_acme_cpanlists(%args) -> any

Create "AUTHOR LISTS" and "MODULE LISTS" POD sections from @Author_Lists and @Module_Lists.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<author_lists> => I<array>

As an alternative to `module`, you can directly supply @Author_Lists here.

=item * B<module> => I<str>

=item * B<module_lists> => I<array>

As an alternative to `module`, you can directly supply @Module_Lists here.

=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-From-Acme-CPANLists>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-From-Acme-CPANLists>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-From-Acme-CPANLists>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
