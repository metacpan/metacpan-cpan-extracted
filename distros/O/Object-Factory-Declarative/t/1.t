#! /usr/bin/perl

use Test;
BEGIN { plan tests => 2 };
use Object::Factory::Declarative;
ok(1); # If we made it this far, we're ok.

# The tests require a class or two...
my $obj = new Class1;
ok($obj->value == 19);

package Class1;
use Object::Factory::Declarative
(
    '--defaults' =>
    {
        constructor => 'build_it',
        method => 'apply_it',
        constructor_args =>
        {
            value => 4,
        },
        method_args =>
        {
            add => 3,
            mult => 4,
        },
    },
    new =>
    {
        method_args =>
        {
            add => 'three',
            mult => 'four',
        },
        constructor_args =>
        {
            value => 'four',
        },
    },
) ;

sub build_it
{
    my ($self, @args) = @_;
    my $class = ref $self || $self;
    my $rv = bless { }, $class;
    if(@args % 2 == 1)
    {
        $rv->{value} = shift @args;
    }
    else
    {
        %$rv = @args;
    }
    $rv;
}

sub apply_it
{
    my ($self, @args) = @_;
    die "apply_it: not a class method" unless ref $self;
    die "apply_it: expected a hash" if @args%2;
    my %a = @args;
    my $v = delete $a{div};
    if($v)
    {
        $self->{value} /= $v;
    }
    $v = delete $a{mult};
    if(defined $v)
    {
        $self->{value} *= $v;
    }
    $v = delete $a{sub};
    if(defined $v)
    {
        $self->{value} -= $v;
    }
    $v = delete $a{add};
    if(defined $v)
    {
        $self->{value} += $v;
    }
    if(%a)
    {
        $kv = join(' ', keys %a);
        die "apply_it: unrecognized keys $kv";
    }
    return $self->{value};
}

sub value
{
    my ($self) = @_;
    die "value: not a class method" unless ref $self;
    my $oval = $self->{value};
    if(@_>1)
    {
        $self->{value} = $_[1];
    }
    return $oval;
}

sub three
{
    return 3;
}

sub four
{
    return 4;
}
