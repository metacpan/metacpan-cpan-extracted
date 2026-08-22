#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();
use File::Spec ();
use Template::Stencil;

# Tied hashes in a path.
#
# Path resolution reads a hash with hv_common and a hash precomputed at
# compile time - one probe, no key SV. That is right for every ordinary hash
# and it does not go through tie magic, so before this was fixed a tied hash
# resolved to NOTHING: not an error, not a wrong value, an empty tag and no
# way to tell why.
#
# It matters because a tied hash is how a caller hands a template something it
# should not have to materialise up front - a large catalogue, a lazy record,
# a database row. Punk::Plugin::I18n is the case that found it.
#
# There are two layers to get right, and the second is the one that looks
# fixed and is not: hv_fetch_ent gives back a PVLV carrying GET MAGIC rather
# than the value, and the tie's FETCH only runs when that magic is read. A
# resolver that returns it unread hands SvOK an undef and renders empty again.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub tmpl {
    my ($name, $body) = @_;
    open my $fh, '>', File::Spec->catfile($dir, "$name.tmpl") or die $!;
    print $fh $body;
    close $fh;
}

{
    package TiedCat;
    sub TIEHASH { bless { n => 0, %{ $_[1] || {} } }, $_[0] }
    sub FETCH   { my ($s, $k) = @_; $s->{n}++; return $s->{data}{$k} }
    sub EXISTS  { exists $_[0]->{data}{ $_[1] } }
    sub fetches { $_[0]->{n} }
}

tmpl(one    => '[{% t.greeting %}]');
tmpl(nested => '[{% t.deep.a %}]');
tmpl(miss   => '[{% t.absent %}]');
tmpl(mixed  => '[{% plain.x %}|{% t.greeting %}]');
tmpl(twice  => '[{% t.greeting %}{% t.greeting %}]');

my $engine = Template::Stencil->new(template_dir => $dir);

my %h;
my $obj = tie %h, 'TiedCat', {
    data => {
        greeting => 'hello',
        deep     => { a => 'down here' },
        absent   => undef,
    },
};

# ---- the fix -----------------------------------------------------------------
{
    is($engine->render('one', { t => \%h }), '[hello]',
        'a tied hash in a path resolves - it rendered empty before, with no '
      . 'error to say so');

    is($engine->render('nested', { t => \%h }), '[down here]',
        'and a plain hash reached THROUGH a tied one still resolves');
}

# ---- the tie is actually driven ----------------------------------------------
# Not "a value appeared" but "FETCH ran", because a resolver that found the
# value some other way would pass the test above and still be wrong.
{
    my $before = $obj->fetches;
    $engine->render('one', { t => \%h });
    cmp_ok($obj->fetches, '>', $before,
        'FETCH is called - the value comes from the tie rather than from '
      . 'somewhere the resolver happened to look');
}

# ---- a key the tie does not have ---------------------------------------------
{
    is($engine->render('miss', { t => \%h }), '[]',
        'a tied key returning undef renders as the empty string, the same '
      . 'as any other missing path');
}

# ---- the ordinary path is untouched ------------------------------------------
{
    is($engine->render('mixed', { plain => { x => 'P' }, t => \%h }),
        '[P|hello]',
        'plain and tied hashes resolve side by side in one template');

    is($engine->render('twice', { t => \%h }), '[hellohello]',
        'the same tied key twice in one render is stable - the value is read '
      . 'through its magic each time rather than held across the fetch');
}

# ---- escaping still applies --------------------------------------------------
{
    my %e;
    tie %e, 'TiedCat', { data => { x => '<b>&</b>' } };
    tmpl(esc => '{% t.x %}');
    tmpl(raw => '{% raw t.x %}');
    is($engine->render('esc', { t => \%e }), '&lt;b&gt;&amp;&lt;/b&gt;',
        'a value from a tie is escaped like any other - the tie is where the '
      . 'value came from, not permission to skip the escaping');
    is($engine->render('raw', { t => \%e }), '<b>&</b>', 'and raw opts out');
}

done_testing;
