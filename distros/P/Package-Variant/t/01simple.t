use strictures 2;
use Test::More;
use Test::Fatal;
use Package::Variant ();

my @DECLARED;

BEGIN {
  package TestSugar;
  use Exporter 'import';
  our @EXPORT_OK = qw( declare );
  sub declare { push @DECLARED, [@_] }
  $INC{'TestSugar.pm'} = __FILE__;
}

BEGIN {
  package TestVariable;
  use Package::Variant
    importing => { 'TestSugar' => [qw( declare )] },
    subs      => [qw( declare )];
  sub make_variant {
    my ($class, $target, @args) = @_;
    ::ok(__PACKAGE__->can('install'), 'install() is available')
      or ::BAIL_OUT('install() subroutine was not exported!');
    ::ok(__PACKAGE__->can('declare'), 'declare() import is available')
      or ::BAIL_OUT('proxy declare() subroutine was not exported!');
    declare target => $target;
    declare args   => [@args];
    declare class  => $class->_test_class_method;
    install target => sub { $target };
    install args   => sub { [@args] };
  }
  sub _test_class_method {
    return shift;
  }
  $INC{'TestVariable.pm'} = __FILE__;
}

my $variant = do {
    package TestScopeA;
    use TestVariable;
    TestVariable(3..7);
};

ok defined($variant), 'new variant is a defined value';
ok length($variant), 'new variant has length';
is $variant->target, $variant, 'target was new variant';
is_deeply $variant->args, [3..7], 'correct arguments received';

is_deeply shift(@DECLARED), [target => $variant],
  'target passed via proxy';
is_deeply shift(@DECLARED), [args => [3..7]],
  'arguments passed via proxy';
is_deeply shift(@DECLARED), [class => 'TestVariable'],
  'class method resolution';
is scalar(@DECLARED), 0, 'proxy sub called right amount of times';

use TestVariable as => 'RenamedVar';
is exception {
  my $renamed = RenamedVar(9..12);
  is_deeply $renamed->args, [9..12], 'imported generator can be renamed';
}, undef, 'no errors for renamed usage';

my @imported;
BEGIN {
  package TestImportableA;
  sub import { push @imported, shift }
  $INC{'TestImportableA.pm'} = __FILE__;
  package TestImportableB;
  sub import { push @imported, shift }
  $INC{'TestImportableB.pm'} = __FILE__;
  package TestArrayImports;
  use Package::Variant
    importing => [
      'TestImportableA',
      'TestImportableB',
    ];
  sub make_variant { }
  $INC{'TestArrayImports.pm'} = __FILE__;
}

use TestArrayImports;
TestArrayImports(23);

is_deeply [@imported], [qw( TestImportableA TestImportableB )],
  'multiple imports in the right order';

BEGIN {
  package TestSingleImport;
  use Package::Variant importing => 'TestImportableA';
  sub make_variant { }
  $INC{'TestSingleImport.pm'} = __FILE__;
}

@imported = ();

use TestSingleImport;
TestSingleImport(23);

is_deeply [@imported], [qw( TestImportableA )],
  'scalar import works';

@imported = ();

TestSingleImport::->build_variant;

is_deeply [@imported], [qw( TestImportableA )],
  'build_variant works';

like exception {
  Package::Variant->import(
    importing => \'foo', subs => [qw( foo )],
  );
}, qr/importing.+option.+hash.+array/i, 'invalid "importing" option';

like exception {
  Package::Variant->import(
    importing => { foo => \'bar' }, subs => [qw( bar )],
  );
}, qr/import.+argument.+foo.+not.+array/i, 'invalid import argument list';

like exception {
  Package::Variant->import(
    importing => [ foo => ['bar'], ['bam'], subs => [qw( bar )] ],
  );
}, qr/value.+3.+importing.+not.+string/i, 'importing array invalid key';

like exception {
  Package::Variant->import(
    importing => [ foo => \'bam', subs => [qw( bar )] ],
  );
}, qr/value.+2.+foo.+importing.+array/i, 'importing array invalid list';

BEGIN {
  package TestOverrideName;

  use Package::Variant;

  sub make_variant_package_name {
    my (undef, @args) = @_;
    return $args[0];
  }

  sub make_variant {
    install hey => sub { 'hey' };
  }
}

is(TestOverrideName::->build_variant('hey'), 'hey');

is(hey->hey, 'hey', 'hey');

done_testing;
