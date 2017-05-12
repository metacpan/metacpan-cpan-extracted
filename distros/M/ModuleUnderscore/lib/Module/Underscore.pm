#
# This file is part of ModuleUnderscore
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Module::Underscore;

# ABSTRACT: convert module name to underscore string name and underscore string name to module name
use strict;
use warnings;
our $VERSION = '0.4';    # VERSION
use base 'Exporter';

our @EXPORT_OK = qw(
    underscore_to_module
    module_to_underscore
);

our %EXPORT_TAGS = ( 'all' => \@EXPORT_OK );

sub underscore_to_module {
    my ($underscore_string) = @_;
    my $module_string = lc($underscore_string);
    $module_string =~ s/[^a-z0-9]+(.?)/::\u$1/gx;
    $module_string = ucfirst($module_string);

    return $module_string;
}

sub module_to_underscore {
    my ($module_string) = @_;

    my $underscore_string = lc($module_string);
    $underscore_string =~ s/[^a-z0-9]+/_/gx;

    return $underscore_string;
}

1;

__END__

=pod

=head1 NAME

Module::Underscore - convert module name to underscore string name and underscore string name to module name

=head1 VERSION

version 0.4

=head1 METHODS

=head2 underscore_to_module

underscore_to_module($underscore_string)

Transform underscore string into module string
It will replace any caracters that is not [a-z0-9] into a "::" and uppercase the letter just after

=head2 module_to_underscore

module_to_underscore($module_string)

Transform module string into a underscore string
Any non word will be replace by "_"

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/ModuleUnderscore/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
