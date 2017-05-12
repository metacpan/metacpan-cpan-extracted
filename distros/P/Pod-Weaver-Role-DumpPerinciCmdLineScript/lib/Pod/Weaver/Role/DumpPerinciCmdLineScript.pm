package Pod::Weaver::Role::DumpPerinciCmdLineScript;

our $DATE = '2016-05-20'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use Moose::Role;

use Data::Dmp;
use File::Slurper qw(write_binary);
use Perinci::CmdLine::Dump;

sub dump_perinci_cmdline_script {
    my ($self, $input) = @_;

    # find file object
    my $file;
    for (@{ $input->{zilla}->files }) {
        if ($_->name eq $input->{filename}) {
            $file = $_;
            last;
        }
    }
    die "Can't find file object for $input->{filename}" unless $file;

    # because we need an actual file for Perinci::CmdLine::Dump, we'll dump the
    # content of the file object to a temp file first. this includes DZF:OnDisk
    # object too, because the content and the name might not match actual file
    # on the filesystem anymore (e.g. see DZP:AddFile::FromFS where the file
    # object has its name() changed).
    my $tempname;
    {
        require File::Temp;
        (undef, $tempname) = File::Temp::tempfile();
        $self->log_debug(["Writing %s to %s", $file->name, $tempname]);
        write_binary($tempname, $file->encoded_content);
    }

    # just like in Dist::Zilla::Role::DumpPerinciCmdLineScript, we also set this
    # env to let script know that it's being dumped in dzil context, so they can
    # act accordingly if they need to. this is first done when I'm building
    # App-lcpan, where the bin/lcpan script collects subcommands by listing
    # subcommand modules (App::lcpan::Cmd::*). When the dist is being built, we
    # only want to collect subcommand modules from our own dist (@INC = ("lib"))
    # but when operating normally, we want to search all installed modules
    # (normal @INC). --perlancar
    local $ENV{DZIL} = 1;

    $self->log_debug(["Dumping Perinci::CmdLine script '%s'", $file->name]);

    my $res = Perinci::CmdLine::Dump::dump_perinci_cmdline_script(
        filename => $tempname,
        libs => ['lib'],
    );

    $self->log_debug(["Dump result: %s", dmp($res)]);
    $res;
}

no Moose::Role;
1;
# ABSTRACT: Role to dump Perinci::CmdLine script

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Role::DumpPerinciCmdLineScript - Role to dump Perinci::CmdLine script

=head1 VERSION

This document describes version 0.06 of Pod::Weaver::Role::DumpPerinciCmdLineScript (from Perl distribution Pod-Weaver-Role-DumpPerinciCmdLineScript), released on 2016-05-20.

=head1 METHODS

=head2 $obj->dump_perinci_cmdline_script($input)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Role-DumpPerinciCmdLineScript>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Role-DumpPerinciCmdLineScript>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Role-DumpPerinciCmdLineScript>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Dist::Zilla::Role::DumpPerinciCmdLineScript>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
