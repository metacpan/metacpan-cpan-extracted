#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use File::Temp ();
use File::Spec ();

require_ok('Router::Ragel');

# ragel writes to fd 2, so a test that deliberately feeds it bad input would
# otherwise litter an automated `make test` report.
sub quietly {
    my $code = shift;
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR, '>', File::Spec->devnull or die "silence STDERR: $!";
    my @r = eval { $code->() };
    my $err = $@;
    open STDERR, '>&', $saved or die "restore STDERR: $!";
    close $saved;
    die $err if $err;
    return wantarray ? @r : $r[0];
}

# Misuse that used to be undefined behaviour runs in a child: a regression is
# a signal, not a failed assertion, and must not take the file down with it.
sub run_child {
    my $code = shift;
    my $fh = File::Temp->new(SUFFIX => '.pl');
    print {$fh} qq{use lib "$Bin/../lib";\nuse Router::Ragel;\n}, $code;
    close $fh;
    my $out = qx{"$^X" "$fh" 2>&1};
    return { signal => $? & 127, status => $? >> 8, output => $out };
}

subtest 'match() croaks on a reference that is not a router' => sub {
    # SvROK alone let a qr// body reach av_fetch on unrelated memory.
    my %refs = (
        'qr//' => 'qr/x/',
        'hashref' => '{ a => 1, b => 2, c => 3 }',
        'scalarref' => '\\(my $s = "x")',
        'coderef' => 'sub { 1 }',
        'globref' => '\\*STDOUT',
        'ref to ref' => '\\\\"str"',
        'blessed hashref' => 'bless({}, "Router::Ragel")',
    );
    for my $name (sort keys %refs) {
        my $r = run_child(qq{
            eval { Router::Ragel::match($refs{$name}, '/x/1') };
            print \$\@ ? "CROAK: \$\@" : "NO CROAK\\n";
        });
        is($r->{signal}, 0, "$name: no fatal signal");
        like($r->{output}, qr/requires a router object/, "$name: croaks with a useful message");
    }
};

subtest 'match() croaks when slot 2 is not a usable pointer' => sub {
    my $r = run_child(q{
        my $fake = bless [ [], 0, "not a pointer" ], 'Router::Ragel';
        eval { $fake->match('/x') };
        print $@ ? "CROAK: $@" : "NO CROAK\n";
    });
    is($r->{signal}, 0, 'no fatal signal');
    like($r->{output}, qr/compile\(\) not called/, 'non-integer slot 2 is rejected');
};

subtest '<type> may not embed Ragel actions' => sub {
    # Ragel inline action blocks emit their bodies as raw C into the library.
    my @evil = (
        '/x/:id<[0-9]+ %{ evil(); }>',
        '/x/:id<[0-9]+ ${ evil(); }>',
        '/x/:id<[0-9]+ @{ evil(); }>',
        '/x/:id<[0-9]+ ) ; }%% void evil(void) {} %%{ zzz = ( [0-9]+>',
        '/x/:id<[0-9]+ # comment>',
        # A newline lets a '#' comment swallow the rest of the emitted line.
        "/x/:id<[0-9]+\n[a-z]+>",
        # Splices a second statement, stealing this route's capture actions.
        '/x/:id<[0-9]+ ) ; zzz = ( [0-9]+>',
        # An unbalanced quote swallows the rest of the generated line.
        "/x/:id<[0-9]+ '>",
        '/x/:id<[0-9]+ (>',
        '/x/:id<[0-9]+ [a-z>',
    );
    for my $pat (@evil) {
        my $r = Router::Ragel->new->add($pat, 'd');
        eval { $r->compile };
        (my $show = $pat) =~ s/\n/\\n/g;
        like($@, qr/Router::Ragel: .*<type>/, "rejected: $show");
    }
};

