use strict;
use warnings;

# Windows before Perl 5.38 reports 0 as the inode of every file.  The
# template scan used device:inode to spot a directory it had already
# walked, so there every directory after the first looked "seen" and was
# skipped: a newer template in a subdirectory, or behind a symlink, never
# moved Last-Modified.  This file makes stat() report inode 0 here too, so
# the fallback is tested on every platform.
BEGIN {
	*CORE::GLOBAL::stat = sub (;*) {
		my @stat = @_ ? CORE::stat($_[0]) : CORE::stat($_);
		$stat[1] = 0 if @stat;
		return @stat;
	};
}

use File::Path qw(make_path);
use File::Temp ();
use Mojo::Date;
use Mojolicious;
use Test::Mojo;
use Test::More;

sub write_file {
	my ($path, $content, $mtime) = @_;
	open(my $fh, '>', $path) or die "$path: $!";
	print {$fh} $content;
	close($fh);
	utime($mtime, $mtime, $path) or die "utime $path: $!";
	return;
}

sub build_app {
	my $dir = shift;
	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->renderer->paths([$dir]);
	$app->plugin('Buffer');
	$app->routes->get('/template' => sub { shift->render(template => 'page') });
	return $app;
}

subtest 'stat reports inode 0 in this file' => sub {
	my @stat = stat(__FILE__);
	is($stat[1], 0, 'the override is in force');
};

subtest 'a newer template in a nested directory is seen' => sub {
	my $dir = File::Temp->newdir('mpb-no-inode-XXXXXX', TMPDIR => 1);
	my $script = "$dir/app.pl";
	write_file($script, "1;\n", 1_000);
	write_file("$dir/page.html.ep", 'page', 2_000);

	make_path("$dir/a/b");
	write_file("$dir/a/b/newer.html.ep", 'newer', 3_000);
	utime(2_100, 2_100, "$dir/a/b") or die "utime: $!";
	utime(2_100, 2_100, "$dir/a") or die "utime: $!";
	utime(900, 900, "$dir") or die "utime: $!";

	local $0 = $script;
	my $t = Test::Mojo->new(build_app("$dir"));
	$t->ua->transactor->compressed(0);
	$t->get_ok('/template')->status_is(200);
	is($t->tx->res->headers->last_modified, Mojo::Date->new(3_000)->to_string,
		'Last-Modified comes from the template two directories down');
};

subtest 'a symlink loop still ends without inodes' => sub {
	my $dir = File::Temp->newdir('mpb-no-inode-loop-XXXXXX', TMPDIR => 1);
	my $script = "$dir/app.pl";
	write_file($script, "1;\n", 1_000);
	write_file("$dir/page.html.ep", 'page', 2_000);

	my $ok = eval { symlink("$dir", "$dir/loop") or die "$!\n"; 1 };
	plan skip_all => "symlinks are unavailable: $@" unless $ok;
	utime(900, 900, "$dir") or die "utime: $!";

	local $0 = $script;
	my $t = Test::Mojo->new(build_app("$dir"));
	$t->ua->transactor->compressed(0);

	my $completed = eval {
		local $SIG{ALRM} = sub { die "the symlink loop did not terminate\n" };
		alarm(10);
		$t->get_ok('/template')->status_is(200);
		alarm(0);
		1;
	};
	alarm(0);
	ok($completed, 'the request finishes: the depth limit ends the loop') or diag($@);
	is($t->tx->res->headers->last_modified, Mojo::Date->new(2_000)->to_string,
		'the newest real template still decides Last-Modified')
		if $completed;
};

done_testing();
