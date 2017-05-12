package Module::Install::Mousse;
use strict;
use warnings;

use Module::Install::Base;

use vars qw(@ISA);
BEGIN { @ISA = 'Module::Install::Base' }

# Make from Mousse (as in Chocolate)
sub use_mousse {
    my $self = shift;
    return unless $self->is_admin;
    my $module = shift
        or die "use_mousse requires the name of a target module";
    my $output_path = $module;
    $output_path =~ s/::/\//g;
    $output_path = "lib/$output_path.pm";
    require Mousse::Maker;
    Mousse::Maker::make_from_mousse($module, $output_path);
}

# Make from Mouse (as in Mickey)
sub use_mousse_dev {
    my $self = shift;
    return unless $self->is_admin;
    my $module = shift
        or die "use_mousse_dev requires the name of a target module";
    my $output_path = $module;
    $output_path =~ s/::/\//g;
    $output_path = "lib/$output_path.pm";
    require Mousse::Maker;
    Mousse::Maker::make_from_mouse($module, $output_path);
}

1;

=encoding utf8

=head1 NAME

Module::Install::Mousse - Module::Install Support for Mousse

=head1 SYNOPSIS

    use inc::Module::Install;

    name     'Chocolate';
    all_from 'lib/Chocolate.pm';

    use_mousse 'Chocolate::Mousse';

    WriteAll;

=head1 DESCRIPTION

This module copies Mousse.pm as your module distibution's OO base module.
See L<Mousse> for full details.

Now you can get full Mousse OO support for your module with no external
dependency on Mousse.

Just add this line to your Makefile.PL:

    use_mousse 'Your::Module::OO';

That's it. Really. Now Mousse is bundled into your module under the
name C<Your::Module::OO>, there is no burden on the person installing
your module.

=head1 AUTHOR

Ingy döt Net <ingy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2010. Ingy döt Net.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
