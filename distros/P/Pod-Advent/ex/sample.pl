use Example::Module;
my $obj = Example::Module->new();
foreach my $x ( $obj->get_list ){
  printf "Foo == %s ==\n", $x;
}
