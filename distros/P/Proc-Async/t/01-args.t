#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 15;

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Proc::Async;
diag( "Methods arguments" );

#    starts ($args, [$options])
#    starts (@args, [$options])
my @args = qw(echo yes no);
my %options = (DIR => '/my/dir');
{
    my ($args, $options) = Proc::Async::_process_start_args ( \@args );
    is (scalar @$args, scalar @args, "Number of args does not match");
    is_deeply ($args, \@args, "Args do not match");
    is (scalar keys %$options, 0, "Options are not empty");
}
{
    my ($args, $options) = Proc::Async::_process_start_args ( \@args, \%options );
    is (scalar @$args, scalar @args, "Number of args does not match");
    is_deeply ($args, \@args, "Args do not match");
    is (scalar keys %$options, scalar keys %options, "Number of options does not match");
    is_deeply ($options, \%options, "Options do not match");
}
{
    my ($args, $options) = Proc::Async::_process_start_args ( @args );
    is (scalar @$args, scalar @args, "Number of args does not match");
    is_deeply ($args, \@args, "Args do not match");
    is (scalar keys %$options, 0, "Options are not empty");
}
{
    my ($args, $options) = Proc::Async::_process_start_args ( @args, \%options );
    is (scalar @$args, scalar @args, "Number of args does not match");
    is_deeply ($args, \@args, "Args do not match");
    is (scalar keys %$options, scalar keys %options, "Number of options does not match");
    is_deeply ($options, \%options, "Options do not match");
}

__END__

