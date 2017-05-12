package MooseX::GlobRefTestBase;

use Test::Unit::Lite;
use parent 'Test::Unit::TestCase';

use Test::Assert ':all';

use Scalar::Util 'reftype';

sub test_class {
    fail('test_class is not overriden');
};

sub test___isa {
    my $self = shift;
    my $test_class = $self->test_class;

    my $obj = $test_class->new;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    assert_equals('GLOB', reftype($obj));
};

sub test_accessor {
    my $self = shift;
    my $test_class = $self->test_class;

    my $obj = $test_class->new;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    assert_equals('default', $obj->field);
    assert_equals(1, $obj->field(1));
    assert_equals(1, $obj->field);
    assert_true($obj->clear_field);
    assert_equals('default', $obj->field);
};

sub test_slot_moc {
    my $self = shift;
    my $test_class = $self->test_class;

    my $mi = $test_class->meta->get_meta_instance;
    assert_not_null($mi);

    my $obj = $mi->create_instance;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    assert_true(! $mi->is_slot_initialized($obj, 'field'));
    assert_null($mi->get_slot_value($obj, 'field'));
    assert_equals(1, $mi->set_slot_value($obj, 'field', 1));
    assert_true($mi->is_slot_initialized($obj, 'field'));
    assert_equals(1, $mi->get_slot_value($obj, 'field'));
    assert_true($mi->deinitialize_slot($obj, 'field'));
    assert_null($mi->get_slot_value($obj, 'field'));
    assert_true(! $mi->is_slot_initialized($obj, 'field'));
    assert_equals(1, $mi->set_slot_value($obj, 'field', 1));
    assert_equals(1, $mi->get_slot_value($obj, 'field'));

    my $cloned = $mi->clone_instance( $obj );
    assert_not_null($cloned);
    assert_str_not_equals($obj, $cloned);
    assert_true($mi->is_slot_initialized($cloned, 'field'));
    assert_equals(1, $mi->get_slot_value($cloned, 'field'));
};

sub test_slot_moc_inline {
    my $self = shift;
    my $test_class = $self->test_class;

    my $mi = $test_class->meta->get_meta_instance;
    assert_not_null($mi);

    my $code_create_instance = $mi->inline_create_instance('$test_class');
    assert_not_equals('', $code_create_instance);
    my $code_get_slot_value = $mi->inline_get_slot_value('$obj', 'field');
    assert_not_equals('', $code_get_slot_value);
    my $code_is_slot_initialized = $mi->inline_is_slot_initialized('$obj', 'field');
    assert_not_equals('', $code_is_slot_initialized);
    my $code_set_slot_value = $mi->inline_set_slot_value('$obj', 'field', '$value');
    assert_not_equals('', $code_set_slot_value);
    my $code_deinitialize_slot = $mi->inline_deinitialize_slot('$obj', 'field');
    assert_not_equals('', $code_deinitialize_slot);

    my $obj = eval $code_create_instance;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    assert_null(eval $code_get_slot_value);
    assert_true(! eval $code_is_slot_initialized);
    my $value = 42;
    assert_equals($value, eval $code_set_slot_value);
    assert_equals($value, eval $code_get_slot_value);
    assert_true(eval $code_is_slot_initialized);
    assert_true(eval $code_deinitialize_slot);
    assert_null(eval $code_get_slot_value);
    assert_true(! eval $code_is_slot_initialized);
};

sub test_weak_field {
    my $self = shift;
    my $test_class = $self->test_class;

    my $mi = $test_class->meta->get_meta_instance;
    assert_not_null($mi);
    my $obj = $test_class->new;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    assert_null($obj->weak_field);
    {
           my $scalar = 'SCALAR';
           assert_not_null($obj->weak_field(\$scalar));
           assert_not_null($obj->weak_field);
           assert_equals('SCALAR', ${$obj->weak_field});
           $mi->weaken_slot_value($obj, 'weak_field');
    };
    assert_null($obj->weak_field);
};

sub test_dump {
    my $self = shift;
    my $test_class = $self->test_class;

    my $obj = $test_class->new;
    assert_not_null($obj);
    assert_isa($test_class, $obj);
    $obj->field('VALUE');
    my @dump = $obj->dump;
    assert_equals( 2, scalar @dump );
    assert_matches( qr/$test_class.*VALUE/s, join '', @dump );
    my $dump = $obj->dump;
    assert_matches( qr/$test_class.*VALUE/s, $dump );
};

1;
