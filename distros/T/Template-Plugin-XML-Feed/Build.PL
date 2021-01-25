use Module::Build;

my $build = Module::Build->new(
  module_name        => 'Template::Plugin::XML::Feed',
  dist_version       => '1.0.2',
  license            => 'perl',
  create_makefile_pl => 'traditional',
  requires           => {
    Template => 0,
    XML::Feed => 0,
  },
  build_requires     => {
    Test::More => 0,
  },
  build_recommends   => {
    Test::Pod           => 0,
    Test::Pod::Coverage => 0,
  },
  meta_merge => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
       type => 'git',
       url  => 'git://github.com/davorg/template-plugin-xml-feed.git',
       web  => 'https://github.com/davorg/template-plugin-xml-feed',
     },
      bugtrakcer => {
       web  => 'https://github.com/davorg/template-plugin-xml-feed/issues',
     },
   },
 },
);

$build->create_build_script;
