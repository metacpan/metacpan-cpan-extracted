package Spork::Shlomify::Config;

use strict;
use warnings;

use Spork;

use Spork::Config -Base;

sub default_classes {
    return
        (
            $self->SUPER::default_classes(),
            config_class => 'Spork::Shlomify::Config',
            formatter_class => 'Spork::Shlomify::Formatter',
            slides_class => 'Spork::Shlomify::Slides',
        );
}

1;

=head1 NAME

Spork::Shlomif::Config - the configuration class for Spork::Shlomify

=head1 FUNCTIONS

=head2 $self->default_classes()

Initializes the default classes for Spork::Shlomify.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 LICENSE

MIT X11 License

=head1 SEE ALSO

L<Spork::Shlomify>

