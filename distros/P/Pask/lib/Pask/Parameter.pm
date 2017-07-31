package Pask::Parameter;

use Carp;
use Getopt::Long;
use Scalar::Util qw(looks_like_number);
use POSIX qw(strftime);

use Pask::Container;
use Pask::Storage;

my ($re_date, $re_time) = ("\\d{4}-\\d{1,2}-\\d{1,2}", "\\d{1,2}:\\d{1,2}:\\d{1,2}");
my ($format_date, $format_time) = ("%Y-%m-%d", "%H:%M:%S");

my $types = {
    "date" => {
        "verify" => sub { &verfify_datetime($re_date, shift) },
        "generate" => sub { &generate_datetime($format_date, shift) }
    },
    "time" => {
        "verify" => sub { &verfify_datetime($re_time, shift) },
        "generate" => sub { &generate_datetime($format_time, shift) }
    },
    "datetime" => {
        "verify" => sub { &verfify_datetime("$re_date $re_time", shift)},
        "generate" => sub { &generate_datetime("$format_date $format_time", shift) }
    },
    "number" => {
        "verify" => sub { looks_like_number shift },
        "generate" => sub { "$_[0]" }
    },
    "string" => {
        "verify" => sub { defined shift },
        "generate" => sub { "$_[0]" }
    }
};

sub generate_datetime {
    my @now = localtime;
    my ($format, $target) = (shift, shift);
    return undef unless $target;
    Pask::Storage::error "Date and Time Type can not unsupport function $target!" unless grep /^$target$/, ("now", "yesterday", "tomorrow");
    --$now[3] if $target eq "yesterday";
    ++$now[3] if $target eq "tomorrow";
    strftime $format, @now;
}

sub verfify_datetime {
    my ($format, $value) = (shift, shift);
    grep /^$format$/, $value;
}

sub add {
    my ($name, $parameter) = @_;
    Carp::confess "parameter need a task name!" unless $name;
    Carp::confess "parameter can not be null!" unless $parameter;
    Pask::Container::set_parameter $name, $parameter;
}

sub from {
    my $argv;
    GetOptions(shift . "=s" => \$argv);
    $argv;
}

sub is {
    my ($type, $food) = (shift, shift);
    Pask::Storage::error "Type [$type] is unvalid!" unless grep /^$type$/, keys %$types;
    $types->{$type}{"generate"}($food);
}

sub is_delicious {
    my ($type, $name, $food) = (shift, shift, shift);
    return ($type, $name, $food) unless $food;
    Pask::Storage::error "Type [$type] is unvalid!" unless grep /^$type$/, keys %$types;
    Pask::Storage::error "Parameter [$name] value is [$food] and it is not type [$type]!" unless $types->{$type}{"verify"}($food);
}

sub is_satisfied {
    my ($map, $deps, $fn, $name) = ({}, shift);
    $fn = sub {
        my $dep = shift;
        foreach (@{$dep}) {
            Pask::Storage::error "Argument Dependency Conflect!" if (grep /^$name$/, @{$map->{$_}});
            &$fn($_)
        }
    };
    foreach (keys %$deps) {
        $name = $_;
        Pask::Storage::error "Argument Dependency Conflect!" if (grep /^$name$/, @{$deps->{$_}{"dependency"}});
        &$fn($deps->{$_}{"dependency"});
        $map->{$_} = $deps->{$_}{"dependency"};
    }
}

sub cook {
    my ($map, $i, $k, $v, $fn) = ({}, 1);
    my ($materials, $foods, $recipe) = ({}, {}, shift);
    $recipe->{""}{"dependency"} = [keys %$recipe];
    $fn = sub {
        my $entry = shift;
        foreach (@{$recipe->{$entry}{"dependency"}}) {
            unless ($map->{$_}) {
                &$fn($_);
                $map->{$_} = $i++;
                $materials->{$_} = from $recipe->{$_}{"argument"} if $recipe->{$_}{"argument"};
                $materials->{$_} = is $recipe->{$_}{"type"}, $recipe->{$_}{"default"} unless $materials->{$_};
                $foods->{$_} = $materials->{$_};
            }
        }
    };
    &$fn($_) foreach keys %$recipe;
    foreach my $key (sort { $map->{$a} <=> $map->{$b} } keys %$map) {
        foreach (@{$recipe->{$key}{"exec"}}) {
            ($k, $v) = %$_;
            $foods->{$key} = &$v($materials) if $k eq "fn";
            $foods->{$key} = &$v($foods, $materials) if $k eq "todo";
        }
        Pask::Storage::error "Parameter [", $key, "] can not be null!" unless $recipe->{$key}{"nullable"} || $foods->{$key};
        is_delicious $recipe->{$key}{"type"}, $key, $foods->{$key};
    }
    $foods;
}

sub make_recipe {
    my ($recipe, $k, $v) = ({"type" => "string", "exec" => []});
    my ($name, $materials) = (shift, shift);
    foreach (@$materials) {
        unless (ref $_) {
            $_ = {"argument" => $name} if $_ eq "argument";
            $_ = {"nullable" => 1} if $_ eq "nullable";
        }
        ($k, $v) = %$_;
        $recipe->{$k} = $v if (grep /^$k$/, ("type", "argument", "default", "nullable", "dependency"));
        push @{$recipe->{"exec"}}, {$k => $v} if $k eq "fn" or $k eq "todo";
    }
    $recipe;
}

sub parse {
    my ($recipe, $materials, $foods) = ({});
    my $args = shift;
    $recipe->{$_} = make_recipe $_, $args->{$_} foreach keys %$args;
    is_satisfied $recipe;
    # $materials = buy $recipe;
    $foods = cook $recipe;
}

1;
