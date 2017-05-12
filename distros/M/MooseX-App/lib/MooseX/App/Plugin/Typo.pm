# ============================================================================
package MooseX::App::Plugin::Typo;
# ============================================================================

use 5.010;
use utf8;

use namespace::autoclean;
use Moose::Role;

sub plugin_metaroles {
    my ($self,$class) = @_;

    return {
        class   => ['MooseX::App::Plugin::Typo::Meta::Class'],
    }
}

1;

__END__

=encoding utf8

=head1 NAME

MooseX::App::Plugin::Typo - Handle typos in command names

=head1 SYNOPSIS

In your base class:

 package MyApp;
 use MooseX::App qw(Typo);

In your shell

 bash$ myapp pusl
 Ambiguous command 'pusl'
 Which command did you mean?
 * push
 * pull

=head1 DESCRIPTION

This plugin tries to handle typos in command names

=cut