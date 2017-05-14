#!perl -T

use strict;
use warnings;

use autodie;
use Test::Most;
use File::Find::Node;
use File::Slurp;

use Readonly;

Readonly::Scalar  my $PROBLEM_PATH => 'lib/Project/';

my @found;
my %required_for;

my $get_mod_info = qr{
    \A
    (?<type>
        (?:test_)?
        requires
    )
    \s+
    '
    (?<name>
        [^']+
    )
    '
    (?:
        \s+
        =>
        \s+
        '
        (?<version>
            [\d.]+
        )
        '
    )?
    ;
    \s*
    \z
}xmso;

my $same_version = qr{
    ^
    =head1 \s VERSION $
    [\s\n]+
    Version \s
    (?<version>
        v
        [\d.]+
    )
    $
    [\s\n]+
    =cut
    [\s\n]+
    use \s version \s 0.77;
    [^;]+
    \k{version}
}xmso;

my $same_name = qr{
    ^
    package \s
    (?:
        (?<name>
            Project::Euler::Problem::P
            (?<prob>
                \d+
            )
        )
      |
        (?<name>
            Project::Euler(?!::Problem::P\d+;)
            [^\s;]*
        )
    )
    ;$
    .+
    ^
    =head1 \s NAME
    [\s\n]+
    ^
    \k{name} \s - \s 
    (?(<prob>)
        Solutions \s for \s problem \s \k{prob}
        $
        .+
        =head2 \s Problem \s Number$
        [\s\n]+
        \k{prob}
    |
        \S+
    )
    .+
    ^ 1; \s+ \# \s+ End \s of \s \k{name} \Z
}xmso;


sub process_file {
    my $file = shift;
    return  unless  $file->path =~ /\.(?:p[ml])$/i;

    my $contents = read_file $file->path;

    push @found, [$file->path, $contents];
}

my $f = File::Find::Node->new($PROBLEM_PATH);
$f->process(\&process_file)->find;

plan tests =>   ( scalar @found * 2 );


for  my $found  (@found) {
    my ($path, $contents) = @$found;
    ok($contents =~ $same_version, "$path does not have the correct version");
    ok($contents =~ $same_name,    "$path does not have consistent names");
}
