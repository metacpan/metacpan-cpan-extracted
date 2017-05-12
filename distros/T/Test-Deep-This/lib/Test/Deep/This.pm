#!/usr/bin/perl
package Test::Deep::This;
BEGIN {
  $Test::Deep::This::VERSION = '1.00';
}
use strict;
use base qw(Exporter);
our @EXPORT = (qw/this/);

use Data::Dumper;
use Test::Deep;
use base qw(Test::Deep::Cmp);


sub this() {
    return __PACKAGE__->new({ code => sub { $_[0] }, msg => "<<this>>" });
}

sub init {
    my $self = shift;
    my ($data) = @_;

    $self->{$_} = $data->{$_} for keys %$data;
    return $self;

}

sub descend {
    my $self = shift;
    my ($val) = @_;

    return $self->{code}->($val);
}

sub renderExp {
    my $self = shift;
    return "$self";
}

sub _dump {
    my $dumper = Data::Dumper->new([@_]);
    $dumper->Terse(1)->Indent(0);
    return $dumper->Dump;
}

sub _upgrade {
    my $self = shift;
    return $self if ref $self eq 'Test::Deep::This';
    return __PACKAGE__->new({
        code => sub { return $self },
        msg => _dump($self),
    });
}

sub _operator1 {
    my ($op) = @_;
    return eval "sub { $op(\$_[0]) }";
}

sub _operator2 {
    my ($op) = @_;
    return eval "sub { \$_[0] $op \$_[1] }";
}

use overload '""' => sub { $_[0]->{msg} };

use overload
    map {
        my $op = $_;
        my $operator = _operator2($op);
  
        $op => sub {
            my ($left, $right, $reorder) = @_;
            ($left, $right) = ($right, $left) if $reorder;
            $left = _upgrade($left);
            $right = _upgrade($right);
            return __PACKAGE__->new({
                code => sub {
                    my $val = shift;
                    $operator->($left->{code}->($val), $right->{code}->($val));
                }, 
                # overload("") returns a string representation of a predicate
                # but overload(.) generates a delayed operator '.'
                msg => "("."$left".") $op ("."$right".")", #FIXME: track operator priorities and omit braces where possible
            });
        }
    } qw(> < >= <= == != <=> lt gt le ge eq ne cmp), qw(+ - * / % ** << >> x .);

use overload
    map {
        my $op = $_;
        my $operator = _operator1($op);
  
        $op => sub {
            my ($arg) = @_;
            return __PACKAGE__->new({
                code => sub {
                    my $val = shift;
                    $operator->($arg->{code}->($val));
                }, 
                msg => "$op ("."$arg".")",
            });
        }
    } qw(! neg atan2 cos sin exp abs log sqrt);

use overload 'fallback' => 0;

1;