subtest 'documented <type> expressions still compile and match' => sub {
    my $r = Router::Ragel->new
        ->add('/a/:v<int>', 'int')
        ->add('/b/:v<hex>', 'hex')
        ->add('/c/:v<string>', 'string')
        ->add('/d/:v< int >', 'spaced')
        ->add('/e/:v<[0-9]{4}>', 'quant')
        ->add('/f/:v<[0-9]{2,4}>', 'quant2')
        ->add('/g/:v<[a-z0-9\-]+>', 'class')
        ->add('/h/:v<[a-z]*>', 'star')
        ->add('/i/:v<digit{3}>', 'keyword')
        ->add('/j/:v<(\'ab\'|\'cd\')+>', 'alt');
    ok(eval { $r->compile; 1 }, 'every documented type form compiles') or diag $@;
    return unless $r->[2];

    is(($r->match('/a/42'))[1], '42', '<int>');
    is(($r->match('/b/dead'))[1], 'dead', '<hex>');
    is(($r->match('/c/zz'))[1], 'zz', '<string>');
    is(($r->match('/d/7'))[1], '7', '< int >');
    is(($r->match('/e/1234'))[1], '1234', '<[0-9]{4}>');
    is(($r->match('/f/123'))[1], '123', '<[0-9]{2,4}>');
    is(($r->match('/g/a-1'))[1], 'a-1', '<[a-z0-9\\-]+>');
    is(($r->match('/h/'))[1], '', '<[a-z]*> matching empty');
    is(($r->match('/i/123'))[1], '123', '<digit{3}>');
    is(($r->match('/j/abcd'))[1], 'abcd', "<('ab'|'cd')+>");
};

subtest 'a multi-term <type> captures the whole match' => sub {
    # Unparenthesised, the capture actions instrument the type's last term
    # only: concatenation captures a suffix and an alternation branch that
    # misses them leaves the read-back on an uninitialized slot.
    my $r = run_child(q{
        my $r = Router::Ragel->new
            ->add('/w/:a/:b', 'W')
            ->add('/c/:v<[a-z]+ [0-9]+>', 'C')
            ->add("/u/:v<'ab' | 'cdef'>", 'U')
            ->compile;
        $r->match('/w/mmmmmmmmmmmmmmmmmmmmmmmmmmmm/nnnnnnnnnnnnnnnnnnnnnnnn');
        print "concat=", ($r->match('/c/ab12'))[1], "\n";
        print "alt1=",   ($r->match('/u/ab'))[1], "\n";
        print "alt2=",   ($r->match('/u/cdef'))[1], "\n";
    });
    is($r->{signal}, 0, 'no fatal signal');
    like($r->{output}, qr/^concat=ab12$/m, 'concatenation captures every term');
    like($r->{output}, qr/^alt1=ab$/m, 'alternation: the branch without the actions');
    like($r->{output}, qr/^alt2=cdef$/m, 'alternation: the branch with the actions');
};

subtest 'an undecidable capture boundary croaks instead of panicking' => sub {
    # Packed placeholders can leave the machine closing a capture before it
    # opened it, which used to reach newSVpvn as a negative length.
    my $r = Router::Ragel->new
        ->add("/amb/:a<[a-z0-9]+>:b<('a'|'ab')>:c<[a-z0-9]+>", 'A')
        ->compile;
    my @got = eval { $r->match('/amb/0a0a') };
    like($@, qr/\QRouter::Ragel: ambiguous capture boundary\E/,
        'the module names the problem instead of leaking a perl panic');
    like($@, qr/\Q:a<[a-z0-9]+>\E/, 'and names the pattern that caused it');
    unlike($@, qr/sv_setpvn/, 'no perl internals in the message');

    # The documented cure: a separator the preceding type cannot start.
    my $sep = Router::Ragel->new->add('/sep/:a<int>-:b<int>', 'S')->compile;
    is_deeply([$sep->match('/sep/12-34')], ['S', '12', '34'],
        'a literal separator splits exactly');
};

subtest "a '/' inside <type> is reported as a slash, not as a stray '<'" => sub {
    my $r = Router::Ragel->new->add('/a/:x<[^/]+>', 'd');
    eval { $r->compile };
    like($@, qr/\Qunterminated '<'\E/, 'still reports the unterminated type');
    like($@, qr{\Q'/' is not allowed inside a <type>\E}, 'and points at the slash');

    my $plain = Router::Ragel->new->add('/a/:x<[a-z', 'd');
    eval { $plain->compile };
    like($@, qr/\Qunterminated '<'\E/, 'a genuinely unterminated type still says so');
    unlike($@, qr/\Qnot allowed inside\E/, '...without the misleading slash hint');
};

subtest 'the first > ends the type, so nothing after it is grammar' => sub {
    # This is what keeps '>{ action }' out of the machine.
    my $r = Router::Ragel->new->add('/g/:id<[0-9]+>{ evil(); }', 'lit')->compile;
    is_deeply([$r->match('/g/42{ evil(); }')], ['lit', '42'],
        'text after the closing > is matched literally');
    is_deeply([$r->match('/g/42')], [], 'the literal suffix is required');
};

subtest 'compiled matchers are not bound as public subs' => sub {
    Router::Ragel->new->add('/ns/:id', 'N')->compile;
    my @leaked = do { no strict 'refs'; sort grep /^match_/, keys %{'Router::Ragel::'} };
    is_deeply(\@leaked, [], 'per-machine matchers stay static, out of the package')
        or diag "leaked: @leaked";

    ok(!Router::Ragel->can('store_func_ptr'),
        'no XSUB writes the compiled pointer into a caller-supplied arrayref');
};

