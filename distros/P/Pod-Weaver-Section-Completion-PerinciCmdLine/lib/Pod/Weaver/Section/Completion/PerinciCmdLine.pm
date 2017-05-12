package Pod::Weaver::Section::Completion::PerinciCmdLine;

our $DATE = '2016-04-30'; # DATE
our $VERSION = '0.14'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::DetectPerinciCmdLineScript';
with 'Pod::Weaver::Role::Section';
with 'Pod::Weaver::Role::SectionText::SelfCompletion';
with 'Pod::Weaver::Role::SectionText::HasCompletion';

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename} || 'file';

    my $res = $self->detect_perinci_cmdline_script($input);
    if ($filename !~ m!^(bin|script)/!) {
        $self->log_debug(["skipped file %s (not bin/script)", $filename]);
        return;
    } elsif ($res->[0] != 200) {
        die "Can't detect Perinci::CmdLine script for $filename: $res->[0] - $res->[1]";
    } elsif (!$res->[2]) {
        $self->log_debug(["skipped file %s (not a Perinci::CmdLine script: %s)", $filename, $res->[3]{'func.reason'}]);
        return;
    }

    (my $command_name = $filename) =~ s!.+/!!;

    # file looks like a completer script, don't bother generating completer for
    # completer :)
    if ($command_name =~ /\A_/) {
        $self->log_debug(["skipped script %s (a completer itself)", $filename]);
        return;
    }

    my $text;
    if ($res->[3]{'func.is_inline'}) {
        $text = $self->section_text_has_completion({command_name=>$command_name});
    } else {
        $text = $self->section_text_self_completion({command_name=>$command_name});
    }

    $self->add_text_to_section($document, $text, 'COMPLETION');
}

no Moose;
1;
# ABSTRACT: Add a COMPLETION section for Perinci::CmdLine-based scripts

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Section::Completion::PerinciCmdLine - Add a COMPLETION section for Perinci::CmdLine-based scripts

=head1 VERSION

This document describes version 0.14 of Pod::Weaver::Section::Completion::PerinciCmdLine (from Perl distribution Pod-Weaver-Section-Completion-PerinciCmdLine), released on 2016-04-30.

=head1 SYNOPSIS

In your C<weaver.ini>:

 [Completion::PerinciCmdLine]

=head1 DESCRIPTION

This section plugin adds a COMPLETION section for Perinci::CmdLine-based
scripts. The section contains information on how to activate shell tab
completion for the scripts.

=for Pod::Coverage weave_section

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Section-Completion-PerinciCmdLine>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Section-BashCompletion-PerinciCmdLine>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Section-Completion-PerinciCmdLine>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::CmdLine>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
