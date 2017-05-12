use strict;
use IO::File;
use DBI;
use vars qw($VERSION);
$VERSION='1.05';

package StatsView::Oracle;
use vars qw ($Finished);

################################################################################

sub harikari(@)
{
my $msg = "@_";
$msg =~ s/ at .*$//;
print($msg);
exit(1);
}

################################################################################

sub new($$$$$$$;)
{
my ($class, $database, $username, $password,
    $file, $rate, $skew, @monitors) = @_;
$class = ref($class) || $class;
my $self = { skew => $skew, rate => $rate };

# Check rate and skew are valid
die("Invalid rate/skew combination\n") if ($rate < $skew * scalar(@monitors));

# Connect to Oracle
local $SIG{__DIE__} = \&harikari;
$self->{db} = DBI->connect("dbi:Oracle:$database", $username, $password,
                           { AutoCommit => 0, RaiseError => 1 });

# Open the output file
$self->{fh} = IO::File->new($file, "w") || die("Can't open $file: $!\n");

# Write the header
my ($D, $M, $Y) = (localtime())[3,4,5]; $M++; $Y += 1900;
$self->{fh}->printf("Oracle Statistics File created on %.2d/%.2d/%.4d\n\n",
                    $D, $M, $Y);

# Create the monitors
my $path = $class;
$path =~ s!::!/!g;
foreach my $monitor (@monitors)
   {
   require "$path/$monitor.pm";
   push(@{$self->{monitors}},
        "${class}::${monitor}"->new($self->{db}, $self->{fh}, $rate));
   }

# Start the data section
$self->{fh}->print("Data rate:  $self->{rate}\n\n");

return(bless($self, $class));
}

################################################################################

sub run($$)
{
my ($self, $count) = @_;
my ($rate, $skew) = @$self{qw(rate skew)};
my $sleep = $rate - (scalar(@{$self->{monitors}}) * $skew);
local $SIG{__DIE__} = \&harikari;
while ($count-- != 0 && ! $StatsView::Oracle::Finished)
   {
   foreach my $monitor (@{$self->{monitors}})
      {
      my ($s, $m, $h, $D, $M, $Y) = localtime();
      $M++; $Y += 1900;
      my $ts = sprintf("%.2d/%.2d/%.4d %2d:%.2d:%.2d", $D, $M, $Y, $h, $m, $s);
      $monitor->sample($ts);
      sleep($skew);
      }
   sleep($sleep);
   }
}

################################################################################

sub DESTROY($)
{
my ($self) = @_;
undef($self->{monitors});
$self->{fh}->close();
local $SIG{__DIE__} = \&harikari;
$self->{db}->disconnect();
}

################################################################################
1;
