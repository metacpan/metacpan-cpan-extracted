#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;
use Safe::Caller;
use Test::More tests => 14;

{
    my $caller = Safe::Caller->new;

    my $self = Foo->new($caller);
    my @retval = $self->baz;

    is($retval[0], 'main', '$self->{package}->()');
    is($retval[1], File::Spec->catfile('t', 'called_from.t'), '$self->{filename}->()');
    is($retval[2], '14', '$self->{line}->()');
    is($retval[3], 'Base::baz', '$self->{subroutine}->()');
    is($retval[4], 'main', '$self->{pkg}->() (deprecated)');
    is($retval[5], File::Spec->catfile('t', 'called_from.t'), '$self->{file}->() (deprecated)');
    is($retval[6], 'Base::baz', '$self->{sub}->() (deprecated)');

    $self = Bar->new($caller);
    @retval = $self->baz;

    ok($retval[0], 'called_from_package()');
    ok($retval[1], 'called_from_filename()');
    ok($retval[2], 'called_from_line()');
    ok($retval[3], 'called_from_subroutine()');
    ok($retval[4], 'called_from_pkg() (deprecated)');
    ok($retval[5], 'called_from_file() (deprecated)');
    ok($retval[6], 'called_from_sub() (deprecated)');
}

package Base;

sub new
{
    my $class = shift;
    my ($caller) = @_;
    return bless { 'caller' => $caller }, $class;
}

sub baz
{
    $_[0]->bar;
}

package Foo;

use base qw(Base);

sub bar
{
    my $self = shift;
    return map { $self->{'caller'}->{$_}->() } qw(package filename line subroutine pkg file sub);
}

package Bar;

use base qw(Base);

sub bar
{
    my $self = shift;
    return ($self->{'caller'}->called_from_package('Base'),
            $self->{'caller'}->called_from_filename(File::Spec->catfile('t', 'called_from.t')),
            $self->{'caller'}->called_from_line(47),
            $self->{'caller'}->called_from_subroutine('Base::baz'),
            $self->{'caller'}->called_from_pkg('Base'),
            $self->{'caller'}->called_from_file(File::Spec->catfile('t', 'called_from.t')),
            $self->{'caller'}->called_from_sub('Base::baz'));
}
