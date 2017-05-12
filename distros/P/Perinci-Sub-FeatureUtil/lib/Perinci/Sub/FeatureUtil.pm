package Perinci::Sub::FeatureUtil;

our $DATE = '2016-05-10'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       declare_function_feature
               );

sub declare_function_feature {
    my %args   = @_;
    my $name   = $args{name}   or die "Please specify feature's name";
    my $schema = $args{schema} or die "Please specify feature's schema";

    $name =~ /\A\w+\z/
        or die "Invalid syntax on feature's name, please use alphanums only";

    require Sah::Schema::rinci::function_meta;

    my $sch = $Sah::Schema::rinci::function_meta::schema;
    my $props = $sch->[1]{_prop}
        or die "BUG: Schema structure changed (1a)";
    $props->{features}{_keys}{$name}
        and die "Feature property '$name' already defined in schema";
    $props->{features}{_keys}{$name} = {};
}

1;
# ABSTRACT: Utility routines for Perinci::Sub::Feature::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::FeatureUtil - Utility routines for Perinci::Sub::Feature::* modules

=head1 VERSION

This document describes version 0.04 of Perinci::Sub::FeatureUtil (from Perl distribution Perinci-Sub-FeatureUtil), released on 2016-05-10.

=head1 SYNOPSIS

=head1 FUNCTIONS

=head2 declare_function_feature

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-FeatureUtil>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Perinci-Sub-FeatureUtil>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-FeatureUtil>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci>

Perinci::Sub::Feature::* modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
