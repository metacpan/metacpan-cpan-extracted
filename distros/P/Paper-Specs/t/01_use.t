use Test::More no_plan;

open(FH,'./MANIFEST') or die "cannot open MANIFEST: $!";
while(<FH>) {
    next    unless(m!lib/(.*).pm!);
    my $module = $1;
    $module =~ s!/!::!g;
    use_ok($module);
}

close(FH);
