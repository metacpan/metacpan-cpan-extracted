package Test::WWW::Selenium;
use strict;
use warnings;
use base 'Exporter';
use Test::More;

our @EXPORT_OK = '$SEL';

our $SEL; # singleton

sub new {
    my ($class, %opts) = @_;
    if ($SEL) {
        $SEL->{args} = \%opts;
        return $SEL;
    }
    $SEL = { args => \%opts };
    bless $SEL, $class;
    return $SEL;
}

sub set_return_value {
    my ($self, $name, $return) = @_;
    push @{$self->{return}{$name}}, $return;
}

sub method_args_ok {
    my ($self, $name, $expected) = @_;
    my $actual = shift @{$self->{$name}};
    is_deeply $actual, $expected;
}

sub empty_ok {
    my $self = shift;
    my $ignore_extra = shift;
    for my $k (keys %$self) {
        next if $k eq 'return' or $k eq 'args';
        next if ref($self->{$k}) eq 'ARRAY' and @{$self->{$k}} == 0;
        if ($ignore_extra) {
            delete $self->{$k};
        }
        else {
            ok 0, "extra call to $k - " . ref($self->{$k});
        }
    }
    $self->{return} = {};
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $name = $AUTOLOAD;
    $name =~ s/.+:://;
    return if $name eq 'DESTROY';

    my ($self, $opt1, $opt2) = @_;
    if ($opt2) {
        push @{$self->{$name}}, [$opt1, $opt2];
    }
    else {
        push @{$self->{$name}}, $opt1;
    }

    if ($self->{return}{$name}) {
        return shift @{$self->{return}{$name}};
    }
    return;
}

1;
