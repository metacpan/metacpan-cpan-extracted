#
# note: i had such a hard time trying to do this with a tarball.
# forgiveme for doing this with Data::Dumper :)
#
use strict;
use warnings;

use File::Find::Rule;
use IO::All;
use YAML;

# some bits stolen from Ingy! (thanks, Brian :)
use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0)) or die "Couldn't chdir to ".dirname($0);
chomp( my $cwd = `pwd` );
(my $outfilename = basename($0)) =~ s/\.PL$//;

print "Preparing $outfilename...\n";
my $out = io($outfilename);

# make sure our defaults dir exists
my $dir = '../defaults';
die "Can't find defaults dir '$dir'" unless -d $dir;
chdir $dir;

# read in all files in defaults
my $data;
my $rule = File::Find::Rule->new;
$rule->or(
    $rule->new->directory->name('.svn')->prune->discard,
    $rule->new->directory->name('.')->discard,
    $rule->new->file->name(qr/\.swp$/)->discard,
    $rule->new,
);
foreach ( $rule->in('.') ) {
    next unless -f;
    print "Adding $_ to self-extractor..\n";
    $data->{$_} = io($_)->slurp;
}

# print script & archive
chdir($cwd) or die "Couldn't chdir to $cwd";
$out->print( "$Config{startperl}\n", join('',<DATA>) );
$out->print( "\n__DATA__\n", Dump($data) );
chmod 0755, $outfilename;
print "Done!\n";

__DATA__
use warnings;
use strict;

use File::Basename qw(dirname);
use File::Path qw(mkpath);
use YAML;
use IO::All;

# allow passing of -y and -n 
my ( $always_yes, $always_no );
if ( defined $ARGV[0] ) {
    if ( $ARGV[0] =~ /^--?y(es)?$/i ) {
        $always_yes = 1;
    }
    elsif ( $ARGV[0] =~ /^--?no?$/i ) {
        $always_no = 1;
    }
    else {
        print STDERR <<END;
usage: $0 [ -y | -n ]
-y will always overwrite files, -n will ignore existing files.
END
    }
}

# extract the files
print "Extracting SoggyOnion default files..\n";
my $data = Load(join('',<DATA>));
foreach my $path ( sort keys %$data ) {
    mkpath( dirname($path), 0, 0711 );
    if ( -f $path && not $always_yes ) {
        next if $always_no;
        my $response = '';
        while ( $response !~ /^(y|n)/i ) {
            print "$path exists. overwrite? [Y/n] ";
            $response = <STDIN>;
            $response = 'y' unless $response =~ /\S/;
        }
        next if $response =~ /^n/i;
    }

    # customize the configuration
    if ( $path eq 'config.yaml' ) {
        #print "Customizing $path\n";
        chomp(my $pwd = `pwd`);
        for ($data->{$path}) {
            s/^(\s+templatedir:\s+).+$/$1'$pwd\/templates'/m;
            s/^(\s+outputdir:\s+).+$/$1'$ENV{HOME}\/public_html'/m;
            s/^(\s+cachedir:\s+).+$/$1'\/tmp\/$ENV{USER}-cachedir'/m;
        }
    }

    #print "Writing $path\n";
    io($path)->print( $data->{$path} );
}

# instructions
print <<END;

Congratulations! Here's all that's left to do:
    
    1. Edit config.yaml
    2. Run: soggyonion /path/to/config.yaml
    3. Add the command you ran in #2 as a twice-a-day (or so) cron job
    4. Point your browser at the directory you specified as outputdir
       in the configuration

END

