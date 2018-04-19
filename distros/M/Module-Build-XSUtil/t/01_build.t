use Test::More;
use Config;
use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Temp qw(tempdir);
use File::Copy::Recursive::Reduced 'dircopy';
use Cwd::Guard qw(cwd_guard);
use Capture::Tiny qw(capture);

my $perl = $Config{perlpath};
my @perl = ($perl, map { "-I" . $_ } @INC);
 
my $eg_dir = rel2abs(catdir(qw/eg Foo/));
my $tmp_dir = tempdir( CLEANUP => 1 );
 
dircopy($eg_dir, $tmp_dir);
 
like run_cmd($tmp_dir, @perl, catfile($tmp_dir, 'Build.PL')), qr/Creating new 'Build' script for 'Foo' version/;
run_cmd($tmp_dir, @perl, catfile($tmp_dir, 'Build'));
like run_cmd($tmp_dir, @perl, catfile($tmp_dir, 'Build test')), qr/Result\:\s*PASS/;
done_testing;
 
sub run_cmd {
    my ($work_dir, @cmd) = @_;
    my $cmd = join ' ', @cmd;
    my $guard = cwd_guard($work_dir);
    my ($stdout, $stderr, $result) = capture{
        system($cmd);
    };
    diag $stderr if $result != 0;
    return $stdout;
}
 
__END__
