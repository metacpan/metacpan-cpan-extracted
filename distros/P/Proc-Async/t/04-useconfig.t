#!perl -T

#use Test::More qw(no_plan);
use Test::More tests => 7;

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Proc::Async;
diag( "My configuration" );

# start and fill a configuration
my $args = [ qw(echo yes no) ];
my $options = { OH => 'yes', BETTER => 'no' };
my $jobid = Proc::Async::_generate_job_id();
my $cfgfile = Proc::Async::_start_config ($jobid, $args, $options);
ok (-e $cfgfile, "Configuration does not exist");

# re-read and check the configuration
{
    my ($cfg, $cfgfile) = Proc::Async->get_configuration ($jobid);
    is_deeply ([ $cfg->param ('job.arg') ], $args, "Re-Read args failed");
    is ($cfg->param ('job.id'), $jobid, "Re-Read jobid failed");
    is ($cfg->param ('job.status'), Proc::Async::STATUS_CREATED, "Re-Read status failed");
    foreach my $key (keys %$options) {
        is ($cfg->param ('option.' . $key), $options->{$key}, "Re-Read option '$key' failed");
    }
}

__END__
