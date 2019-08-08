package Perinci::CmdLineX::CommonOptions::SelfUpgrade;

our $DATE = '2019-08-07'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

# currently this is crude, we'll be more proper after Perinci::Script and plugin
# system is developed.

sub apply_to_object {
    my ($class, $cmd) = @_;

    my $copts = $cmd->common_opts;

    # XXX use hook to check if meta (or other copt) uses -U (or --self-upgrade).
    # avoid using -U if meta uses -U.

    $copts->{self_upgrade} = {
        getopt  => "self-upgrade|U",
        summary => "Update program to latest version from CPAN",
        usage   => "--self-upgrade (or -U)",
        handler => sub {
            my ($go, $val, $r) = @_;
            $r->{action} = 'self_upgrade';
            $r->{skip_parse_subcommand_argv} = 1;
        },
    };
}

package # hide from PAUSE
    Perinci::CmdLine::Base;
use Log::ger;

sub action_self_upgrade {
    require File::Which;
    require HTTP::Tiny;
    require JSON::MaybeXS;

    my ($self, $r) = @_;

    unless (File::Which::which("cpanm")) {
        return [412, "Cannot upgrade: 'cpanm' program not available"];
    }

    my @modules;
    if ($Perinci::CmdLineX::CommonOptions::SelfUpgrade::_list_modules) {
        # get list of modules to download from this hook
        @modules = $Perinci::CmdLineX::CommonOptions::SelfUpgrade::_list_modules->();
    } else {
        my $url = $self->url;
        unless ($url =~ m!\A(?:pl:|riap://perl)?/(.+)/[^/]*\z!) {
            return [412, "Cannot upgrade: Unsupported Riap URL $url"];
        }
        (my $module = $1) =~ s!/!::!g;
        @modules = ($module);
    }

    my @failed_modules;
    log_info "Upgrading these modules: %s ...", \@modules;
    #print "Upgrading these modules: ", join(", ", @modules), "\n";
    for my $module (@modules) {
        (my $module_pm = "$module.pm") =~ s!::!/!g;
        eval { require $module_pm };
        if ($@) {
            warn "Cannot upgrade module '$module': $@, skipped\n";
            push @failed_modules, $module;
            next;
        }
        my $local_version = ${"$module\::VERSION"};

        my $apiurl = "http://fastapi.metacpan.org/v1/module/$module?fields=version";
        my $apires = HTTP::Tiny->new->get($apiurl);
        unless ($apires->{success}) {
            warn "Cannot upgrade module '$module': Can't check latest version from $apiurl: $apires->{status} - $apires->{reason}\n";
            push @failed_modules, $module;
            next;
        }

        eval { $apires = JSON::MaybeXS::decode_json($apires->{content}) };
        if ($@) {
            warn "Cannot upgrade module '$module': Invalid API response from $apiurl: not valid JSON: $@\n";
            push @failed_modules, $module;
            next;
        }

        my $version_on_cpan;
        if ($apires->{message}) {
            if ($apires->{code} == 404) {
                warn "Cannot upgrade module '$module': module not found on CPAN\n";
                push @failed_modules, $module;
                next;
            }
        }

        $version_on_cpan = $apires->{version};
        unless (defined $version_on_cpan) {
            warn "Cannot upgrade module '$module': Module's latest version on CPAN is undefined\n";
            push @failed_modules, $module;
            next;
        }

        if (defined $local_version &&
                version->parse($local_version) >= version->parse($version_on_cpan)) {
            log_info "Local version ($local_version) of module '$module' is already newest".
                ($local_version ne $version_on_cpan ? " ($version_on_cpan)" : "");
            next;
        }

        say "Updating to version $version_on_cpan ...";
        system "cpanm", "-n", $module;

        my $exit_code = $? < 0 ? $? : $? >> 8;

        if ($exit_code) {
            warn "Cannot upgrade module '$module': cpanm failed (exit code $exit_code)\n";
            push @failed_modules, $module;
            next;
        }
    }

    if (@failed_modules) {
        [500, "One or more modules cannot be upgraded: ".join(", ", @failed_modules)];
    } else {
        [200, "OK"];
    }
}

1;
# ABSTRACT: Add --self-upgrade (-U) common option to upgrade program to the latest version on CPAN

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::CmdLineX::CommonOptions::SelfUpgrade - Add --self-upgrade (-U) common option to upgrade program to the latest version on CPAN

=head1 VERSION

This document describes version 0.003 of Perinci::CmdLineX::CommonOptions::SelfUpgrade (from Perl distribution Perinci-CmdLineX-CommonOptions-SelfUpgrade), released on 2019-08-07.

=head1 SYNOPSIS

 use Perinci::CmdLine::Lite; # or ::Classic, or ::Any
 use Perinci::CmdLineX::CommonOptions::SelfUpgrade;

 my $cmd = Perinci::CmdLine::Lite->new(...);
 Perinci::CmdLineX::CommonOptions::SelfUpgrade->apply_to_object($cmd);

 $cmd->run;

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-CmdLineX-CommonOptions-SelfUpgrade>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-CmdLineX-CommonOptions-SelfUpgrade>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-CmdLineX-CommonOptions-SelfUpgrade>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
