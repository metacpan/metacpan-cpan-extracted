#!perl
#PODNAME: Raisin::Plugin
#ABSTRACT: Base class for Raisin plugins

use strict;
use warnings;

package Raisin::Plugin;
$Raisin::Plugin::VERSION = '0.93';
use Carp;

sub new {
    my ($class, $app) = @_;
    my $self = bless {}, $class;
    $self->{app} = $app;
    $self;
}

sub app { shift->{app} }

sub build {
    my ($self, %args) = @_;
}

sub register {
    my ($self, %items) = @_;

    while (my ($name, $item) = each %items) {
        no strict 'refs';
        #no warnings 'redefine';

        my $class = ref $self->app;
        my $caller = $self->app->{caller};

        my $glob = "${class}::${name}";
        my $app_glob = $caller ? "${caller}::${name}" : undef;

        if ($self->app->can($name)) {
            croak "Redefining of $glob not allowed";
        }

        if (ref $item eq 'CODE') {
            *{$glob} = $item;
            *{$app_glob} = $item if $app_glob;
        }
        else {
            $self->app->{$name} = $item;
            *{$glob} = sub { shift->{$name} };
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Raisin::Plugin - Base class for Raisin plugins

=head1 VERSION

version 0.93

=head1 SYNOPSIS

    package Raisin::Plugin::Hello;
    use parent 'Raisin::Plugin';

    sub build {
        my ($self, %args) = @_;
        $self->register(hello => sub { print 'Hello!' });
    }

=head1 DESCRIPTION

Provides the base class for creating Raisin plugins.

=head1 METHODS

=head3 build

Main method for each plugin.

=head3 register

Registers one or many methods into the application.

    $self->register(hello => sub { print 'Hello!' });

=head1 AUTHOR

Artur Khabibullin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Artur Khabibullin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
