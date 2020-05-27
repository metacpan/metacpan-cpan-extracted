use strict;
use Test::More 0.98;

use String::Secret;
use Scalar::Util qw/refaddr/;
use Storable qw/nfreeze thaw dclone/;

my $secret = String::Secret->new('mysecret');

my $freezed = eval { nfreeze($secret) };
is $@, '', 'freeze successful';
eval { thaw($freezed) };
like $@, qr/\Qcannot deserialize it/, 'block to thaw';

my $cloned_secret = eval { dclone($secret) };
is $@, '', 'dclone successful';
is $cloned_secret->unwrap, 'mysecret', 'clone can unwrap it';

subtest 'freezed content' => sub {
    my $deserialized_secret = force_thaw_storable($freezed);
    is $deserialized_secret->unwrap, '*' x 8, 'masked';
};

subtest 'serializable' => sub {
    my $serializable_secret = $secret->to_serializable();

    my $freezed = eval { nfreeze($serializable_secret) };
    is $@, '', 'freeze successful';

    my $deserialized_secret = eval { thaw($freezed) };
    is $@, '', 'thaw successful';
    is $deserialized_secret->unwrap, 'mysecret', 'do not masked';

    my $cloned_secret = eval { dclone($serializable_secret) };
    is $@, '', 'dclone successful';
    is $cloned_secret->unwrap, 'mysecret', 'clone can unwrap it';
};

subtest '$DISABLE_MASK = 1' => sub {
    local $String::Secret::DISABLE_MASK = 1;

    my $freezed = eval { nfreeze($secret) };
    is $@, '', 'freeze successful';
    eval { thaw($freezed) };
    like $@, qr/\Qcannot deserialize it/, 'block to thaw';

    subtest 'freezed content' => sub {
        my $deserialized_secret = force_thaw_storable($freezed);
        is $deserialized_secret->unwrap, 'mysecret', 'do not masked';
    };
};

sub force_thaw_storable {
    my $freezed = shift;

    no warnings qw/redefine/;
    local *String::Secret::STORABLE_thaw = do {
        use warnings qw/redefine/;
        my $super = \&String::Secret::STORABLE_thaw;
        sub {
            my ($self, $cloning, $masked) = @_;
            return $self->$super(1, $masked); # force as cloneing
        };
    };
    use warnings qw/redefine/;

    return thaw($freezed);
}

done_testing;

