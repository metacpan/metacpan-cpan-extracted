package Pod::Weaver::Section::Completion::GetoptLongComplete;

our $DATE = '2016-04-30'; # DATE
our $VERSION = '0.08'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';
with 'Pod::Weaver::Role::SectionText::SelfCompletion';

use List::Util qw(first);

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    my $command_name;
    if ($filename =~ m!^(bin|script)/(.+)$!) {
        $command_name = $2;
    } else {
        $self->log_debug(["skipped file %s (not an executable)", $filename]);
        return;
    }

    # file looks like a completer script, don't bother generating completer for
    # completer :)
    if ($command_name =~ /\A_/) {
        $self->log_debug(["skipped script %s (a completer itself)", $filename]);
        return;
    }

    # find file content in zilla object, not directly in filesystem, because the
    # file might be generated dynamically by dzil.
    my $file = first { $_->name eq $filename } @{ $input->{zilla}->files };
    unless ($file) {
        $self->log_fatal(["can't find file %s in zilla object", $filename]);
    }
    my $content = $file->content;
    #unless ($content =~ /\A#!.+perl/) {
    #    $self->log_debug(["skipped file %s (not a Perl script)",
    #                      $filename]);
    #    return;
    #}
    unless ($content =~ /(use|require)\s+Getopt::Long::Complete\b/) {
        $self->log_debug(["skipped file %s (does not use Getopt::Long::Complete)",
                          $filename]);
        return;
    }

    my $text = $self->section_text_self_completion({command_name=>$command_name});

    $self->add_text_to_section($document, $text, 'COMPLETION');
}

no Moose;
1;
# ABSTRACT: Add a COMPLETION section for Getopt::Long::Complete-based scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Completion::GetoptLongComplete - Add a COMPLETION section for Getopt::Long::Complete-based scripts

=head1 VERSION

This document describes version 0.08 of Pod::Weaver::Section::Completion::GetoptLongComplete (from Perl distribution Pod-Weaver-Section-Completion-GetoptLongComplete), released on 2016-04-30.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [Completion::GetoptLongComplete]

=head1 DESCRIPTION

This section plugin adds a COMPLETION section for Getopt::Long::Complete-based
scripts. The section contains information on how to activate shell tab
completion for the scripts.

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-Completion-GetoptLongComplete>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-Completion-GetoptLongComplete>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-Completion-GetoptLongComplete>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Getopt::Long::Complete>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
