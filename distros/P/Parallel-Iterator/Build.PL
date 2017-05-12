# $Id: Build.PL 2676 2007-10-03 17:38:27Z andy $
use strict;
use warnings;
use Module::Build;

my $build_class = Module::Build->subclass(
    class => 'inc::MyBuilder',
    code  => <<'    SUBCLASS',
      sub ACTION_testauthor {
          my $self = shift;
          $self->test_files('t', 'xt/author');
          $self->generic_test( type => 'default' );
      }
    SUBCLASS
);

my $builder = $build_class->new(
    module_name       => 'Parallel::Iterator',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/Parallel/Iterator.pm',
    requires          => {
        'Test::More' => 0,
        'Storable'   => 0,
        'IO::Handle' => 0,
        'IO::Select' => 0,
        'Config'     => 0,
        perl         => '5.8.0',
    },
    add_to_cleanup => ['Parallel-Iterator-*'],
);

$builder->create_build_script();
