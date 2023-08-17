#!perl
use Shell::POSIX::Select;
&print_count();
sub nll()
  {
  0;
  }

{
our $count;
format STDOUT =
^<<<
$count
.
sub print_count()
{
$count=0;
select(STDOUT);
write(STDOUT);
};
}

__END__
