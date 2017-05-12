
use strict;
use warnings;

use Module::Build 0.3601;

my $class = Module::Build->subclass(code => <<'EOF');
use File::Copy;
use File::Spec::Functions;
sub process_grammar_files {
    my $self = shift;
    my $grammar='Grammar.pm';

    # precompile grammar
    system("$^X -MParse::RecDescent - grammar Module::ExtractUse::Grammar");

    # add $VERSION to grammer
    open(my $fh,'<',$grammar) || die "cannot read $grammar: $!";
    my @content = <$fh>;
    close $fh;
    splice(@content,1,0,'our $VERSION=0.341;'."\n");
    open(my $out,">",$grammar) || die "cannot write $grammer: $!";
    print $out @content;
    close $out;

    # move Grammer.pm to right place
    my $target = catfile(qw(lib Module ExtractUse),$grammar);
    move($grammar, $target) || die "Could not move precompiled $grammar to lib/Module/ExtractUse/Grammer.pm: $!";
}

EOF

my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.28',
    'Test::Deep' => '0',
    'Test::More' => '0',
    'Test::NoWarnings' => '0'
  },
  'configure_requires' => {
    'Module::Build' => '0.28'
  },
  'requires' => {
    'Carp' => '0',
    'Parse::RecDescent' => '1.967009',
    'Pod::Strip' => '0',
    'perl' => '5.008',
    'strict' => '0',
    'vars' => '0',
    'warnings' => '0'
  },
  'dist_abstract' => 'Find out what modules are used',
  'dist_author' => [
    'Thomas Klausner <domm@cpan.org>',
    'Kenichi Ishigaki <kishigaki@gmail.com>'
  ],
  'dist_name' => 'Module-ExtractUse',
  'dist_version' => '0.341',
    'license' => 'perl',
    'module_name' => 'Module::ExtractUse',
  'module_name' => 'Module::ExtractUse',
  'recursive_test_files' => 1,
);

my $build = $class->new(%module_build_args);
$build->add_build_element('grammar');

$build->create_build_script;
