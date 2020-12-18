use strict;
use warnings;
use feature 'say';

use Capture::Tiny qw(:all);
use Data::Dumper;
use File::Path qw(remove_tree);
use Test::More;

BEGIN {
    use_ok( 'Syntax::Check' ) || print "Bail out!\n";
}

my $m = 'Syntax::Check';
my $f = 't/data/test.pl';
my $b = 'bin/syncheck';

# fail no file
{
    my $ret = eval { $m->new; 1; };
    is $ret, undef, "If no file param sent in, croak ok";
}

# params
{

    # just file
    {
        my ($out, $err) = capture {
            $m->new(file => $f)->check;
        };

        like $err, qr/syntax OK/, "with just file param, ok";
        unlike $err, qr/pragma/, "with just file param, no verbose ok";
    }

    # verbose
    {
        my ($out, $err) = capture {
            $m->new(verbose => 1, file => $f)->check;
        };

        like $err, qr/syntax OK/, "verbose success ok";
        like $out, qr/pragma/, "verbose info output ok";
    }

    # keep disabled (default)
    {
        my ($temp_dir);
        my ($out, $err) = capture {
            my $o = $m->new(file => $f)->check;
        };
        like $err, qr/syntax OK/, "keep disabled success ok";
        unlike $out, qr/pragma/, "keep disabled w/o verbose output ok";
    }
    # keep enabled
    {
        my $temp_dir;

        my ($out, $err) = capture {
            my $o = $m->new(keep => 1, file => $f);
            $o->check;
            $temp_dir = $o->{lib};
        };

        like $err, qr/syntax OK/, "enable keep success ok";
        unlike $out, qr/pragma/, "enable keep w/o verbose output ok";
        is defined $temp_dir && -d $temp_dir, 1, "temp dir kept if keep enabled";

        is remove_tree($temp_dir), 8, "temp dir removed ok";
        is -d $temp_dir, undef, "temp dir kept ok";
    }

    # keep enabled && verbose
    {
        my $temp_dir;

        my ($out, $err) = capture {
            my $o = $m->new(keep => 1, verbose => 1, file => $f);
            $o->check;
            $temp_dir = $o->{lib};
        };

        like $err, qr/syntax OK/, "enable keep && success success ok";
        like $out, qr/pragma/, "enable keep with verbose output ok";
        like $out, qr/temp lib dir/, "enable keep with verbose output ok";
        is defined $temp_dir && -d $temp_dir, 1, "temp dir kept && verbose if keep enabled";

        is remove_tree($temp_dir), 8, "temp dir removed (keep & verbose) ok";
        is -d $temp_dir, undef, "temp dir removed (keep & verbose) ok";

    }
}

# binary
{
    # no file param
    {
        my ($out, $err) = capture { `$^X $b` };
        like $err, qr/Program needs a file/, "bin: croak if no file arg ok";
    }

    # only file param
    {
        my ($out, $err) = capture { `$^X $b $f` };
        like $err, qr/syntax OK/, "bin: with just file param, ok";
        unlike $err, qr/pragma/, "bin: with just file param, no verbose ok";
    }

    # verbose
    {
        # -v
        {
            my $out;
            my (undef, $err) = capture {$out = `$^X $b -v $f`};

            like $err, qr/syntax OK/, "bin: -v success ok";
            like $out, qr/pragma/, "bin: -v success prints pragma ok";
            like $out, qr/File::Path/, "bin: -v success prints available modules ok";

            if ($out =~ /Created temp lib dir '(.*)'/) {
                is -d $1, undef, "bin: --verbose w/o keep temp dir removed ok";
            }
        }

        # --verbose
        {
            my $out;
            my (undef, $err) = capture { $out = `$^X $b --verbose $f` };

            like $err, qr/syntax OK/, "bin: --verbose success ok";
            like $out, qr/pragma/, "bin: --verbose info output ok";

            if ($out =~ /Created temp lib dir '(.*)'/) {
                is -d $1, undef, "bin: --verbose w/o keep temp dir removed ok";
            }
        }
    }

    # keep disabled (default)
    {
        my $out;
        my (undef, $err) = capture { $out = `$^X $b $f`};

        like $err, qr/syntax OK/, "bin: keep disabled success ok";
        unlike $out, qr/pragma/, "bin: keep disabled w/o verbose output ok";

        if ($out =~ /Created temp lib dir '(.*)'/) {
            is -d $1, '', "bin: --verbose w/o keep temp dir removed ok";
        }
    }

    # keep enabled
    {
        my $out;
        my (undef, $err) = capture { $out = `$^X $b -v -k $f` };

        like $err, qr/syntax OK/, "bin: enable keep success ok";
        like $out, qr/pragma/, "bin: enable keep with verbose output ok";

        if ($out =~ /Created temp lib dir '(.*)'/) {
            is -d $1, 1, "bin: --keep temp dir kept ok";
            is remove_tree($1), 8, "bin: --keep rmdir temp dir removed ok";
            is -d $1, undef, "bin: --keep temp dir removed ok";
        }
    }

    # help
    {
        like `$^X $b -h`, qr/USAGE/, "help displayed with -h ok";
        like `$^X $b --help`, qr/USAGE/, "help displayed with --help ok";
    }
}

done_testing;
