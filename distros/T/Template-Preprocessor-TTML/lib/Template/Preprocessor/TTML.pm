package Template::Preprocessor::TTML;
$Template::Preprocessor::TTML::VERSION = '0.0105';
use warnings;
use strict;

use base 'Template::Preprocessor::TTML::Base';

use Template;
use Template::Preprocessor::TTML::CmdLineProc;

__PACKAGE__->mk_accessors(
    qw(
        argv
        opts
        )
);



sub initialize
{
    my $self = shift;
    my %args = (@_);
    $self->argv( [ @{ $args{'argv'} } ] );

    return 0;
}


sub _calc_opts
{
    my $self = shift;
    my $cmd_line =
        Template::Preprocessor::TTML::CmdLineProc->new( argv => $self->argv() );
    $self->opts( $cmd_line->get_result() );
}

sub _get_output
{
    my $self = shift;
    if ( $self->opts()->output_to_stdout() )
    {
        return ();
    }
    else
    {
        return ( $self->opts()->output_filename() );
    }
}

sub _get_mode_callbacks
{
    return {
        'regular' => "_mode_regular",
        'help'    => "_mode_help",
        'version' => "_mode_version",
    };
}

sub _mode_version
{
    print <<"EOF";
This is TTML version $Template::Preprocessor::TTML::VERSION
TTML is a Command Line Preprocessor based on the Template Toolkit
(http://www.template-toolkit.org/)

More information about TTML can be found at:

http://search.cpan.org/dist/Template-Preprocessor-TTML/
EOF
}

sub _get_help_text
{
    return <<"EOF";
ttml - A Template Toolkit Based Preprocessor
Usage: ttml [-o OUTPUTFILE] [OPTIONS] INPUTFILE

Options:
    -o OUTPUTFILE - Output to file instead of stdout.
    -I PATH, --include=PATH - Append PATH to the include path
    -DVAR=VALUE, --define=VAR=VALUE - Define a pre-defined variable.
    --includefile=FILE - Include FILE at the top.

    -V, --version - display the version number.
    -h, --help - display this help listing.
EOF
}

sub _mode_help
{
    my $self = shift;

    print $self->_get_help_text();

    return 0;
}

sub run
{
    my $self = shift;
    $self->_calc_opts();

    return $self->can(
        $self->_get_mode_callbacks()->{ $self->opts()->run_mode() } )->($self);
}

sub _mode_regular
{
    my $self   = shift;
    my $config = {
        INCLUDE_PATH => [ @{ $self->opts()->include_path() }, ".", ],
        EVAL_PERL    => 1,
        PRE_PROCESS  => $self->opts()->include_files(),
    };
    my $template = Template->new($config);

    if (
        !$template->process(
            $self->opts()->input_filename(), $self->opts()->defines(),
            $self->_get_output(),
        )
        )
    {
        die $template->error();
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Preprocessor::TTML - Preprocess files using the Template Toolkit
from the command line.

=head1 VERSION

version 0.0105

=head1 SYNOPSIS

    use Template::Preprocessor::TTML;

    my $obj = Template::Preprocessor::TTML->new(argv => [@ARGV]);
    $obj->run()

    ...

=head1 VERSION

version 0.0105

=head1 FUNCTIONS

=head2 initialize()

Internal function for initializing the object.

=head2 run

Performs the processing.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-template-preprocessor-ttml@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Preprocessor-TTML>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Template-Preprocessor-TTML>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Preprocessor-TTML>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Template-Preprocessor-TTML>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Template-Preprocessor-TTML>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Template-Preprocessor-TTML>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Template::Preprocessor::TTML>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-template-preprocessor-ttml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Template-Preprocessor-TTML>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thewml/latemp>

  git clone http://bitbucket.org/shlomif/latemp

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Preprocessor-TTML> or
by email to
L<bug-template-preprocessor-ttml@rt.cpan.org|mailto:bug-template-preprocessor-ttml@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/Template-Preprocessor-TTML>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Template-Preprocessor-TTML>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/Template-Preprocessor-TTML>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/T/Template-Preprocessor-TTML>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Template-Preprocessor-TTML>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Template::Preprocessor::TTML>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-template-preprocessor-ttml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Template-Preprocessor-TTML>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thewml/latemp>

  git clone http://bitbucket.org/shlomif/latemp

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Preprocessor-TTML> or
by email to
L<bug-template-preprocessor-ttml@rt.cpan.org|mailto:bug-template-preprocessor-ttml@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
