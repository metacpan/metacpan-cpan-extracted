#line 1
package Plack::Test;
use strict;
use warnings;
use Carp;
use parent qw(Exporter);
our @EXPORT = qw(test_psgi);

our $Impl;
$Impl ||= $ENV{PLACK_TEST_IMPL} || "MockHTTP";

sub create {
    my($class, $app, @args) = @_;

    my $subclass = "Plack::Test::$Impl";
    eval "require $subclass";
    die $@ if $@;

    no strict 'refs';
    if (defined &{"Plack::Test::$Impl\::test_psgi"}) {
        return \&{"Plack::Test::$Impl\::test_psgi"};
    }

    $subclass->new($app, @args);
}

sub test_psgi {
    if (ref $_[0] && @_ == 2) {
        @_ = (app => $_[0], client => $_[1]);
    }
    my %args = @_;

    my $app    = delete $args{app}; # Backward compat: some implementations don't need app
    my $client = delete $args{client} or Carp::croak "client test code needed";

    my $tester = Plack::Test->create($app, %args);
    return $tester->(@_) if ref $tester eq 'CODE'; # compatibility

    $client->(sub { $tester->request(@_) });
}

1;

__END__

#line 191
