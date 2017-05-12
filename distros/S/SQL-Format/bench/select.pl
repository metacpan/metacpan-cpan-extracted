use strict;
use warnings;
use lib 'lib';
use feature 'say';
use lib::xi;
use SQL::Abstract;
use SQL::Maker;
use SQL::Format;
use SQL::Object qw(sql_obj);
use SQL::Interp qw(sql_interp);
use Benchmark qw(cmpthese :hireswallclock);
use Config;
use Data::Dumper;

sub DEBUG () { 0 }
my $count ||= -1;

#$SQL::Format::QUOTE_CHAR = '';

show_version(qw{
    SQL::Abstract
    SQL::Maker
    SQL::Interp
    SQL::Object
    SQL::Format
});

my $abstract = SQL::Abstract->new;
my $maker    = SQL::Maker->new(driver => 'SQLite', new_line => ' ');
my $sqlf     = SQL::Format->new;

cmpthese $count, {
    'SQL::Abstract' => sub {
        my ($stmt, @bind) = $abstract->select(foo => [qw/bar baz/], {
            hoge => { -in => [qw/fuga piyo/] },
            fizz => { '>' => 'bazz' },
        });
        say Dumper [$stmt, @bind] if DEBUG;
    },
    'SQL::Maker' => sub {
        my ($stmt, @bind) = $maker->select(foo => [qw/bar baz/], {
            hoge => [qw/fuga piyo/],
            fizz => { '>' => 'bazz' },
        });
        say Dumper [$stmt, @bind] if DEBUG;
    },
    'SQL::Format' => sub {
#        my ($stmt, @bind) = sqlf 'SELECT %c FROM %t WHERE %w' => (
#            [qw/bar baz/],
#            'foo',
#            {
#                hoge => [qw/fuga piyo/],
#                fizz => { '>' => 'bazz' },
#            },
#        );
        my ($stmt, @bind) = $sqlf->select(foo => [qw/bar baz/], {
            hoge => [qw/fuga piyo/],
            fizz => { '>' => 'bazz' },
        });
        say Dumper [$stmt, @bind] if DEBUG;
    },
    'SQL::Interp' => sub {
        my ($stmt, @bind) = sql_interp 'SELECT bar baz FROM foo WHERE', {
            hoge => [qw/fuga piyo/],
            fizz => { '>' => 'buzz' },
        };
        say Dumper [$stmt, @bind] if DEBUG;
    },
    'SQL::Object' => sub {
        my $sql = sql_obj 'fizz > :fizz AND hoge IN :hoge' => { fizz => 'buzz', hoge => [qw/fuga piyo/] };
        my ($stmt, @bind) = ('SELECT bar baz FROM foo WHERE '.$sql->as_sql, $sql->bind);
        say Dumper [$stmt, @bind] if DEBUG;
    },
}, 'all';

sub show_version {
    my $cpu = '';
    if ($^O eq 'linux') {
        $cpu = (split ': ', scalar `grep "model name" /proc/cpuinfo | uniq`)[1];
    }
    elsif ($^O eq 'darwin') {
        $cpu = (split ': ', scalar `sysctl machdep.cpu.brand_string`)[1];
    }
    chomp($cpu);

    say "# CPU: $cpu";
    say "# perl-$^V ($Config{archname})";
    printf "# %-14s: v%s\n", $_, $_->VERSION for @_;
}

__END__
