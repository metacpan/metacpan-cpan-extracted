package Module::Load::DiffINC;

our $DATE = '2017-08-02'; # DATE
our $VERSION = '0.001'; # VERSION

sub import {
    my $pkg = shift;

    my %INC0 = %INC;
    for my $mod (@_) {
        (my $mod_pm = "$mod.pm") =~ s!::!/!g;
        require $mod_pm;
    }
    for my $k (sort keys %INC0) {
        next if exists $INC{$k};
        print "-$k\t$INC0{$k}\n";
    }
    for my $k (sort keys %INC) {
        next if exists $INC0{$k};
        print "+$k\t$INC{$k}\n";
    }
}

1;
# ABSTRACT: Load a module and show difference in %INC before vs after

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::Load::DiffINC - Load a module and show difference in %INC before vs after

=head1 VERSION

This document describes version 0.001 of Module::Load::DiffINC (from Perl distribution Module-Load-DiffINC), released on 2017-08-02.

=head1 SYNOPSIS

On the command-line:

 % perl -MModule::Load::DiffINC=Log::ger::Util -e1
 +Log/ger.pm     /home/ujang/perl5/perlbrew/perls/perl-5.26.0/lib/site_perl/5.26.0/Log/ger.pm
 +Log/ger/Heavy.pm       /home/ujang/perl5/perlbrew/perls/perl-5.26.0/lib/site_perl/5.26.0/Log/ger/Heavy.pm
 +Log/ger/Util.pm        /home/ujang/perl5/perlbrew/perls/perl-5.26.0/lib/site_perl/5.26.0/Log/ger/Util.pm
 +strict.pm      /home/ujang/perl5/perlbrew/perls/perl-5.26.0/lib/5.26.0/strict.pm
 +warnings.pm    /home/ujang/perl5/perlbrew/perls/perl-5.26.0/lib/5.26.0/warnings.pm

=head1 DESCRIPTION

This module will record C<%INC>, load (using C<require()>) all modules specified
in the import argument, then compare C<%INC> with the originally recorded before
loading the modules.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-Load-DiffINC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-Load-DiffINC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Module-Load-DiffINC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
