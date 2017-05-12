package Puncheur::Runner;
use strict;
use warnings;

use Plack::Runner;
use Plack::Util;

sub new {
    my ($class, $app, $plackup_options) = @_;
    $plackup_options ||= {};
    $app = Plack::Util::load_class($app);
    my ($options, $argv);
    if ($app->can('parse_options')) {
        ($options, $argv) = $app->parse_options(@ARGV);
    }
    $argv = [@ARGV] unless $argv;

    my @default;
    while (my ($key, $value) = each %$plackup_options) {
        push @default, "--$key=$value";
    }
    my $runner = Plack::Runner->new;
    $runner->parse_options(@default, @$argv);

    if (!$app->can('parse_options')) {
        my %options = @{ $runner->{options} };
        delete $options{$_} for qw/listen socket/;
        $options = \%options;
    }

    bless {
        app         => $app,
        runner      => $runner,
        app_options => $options,
    }, $class;
}

sub run {
    my $self = shift;
    my %opts = @_ == 1 ? %{$_[0]} : @_;

    my $app_options = $self->{app_options};
    my $psgi = $self->{app}->new(%$app_options, %opts)->to_psgi;
    $self->{runner}->run($psgi);
}

1;
