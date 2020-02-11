package Pod::Weaver::Plugin::Data::Sah::Filter;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-10'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Data-Sah-Filter'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Data::Dmp;
use File::Temp;

sub _process_filter_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $zilla = $input->{zilla};

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    my ($rule_cat, $rule_desc, $meta);
    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;

        {
            no strict 'refs';
            $meta = $package->meta;
        }
        $package =~ /\AData::Sah::Filter::\w+::(\w+)::(\w+)\z/
            or $self->log_fatal("Invalid module name $package, please use Data::Sah::Filter::<LANG>::<CATEGORY>::<DESCRIPTION>");
        $rule_cat  = $1;
        $rule_desc = $2;
    }

    # add Synopsis section
    {
        my @pod;
        push @pod, "Use in Sah schema's C<prefilters> (or C<postfilters>) clause:\n\n",
            " ", dmp([$meta->{target_type} // "str", "prefilters" => ["$rule_cat\::$rule_desc"]]), "\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'SYNOPSIS',
            {
                after_section => ['VERSION', 'NAME'],
                before_section => 'DESCRIPTION',
                ignore => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub _list_my_filter_modules {
    my ($self, $input) = @_;

    my @res;
    for my $file (@{ $input->{zilla}->files }) {
        my $name = $file->name;
        next unless $name =~ m!^lib/Data/Sah/Filter/!;
        $name =~ s!^lib/!!; $name =~ s/\.pm$//; $name =~ s!/!::!g;
        push @res, $name;
    }
    @res;
}

sub _process_filterbundle_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    # add list of Bencher::Scenario::* modules to Description
    {
        my @pod;
        my @filter_mods = $self->_list_my_filter_modules($input);
        push @pod, "This distribution contains the following L<Sah> filter rule modules:\n\n";
        push @pod, "=over\n\n";
        push @pod, "=item * L<$_>\n\n" for @filter_mods;
        push @pod, "=back\n\n";

        $self->add_text_to_section(
            $document, join("", @pod), 'DESCRIPTION',
            {
                after_section => ['SYNOPSIS'],
                top => 1,
            });
    }

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(Data/Sah/Filter/.+)\.pm$!) {
        {
            $package = $1 // $2;
            $package =~ s!/!::!g;
            $self->_process_filter_module($document, $input, $package);
        }
    }
    if ($filename =~ m!^lib/(Data/Sah/FilterBundle/.+)\.pm$!) {
        {
            # since this PW plugin might be called more than once, we avoid
            # duplicate processing via a state variable
            state %mem;
            last if $mem{$filename}++;
            $package = $1;
            $package =~ s!/!::!g;
            $self->_process_filterbundle_module($document, $input, $package);
        }
    }
}

1;
# ABSTRACT: Plugin to use when building Data::Sah::Filter::* or Data::Sah::FilterBundle::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Data::Sah::Filter - Plugin to use when building Data::Sah::Filter::* or Data::Sah::FilterBundle::* distribution

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::Data::Sah::Filter (from Perl distribution Pod-Weaver-Plugin-Data-Sah-Filter), released on 2020-02-10.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Data::Sah::Filter]

=head1 DESCRIPTION

This plugin is to be used when building C<Data::Sah::Filter::*> or
C<Data::Sah::FilterBundle::*> distribution. Currently it does the following:

For each C<lib/Data/Sah/Filter/*> module file:

=over

=item * Add a Synopsis section (if doesn't already exist) containing an example on how to use the Sah filter rule module in a Sah schema

=back

For each C<lib/Data/Sah/FilterBundle/*> module file:

=over

=item * Add list of filter rule modules at the beginning of Description section

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Filter>

L<Dist::Zilla::Plugin::Data::Sah::Filter>

L<Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
