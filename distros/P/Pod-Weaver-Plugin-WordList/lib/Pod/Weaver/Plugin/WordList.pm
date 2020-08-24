package Pod::Weaver::Plugin::WordList;

our $DATE = '2020-08-23'; # DATE
our $VERSION = '0.062'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use File::Slurper qw(write_text);
use File::Temp qw(tempfile);
use List::Util qw(first);
use Perinci::Result::Format::Lite;

sub _md2pod {
    require Markdown::To::POD;

    my ($self, $md) = @_;
    my $pod = Markdown::To::POD::markdown_to_pod($md);
    # make sure we add a couple of blank lines in the end
    $pod =~ s/\s+\z//s;
    $pod . "\n\n\n";
}

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    {
        # we need to load the munged version of module
        my ($temp_fh, $temp_fname) = tempfile();
        my ($file) = grep { $_->name eq $filename } @{ $input->{zilla}->files };
        write_text($temp_fname, $file->content);
        require $temp_fname;
    }

    my $wl_name = $package;
    $wl_name =~ s/\AWordList:://;

  ADD_SYNOPSIS_SECTION:
    {
        my @pod;
        push @pod, " use $package;\n\n";
        push @pod, " my \$wl = $package->new;\n\n";

        push @pod, " # Pick a (or several) random word(s) from the list\n";
        push @pod, " my \$word = \$wl->pick;\n";
        push @pod, " my \@words = \$wl->pick(3);\n\n";

        push @pod, " # Check if a word exists in the list\n";
        push @pod, " if (\$wl->word_exists('foo')) { ... }\n\n";

        push @pod, " # Call a callback for each word\n";
        push @pod, " \$wl->each_word(sub { my \$word = shift; ... });\n\n";

        push @pod, " # Iterate\n";
        push @pod, " my \$first_word = \$wl->first_word;\n";
        push @pod, " while (defined(my \$word = \$wl->next_word)) { ... }\n\n";

        push @pod, " # Get all the words\n";
        push @pod, " my \@all_words = \$wl->all_words;\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_SYNOPSIS_SECTION

  ADD_WORDLIST_PARAMETERS_SECTION:
    {
        my $params = \%{"$package\::PARAMS"};
        last unless keys %$params;

        my $examples = \@{"$package\::EXAMPLES"};
        my $first_example_with_args = first { $_->{args} && keys %{ $_->{args} } } @$examples;

        my @pod;

        push @pod, <<_;

This is a parameterized wordlist module. When loading in Perl, you can specify
the parameters to the constructor, for example:

 use $package;
_
        my $args;
        if ($first_example_with_args) {
            my $eg = $first_example_with_args;
            push @pod, " # $eg->{summary}\n" if defined $eg->{summary};
            $args = $eg->{args};
        } else {
            $args = {foo=>1, bar=>2};
        }

        push @pod, " my \$wl = $package\->(".
            join(", ", map {"$_ => $args->{$_}"} sort keys %$args).");\n\n";

        push @pod, <<_;

When loading on the command-line, you can specify parameters using the
C<WORDLISTNAME=ARGNAME1,ARGVAL1,ARGNAME2,ARGVAL2> syntax, like in L<perl>'s
C<-M> option, for example:

_

        if ($first_example_with_args) {
            my $eg = $first_example_with_args;
            push @pod, " % wordlist -w $wl_name=",
                join(",", map { "$_=$eg->{args}{$_}" } sort keys %{ $eg->{args} }), "\n\n";
        } else {
            push @pod, " % wordlist -w $wl_name=foo,1,bar,2 ...\n\n";
        }

        push @pod, "Known parameters:\n\n";
        for my $paramname (sort keys %$params) {
            my $paramspec = $params->{$paramname};
            push @pod, "=head2 $paramname\n\n";
            push @pod, "Required. " if $paramspec->{req};
            if (defined $paramspec->{summary}) {
                require String::PodQuote;
                push @pod, String::PodQuote::pod_quote($paramspec->{summary}), ".\n\n";
            }
            push @pod, $self->_md2pod($paramspec->{description})
                if $paramspec->{description};
        }

        $self->add_text_to_section(
            $document, join("", @pod), 'WORDLIST PARAMETERS',
            {
                after_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_WORDLIST_PARAMETERS_SECTION

  ADD_STATISTICS_SECTION:
    {
        no strict 'refs';
        my @pod;
        my $stats = \%{"$package\::STATS"};
        last unless keys %$stats;
        my $str = Perinci::Result::Format::Lite::format(
            [200,"OK",$stats], "text-pretty");
        $str =~ s/^/ /gm;
        push @pod, $str, "\n";

        push @pod, "The statistics is available in the C<\%STATS> package variable.\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'STATISTICS',
            {
                after_section => ['SYNOPSIS'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    } # ADD_STATISTICS_SECTION

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(WordList/.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
    }
}

1;
# ABSTRACT: Plugin to use when building WordList::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::WordList - Plugin to use when building WordList::* distribution

=head1 VERSION

This document describes version 0.062 of Pod::Weaver::Plugin::WordList (from Perl distribution Pod-Weaver-Plugin-WordList), released on 2020-08-23.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-WordList]

=head1 DESCRIPTION

This plugin is to be used when building C<WordList::*> distribution. Currently
it does the following:

=over

=item * Add a Synopsis section (if doesn't already exist) showing how to use the module

=item * Add Statistics section showing statistics from C<%STATS> (which can be generated by DZP:WordList)

=back

=for Pod::Coverage ^(weave_section)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-WordList>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-WordList>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-WordList>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<WordList>

L<Dist::Zilla::Plugin::WordList>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
