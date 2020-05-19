use Test2::V0 -no_srand => 1;
use lib 't/lib';
use LiveTest;
use NewFangle qw( newrelic_configure_log );

my $app = NewFangle::App->new;

is(
  $app->start_web_transaction("web1"),
  object {
    call [ isa => 'NewFangle::Transaction' ] => T();
    call [ add_attribute_int    => 'foo_int',              10 ] => T();
    call [ add_attribute_long   => 'foo_long',             11 ] => T();
    call [ add_attribute_double => 'foo_double',         3.14 ] => T();
    call [ add_attribute_string => 'foo_string', 'hello perl' ] => T();
    call end => T();
  },
);

is(
  $app->start_non_web_transaction("nonweb1"),
  object {
    call [ isa => 'NewFangle::Transaction' ] => T();
    call [ notice_error => 3, "oh boy this is bad", "Error::Class" ] => U();
  },
);

is(
  $app->start_web_transaction('ignore1'),
  object {
    call [ isa => 'NewFangle::Transaction' ] => T();
    #call [ record_custom_event => NewFangle::CustomEvent->new("roar") ] => T();
    call [ set_name => 'ignore2' ] => T();
    call [ record_custom_metric => 'cm', 3.14 ] => T();
    call ignore => T();
  },
);

done_testing;
