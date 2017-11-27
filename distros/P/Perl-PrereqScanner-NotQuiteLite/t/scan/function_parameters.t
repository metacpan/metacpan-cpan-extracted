use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Test::More;
use t::scan::Util;

test(<<'TEST'); # MHOWARD/Class-Type-Enum-0.009/lib/Class/Type/Enum.pm
use Function::Parameters;

method coerce_any ($class: $value) {
  return $value if eval { $value->isa($class) };

  for my $method (qw( inflate_ordinal inflate_symbol )) {
    my $enum = eval { $class->$method($value) };
    return $enum if $enum;
  }
  croak "Could not coerce invalid value [$value] into $class";
}
TEST

test(<<'TEST'); # MHOWARD/Class-Type-Enum-0.009/lib/Class/Type/Enum.pm
use Function::Parameters;

method stringify ($, $) {
  $self->ord_to_sym->{$self->{ord}};
}
TEST

test(<<'TEST'); # TJC/Test-PostgreSQL-1.23/lib/Test/PostgreSQL.pm
use Moo;
use Function::Parameters qw(:strict);

has base_dir => (
  is => "rw",
  default => sub {
    File::Temp->newdir(
        'pgtest.XXXXX',
        CLEANUP => $ENV{TEST_POSTGRESQL_PRESERVE} ? undef : 1,
        EXLOCK  => 0,
        TMPDIR  => 1
    );
  },
  coerce => fun ($newval) {
    # Ensure base_dir is absolute; usually only the case if the user set it.
    # Avoid munging objects such as File::Temp
    ref $newval ? $newval : File::Spec->rel2abs($newval);
  },
);
TEST

test(<<'TEST'); # ZMUGHAL/Renard-Curie-0.001/lib/Renard/Curie/Component/LogWindow.pm
use Function::Parameters;

method log( (Str) :$category, (Str) :$level, (Str) :$message ) {
        $self->add_log( {
                category => $category,
                level => $level,
                message => $message } );

        my $buffer = $self->builder->get_object('log-text')->get_buffer;
        $buffer->insert( $buffer->get_end_iter,
                sprintf("[%s] {%s} %s\n", $level, $category, $message ) );

        $self->_scroll_log_textview_to_end;
}
TEST

done_testing;
