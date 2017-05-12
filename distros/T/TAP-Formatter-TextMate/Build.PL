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
    module_name       => 'TAP::Formatter::TextMate',
    license           => 'perl',
    dist_author       => 'Andy Armstrong <andy@hexten.net>',
    dist_version_from => 'lib/TAP/Formatter/TextMate.pm',
    requires          => {
        'Test::More'             => 0,
        'Test::Harness'          => '2.99',
        'Test::More::Diagnostic' => 0,
        'HTML::Tiny'             => 0,
    },
    add_to_cleanup => ['TAP-Formatter-TextMate-*'],
);

$builder->create_build_script();
