use strict;
use warnings;

use Test::More;
use File::Find;
use IPC::Run3;

my @files;
find( { wanted   => sub {
            push @files, $File::Find::name if -f;
            $File::Find::prune = 1 if $_ eq "t/tmp" or m{/\.git$};
        },
        no_chdir => 1 },
      qw{lib html xt} );

if ( my $dir = `git rev-parse --git-dir 2>/dev/null` ) {
    # We're in a git repo, use the ignore list
    chomp $dir;
    my %ignores;
    $ignores{ $_ }++ for grep $_, split /\n/,
        `git ls-files -o -i --exclude-standard .`;
    @files = grep {not $ignores{$_}} @files;
}

sub check {
    my $file = shift;
    my %check = (
        strict   => 0,
        warnings => 0,
        no_tabs  => 0,
        shebang  => 0,
        exec     => 0,
        compile_perl => 0,
        @_,
    );

    if ($check{strict} or $check{warnings} or $check{shebang} or $check{no_tabs}) {
        local $/;
        open my $fh, '<', $file or die $!;
        my $content = <$fh>;

        unless ($check{shebang} != -1 and $content =~ /^#!(?!.*perl)/i) {
            like(
                $content,
                qr/^use strict(?:;|\s+)/m,
                "$file has 'use strict'"
            ) if $check{strict};

            like(
                $content,
                qr/^use warnings(?:;|\s+)/m,
                "$file has 'use warnings'"
            ) if $check{warnings};
        }

        if ($check{shebang} == 1) {
            like( $content, qr/^#!/, "$file has shebang" );
        } elsif ($check{shebang} == -1) {
            unlike( $content, qr/^#!/, "$file has no shebang" );
        }

        if ($check{no_tabs} == 1) {
            unlike( $content, qr/\t/, "$file has no hard tabs" );
        }
    }

    my $executable = ( stat $file )[2] & oct(100);
    if ($check{exec} == 1) {
        ok( $executable, "$file permission is u+x" );
    } elsif ($check{exec} == -1) {
        ok( !$executable, "$file permission is u-x" );
    }

    if ($check{compile_perl}) {
        my ($input, $output, $error) = ('', '', '');
        run3( [ $^X, '-Ilib', '-Mstrict', '-Mwarnings', '-c', $file ], \$input, \$output, \$error, );
        is $error, "$file syntax OK\n", "$file syntax is OK";
    }
}

check( $_, shebang => -1, exec => -1, warnings => 1, strict => 1, no_tabs => 1 )
    for grep {m{^lib/.*\.pm$}} @files;

check( $_, shebang => -1, exec => -1, warnings => 1, strict => 1, no_tabs => 1 )
    for grep {m{^x?t/.*\.t$}} @files;

check( $_, shebang => 1, exec => 1, warnings => 1, strict => 1, no_tabs => 1 )
    for grep {m{^s?bin/}} @files;

check( $_, compile_perl => 1, exec => 1, no_tabs => 1 )
    for grep { -f $_ } map { my $v = $_; $v =~ s/\.in$//; $v } grep {m{^s?bin/} and not m{\.sh$}} @files;

check( $_, exec => -1, no_tabs => 1 )
    for grep {m{^html/}} @files;

check( $_, exec => -1, no_tabs => 1 )
    for grep {m{^static/}} @files;

check( $_, exec => -1, no_tabs => 1 )
    for grep {m{^po/}} @files;

check( $_, exec => -1, no_tabs => 1 )
    for grep {m{^etc/}} @files;

done_testing;
