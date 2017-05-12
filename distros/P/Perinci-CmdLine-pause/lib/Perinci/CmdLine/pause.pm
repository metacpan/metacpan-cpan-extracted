package Perinci::CmdLine::pause;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.30'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::Any::IfLOG qw($log);

use parent qw(Perinci::CmdLine::Lite);

use PERLANCAR::File::HomeDir qw(get_my_home_dir);

sub hook_after_read_config_file {
    my ($self, $r) = @_;

    return unless $self->read_config;
    return if $r->{read_config_files} && @{$r->{read_config_files}};

    my $path = get_my_home_dir() . "/.pause";
    return unless -f $path;

    open my($fh), "<", $path or die [500, "Can't read $path: $!"];
    $log->tracef("[pericmd-pause] Reading %s ...", $path);
    $r->{read_config_files} = [$path];
    while (<$fh>) {
        if (/^user\s+(.+)/) { $r->{config}{GLOBAL}{username} = $1 }
        elsif (/^password\s+(.+)/) { $r->{config}{GLOBAL}{password} = $1 }
    }
}

1;
# ABSTRACT: Perinci::CmdLine::Lite subclass for pause

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLine::pause - Perinci::CmdLine::Lite subclass for pause

=head1 VERSION

This document describes version 0.30 of Perinci::CmdLine::pause (from Perl distribution Perinci-CmdLine-pause), released on 2015-09-03.

=head1 DESCRIPTION

This class adds a hook_after_read_config_file to read L<CPAN::Uploader>'s config
file in C<~/.pause>. Encrypted C<.pause> is not supported.

This module is distributed separately from L<App::pause> because we want
L<pause> to be fatpacked and depends only on a few other modules (LWP::UserAgent
and LWP::Protocol::https).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLine-pause>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLine-pause>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLine-pause>

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
