use Modern::Perl;
use Log::LogMethods::Log4perlLogToString;
use Carp qw(confess);
use Data::Dumper;
BEGIN { $SIG{__DIE__} = sub { confess @_ }; }
use Test::More qw(no_plan);

my $class='Net::AppDynamics::REST';
require_ok($class);
use_ok($class);

my $string;
my $logger=LoggerToString($class,$string);

my %args;

my $run_extended=6;

$ENV{TEST_PORT}=8090 unless defined($ENV{TEST_PORT});
$ENV{TEST_PROTO}='http' unless defined($ENV{TEST_PROTO});
$ENV{TEST_CUSTOMER}='customer1' unless defined($ENV{TEST_CUSTOMER});
my @missing;
{
  foreach my $var (qw(USER PASS SERVER PROTO PORT CUSTOMER)) {
    my $name=lc($var);
    my $env="TEST_$var";

    if(defined($ENV{$env})) {
      $args{$var}=$ENV{$env};
      --$run_extended;
    } else {
      $args{$var}='test';
      push @missing,$env; 
    }
  }
}

my $self=$class->new(
  logger=>$logger,
  %args,
);
isa_ok($self,$class);

cmp_ok($self->base_url,'eq',$self->PROTO.'://'.$self->SERVER.':'.$self->PORT,'Make sure we have a valid url');

SKIP: {
  skip "The following env variables were not set: ".join(', ',@missing),1 unless $run_extended==0;
  ok($self->resolve('business_transactions','login'),'should resolve our transaction');
}
SKIP: {
  skip "The following env variables were not set: ".join(', ',@missing),1 unless $run_extended==0;
  $self->agent->max_que_count(100);
  {
    my $result=$self->walk_all;
    ok($result,'should get a result without an error');
  }
  my $cv=AnyEvent->condvar;
  my $t=AnyEvent->timer(after=>60,cb=>sub { $cv->send });

  $self->que_check_cache(sub {
    my ($self,$id,$result)=@_;
    ok($result,"Check cache");
    my $cache;
    $cache=$result->get_data;
    $self->que_check_cache(sub {
      my ($self,$id,$result)=@_;
      ok($result,"Check cache again");
      my $cmp=$result->get_data;
      cmp_ok($cmp,'eq',$cache,'Checking the cache again.. Sould have the same refrence as before');
      $cv->end;
    });
    $cv->begin;
    $self->agent->run_next;
      $self->que_check_cache(sub {
        my ($self,$id,$result)=@_;
        ok($result,"Check cache again");
        my $cmp=$result->get_data;
        cmp_ok($cmp,'ne',$cache,'Forcing cache refresh.. Sould have a new refrence');
        $cv->end;
      },1);
      $cv->begin;
      $self->agent->run_next;
    $cv->end;
  });
  $cv->begin;
  $self->agent->run_next;

  $cv->recv;
  my $result=$self->walk_all;
  ok($result,'should get a result without an error');

}

done_testing;
