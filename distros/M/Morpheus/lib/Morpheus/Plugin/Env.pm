package Morpheus::Plugin::Env;
{
  $Morpheus::Plugin::Env::VERSION = '0.46';
}
use strict;

# ABSTRACT: plugin which provides config values based on MORPHEUS env variable

use base qw(Morpheus::Plugin::Content);

sub list ($$) {
    my ($class, $ns) = @_;
    return ('' => 'MORPHEUS'); #TODO: configure like (ENV_VAR1 => '/key1/', ENV_VAR2 => '/key2/subkey/', ...)
}

sub content ($$) {
    my ($self, $token) = @_;
    die if $token ne 'MORPHEUS';
    return $ENV{MORPHEUS} if $ENV{MORPHEUS};
    return;
}

1;

__END__
=pod

=head1 NAME

Morpheus::Plugin::Env - plugin which provides config values based on MORPHEUS env variable

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

