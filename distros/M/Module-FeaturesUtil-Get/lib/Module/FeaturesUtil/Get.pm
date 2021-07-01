package Module::FeaturesUtil::Get;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-02-24'; # DATE
our $DIST = 'Module-FeaturesUtil-Get'; # DIST
our $VERSION = '0.001'; # VERSION

use strict 'subs', 'vars';
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(
                       get_features_decl
                       get_feature_val
                       module_declares_feature
               );

sub get_features_decl {
    my $mod = shift;

    # first, try to get features declaration from MODNAME::_ModuleFeatures's %FEATURES
    my $proxymod = "$mod\::_ModuleFeatures";
    (my $proxymodpm = "$proxymod.pm") =~ s!::!/!g;
    my $features_decl = \%{"$proxymod\::FEATURES"};
    return $features_decl if scalar keys %$features_decl;

    # second, try to get features declaration from MODNAME %FEATURES
    $features_decl = \%{"$mod\::FEATURES"};
    return $features_decl; # if scalar keys %$features_decl;

    # XXX compare the two if both declarations exist
}

sub get_feature_val {
    my ($module_name, $feature_set_name, $feature_name) = @_;

    my $features_decl = get_features_decl($module_name);
    return undef unless $features_decl->{features}{$feature_set_name};

    my $val0 = $features_decl->{features}{$feature_set_name}{$feature_name};
    return ref $val0 eq 'HASH' ? $val0->{value} : $val0;
}

sub module_declares_feature {
    my ($module_name, $feature_set_name, $feature_name) = @_;

    my $features_decl = get_features_decl($module_name);
    return undef unless $features_decl->{features}{$feature_set_name};

    exists $features_decl->{features}{$feature_set_name}{$feature_name};
}

1;
# ABSTRACT: Get a feature

__END__

=pod

=encoding UTF-8

=head1 NAME

Module::FeaturesUtil::Get - Get a feature

=head1 VERSION

This document describes version 0.001 of Module::FeaturesUtil::Get (from Perl distribution Module-FeaturesUtil-Get), released on 2021-02-24.

=head1 SYNOPSIS

 use Module::FeaturesUtil::Get qw(
     get_features_decl
     get_feature_val
     module_declares_feature
 );

 # Get features declaration:
 my $features_decl = get_features_decl('Text::Table::Tiny');

 # Get value of a feature:
 if (!get_feature_val('Text::Table::Tiny', 'TextTable', 'align_cell_containing_color_codes')) {
     # strip color codes first
     for ($str1, $str2) { s/\e\[[0-9;]+m/sg }
 }
 push @rows, [$str1, $str2];

 # Check whether a module declares a feature:
 if (module_declares_feature('Text::Table::Tiny', 'TextTable', 'speed')) {
    ...
 }

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 get_features_decl

Usage:

 my $features_decl = get_features_decl($module_name);

Features declaration is first looked up from proxy module's C<%FEATURES> package
variable, then from the module's C<%FEATURES>. Proxy module is
C<$module_name>I<::_ModuleFeatures>. You have to load the modules yourself; this
routine will not load the modules for you.

This module will also NOT check the validity of features declaration.

=head2 get_feature_val

Usage:

 my $val = get_feature_val($module_name, $feature_set_name, $feature_name);

Example:

 if (!get_feature_val('Text::Table::Tiny', 'TextTable', 'align_cell_containing_color_codes')) {
     # strip color codes first
     for ($str1, $str2) { s/\e\[[0-9;]+m/sg }
 }
 push @rows, [$str1, $str2];

Get the value of a feature from a module's features declaration.

Features declaration is retrieved using L</get_features_decl>.

This routine will also NOT check the feature set specification.

=head2 module_declares_feature

Usage:

 my $bool = module_declares_feature($module_name, $feature_set_name, $feature_name);

Check whether module declares a feature.

Features declaration is retrieved using L</get_features_decl>.

This routine will also NOT check the feature set specification.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Module-FeaturesUtil-Get>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Module-FeaturesUtil-Get>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-Module-FeaturesUtil-Get/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Module::Features>

This module does not check whether a feature declaration is valid or whether a
feature set specification is valid. To do that, use
L<Module::FeaturesUtil::Check>'s C<check_features_decl> and
C<check_feature_set_spec>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
