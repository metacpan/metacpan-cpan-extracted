package Mojolicious::Plugin::Vparam::Filters;
use Mojo::Base -strict;
use Mojolicious::Plugin::Vparam::Common qw(load_class);
use List::MoreUtils                     qw(any);

sub min($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value should not be greater than %s", $_[1]
        unless $_[0] >= $_[1];
    return 0;
}

sub max($$) {
    my $e = load_class('Mojolicious::Plugin::Vparam::Numbers');
    die $e if $e;

    my $numeric = Mojolicious::Plugin::Vparam::Numbers::check_numeric( $_[0] );
    return $numeric if $numeric;

    return sprintf "Value should not be less than %s", $_[1]
        unless $_[0] <= $_[1];
    return 0;
}

sub range($$$) {
    my $min = min $_[0] => $_[1];
    return $min if $min;

    my $max = max $_[0] => $_[2];
    return $max if $max;

    return 0;
}

sub like($$) {
    return 'Value not defined'      unless defined $_[0];
    return 'Wrong format'           unless $_[0] =~ $_[1];
    return 0;
}

sub in($$) {
    die 'Not ArrayRef'              unless 'ARRAY' eq ref $_[1];

    return 'Value not defined'      unless defined $_[0];
    return 'Wrong value'            unless any {$_[0] eq $_} @{$_[1]};

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

sub register {
    my ($class, $self, $app, $conf) = @_;

    $app->vfilter(regexp      => sub { like     $_[1], $_[2] } );
    $app->vfilter(in          => sub { in       $_[1], $_[2] } );
    $app->vfilter(min         => sub { min      $_[1], $_[2] } );
    $app->vfilter(max         => sub { max      $_[1], $_[2] } );
    $app->vfilter(range       => sub { range    $_[1], $_[2][0], $_[2][1] } );
    $app->vfilter(size        => sub { size     $_[1], $_[2][0], $_[2][1] } );

    return;
}

1;
