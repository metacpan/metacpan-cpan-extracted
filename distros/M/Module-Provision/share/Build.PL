use strict;
use warnings;
use version; our $VERSION = qv( '0.1' );

use File::Spec::Functions   qw( catfile );
use Module::Build;

sub whimper { print {*STDOUT} $_[ 0 ]."\n"; exit 0 }

my $perl_ver   = [% perl %];
my $module     = '[% project %]';
my $class_path = catfile( 'lib', split m{ :: }mx, "${module}.pm" );

$] >= $perl_ver or $ENV{PERL5_CPANPLUS_IS_VERSION}
   or whimper "Minimum required Perl version is ${perl_ver}";

Module::Build->new
   (  add_to_cleanup      => [ 'Debian_CPANTS.txt', 'MANIFEST.bak',
                               '[% distname %]-*',
                               map { ( '*/' x $_ ).'*~' } 0 .. 5 ],
      build_requires      => {
         'version'        => 0.88,
         'Module::Build'  => 0.4004, },
      configure_requires  => {
         'version'        => 0.88,
         'Module::Build'  => 0.4004, },
      create_license      => 1,
      create_packlist     => 0,
      create_readme       => 1,
      dist_version_from   => $class_path,
      license             => '[% license %]' || 'perl',
      meta_merge          => __get_resources(),
      module_name         => '[% project %]',
      no_index            => { directory => [ qw( examples inc share t ) ] },
      notes               => {
         min_perl_version => $perl_ver,
         url_prefix       => 'https://metacpan.org/module/', },
      recommends          => {
         'App::cpanminus' => 1.6005, },
      requires            => {
         'perl'           => $perl_ver,
         'Class::Usul'    => '0.22.0', },
      sign                => 1,
      share_dir           => -d 'share' ? 'share' : undef,
   )->create_build_script; # Goal!

exit 0;

sub __get_resources {
   my $distname  = '[% distname %]';
   my $home_page = '[% home_page %]',
   my $tracker   = 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=';
   my $resources = {};

   $resources->{bugtracker} = $tracker.$distname;
   $home_page and $resources->{homepage} = $home_page;
   $resources->{license} = [ 'http://dev.perl.org/licenses/' ];

   # Only get repository info when authoring a distribution
   my $repo; -f 'MANIFEST.SKIP' and $repo = __get_repository()
      and $resources->{repository} = $repo;

   return { resources => $resources };
}

sub __get_repository { # Accessor for the VCS repository information
   my $repo;

   -d q(.git) and $repo = __get_git_repository() and return $repo;
   -d q(.svn) and $repo = __get_svn_repository() and return $repo;

   return;
}

sub __get_git_repository {
   return (map  { s{ : }{/}mx; s{ @ }{://}mx; $_ }
           grep { m{ \A git }mx }
           map  { s{ \s+ }{ }gmx; (split ' ', $_)[ 1 ] }
           grep { m{ \A origin }mx }
              qx{ git remote -v 2>/dev/null })[ 0 ];
}

sub __get_svn_repository {
   return (grep { ! m{ \A file: }mx }
           (split q( ), (grep { m{ \A URL: }mx }
                            qx{ svn info })[ 0 ])[ 1 ])[ 0 ];
}

# Local Variables:
# mode: perl
# eval: (load-project-state "[% appdir %]")
# tab-title: [% project %]
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
