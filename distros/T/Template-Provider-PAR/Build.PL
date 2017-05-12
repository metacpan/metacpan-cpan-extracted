use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(code => <<'CODE');
use strict;
# check verision in files is correct.
sub pod_version_ok
{
    my $builder = shift;
    my $file = shift;
    my $version = $builder->dist_version;
    my (@version_lines, @version_matches);
    open my $fh, $file or die "Failed to open $file for POD version check: $!";
    eval 
    {
        @version_lines = grep /^=head1 VERSION/.../^=head1/, <$fh>;
        @version_matches = grep { /\b\Q$version\E\b/ } @version_lines;
    };
    close $fh;
    die $@ if $@;

    return 1 if !@version_lines or @version_matches;
    print "Version POD section defined but does not mention version '$version' in $file\n";
    return;
}

# check versions in POD
sub ACTION_distcheck
{
    my $self = shift;

    return $self->SUPER::ACTION_distcheck(@_)
        unless grep { 
            !$self->pod_version_ok($_); 
        } @{ $self->rscan_dir('lib', qr/\.(pm|pod)$/) };

    # a bad pod found

    my $version = $self->dist_version;
    my $msg = "POD versions appear to be out of sync with the distribution version $version\n";
    $self->invoked_action eq 'distcheck'?
        die $msg : warn $msg;
}

CODE


my $builder = $class->new
    (module_name         => 'Template::Provider::PAR',
     license             => 'perl',
     dist_author         => 'Nick Woolley <npw@cpan.org>',
     dist_version_from   => 'lib/Template/Provider/PAR.pm',
     dist_abstract       => 'Include templates from a path within a PAR or Zip archive',
     create_readme       => 1,
     create_makefile_pl  => 'traditional',
     requires => 
     {
      'Test::More' => 0,
      'version'    => 0,
      'Module::Build' => 0,
      'Template::Provider'   => '2.93',
      'PAR' => 0,
      'Archive::Zip' => 0,
      'File::Spec' => 0,
      'Scalar::Util' => 0,
     },
     recommends => 
     {
      'Test::Differences' => '0.47',
      'Test::Pod::Coverage' => 0,
      'Test::Perl::Critic' => 0,
      'Test::Pod' => 0,
      'Test::Prereq::Build' => 0,
     },
     test_files         => [ glob('t/*.t') ],
     add_to_cleanup      => [ 'Template-Provider-PAR-*', 't/tmp/*' ],
    );



$builder->create_build_script();

