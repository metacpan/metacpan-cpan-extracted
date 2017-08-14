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
my $self=$class->new(
  logger=>$logger,
  USER=>'test',
  PASS=>'test',
  SERVER=>'test',
);
isa_ok($self,$class);

cmp_ok($self->base_url,'eq',$self->PROTO.'://'.$self->SERVER.':'.$self->PORT,'Make sure we have a valid url');
#diag($self->base_url);

done_testing;
