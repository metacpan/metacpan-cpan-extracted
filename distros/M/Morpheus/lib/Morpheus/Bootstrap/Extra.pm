package Morpheus::Bootstrap::Extra;
{
  $Morpheus::Bootstrap::Extra::VERSION = '0.46';
}
use strict;
use warnings;

# ABSTRACT: extra plugins - Env and File

use Morpheus::Plugin::Env;
use Morpheus::Plugin::File;

use Morpheus::Plugin::Simple;

use Morpheus -defaults => {
    '/morpheus/plugin/file/options/path' => ['./etc/', '/etc/'],
};

sub new {
    return Morpheus::Plugin::Simple->new({
        "morpheus" => {
            "plugins" => {

                File => {
                    priority => 30,
                    object => Morpheus::Plugin::File->new(),
                },

                Env => {
                    priority => 70,
                    object => Morpheus::Plugin::Env->new(),
                }
            }
        }
    });
}

1;


__END__
=pod

=head1 NAME

Morpheus::Bootstrap::Extra - extra plugins - Env and File

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

