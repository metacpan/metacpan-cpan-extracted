use strict;
use Test::More 0.96; # for subtests
use Test::Exception;
use Pandoc;

plan skip_all => 'pandoc executable required' unless pandoc;
# XXX: does Test::More/IPC::Run3 lack write permissions?

my $args = ['-t' => 'markdown'];

subtest 'pandoc( ... )' => sub {
    my ($html, $md);
    is pandoc({ in => \'*.*', out => \$html }), 0, 'pandoc({in =>..., out=>...}';
    is $html, "<p><em>.</em></p>\n", 'markdown => html';

    ## no critic
    pandoc -f => 'html', -t => 'markdown', { in => \$html, out => \$md };
    like $md, qr/^\*\.\*/, 'html => markdown';
};

subtest 'run(@args, \%opts)' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    lives_ok { pandoc->run( @$args, \%opts ) }, 'run';
    like $out, qr!^\s*foo\s*$!, 'stdout';
    note $out;
    is $err //= "", "", 'stderr';

    lives_ok { pandoc->run( 'README.md', \%opts ) }, 'run with filename';
};

subtest '->run(\@args, \%opts)' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    lives_ok { pandoc->run( $args, \%opts ) }, 'run';
    like $out, qr!^\s*foo\s*$!, 'stdout';
    is $err //= "", "", 'stderr';
};

subtest '->run(\@args, %opts)' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    lives_ok { pandoc->run( $args, %opts ) }, 'run';
    like $out, qr!^\s*foo\s*$!, 'stdout';
    is $err //= "", "", 'stderr';
};

subtest '->run([], %opts)' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    lives_ok { pandoc->run( [], %opts ) }, 'run';
    like $out, qr!<p>foo</p>!, 'stdout';
    is $err //= "", "", 'stderr';
};

subtest 'run(%opts)' => sub {
    my $out;
    lives_ok { pandoc in => \"# hi", out => \$out };
    is $out, "<h1 id=\"hi\">hi</h1>\n", 'run( %opts )';
};

subtest '->run(\@args, qw[odd length list])' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    throws_ok { pandoc->run( $args, %opts, 'foo' ) } 
        qr!^\QToo many or ambiguous arguments!, 'run';
};

subtest '->run(\@args, ..., \%opts)' => sub {
    my $in = 'foo';
    my %opts = ( in => \$in, out => \my($out), err => \my($err) );
    throws_ok { pandoc->run( $args, qw[foo, bar], \%opts ) } 
        qr!^\QToo many or ambiguous arguments!, 'run';
};

done_testing;
