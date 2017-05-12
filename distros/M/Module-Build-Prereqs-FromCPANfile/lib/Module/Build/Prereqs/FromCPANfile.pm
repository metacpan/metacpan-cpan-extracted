package Module::Build::Prereqs::FromCPANfile;
use strict;
use warnings;
use Module::CPANfile 1.0000;
use CPAN::Meta::Prereqs 2.132830;
use Exporter qw(import);
use version 0.80;

our $VERSION = "0.02";

our @EXPORT = our @EXPORT_OK = qw(mb_prereqs_from_cpanfile);

sub mb_prereqs_from_cpanfile {
    my (%args) = @_;
    my $version = $args{version};
    $version = _get_mb_version() if not defined $version;
    my $cpanfile_path = $args{cpanfile};
    $cpanfile_path = "cpanfile" if not defined $cpanfile_path;

    my $file = Module::CPANfile->load($cpanfile_path);
    return _prereqs_to_mb($file->prereqs, $version);
}

sub _get_mb_version {
    require Module::Build;
    return $Module::Build::VERSION;
}

sub _prereqs_to_mb {
    my ($prereqs, $mb_version_str) = @_;
    my %result = ();
    my $mb_version = version->parse($mb_version_str);
    _put_result($prereqs->requirements_for("runtime", "requires"), \%result, "requires");
    _put_result($prereqs->requirements_for("runtime", "recommends"), \%result, "recommends");
    _put_result($prereqs->requirements_for("runtime", "conflicts"), \%result, "conflicts");
    if($mb_version < version->parse("0.30")) {
        _put_result($prereqs->merged_requirements(["configure", "build", "test"], ["requires"]),
                    \%result, "build_requires");
    }elsif($mb_version < version->parse("0.4004")) {
        _put_result($prereqs->merged_requirements(["build", "test"], ["requires"]),
                    \%result, "build_requires");
        _put_result($prereqs->requirements_for("configure", "requires"), \%result, "configure_requires");
    }else {
        foreach my $phase (qw(configure build test)) {
            _put_result($prereqs->requirements_for($phase, "requires"), \%result, "${phase}_requires");
        }
    }
    return %result;
}

sub _put_result {
    my ($requirements, $result_hashref, $result_key) = @_;
    my $reqs_hashref = $requirements->as_string_hash;
    if(keys %$reqs_hashref) {
        $result_hashref->{$result_key} = $reqs_hashref;
    }
}


1;
__END__

=pod

=head1 NAME

Module::Build::Prereqs::FromCPANfile - construct prereq parameters of Module::Build from cpanfile

=head1 SYNOPSIS

    use Module::Build;
    use Module::Build::Prereqs::FromCPANfile;
    
    Module::Build->new(
        ...,
        mb_prereqs_from_cpanfile()
    )->create_build_script();


=head1 DESCRIPTION

This simple module reads L<cpanfile> and converts its content into
valid prereq parameters for C<new()> method of L<Module::Build>.

Currently it does not support "optional features" specification (See L<cpanfile/feature>).

=head1 EXPORTED FUNCTION

The following function is exported by default.

=head2 %prereq_params = mb_prereqs_from_cpanfile(%args)

Reads L<cpanfile>, parses its content and returns corresponding C<%prereq_params> for L<Module::Build>.

Fields in C<%args> are:

=over

=item C<version> => VERSION_STR (optional, default: $Module::Build::VERSION)

Version number of the target L<Module::Build>.

If omitted, L<Module::Build> is loaded and C<$Module::Build::VERSION> is used.

=item C<cpanfile> => FILEPATH (optional, default: "cpanfile")

File path to the cpanfile to be loaded.

If omitted, it loads "cpanfile" in the current directory.

=back


=head1 SEE ALSO

=over

=item L<Module::Build>

=item L<Module::Build::Pluggable::CPANfile>

Maybe this module does the same job better, but it has heavier dependency.

=back

=head1 REPOSITORY

L<https://github.com/debug-ito/Module-Build-Prereqs-FromCPANfile>

=head1 BUGS AND FEATURE REQUESTS

Please report bugs and feature requests to my Github issues
L<https://github.com/debug-ito/Module-Build-Prereqs-FromCPANfile/issues>.

Although I prefer Github, non-Github users can use CPAN RT
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Build-Prereqs-FromCPANfile>.
Please send email to C<bug-Module-Build-Prereqs-FromCPANfile at rt.cpan.org> to report bugs
if you do not have CPAN RT account.


=head1 AUTHOR
 
Toshio Ito, C<< <toshioito at cpan.org> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

