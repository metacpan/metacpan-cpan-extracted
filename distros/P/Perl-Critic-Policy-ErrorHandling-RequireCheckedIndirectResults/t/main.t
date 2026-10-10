#!/usr/bin/env perl
use strict;
use warnings FATAL => 'all';

use re '/aa';

use 5.014;

=head1 NAME

t/main.t - which calls the policy reads as dropping the result of a syscall or
an eval one call away, and which it leaves alone

=head1 DESCRIPTION

Tables of snippets that must be reported and a table that must not.

A reported call is a statement of its own, of a sub whose value is the result
of a builtin that the configuration names, or of an C<eval> block.  The edges
are the ways of returning such a result, the ways of dropping it, and the calls
that look the same and are not.

=cut

use Test::More;
use File::Path ();
use File::Temp ();
use Perl::Critic;
use Perl::Critic::Distribution ();

# Loaded so that a syntax error in it is a compile failure here rather than
# Perl::Critic reporting no such policy.  Named as a string below, which is
# what ProhibitUnusedImports cannot see.
use Perl::Critic::Policy::ErrorHandling::RequireCheckedIndirectResults;    ## no critic (ProhibitUnusedImports)

# The anchored long name because -single-policy is a pattern.
my $POLICY = '^Perl::Critic::Policy::ErrorHandling::RequireCheckedIndirectResults$';

# -profile => q{} because Perl::Critic otherwise walks up from cwd looking for a
# .perlcriticrc, finds this dist's own, and runs every policy in it against
# these snippets.  A configured case passes its profile as a string instead.
my $critic_with = sub {
    my ($config) = @_;
    my $profile = defined $config ? \"[ErrorHandling::RequireCheckedIndirectResults]\n$config\n" : q{};
    return Perl::Critic->new( -profile => $profile, '-single-policy' => $POLICY, -severity => 1 );
};
my $critic = $critic_with->();

my $check_table = sub {
    my ( $label, $with, %cases ) = @_;
    foreach my $case ( sort keys %cases ) {
        my ( $expected, $source ) = @{ $cases{$case} };
        is( scalar $with->critique( \$source ), $expected, "$label: $case" ) or diag $source;
    }
    return;
};

my $SUB = q{sub finish { return close $_[0] } };

$check_table->(
    'a sub whose value is a result to check',
    $critic,
    'close, returned'           => [ 1, $SUB . q{finish($fh);} ],
    'as its last statement'     => [ 1, q{sub finish { close $_[0] } finish($fh);} ],
    'open'                      => [ 1, q{sub open_log { return open my $fh, '>>', $_[0] } open_log($path);} ],
    'open, last'                => [ 1, q{sub open_log { open my $fh, '>>', $_[0] } open_log($path);} ],
    'print, as the default has' => [ 1, q{sub shout { print "hello\n" } shout();} ],
    'an eval block'             => [ 1, q{sub try_it { return eval { risky(); 1 } } try_it();} ],
    'an eval block, last'       => [ 1, q{sub try_it { eval { risky(); 1 } } try_it();} ],
    'a lexical sub'             => [ 1, q{my sub finish { return close $_[0] } finish($fh);} ],
    'on one of its paths'       => [ 1, q{sub finish { return 1 if -d $_[0]; return close $_[0] } finish($fh);} ],
    'called before its body'    => [ 1, q{finish($fh); sub finish { return close $_[0] }} ],
    'called once in two places' => [ 2, $SUB . q{finish($a1); finish($a2);} ],
);

$check_table->(
    'dropped',
    $critic,
    'a statement of its own'     => [ 1, $SUB . q{finish($fh);} ],
    'without parens'             => [ 1, $SUB . q{finish $fh;} ],
    'with a postfix if'          => [ 1, $SUB . q{finish($fh) if $want;} ],
    'with a postfix foreach'     => [ 1, $SUB . q{finish($_) foreach @handles;} ],
    'last in the block of an if' => [ 1, $SUB . q{if ($want) { finish($fh) }} ],
    'in the block of a foreach'  => [ 1, $SUB . q{foreach my $h (@handles) { finish($h); print $h }} ],
);

