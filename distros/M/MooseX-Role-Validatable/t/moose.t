use strict;
use Test::More;

{

    package MyClass;

    use Moose;
    with 'MooseX::Role::Validatable';

    has 'ok' => (is => 'ro');
    has 'attr1' => (
        is         => 'rw',
        lazy_build => 1
    );

    sub _build_attr1 {
        my $self = shift;

        # Note initialization errors
        $self->add_errors({
                message           => 'Error: blabla',
                message_to_client => 'Something is wrong!'
            }) unless $self->ok;
    }

    sub _validate_some_other_errors {    # _validate_*
        my $self = shift;

        my @errors;
        push @errors,
            {
            message           => 'm...',
            message_to_client => 'c...',
            };
        return @errors;
    }

    sub _validate_other {
        return ('str');
    }

    no Moose;
    __PACKAGE__->meta->make_immutable;
}

## test MyClass
my $ex                 = MyClass->new;
my $validation_methods = $ex->validation_methods;
ok(grep { $_ eq '_validate_some_other_errors' } @$validation_methods);
ok(grep { $_ eq '_validate_other' } @$validation_methods);

ok($ex->initialized_correctly());
ok(!$ex->confirm_validity);
ok(!$ex->passes_validation);
my @errors = $ex->all_errors();
is(scalar(@errors), 2);
ok(grep { $_->message eq 'm...' } @errors);
ok(grep { $_->message eq 'str' } @errors);
ok(grep { $_->message_to_client eq 'c...' } @errors);
ok(grep { $_->message_to_client eq 'str' } @errors);

$ex = MyClass->new(ok => 0);
$ex->attr1;    # call lazy
ok(!$ex->initialized_correctly());
@errors = $ex->all_init_errors();
is(scalar(@errors), 1);
ok($errors[0]->message,           'Error: blabla');
ok($errors[0]->message_to_client, 'Something is wrong!');

done_testing;

1;
