package Perinci::Sub::Util::PropertyModule;

our $DATE = '2016-05-15'; # DATE
our $VERSION = '0.46'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(
                       get_required_property_modules
               );

sub get_required_property_modules {
    no warnings 'once';
    no warnings 'redefine';

    my $meta = shift;

    # Here's how it works: first we reset the
    # $Sah::Schema::rinci::functio_meta::schema structure which contains the
    # list of supported properties. This is done by emptying it and
    # force-reloading the Sah::Schema::rinci::function_meta module, which is the
    # module responsible for declaring the structure.
    #
    # We also delete Perinci::Sub::Property::* entries from %INC to force-reload
    # them. We then record %INC at this point (1).
    #
    # Then we run $meta to normalize_function_data(), which will load additional
    # Perinci::Sub::Property::* modules that are needed.
    #
    # Finally we compare the previous content %INC (at point (1)) with the
    # current %INC. We now get the list of required Perinci::Sub::Property::*
    # modules.

    %Sah::Schema::rinci::function_meta::schema = ();
    delete $INC{'Sah/Schema/rinci/function_meta.pm'};
    require Sah::Schema::rinci::function_meta;

    for (grep {m!^Perinci/Sub/Property/!} keys %INC) {
        delete $INC{$_};
    }

    require Perinci::Sub::Normalize;

    my %inc_before = %INC;
    Perinci::Sub::Normalize::normalize_function_metadata($meta);

    my %res;
    for (keys %INC) {
        next unless m!^Perinci/Sub/Property/!;
        next if $inc_before{$_};
        $res{$_} = 1;
    }

    [map {my $mod = $_; $mod =~ s!/!::!g; $mod =~ s/\.pm\z//; $mod}
         sort keys %res];
}

1;
# ABSTRACT: Given a Rinci function metadata, find what property modules are required

__END__

=pod

=encoding UTF-8

=head1 NAME

Perinci::Sub::Util::PropertyModule - Given a Rinci function metadata, find what property modules are required

=head1 VERSION

This document describes version 0.46 of Perinci::Sub::Util::PropertyModule (from Perl distribution Perinci-Sub-Util-PropertyModule), released on 2016-05-15.

=head1 SYNOPSIS

 use Perinci::Sub::Util::PropertyModule qw(get_required_property_modules);

 my $meta = {
     v => 1.1,
     args => {
         foo => {
             ...
             'form.widget' => '...',
         },
         bar => {},
     },
     'cmdline.skip_format' => 1,
     result => {
         table => { ... },
     },
 };
 my $mods = get_required_property_modules($meta);

Result:

 ['Perinci::Sub::Property::arg::form',
  'Perinci::Sub::Property::cmdline',
  'Perinci::Sub::Property::result::table']

=head1 FUNCTIONS

=head2 get_required_property_modules($meta) => array

Since the Perinci framework is modular, additional properties can be introduced
by additional property modules (C<Perinci::Sub::Property::*>). These properties
might be experimental, 3rd party, etc.

This function can detect which modules are used.

This function can be used during distribution building to automatically add
those modules as prerequisites.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Sub-Util-PropertyModule>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Sub-Util-PropertyModule>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Sub-Util-PropertyModule>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
