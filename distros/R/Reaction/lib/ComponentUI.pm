package ComponentUI;

use strict;
use warnings;

use Catalyst::Runtime '5.80';

# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root
#                 directory

use Catalyst qw/ ConfigLoader Static::Simple I18N /;

our $VERSION = '0.01';

# Configure the application.
#
# Note that settings in ComponentUI.yml (or other external
# configuration file that you set up manually) take precedence
# over this when using ConfigLoader. Thus configuration
# details given here can function as a default configuration,
# with a external configuration file acting as an override for
# local deployment.

__PACKAGE__->config( name => 'ComponentUI' );

# Start the application
__PACKAGE__->setup;


=head1 NAME

ComponentUI - Catalyst based application

=head1 SYNOPSIS

    script/componentui_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<ComponentUI::Controller::Root>, L<Catalyst>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut

1;
