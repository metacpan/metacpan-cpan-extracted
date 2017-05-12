package Morpheus::Plugin::Simple;
{
  $Morpheus::Plugin::Simple::VERSION = '0.46';
}
use strict;
use warnings;

# ABSTRACT: plugin for simple static configuration

use Morpheus::Utils qw(normalize);

sub new ($$) {
    my ($class, $data) = @_;
    my $_data = $data;
    $data = sub { $_data } unless ref $data eq "CODE";
    bless {
        data => $data,
    } => $class;
}

sub list ($$) {
    return ('' => '');
}

sub get ($$) {
    my ($self, $token) = @_;
    die 'mystery' if $token;

    if (ref $self->{data} eq "CODE") {
        $self->{data} = normalize($self->{data}->());
    }

    return $self->{data};
}

1;

__END__
=pod

=head1 NAME

Morpheus::Plugin::Simple - plugin for simple static configuration

=head1 VERSION

version 0.46

=head1 AUTHOR

Andrei Mishchenko <druxa@yandex-team.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

