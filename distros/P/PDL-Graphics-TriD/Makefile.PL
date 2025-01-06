use strict;
use warnings;
use ExtUtils::MakeMaker;
use PDL::Core::Dev;

my $package_name = "PDL::Graphics::TriD";
(my $repo = $package_name) =~ s#::#-#g;
$repo = "PDLPorters/$repo";
WriteMakefile (
  NAME         => $package_name,
  AUTHOR => 'PerlDL Developers <pdl-general@lists.sourceforge.net>',
  LICENSE=> "perl",
  VERSION_FROM => 'TriD.pm',
  PM => {
    'TriD.pm' => '$(INST_LIBDIR)/TriD.pm',
    (map +($_ => '$(INST_LIBDIR)/'.$_), glob 'TriD/*.pm'),
    'DemoTriD1.pm' => '$(INST_LIB)/PDL/Demos/TriD1.pm',
    'DemoTriD2.pm' => '$(INST_LIB)/PDL/Demos/TriD2.pm',
    'DemoTriDGallery.pm' => '$(INST_LIB)/PDL/Demos/TriDGallery.pm',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 0,
    'PDL' => '2.096',
    'OpenGL' => '0.70',
    'OpenGL::GLUT' => '0.72',
  },
  PREREQ_PM => {
    'PDL' => '2.096',
    'OpenGL' => '0.70',
    'OpenGL::GLUT' => '0.72',
  },
  TEST_REQUIRES => {
    'Test::More' => '0.88',
  },
  META_MERGE => {
    "meta-spec" => { version => 2 },
    resources => {
      homepage => 'http://pdl.perl.org/',
      bugtracker  => {web=>"https://github.com/$repo/issues"},
      repository  => {
        url => "git://github.com/$repo.git",
        type => 'git',
        web => "https://github.com/$repo",
      },
      x_IRC => 'irc://irc.perl.org/#pdl',
    },
  },
);

sub MY::postamble {
  my $oneliner = PDL::Core::Dev::_oneliner(qq{exit if \$ENV{DESTDIR}; use PDL::Doc; eval { PDL::Doc::add_module(shift); }});
  qq|\ninstall :: pure_install\n\t$oneliner \$(NAME)\n|;
}
