use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

BEGIN {
    eval "use Object::Signature;";
    plan skip_all => "Object::Signature is not installed" if $@;
    eval "use Storable 2.11 ();";
    plan skip_all => "Storable is not installed" if $@;
}

use_ok('Object::Signature::Portable');

sub serializer {
    local $Storable::canonical = 1;
    return Storable::nfreeze( $_[0] );
}

my $data = { abc => 123, foo => [qw/ bar baz /] };

is signature( serializer => \&serializer, data => $data ),
    Object::Signature::signature($data),
    'same as Object::Signature';

done_testing;
