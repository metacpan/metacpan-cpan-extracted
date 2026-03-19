#!perl
use v5.36;
use Test::More;

do_tests();
done_testing();

#######################################################################

sub do_tests {

  # use() PlackX::Framework
  ok(
    eval qq{
      package My::Test::App1 {
        use PlackX::Framework;
      }
      1;
    },
    'Create an empty app called $test_app_namespace'
  );

  # Test automatic subclass generation and exporting app_namespace() method to each
  foreach my $auto_class (qw(Handler Request Response Router Router::Engine)) {
    ok(
      "My::Test::App1::$auto_class"->isa('PlackX::Framework::'.$auto_class),
      "$auto_class is automatically created and is subclass of respective PXF class"
    );

    ok(
      "My::Test::App1::$auto_class"->can('app_namespace'),
      "$auto_class has an app_namespace method"
    );

    is(
      "My::Test::App1::$auto_class"->app_namespace => 'My::Test::App1',
       "$auto_class app_namespace method returns correct name"
    );
  }

}
