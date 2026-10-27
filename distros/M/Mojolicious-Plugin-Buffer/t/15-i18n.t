use strict;
use warnings;

use Test::More;
use Encode ();
use File::Basename qw(dirname);
use File::Find ();
use File::Spec ();
use Mojolicious;
use Mojolicious::Plugin::Buffer::I18N;
use Test::Mojo;

# The catalog, the i18n() method and the messages option.  The i18n()
# method is public, so these are black-box tests.

{
	package TestI18N;
	use Mojolicious::Plugin::Buffer::I18N qw(i18n);
	sub new { my ($class, %args) = @_; return bless {%args}, $class }
}

my $catalog = Mojolicious::Plugin::Buffer::I18N->catalog;

subtest 'every key used in lib/ exists in the catalog' => sub {
	# A key used in code but missing from the catalog would print as its own
	# name, so look for every literal key passed to i18n() or _log()
	my $lib = File::Spec->catdir(dirname(dirname(File::Spec->rel2abs($0))), 'lib');
	my %used;
	File::Find::find({no_chdir => 1, wanted => sub {
		return unless /\.pm\z/;
		open(my $fh, '<', $_) or die "$_: $!";
		my $code = do { local $/; <$fh> };
		close($fh);
		$code =~ s/^=\w+.*?^=cut//gms;	# POD examples are not code
		$used{$1} = $File::Find::name while $code =~ /->i18n\(\s*'(\w+)'/g;
		$used{$1} = $File::Find::name while $code =~ /=>\s*'(log_\w+)'/g;
		$used{$1} = $File::Find::name while $code =~ /\?\s*'(log_\w+)'\s*:\s*'log_\w+'/g;
		$used{$1} = $File::Find::name while $code =~ /:\s*'(log_\w+)'/g;
	}}, $lib);

	cmp_ok(scalar(keys %used), '>', 30, 'found the message keys used in the code');
	for my $key (sort keys %used) {
		ok(exists($catalog->{$key}), "$key is in the catalog");
	}
};

subtest 'catalog returns a copy' => sub {
	my $copy = Mojolicious::Plugin::Buffer::I18N->catalog;
	$copy->{retry_later} = 'changed';
	isnt(Mojolicious::Plugin::Buffer::I18N->catalog->{retry_later}, 'changed', 'the catalog is not changed through the copy');
};

subtest 'placeholders' => sub {
	my $obj = TestI18N->new(messages => {
		fmt => 'took %{secs:%.2f}s for %{n:%03d} items, %{name}',
		literal => '100% of %{what}',
	});

	is($obj->i18n('fmt', {secs => 1.5, n => 7, name => 'x'}), 'took 1.50s for 007 items, x', 'sprintf formats are applied');
	is($obj->i18n('fmt', {secs => 1, n => 2}), 'took 1.00s for 002 items, %{name}', 'a missing argument stays visible');
	is($obj->i18n('fmt', {secs => 1, n => 2, name => undef}), 'took 1.00s for 002 items, ', 'an undefined argument is empty');
	is($obj->i18n('literal', {what => 'cases'}), '100% of cases', 'a bare percent sign is left alone');

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is($obj->i18n('fmt', {secs => 'soon', n => 'many', name => 'x'}), 'took 0.00s for 000 items, x',
		'non-numeric values for numeric formats do not die');
	is(scalar(@warnings), 0, 'and do not warn') or diag(@warnings);
};

subtest 'plural and gender variants' => sub {
	my $obj = TestI18N->new(messages => {
		files => {zero => 'no files', one => 'one file', other => '%{count} files'},
		files_no_zero => {one => 'one file', other => '%{count} files'},
		owner => {
			female => {one => 'her file', other => 'her %{count} files'},
			male => {one => 'his file', other => 'his %{count} files'},
			other => {one => 'their file', other => 'their %{count} files'},
		},
		polish => sub {
			my $n = shift->{count};
			my $form = ($n == 1) ? 'plik' : (($n % 10 >= 2) && ($n % 10 <= 4) && (($n % 100 < 10) || ($n % 100 >= 20))) ? 'pliki' : 'plikow';
			return "$n $form";
		},
	});

	is($obj->i18n('files', {count => 0}), 'no files', 'zero');
	is($obj->i18n('files', {count => 1}), 'one file', 'one');
	is($obj->i18n('files', {count => 2}), '2 files', 'other');
	is($obj->i18n('files_no_zero', {count => 0}), '0 files', 'zero falls back to other');
	is($obj->i18n('files', {}), '%{count} files', 'no count selects other');
	is($obj->i18n('files', {count => 'lots'}), '%{count} files' =~ s/%\{count\}/lots/r, 'a non-numeric count selects other');

	is($obj->i18n('owner', {gender => 'female', count => 3}), 'her 3 files', 'gender then plural');
	is($obj->i18n('owner', {gender => 'male', count => 1}), 'his file', 'male singular');
	is($obj->i18n('owner', {gender => 'unknown', count => 1}), 'their file', 'an unknown gender uses other');
	is($obj->i18n('owner', {count => 2}), 'their 2 files', 'no gender uses other');

	is($obj->i18n('polish', {count => 1}), '1 plik', 'a code reference handles a language with more plural forms');
	is($obj->i18n('polish', {count => 3}), '3 pliki', 'paucal');
	is($obj->i18n('polish', {count => 5}), '5 plikow', 'many');
	is($obj->i18n('polish', {count => 22}), '22 pliki', 'paucal again past twenty');
};

subtest 'graceful failure' => sub {
	my $obj = TestI18N->new(messages => {
		dies => sub { die "translator bug\n" },
		missing_variant => {one => 'one'},
		loop => do { my $h = {}; $h->{other} = $h; $h },
		not_text => [1, 2],
	});

	is($obj->i18n('no_such_key'), 'no_such_key', 'an unknown key returns the key');
	is($obj->i18n('dies'), 'dies', 'a dying code reference returns the key');
	is($obj->i18n('missing_variant', {count => 5}), 'missing_variant', 'a missing variant returns the key');
	is($obj->i18n('loop'), 'loop', 'a self-referencing variant hash ends');
	is($obj->i18n('not_text'), 'not_text', 'a non-text template returns the key');

	eval { $obj->i18n(undef) };
	like($@, qr/key/, 'an undefined key is a programming error');
	eval { $obj->i18n('') };
	like($@, qr/key/, 'an empty key is a programming error');
	eval { $obj->i18n('retry_later', 'not a hash') };
	like($@, qr/args/, 'arguments must be a hash');
};

subtest 'class method and overrides' => sub {
	is(TestI18N->i18n('unknown_encoding', {encoding => 'lzma'}),
		q{Mojolicious::Plugin::Buffer: unknown encoding 'lzma'}, 'a class method uses the catalog');
	is(TestI18N->new(messages => 'not a hash')->i18n('unknown_error'), 'unknown error',
		'an unusable messages value is ignored');
	is(TestI18N->new(messages => {unknown_error => 'unbekannter Fehler'})->i18n('unknown_error'),
		'unbekannter Fehler', 'an override wins over the catalog');
};

# The 503 body is the one message a client sees, so check that a translated
# one, with non-ASCII characters, arrives as correctly encoded UTF-8.
# text/plain is excluded so the plugin's own after_dispatch pass, which
# would otherwise encode any character string it finds, leaves the 503
# alone: the encoding must already have been done when the body was set.
subtest 'a translated 503 is sent as UTF-8' => sub {
	my $german = "Die Seite wird erstellt, bitte versuchen Sie es gleich noch einmal \x{2013} danke f\x{fc}r Ihre Geduld.\n";
	my $cache = {};
	my $app = Mojolicious->new;
	$app->log->level('fatal');
	$app->plugin('Buffer',
		cache => bless($cache, 'TestHashCache'),
		cache_lock_timeout => 0.2,
		excluded_types => [qr{^text/plain$}],
		messages => {retry_later => $german},
	);
	$app->routes->get('/slow' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;
		$c->render_later;
		Mojo::IOLoop->timer(1 => sub { $c->render(text => 'built') });
	});

	my $t = Test::Mojo->new($app);
	my ($builder, $waiter);
	$t->ua->get('/slow' => sub { $builder = pop });
	Mojo::IOLoop->timer(0.05 => sub {
		$t->ua->get('/slow' => sub { $waiter = pop; Mojo::IOLoop->stop if $builder });
	});
	Mojo::IOLoop->timer(3 => sub { Mojo::IOLoop->stop });
	Mojo::IOLoop->start;
	Mojo::IOLoop->one_tick until $builder && $waiter;

	is($waiter->res->code, 503, 'the waiter timed out');
	like($waiter->res->headers->content_type, qr/charset=UTF-8/i, 'the charset is declared');
	is(Encode::decode('UTF-8', $waiter->res->body), $german, 'the translated text arrives intact');
};

done_testing();

package TestHashCache;

sub get { $_[0]->{$_[1]} }
sub set { $_[0]->{$_[1]} = $_[2]; 1 }
sub remove { delete $_[0]->{$_[1]} }
