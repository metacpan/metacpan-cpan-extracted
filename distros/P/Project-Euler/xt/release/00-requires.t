#!perl -T

use strict;
use warnings;

use autodie;
use Test::Most;
use File::Find::Node;
use File::Slurp;

use Readonly;

Readonly::Scalar  my $MAKEFILE     => 'Makefile.PL';
Readonly::Scalar  my $PROBLEM_PATH => 'lib/Project/';
Readonly::Scalar  my $TEST_PATH    => 't/';

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
}xmsio;

my $get_used_info = qr{
    (?:^|(?<=;))
    use
    \s+
    (?<name>
        [^\s;]+
    )
    (?:
        \s+
        (?<version>
            [\d.]+
        )
    )?
    (?:
        \s+
        (?:"|'|qw)
        [^;]+
    )?
    \s*
    (?:
        \n[^;]+
    )*
    ;
}xmsio;

my @makefile = read_file($MAKEFILE);
chomp @makefile;

for  my $line  (@makefile) {
    if ($line =~ $get_mod_info) {
        my ($type, $name, $version) = @+{qw/ type  name  version /};
        $required_for{$type =~ /test/ ? 'test' : 'normal'}->{$name} = ($version // 0);
    }
}



sub process_file {
    my $file = shift;
    return  unless  $file->path =~ /\.(?:p[ml]|t)$/i;

    my $contents = read_file $file->path;

    my $type = $file->path =~ /t$/i  ?  'test'  :  'normal';

    while ($contents =~ /$get_used_info/g) {
        my ($name, $version) = @+{qw/ name  version /};
        if ($name !~ /^Project::Euler::|^strict|^warnings/) {
            push @found, [$type, $file->path, $name, $version // 0];
        }
    }
}

my $f = File::Find::Node->new($PROBLEM_PATH);
$f->process(\&process_file)->find;

$f = File::Find::Node->new($TEST_PATH);
$f->process(\&process_file)->find;


plan tests =>   ( scalar @found                          )
              + ( scalar keys %{ $required_for{normal} } )
              + ( scalar keys %{ $required_for{test}   } );


my %checked;
for  my $found  (@found) {
    my ($type, $path, $name, $version) = @$found;
    $checked{$type}->{$name} = 1;
    if ($type eq 'normal'  and  !defined $required_for{$type}->{$name}) {
        fail("[$type] $path - $name ($version) required but not declared");
    }
    elsif ($type eq 'test') {
        if (!defined $required_for{$type}->{$name}) {
            if (!defined $required_for{normal}->{$name}) {
                fail("[$type] $path - $name ($version) required but not declared");
            }
            elsif ($version > 0) {
                my $want_version = $required_for{normal}->{$name};
                cmp_ok($version, '>=', $want_version, "[$type] $path - $name ($version) wrong version");
            }
            else {
                pass();
            }
        }
        elsif ($version > 0) {
            my $want_version = $required_for{$type}->{$name};
            cmp_ok($version, '>=', $want_version, "[$type] $path - $name ($version) wrong version");
        }
        else {
            pass();
        }
    }
    elsif ($version > 0) {
        my $want_version = $required_for{$type}->{$name};
        cmp_ok($version, '>=', $want_version, "[$type] $path - $name ($version) wrong version");
    }
    else {
        pass();
    }
}

for  my $type  (qw/ normal  test /) {
    for  my $wanted  (keys %{ $required_for{$type} }) {
        ok(defined $checked{$type}->{$wanted}, "$wanted is declared but never used");
    }
}
