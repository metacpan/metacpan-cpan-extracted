use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
    class => 'Pod::Site::Build',
    code => q{
        sub ACTION_distdir {
            my $self = shift;
            my $ret = $self->SUPER::ACTION_distdir(@_);
            my $file = File::Spec->catfile($self->dist_dir, qw(bin podsite));
            my $lib = File::Spec->catfile(qw(lib Pod Site.pm));
            return if -s $file > 200; # Skip if it's big.

            chmod 0222, $file;
            open my $fh, '>>', $file or die "Cannot open $file: $!\n";
            open my $pod, '<', $lib or die "Cannot open $lib: $!\n";
            while (<$pod>) {
                if (/^=head1\s+(?:Usage|Options|Author|Copyright)\b/) {
                    print $fh $_;
                    while (<$pod>) {
                        last if /^=/ && $_ !~ /^=head1\s+(?:Usage|Options|Author|Copyright)\b/;
                        print $fh $_;
                    }
                }
            }

            close $pod or die die "Cannot close $lib: $!\n";
            close $fh or die die "Cannot close $file: $!\n";
            chmod 0555, $file;
            return $ret;
        }
    },
);

my $build = $class->new(
    class => 'Module::Build::PodSite',
    module_name        => 'Pod::Site',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.35',
    },
    build_requires     => {
        'Module::Build'    => '0.35',
        'Test::File'       => 0,
        'Test::More'       => '0.88',
        'Test::MockModule' => '0.05',
        'Test::XPath'      => '0.12',
    },
    requires           => {
        'perl'                   => 5.006002,
        'Carp'                   => 0,
        'File::Basename'         => 0,
        'File::Copy'             => 0,
        'File::Path'             => '2.07',
        'File::Spec'             => 0,
        'Getopt::Long'           => 0,
        'HTML::Entities'         => 0,
        'Module::Metadata'       => '1.000000',
        'Object::Tiny'           => 0,
        'Pod::Simple'            => '3.12',
        'Pod::Simple::HTMLBatch' => '3.12',
        'Pod::Simple::Search'    => '3.12',
        'Pod::Simple::XHTML'     => '3.12',
        'Pod::Usage'             => 0,
    },
    recommends         => {
        'Test::Pod'           => '1.41',
        'Test::Pod::Coverage' => '1.06',
    },
    meta_merge         => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Pod-Site/',
            bugtracker => 'http://github.com/theory/pod-site/issues/',
            repository => 'http://github.com/theory/pod-site',
        }
    },
);

$build->add_build_element('js');
$build->add_build_element('css');
$build->create_build_script;