subtest 'patterns must be byte strings' => sub {
    my $r = Router::Ragel->new->add("/caf\x{e9}\x{263a}", 'wide');
    eval { $r->compile };
    like($@, qr/must be a byte string/, 'a pattern with wide characters is rejected');
};

subtest 'a ragel failure names Router::Ragel and the suspect patterns' => sub {
    my $r = Router::Ragel->new
        ->add('/plain/route', 'ok')
        ->add('/other/:untyped', 'ok')
        ->add('/bad/:s<[a-z-]+>', 'bad');
    my $err = quietly(sub { eval { $r->compile }; $@ });
    like($err, qr/^Router::Ragel:/, 'error is attributed to Router::Ragel');
    like($err, qr{\Q/bad/:s<[a-z-]+>\E}, 'the typed pattern is listed');
    unlike($err, qr{\Q/plain/route\E}, 'untyped patterns are not listed as suspects');
};

subtest 'generated code is keyed on the route set, not a counter' => sub {
    # Same patterns must share one machine, so a warmed cache still hits.
    my $first = Router::Ragel->new->add('/keyed/:id<int>', 'A')->compile;
    Router::Ragel->new->add('/unrelated/x', 'X')->compile;   # shift the counter
    my $second = Router::Ragel->new->add('/keyed/:id<int>', 'B')->compile;

    is($second->[2], $first->[2],
        'same route set reuses the same compiled function regardless of creation order');
    is(($first->match('/keyed/1'))[0], 'A', 'first router keeps its own data');
    is(($second->match('/keyed/2'))[0], 'B', 'second router keeps its own data');

    my $other = Router::Ragel->new->add('/different/:id<int>', 'C')->compile;
    isnt($other->[2], $first->[2], 'a different route set gets a different machine');
};

subtest 'recompiling an unchanged router is silent' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    my $r = Router::Ragel->new->add('/silent/:id', 'S')->compile;
    @warnings = ();
    $r->compile;
    is_deeply(\@warnings, [], 'no redefine warnings on an identical recompile')
        or diag join '', @warnings;
    is(($r->match('/silent/9'))[0], 'S', 'still matches after the second compile');
};

subtest 'serialized routers do not carry a stale function pointer' => sub {
    plan skip_all => 'Storable required' unless eval { require Storable; 1 };

    my $r = Router::Ragel->new->add('/frozen/:id', 'F')->compile;
    my $clone = Storable::dclone($r);
    is($clone->[2], undef, 'the raw function pointer is not cloned');
    eval { $clone->match('/frozen/1') };
    like($@, qr/compile\(\) not called/, 'a cloned router refuses to match until recompiled');

    $clone->compile;
    is_deeply([$clone->match('/frozen/1')], ['F', '1'], 'routes survive the round trip');

    my $thawed = Storable::thaw(Storable::freeze($r));
    is($thawed->[2], undef, 'freeze/thaw drops the pointer too');
    is_deeply([$thawed->compile->match('/frozen/2')], ['F', '2'], 'and recompiles cleanly');
};

subtest 'a corrupt route table croaks instead of crashing' => sub {
    # A truncated Storable blob or direct surgery on slot 0 can leave entries
    # the read-back would walk off the end of.
    for my $bad ("['/c/:id']", "'not a ref'", "{}") {
        my $r = run_child(qq{
            my \$r = Router::Ragel->new->add('/c/:id', 'D')->compile;
            \$r->[0][0] = $bad;
            eval { \$r->match('/c/1') };
            print \$\@ ? "CROAK: \$\@" : "NO CROAK\\n";
        });
        is($r->{signal}, 0, "route entry $bad: no fatal signal");
        like($r->{output}, qr/corrupt route table/, "route entry $bad: croaks");
    }
};

subtest 'extra arguments are a mistake, not silent data loss' => sub {
    eval { Router::Ragel->new('unexpected') };
    like($@, qr/new\(\) takes no arguments/, 'new() rejects arguments');

    eval { Router::Ragel->new->add('/x', 'd', 'extra') };
    like($@, qr/add\(\) takes/, 'add() rejects a third argument');

    my $r = Router::Ragel->new->add('/one-arg');
    ok(eval { $r->compile; 1 }, 'one-argument add() is still allowed');
    is_deeply([$r->match('/one-arg')], [undef], '...and stores undef data');
};

done_testing;
