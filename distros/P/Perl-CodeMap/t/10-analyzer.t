use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Perl::CodeMap;

my $root=tempdir(CLEANUP=>1);
sub add_file {
    my ($rel,$content)=@_;
    my $path="$root/$rel";
    my $dir=$path;
    $dir =~ s{/[^/]+$}{};
    make_path($dir) unless -d $dir;
    open my $fh,'>:raw',$path or die $!;
    print {$fh} $content;
    close $fh;
}
add_file('lib/Example/A.pm', <<'SOURCE');
package Example::A;
use strict;
use Example::B;
use parent 'Example::Base';
# A useful first subroutine.
sub run {
    return Example::B::helper();
}
sub _private { return 3; }
1;
SOURCE
add_file('lib/Example/B.pm', <<'SOURCE');
package Example::B;
use Example::A;
# Static dependency cycle intentionally present.
sub helper { return 1; }
1;
SOURCE
add_file('lib/Example/Base.pm',"package Example::Base;\nsub base { 1 }\n1;\n");
add_file('lib/Example/Multi.pm',"package Example::First;\nsub one { 1 }\npackage Example::Second;\nsub two { 2 }\n1;\n");
add_file('lib/Example/Moose.pm',"package Example::Moose;\nextends 'Example::Base';\nwith 'Example::Role';\nmethod work (\$x) { return \$x; }\n1;\n");
add_file('lib/Example/Role.pm',"package Example::Role;\nsub name { 'Role' }\n1;\n");
add_file('lib/Example/Literals.pm', <<'SOURCE');
package Example::Literals;
my $data = <<END_TEXT;
sub not_real { 1 }
END_TEXT
=pod
sub also_not_real { 1 }
=cut
sub real { 1 }
SOURCE
add_file('t/example.t',"package Example::Tests;\nsub test {1}\n");
add_file('vendor/ThirdParty.pm',"package ThirdParty;\nsub thing {1}\n");
my $cm=Perl::CodeMap->new(root=>$root,parser=>'lite');
my $data=$cm->analyze;
my %pkg=map {$_->{path}=>$_} @{$data->{pkgs}};
ok($pkg{'Example::A'},'package discovery');
ok($pkg{'Example::First'} && $pkg{'Example::Second'},'multiple namespaces in a file');
ok(!$pkg{'Example::Tests'},'test files excluded');
ok(!$pkg{'ThirdParty'},'vendor directory excluded');
is_deeply($pkg{'Example::A'}{imports},['Example::B','Example::Base'],'use and parent imports');
is_deeply($pkg{'Example::Moose'}{imports},['Example::Base','Example::Role'],'Moose extends and role');
is_deeply($pkg{'Example::B'}{imports},['Example::A'],'cycle preserved');
is($pkg{'Example::A'}{files}[0]{funcs}[0]{s},3,'sub length');
like($pkg{'Example::A'}{files}[0]{funcs}[0]{d},qr/useful first subroutine/,'adjacent doc comment');
ok(!$pkg{'Example::A'}{files}[0]{funcs}[1]{e},'underscore naming flag');
is(scalar(@{$pkg{'Example::Literals'}{files}[0]{funcs}}),1,'POD and heredoc masked in lite');
is($pkg{'Example::Moose'}{files}[0]{funcs}[0]{k},'method','method syntax collected');
ok(exists $data->{sources}{'lib/Example/A.pm'},'source embedded');
my $no=Perl::CodeMap->new(root=>$root,parser=>'lite',embed_source=>0)->analyze;
is(scalar(keys %{$no->{sources}}),0,'source embedding disabled');
my $new=Perl::CodeMap->new(root=>$root,parser=>'lite');
my $added=$new->hydrate_sources($no,$root);
ok($added>=7,'older JSON hydrated from disk');
my $more=Perl::CodeMap->new(root=>$root,parser=>'lite',include_tests=>1)->analyze;
ok(grep($_->{path} eq 'Example::Tests', @{$more->{pkgs}}),'test inclusion flag');
my $invalid=eval {Perl::CodeMap->new(root=>$root,parser=>'wrong');1};
ok(!$invalid,'invalid parser rejected');

done_testing;
