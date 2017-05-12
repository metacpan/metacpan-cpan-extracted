# ============================================================================
package MooseX::App::Plugin::ConfigHome;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;
with qw(MooseX::App::Plugin::Config);

sub plugin_metaroles {
    my ($self,$class) = @_;

    return {
        class   => [
            'MooseX::App::Plugin::Config::Meta::Class',
            'MooseX::App::Plugin::ConfigHome::Meta::Class'
        ],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::ConfigHome - Config files in users home directory

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(ConfigHome);

=head1 DESCRIPTION

Works just like L<MooseX::App::Plugin::Config> but assumes that the config
file always resides in the user's home directory.

 ~/.${app-base}/config.(yml|xml|ini|...)

=cut