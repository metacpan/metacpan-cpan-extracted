package Pod::From::Acme::CPANModules;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-04-30'; # DATE
our $DIST = 'Pod-From-Acme-CPANModules'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(gen_pod_from_acme_cpanmodules);

our %SPEC;

sub _markdown_to_pod {
    require Markdown::To::POD;
    Markdown::To::POD::markdown_to_pod(shift);
}

$SPEC{gen_pod_from_acme_cpanmodules} = {
    v => 1.1,
    summary => 'Generate POD from an Acme::CPANModules::* module',
    description => <<'_',

Currently what this routine does:

* Fill the Description section from the CPANModules' list description

* Add an Included Modules section, containing the CPANModules' list entries

* Add a Feature Comparison Matrix section, if one or more entries have 'features'

_
    args_rels => {
        req_one => [qw/module author_lists/],
        choose_all => [qw/author_lists module_lists/],
    },
    args => {
        module => {
            name => 'Module name, e.g. Acme::CPANLists::PERLANCAR',
            schema => 'str*',
        },
        list => {
            summary => 'As an alternative to `module`, you can directly supply $LIST here',
            schema => 'hash*',
        },
    },
    result_naked => 1,
};
sub gen_pod_from_acme_cpanmodules {
    my %args = @_;

    my $res = {};

    my $list = $args{list};
    if (my $mod = $args{module}) {
        no strict 'refs';
        my $mod_pm = $mod; $mod_pm =~ s!::!/!g; $mod_pm .= ".pm";
        require $mod_pm;
        $list = ${"$mod\::LIST"};
        ref($list) eq 'HASH' or die "Module $mod doesn't defined \$LIST";
    }

    $res->{raw} = $list;

    if ($list) {
        $res->{pod} = {};

        {
            my $pod = '';
            $pod .= _markdown_to_pod($list->{description})."\n\n"
                if $list->{description} && $list->{description} =~ /\S/;
            $res->{pod}{DESCRIPTION} = $pod if $pod;
        }

        {
            my $pod = '';
            $pod .= "=over\n\n";
            for my $ent (@{ $list->{entries} }) {
                $pod .= "=item * L<$ent->{module}>".($ent->{summary} ? " - $ent->{summary}" : "")."\n\n";
                $pod .= _markdown_to_pod($ent->{description})."\n\n"
                    if $ent->{description} && $ent->{description} =~ /\S/;
                $pod .= "Rating: $ent->{rating}/10\n\n"
                    if $ent->{rating} && $ent->{rating} =~ /\A[1-9]\z/;
                $pod .= "Related modules: ".join(", ", map {"L<$_>"} @{ $ent->{related_modules} })."\n\n"
                    if $ent->{related_modules} && @{ $ent->{related_modules} };
                $pod .= "Alternate modules: ".join(", ", map {"L<$_>"} @{ $ent->{alternate_modules} })."\n\n"
                    if $ent->{alternate_modules} && @{ $ent->{alternate_modules} };
            }
            $pod .= "=back\n\n";
            $res->{pod}{'INCLUDED MODULES'} .= $pod;
        }

        {
            require Acme::CPANModulesUtil::FeatureMatrix;
            my $fres = Acme::CPANModulesUtil::FeatureMatrix::draw_feature_matrix(_list => $list);
            last if $fres->[0] != 200;
            $res->{pod}{'FEATURE COMPARISON MATRIX'} = $fres->[2];
        }

    }

    $res;
}

1;
# ABSTRACT: Generate POD from an Acme::CPANModules::* module

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::From::Acme::CPANModules - Generate POD from an Acme::CPANModules::* module

=head1 VERSION

This document describes version 0.004 of Pod::From::Acme::CPANModules (from Perl distribution Pod-From-Acme-CPANModules), released on 2020-04-30.

=head1 SYNOPSIS

 use Pod::From::Acme::CPANModules qw(gen_pod_from_acme_cpanmodules);

 my $res = gen_pod_from_acme_cpanmodules(module => 'Acme::CPANModules::PERLANCAR::Favorites');

=head1 FUNCTIONS


=head2 gen_pod_from_acme_cpanmodules

Usage:

 gen_pod_from_acme_cpanmodules(%args) -> any

Generate POD from an Acme::CPANModules::* module.

Currently what this routine does:

=over

=item * Fill the Description section from the CPANModules' list description

=item * Add an Included Modules section, containing the CPANModules' list entries

=item * Add a Feature Comparison Matrix section, if one or more entries have 'features'

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<list> => I<hash>

As an alternative to `module`, you can directly supply $LIST here.

=item * B<module> => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-From-Acme-CPANModules>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-From-Acme-CPANModules>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-From-Acme-CPANModules>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
