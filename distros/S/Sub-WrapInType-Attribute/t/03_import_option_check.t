use Test2::V0;

use Sub::WrapInType::Attribute check => 0;

sub a :WrapSub([] => []) { 123 }
sub b :WrapMethod([] => []) { 123 }

note 'WrapSub';
ok lives { a(321) }, 'invalid args';
ok lives { a() }, 'invalid returns';

note 'WrapMethod';
ok lives { __PACKAGE__->b(321) }, 'invalid args';
ok lives { __PACKAGE__->b() }, 'invalid returns';

done_testing;
