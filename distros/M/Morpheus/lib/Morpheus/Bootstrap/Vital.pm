package Morpheus::Bootstrap::Vital;
{
  $Morpheus::Bootstrap::Vital::VERSION = '0.46';
}
use strict;
use warnings;

# ABSTRACT: bootstrap enabling Overrides and Defaults functionality

use Morpheus::Overrides;
use Morpheus::Defaults;

use Morpheus::Plugin::Simple;

sub new {
    return Morpheus::Plugin::Simple->new({
        "morpheus" => {
            "plugins" => {

                Overrides => {
                    priority => 100,
                    object => 'Morpheus::Overrides',
                },
                Defaults => {
                    priority => 10,
                    object => 'Morpheus::Defaults',
                },
            }
        }
    });
}

1;


__END__
=pod

=head1 NAME

Morpheus::Bootstrap::Vital - bootstrap enabling Overrides and Defaults functionality

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

