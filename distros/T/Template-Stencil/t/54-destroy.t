#!perl
use 5.016;
use strict;
use warnings;
use Test::More;
use Config;
use Template::Stencil;

sub engines { Template::Stencil::_stencil_stats()->{engines} }

# Engine freed when the object goes away (magic free, no DESTROY).
{
    my $base = engines();
    {
        my $s = Template::Stencil->new;
        is(engines(), $base + 1, 'engine live while object lives');
        $s->render('{% v %}', { v => 1 });
    }
    is(engines(), $base, 'engine freed with the object');
}

# Many create/destroy cycles are stable.
{
    my $base = engines();
    for (1 .. 200) {
        my $s = Template::Stencil->new(cache_size => 4);
        $s->render("t$_ {% v %}", { v => $_ });
    }
    is(engines(), $base, '200 lifecycle rounds balance');
}

# Weak/blessed misuse does not confuse the destructor.
{
    my $s = Template::Stencil->new;
    my $copy = $s;      # shared refcount
    undef $s;
    is($copy->render('x', {}), 'x', 'object alive via second ref');
}

# Global destruction: an engine held in a package global at exit must
# not warn or crash (PL_dirty path in the free callback).
{
    my $perl = $Config{perlpath};
    my $out = qx{"$perl" -Mblib -MTemplate::Stencil -we 'our \$S = Template::Stencil->new(filters => { f => sub { \$_[0] } }); \$S->render("{% v | f %}", { v => 1 }); print "done\\n"' 2>&1};
    is($?, 0, 'global-destruction exit status clean');
    like($out, qr/^done$/m, 'ran to completion');
    unlike($out, qr/warning|panic|Attempt to free/i,
           'no destruction warnings');
}

done_testing;