$check_table->(
    'allowed',
    $critic,
    'checked with or'              => [ 0, $SUB . q{finish($fh) or die "no $fh";} ],
    'checked with ||'              => [ 0, $SUB . q{finish($fh) || die "no $fh";} ],
    'assigned'                     => [ 0, $SUB . q{my $ok = finish($fh);} ],
    'tested'                       => [ 0, $SUB . q{if ( finish($fh) ) { 1 }} ],
    'returned'                     => [ 0, $SUB . q{sub outer { return finish( $_[0] ) }} ],
    'the value of another sub'     => [ 0, $SUB . q{sub outer { finish( $_[0] ) }} ],
    'the value of a do block'      => [ 0, $SUB . q{my $ok = do { finish($fh) };} ],
    'an argument'                  => [ 0, $SUB . q{ok( finish($fh), 'made' );} ],
    'a sub that asks wantarray'    => [ 0, q{sub finish { die 'check me' if !defined wantarray; return close $_[0] } finish($fh);} ],
    'a result through a variable'  => [ 0, q{sub finish { my $ok = close $_[0]; return $ok } finish($fh);} ],
    'a result inside an inner sub' => [ 0, q{sub finish { my $f = sub { return close $_[0] }; return 1 } finish($fh);} ],
    'a sub that returns another'   => [ 0, q{sub finish { return 1 } finish($fh);} ],
    'a builtin the default leaves' => [ 0, q{sub own { return chmod 0644, $_[0] } own($file);} ],
    'mkdir, which it leaves too'   => [ 0, q{sub make_dir { return mkdir $_[0] } make_dir($dir);} ],
    'a file under autodie'         => [ 0, q{use autodie; sub finish { return close $_[0] } finish($fh);} ],
    'a sub defined elsewhere'      => [ 0, q{finish($fh);} ],
    'an eval of a string, left'    => [ 0, q{sub run_it { return eval $code } run_it();} ],
);

$check_table->(
    'the same spelling, another thing',
    $critic,
    'a method'                => [ 0, $SUB . q{$obj->finish($fh);} ],
    'a hash key'              => [ 0, $SUB . q{$h{finish} = 1;} ],
    'the left of a fat comma' => [ 0, $SUB . q{my %h = ( finish => 1 );} ],
    'the name of the sub'     => [ 0, $SUB ],
);

$check_table->(
    'configured as RequireCheckedSyscalls is',
    $critic_with->('functions = :builtins'),
    'every builtin that returns a status' => [ 1, q{sub own { return chmod 0644, $_[0] } own($file);} ],
    'mkdir among them'                    => [ 1, q{sub make_dir { return mkdir $_[0] } make_dir($dir);} ],
);
$check_table->(
    'configured as RequireCheckedSyscalls is',
    $critic_with->('exclude_functions = print'),
    'a function left out'        => [ 0, q{sub shout { print "hello\n" } shout();} ],
    'and the rest still counted' => [ 1, $SUB . q{finish($fh);} ],
    'and eval with them'         => [ 1, q{sub try_it { return eval { risky(); 1 } } try_it();} ],
);

# A sub in one file of a distribution, and calls of it in another.  Through
# Perl::Critic::Distribution, which needs files on disk under lib/.
{
    local %Perl::Critic::Distribution::FOR;
    local $ENV{XDG_CACHE_HOME} = File::Temp::tempdir( CLEANUP => 1 );

    my $root = File::Temp::tempdir( CLEANUP => 1 );
    File::Path::make_path("$root/lib/Some");
    my %files = (
        'dist.ini'          => "name = Some\n",
        'lib/Some.pm'       => "package Some;\nsub finish { return close \$_[0] }\nsub all { return \@_ }\n1;\n",
        'lib/Some/Same.pm'  => "package Some;\nsub setup {\n    finish(\$_[0]);\n    return 1;\n}\n1;\n",
        'lib/Some/Other.pm' => "package Some::Other;\nsub one {\n    Some::finish(\$_[0]);\n    finish(\$_[0]);\n    return 1;\n}\n1;\n",
        'lib/Some/Fine.pm'  => "package Some::Fine;\nsub one {\n    Some::finish(\$_[0]) or die;\n    Some->finish(\$_[0]);\n    Some::all(\$_[0]);\n    return 1;\n}\n1;\n",
    );
    foreach my $name ( keys %files ) {
        open( my $fh, '>', "$root/$name" ) or die "$root/$name: $!";
        print {$fh} $files{$name};
        close($fh) or die "$root/$name: $!";
    }

    my $found = sub {
        my ($file) = @_;
        return [ map { $_->line_number . q{ } . $_->description } $critic->critique("$root/$file") ];
    };

    is_deeply( $found->('lib/Some/Same.pm'),  ['3 The result of close, returned by a sub, is not checked'], 'another file: a bare call in the package of the sub' );
    is_deeply( $found->('lib/Some/Other.pm'), ['3 The result of close, returned by a sub, is not checked'], 'another file: a qualified call, and not a bare one from another package, whose import is not known' );
    is_deeply( $found->('lib/Some/Fine.pm'),  [],                                                           'another file: a checked call, a method, and a sub that returns a list' );
}

done_testing;
