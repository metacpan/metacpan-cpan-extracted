package Template::Preprocessor::TTML::CmdLineProc;

use strict;
use warnings;


use base 'Template::Preprocessor::TTML::Base';

package Template::Preprocessor::TTML::CmdLineProc::Results;

use base 'Template::Preprocessor::TTML::Base';

__PACKAGE__->mk_accessors(qw(
    defines
    include_files
    include_path
    input_filename
    output_to_stdout
    output_filename
    run_mode
));

sub initialize
{
    my $self = shift;
    $self->output_to_stdout(1);
    $self->include_path([]);
    $self->defines(+{});
    $self->include_files([]);
    $self->run_mode("regular");
    return 0;
}

sub add_to_inc
{
    my $self = shift;
    my $path = shift;
    push @{$self->include_path()}, $path;
}

sub add_to_defs
{
    my ($self, $k, $v) = @_;
    $self->defines()->{$k} = $v;
}

sub add_include_file
{
    my $self = shift;
    my $path = shift;
    push @{$self->include_files()}, $path;
}

package Template::Preprocessor::TTML::CmdLineProc;

__PACKAGE__->mk_accessors(qw(
    argv
    result
));


sub initialize
{
    my $self = shift;
    my (%args) = @_;
    $self->argv($args{argv});

    $self->result(Template::Preprocessor::TTML::CmdLineProc::Results->new());
    return 0;
}

sub _get_next_arg
{
    my $self = shift;
    return shift(@{$self->argv()});
}

sub _no_args_left
{
    my $self = shift;
    return (@{$self->argv()} == 0);
}

sub _get_run_mode_opts_map
{
    return
    {
        "--version" => "version",
        "-V" => "version",
        "--help" => "help",
        "-h" => "help",
    };
}

sub _get_arged_longs_opts_map
{
    return
    {
        "include" => "_process_include_path_opt",
        "includefile" => "_process_add_includefile_opt",
        "define" => "_process_define_opt",
    };
}

sub _handle_middle_run_mode_opt
{
    my ($self, $arg) = @_;
    if (exists($self->_get_run_mode_opts_map()->{$arg}))
    {
        die "Option \"$arg\" was specified in the middle of the command line. It should be a standalone option.";
    }
}

sub _handle_long_option
{
    my $self = shift;
    my $arg_orig = shift;
    if ($arg_orig eq "--")
    {
        return $self->_handle_no_more_options();
    }
    $self->_handle_middle_run_mode_opt($arg_orig);
    my $arg = $arg_orig;
    $arg =~ s!^--!!;
    my $map = $self->_get_arged_longs_opts_map();
    $arg =~ m{^([^=]*)};
    my $option = $1;
    if (exists($map->{$option}))
    {
        my $sub = $self->can($map->{$option});
        if (length($arg) eq length($option))
        {
            if ($self->_no_args_left())
            {
                die "An argument should be specified after \"$arg_orig\"";
            }
            return $sub->(
               $self, $self->_get_next_arg()
            );
        }
        else
        {
            return $sub->(
                $self, substr($arg, length($option)+1)
            );
        }
    }
    die "Unknown option!";
}

sub _handle_no_more_options
{
    my $self = shift;
    $self->_assign_filename($self->_get_next_arg());
}

sub _get_arged_short_opts_map
{
    return
    {
        "o" => "_process_output_short_opt",
        "I" => "_process_include_path_opt",
        "D" => "_process_define_opt",
    };
}

sub _handle_short_option
{
    my $self = shift;
    my $arg_orig = shift;

    $self->_handle_middle_run_mode_opt($arg_orig);

    my $arg = $arg_orig;
    $arg =~ s!^-!!;
    my $map = $self->_get_arged_short_opts_map();
    my $first_char = substr($arg, 0, 1);
    if (exists($map->{$first_char}))
    {
        my $sub = $self->can($map->{$first_char});
        if (length($arg) > 1)
        {
            return $sub->(
                $self, substr($arg, 1)
            );
        }
        else
        {
            if ($self->_no_args_left())
            {
                die "An argument should be specified after \"$arg_orig\"";
            }
            return $sub->(
                $self, $self->_get_next_arg()
            );
        }
    }
    die "Unknown option \"$arg_orig\"!";
}

sub _process_output_short_opt
{
    my $self = shift;
    my $filename = shift;
    $self->result()->output_to_stdout(0);
    $self->result()->output_filename($filename);
}

sub _process_include_path_opt
{
    my $self = shift;
    my $path = shift;
    $self->result()->add_to_inc($path);
}

sub _process_add_includefile_opt
{
    my $self = shift;
    my $file = shift;
    $self->result()->add_include_file($file);
}

sub _process_define_opt
{
    my $self = shift;
    my $def = shift;
    if ($def !~ m{^([^=]+)=(.*)$})
    {
        die "Variable definition should contain a \"=\", but instead it is \"$def\"!";
    }
    my ($var, $value) = ($1, $2);
    $self->result()->add_to_defs($var, $value);
}

sub _assign_filename
{
    my ($self, $arg) = @_;
    if (! $self->_no_args_left())
    {
        die "Junk after filename";
    }
    else
    {
        $self->result()->input_filename($arg);
    }
}

sub _handle_exclusive_run_mode_opt
{
    my $self = shift;
    if ((@{$self->argv()} == 1))
    {
        my $opt = $self->argv()->[0];
        if (exists($self->_get_run_mode_opts_map()->{$opt}))
        {
            $self->result()->run_mode(
                $self->_get_run_mode_opts_map()->{$opt}
            );
            return 1;
        }
    }
    return 0;
}


sub get_result
{
    my $self = shift;

    if ($self->_no_args_left())
    {
        die "Incorrect usage: you need to specify a filename";
    }

    if (! $self->_handle_exclusive_run_mode_opt())
    {
        while (defined(my $arg = $self->_get_next_arg()))
        {
            if ($arg =~ m{^-})
            {
                if ($arg =~ m{^--})
                {
                    $self->_handle_long_option($arg);
                }
                else
                {
                    $self->_handle_short_option($arg);
                }
            }
            else
            {
                $self->_assign_filename($arg);
            }
        }
    }
    return $self->result();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Template::Preprocessor::TTML::CmdLineProc - Process command line arguments

=head1 VERSION

version 0.0104

=head1 SYNOPSIS

    my $obj =
        Template::Preprocessor::TTML::CmdLineProc->new(
            argv => [@ARGV],
        );
    my $result = $obj->get_result();

=head1 DESCRIPTION

The constructor accepts argv as argument, and is destructible to it. It
returns a results object.

=head1 FUNCTIONS

=head2 $cmd_line->initialize(@_)

This is an internal function that initializes the arguments of the object.

=head2 $cmd_line->get_result()

This function calculates the results from the arguments. If something wrong
it will throw an exception. It should be called only once.

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
