package NCustom ;

$Config{'test_data2'}	= "local_value";

sub my_get_url { 
  my ($url, $target_dir) = @_;
  open(OUT,">> $ENV{'HOME'}/stubs.log");
  print OUT "get_url ${url} ${target_dir}\n";
  close(OUT);
};
$Config{'get_url'}      = \&my_get_url;

1;
