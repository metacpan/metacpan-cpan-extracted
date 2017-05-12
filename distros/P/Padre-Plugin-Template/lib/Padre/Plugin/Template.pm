package Padre::Plugin::Template;
use base 'Padre::Plugin';

use 5.008;
use strict;
use warnings;
use Padre::Plugin ();
use Padre::Wx     ();
use Padre::Plugin::Shell::Template;

our $VERSION = '0.1';

my $template_plugin;

#####################################################################
# Padre::Plugin Methods

sub plugin_name {
    'Template';
}

sub padre_interfaces {
    'Padre::Plugin' => 0.43;
}

sub menu_plugins_simple {
    my ($self) = @_;

    $template_plugin = Padre::Plugin::Shell::Template->new();
    my @template_menu = $template_plugin->plugin_menu();
    unless (@template_menu) {
        my $msg = Wx::gettext("Error loading template menu");
        @template_menu = ( $msg => undef );
    }
    '&Template' => [@template_menu];
}

1;

__END__

=pod

=head1 NAME

Padre::Plugin::Template - Use external tools with Padre

=head1 DESCRIPTION

Create new documents using user specified templates. Optionally, 
process the template with an external command as part of creating
the document.

See L<Padre::Plugin::Shell::Template> for details.

=head1 AUTHOR

Gregory Siems E<lt>gsiems@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Gregory Siems

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
