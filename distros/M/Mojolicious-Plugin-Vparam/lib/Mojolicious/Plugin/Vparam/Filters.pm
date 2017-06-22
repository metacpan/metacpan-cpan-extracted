package Mojolicious::Plugin::Vparam::Filters;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(load_class);
use List::MoreUtils                     qw(any);

sub like($$) {
    return 'Value not defined'      unless defined $_[0];
    return 'Wrong format'           unless $_[0] =~ $_[1];
    return 0;
}

sub in($$) {
    my ($str, $list) = @_;

    die 'Not ArrayRef'              unless 'ARRAY' eq ref $list;

    return 'Value not defined'      unless defined $str;
    return 'Wrong value'
        unless any {defined($_) && $str eq $_} @$list;

    return 0;
}

sub size($$$) {
    my ($value, $min, $max) = @_;
    return 'Value is not defined'       unless defined $value;
    return 'Value is not set'           unless length  $value;
    return sprintf "Value should not be less than %s", $min
        unless $min <= length $value;
    return sprintf "Value should not be longer than %s", $max
        unless $max >= length $value;
    return 0;
}

sub num_ge($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value should not be greater than %s", $_[1]
        unless $_[0] >= $_[1];
    return 0;
}

sub num_le($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value should not be less than %s", $_[1]
        unless $_[0] <= $_[1];
    return 0;
}

sub num_eq($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value not equal"    unless $_[0] == $_[1];
    return 0;
}

sub num_ne($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value equal"        unless $_[0] != $_[1];
    return 0;
}

sub num_range($$$) {
    my $min = num_ge $_[0] => $_[1];
    return $min if $min;

    my $max = num_le $_[0] => $_[2];
    return $max if $max;

    return 0;
}

sub str_lt($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value should not be less than %s", $_[1]
        unless $_[0] lt $_[1];
    return 0;
}

sub str_gt($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value should not be greater than %s", $_[1]
        unless $_[0] gt $_[1];
    return 0;
}

sub str_le($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value should not be less or equal than %s", $_[1]
        unless $_[0] le $_[1];
    return 0;
}

sub str_ge($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value should not be greater or equal than %s", $_[1]
        unless $_[0] ge $_[1];
    return 0;
}

sub str_cmp($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value not equal"    if $_[0] cmp $_[1];
    return 0;
}

sub str_eq($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value not equal"    unless $_[0] eq $_[1];
    return 0;
}

sub str_ne($$) {
    return 'Value is not defined'       unless defined $_[0];
    return sprintf "Value equal"        unless $_[0] ne $_[1];
    return 0;
}

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vfilter(regexp      => sub { like     $_[1], $_[2] } );
    $app->vfilter(in          => sub { in       $_[1], $_[2] } );
    $app->vfilter(size        => sub { size     $_[1], $_[2][0], $_[2][1] } );

    $app->vfilter(min         => sub { num_ge   $_[1], $_[2] } );
    $app->vfilter(max         => sub { num_le   $_[1], $_[2] } );
    $app->vfilter(equal       => sub { num_eq   $_[1], $_[2] } );
    $app->vfilter('not'       => sub { num_ne   $_[1], $_[2] } );
    $app->vfilter(range       => sub { num_range $_[1], $_[2][0], $_[2][1] } );

    $app->vfilter('lt'        => sub { str_lt   $_[1], $_[2] } );
    $app->vfilter('gt'        => sub { str_gt   $_[1], $_[2] } );
    $app->vfilter('le'        => sub { str_le   $_[1], $_[2] } );
    $app->vfilter('ge'        => sub { str_ge   $_[1], $_[2] } );
    $app->vfilter('cmp'       => sub { str_cmp  $_[1], $_[2] } );
    $app->vfilter('eq'        => sub { str_eq   $_[1], $_[2] } );
    $app->vfilter('ne'        => sub { str_ne   $_[1], $_[2] } );

    return;
}

1;
