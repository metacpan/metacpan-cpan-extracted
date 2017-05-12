package Padre::Plugin::Filter;
use base 'Padre::Plugin';

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();
use Padre::Wx     ();
use Padre::Plugin::Shell::Filter;

our $VERSION = '0.1';

my $filter_plugin;

#####################################################################
# Padre::Plugin Methods
sub plugin_name {
    'Filter';
}

sub padre_interfaces {
    'Padre::Plugin' => 0.43;
}

sub menu_plugins_simple {
    my ($self) = @_;

    $filter_plugin = Padre::Plugin::Shell::Filter->new();
    my @filter_menu = $filter_plugin->plugin_menu();
    unless (@filter_menu) {
        my $msg = Wx::gettext("Error loading filter menu");
        @filter_menu = ( $msg => undef );
    }
    '&Filter' => [@filter_menu];
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Filter - Unix-like external filters in Padre.

=head1 DESCRIPTION

This plug-in enables the use of Unix-like external filtering 
commands/scripts to transform part or all of the current document.

The output of the filter can either replace the input, be appended to 
the input, or be inserted into a new document.

Unlike Unix filters, the filter mechanism in this plug-in 
is designed to use input and output files rather than STDIN and STDOUT. 

See L<Padre::Plugin::Shell::Filter> for details.

=head1 ENVIRONMENT VARIABLES

To provide additional information for the plugin, various 
environment variables are set prior to performing the plugin 
action. These environment variables are covered in the 
L<Padre::Plugin::Shell::Base> documentation.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
