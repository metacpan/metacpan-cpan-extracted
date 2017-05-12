
use Test::More tests => 1;
use Sysadm::Install qw(cd);
use Log::Log4perl qw(:easy);

my $conf = q(
  log4perl.category = DEBUG, Buffer
  log4perl.appender.Buffer = Log::Log4perl::Appender::TestBuffer
  log4perl.appender.Buffer.layout = Log::Log4perl::Layout::PatternLayout
  log4perl.appender.Buffer.layout.ConversionPattern = %M %F{1} %L> %m%n
);

Log::Log4perl->init( \$conf );
my $buf = Log::Log4perl::Appender::TestBuffer->by_name("Buffer");

cd "..";
func1();

like $buf->buffer(), qr/main:: .*main:: .*main::func1/s, 
     "caller_level";
     
sub func1 {
   local $Log::Log4perl::caller_depth = 
         $Log::Log4perl::caller_depth + 1;
   cd "..";
   func2();
}

sub func2 {
   cd "..";
}
