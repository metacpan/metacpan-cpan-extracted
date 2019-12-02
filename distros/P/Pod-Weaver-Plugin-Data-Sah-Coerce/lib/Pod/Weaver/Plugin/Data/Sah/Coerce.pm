package Pod::Weaver::Plugin::Data::Sah::Coerce;

# AUTHOR
our $DATE = '2019-11-28'; # DATE
our $DIST = 'Pod-Weaver-Plugin-Data-Sah-Coerce'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

use Data::Dmp;
use File::Temp;

sub _process_coerce_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $zilla = $input->{zilla};

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    my ($from_type, $to_type, $rule_desc);
    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;

        $package =~ /\AData::Sah::Coerce::\w+::To_(\w+)::From_(\w+)::(\w+)\z/
            or $self->log_fatal("Invalid module name $package, please use Data::Sah::Coerce::<LANG>::To_<TARGET_TYPE>::From_<SOURCE_TYPE>::<DESC>");
        $to_type = $1;
        $from_type = $2;
        $rule_desc = $3;
    }

    # add Synopsis section
    {
        my @pod;
        push @pod, "To use in a Sah schema:\n\n",
            " ", dmp([$to_type, {"x.perl.coerce_rules" => ["From_$from_type\::$rule_desc"]}]), "\n\n";

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

sub _list_my_coerce_modules {
    my ($self, $input) = @_;

    my @res;
    for my $file (@{ $input->{zilla}->files }) {
        my $name = $file->name;
        next unless $name =~ m!^lib/Data/Sah/Coerce/!;
        $name =~ s!^lib/!!; $name =~ s/\.pm$//; $name =~ s!/!::!g;
        push @res, $name;
    }
    @res;
}

sub _process_coercebundle_module {
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
        my @coerce_mods = $self->_list_my_coerce_modules($input);
        push @pod, "This distribution contains the following L<Sah> coerce rule modules:\n\n";
        push @pod, "=over\n\n";
        push @pod, "=item * L<$_>\n\n" for @coerce_mods;
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
    if ($filename =~ m!^lib/(Data/Sah/Coerce/.+)\.pm$!) {
        {
            $package = $1 // $2;
            $package =~ s!/!::!g;
            $self->_process_coerce_module($document, $input, $package);
        }
    }
    if ($filename =~ m!^lib/(Data/Sah/CoerceBundle/.+)\.pm$!) {
        {
            # since this PW plugin might be called more than once, we avoid
            # duplicate processing via a state variable
            state %mem;
            last if $mem{$filename}++;
            $package = $1;
            $package =~ s!/!::!g;
            $self->_process_coercebundle_module($document, $input, $package);
        }
    }
}

1;
# ABSTRACT: Plugin to use when building Data::Sah::Coerce::* or Data::Sah::CoerceBundle::* distribution

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::Plugin::Data::Sah::Coerce - Plugin to use when building Data::Sah::Coerce::* or Data::Sah::CoerceBundle::* distribution

=head1 VERSION

This document describes version 0.001 of Pod::Weaver::Plugin::Data::Sah::Coerce (from Perl distribution Pod-Weaver-Plugin-Data-Sah-Coerce), released on 2019-11-28.

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Data::Sah::Coerce]

=head1 DESCRIPTION

This plugin is to be used when building C<Data::Sah::Coerce::*> or
C<Data::Sah::CoerceBundle::*> distribution. Currently it does the following:

For each C<lib/Data/Sah/Coerce/*> module file:

=over

=item * Add a Synopsis section (if doesn't already exist) containing an example on how to use the Sah coerce rule module in a Sah schema

=back

For each C<lib/Data/Sah/CoerceBundle/*> module file:

=over

=item * Add list of coerce rule modules at the beginning of Description section

=back

=for Pod::Coverage .*

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Pod-Weaver-Plugin-Data-Sah-Coerce>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Pod-Weaver-Plugin-Data-Sah-Coerce>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Pod-Weaver-Plugin-Data-Sah-Coerce>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Sah::Coerce>

L<Dist::Zilla::Plugin::Data::Sah::Coerce>

L<Sah>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
