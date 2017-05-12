#
# This file is part of Module-Packaged-Generator
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;

package Module::Packaged::Generator::Driver::Mageia;
BEGIN {
  $Module::Packaged::Generator::Driver::Mageia::VERSION = '1.111930';
}
# ABSTRACT: mageia driver to fetch available modules

use Moose;

extends 'Module::Packaged::Generator::Driver::URPMI';


# -- initialization

sub _build__medias {
    my $self = shift;
    my $root = 'http://distrib-coffee.ipsl.jussieu.fr/pub/linux/Mageia/distrib/cauldron/x86_64/media';
    my @medias = qw{ core nonfree tainted };
    my $suffix = 'release/media_info/synthesis.hdlist.cz';
    return { map { $_ => "$root/$_/$suffix" } @medias };
}

1;


=pod

=head1 NAME

Module::Packaged::Generator::Driver::Mageia - mageia driver to fetch available modules

=head1 VERSION

version 1.111930

=head1 DESCRIPTION

This module is the L<Module::Packaged::Generator::Driver> for Mageia.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

