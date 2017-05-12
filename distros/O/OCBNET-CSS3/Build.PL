use 5.008;
use strict;
use warnings FATAL => 'all';
use Module::Build;
use Software::License;
use Config;

if (-d ".git") {
    my ($dir, $manifest);
    open $manifest, ">", "MANIFEST" or die "MANIFEST: $!";
    print $manifest "MANIFEST\n";
    print $manifest `git ls-files`, "\n";
}

my $class = Module::Build->subclass(
    class => "Module::Build::Custom",
    code => <<'SUBCLASS' );

my $re_version = qr/our\s+\$VERSION\s*=\s*[\"\']
                    ([0-9]+\.[0-9]+\.[0-9]+(?:\-.+?)?)
                   [\"\']\s*\;/x;

# ./Build versions
sub ACTION_versions {
    if (-d ".git") {
        require File::Slurp;
        @files = grep { m/.pm$/i } split /\r?\n/, `git ls-files`;
        for(my $i = 0; $i < scalar(@ARGV) - 1; $i++) {
            if ($ARGV[$i] eq "versionize") {
                $tag = $ARGV[$i+1]; last;
            }
        }
        my $file_opt = { binmode => ':raw' };
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, $file_opt);
            if ($data =~ m/$re_version/i) {
                print "  $filename ($1)\n";
            } else {
                print "  $filename ([NA])\n";
            }
        }
    } else {
      die "git directory not found";
    }
}

# ./Build versionize [2.4.6]
sub ACTION_versionize {
    if (-d ".git") {
        my $tag;
        require File::Slurp;
        @files = grep { m/.pm$/i } split /\r?\n/, `git ls-files`;
        for(my $i = 0; $i < scalar(@ARGV) - 1; $i++) {
            if ($ARGV[$i] eq "versionize") {
                $tag = $ARGV[$i+1]; last;
            }
        }
        unless ($tag) {
            $tag = `git describe --abbrev=0 --always`;
            $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
            unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
            { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
            # increment patch level
            else { $tag = $1 . ($2 + 1); }
        }
        $tag =~ s/(?:\A\s+|\Av|\s+\z)//g;
        my $file_opt = { binmode => ':raw' };
        print "update *.pm with new version <$tag>\n";
        unless ( $tag =~ m/(\d+\.\d+\.)(\d+)(?:\-|\z)/ )
        { die "tag <$tag> invalid (\\d+.\\d+.\\d+)\n"; }
        foreach my $filename (@files) {
            my $data = File::Slurp::read_file($filename, $file_opt);
            if ($data =~ s/$re_version/our \$VERSION = \'$tag\';/i) {
                next if $tag eq $1;
                print "  update version $filename (was $1)\n";
                File::Slurp::write_file($filename, $file_opt, $data);
            }
        }
    } else {
      die "git directory not found";
    }
}

SUBCLASS

my $builder = Module::Build::Custom->new(
    module_name         => 'OCBNET::CSS3',
    license             => 'GPL_3',
    dist_author         => q{Marcel Greter <marcel.greter@ocbnet.ch>},
    dist_abstract       => 'Parse, manipulate and render CSS files',
    dist_version_from   => 'lib/OCBNET/CSS3.pm',
    release_status      => 'stable',
    create_license      => 1,
    configure_requires => {
        'Module::Build' => 0,
        'Software::License' => 0
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'File::Slurp' => 0,
    },
    meta_merge => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/mgreter/OCBNET-CSS3.git',
          web => 'https://github.com/mgreter/OCBNET-CSS3',
        }
      },
    },
    add_to_cleanup     => [ 'OCBNET-CSS3-*' ],
    $Config{cc} eq 'clang' ? (
        # clang has a bunch of asinine warnings on by default:
        extra_compiler_flags => '-Wno-parentheses -Wno-tautological-compare -Wno-unused-value',
    ) : (),
    extra_linker_flags => '',
);

$builder->create_build_script();
