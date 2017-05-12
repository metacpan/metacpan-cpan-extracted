use strict;
use warnings;
use Object::Prototype;
#use Test::More tests => 1;
use Test::More qw(no_plan);
my $obj = Object::Prototype->new( {} );
eval { $obj->dump };
ok $@, '$obj->dump' . " is undefined";
$obj->prototype(
    dump => sub {
        use Data::Dumper;
        local ($Data::Dumper::Terse)  = 1;
        local ($Data::Dumper::Indent) = 0;
        return Dumper( $_[0] );
    }
);
eval { $obj->dump };
ok !$@, '$obj->dump' . " now defined";
is $obj->dump, qq{bless( {}, 'Object::Prototype' )}, $obj->dump;
my $kid = Object::Prototype->new(
    $obj,
    {
        name => sub {
            my $self = shift;
            $self->{name} = shift if @_;
            $self->{name};
          }
    }
);
$kid->name('kid');
eval { $obj->name };
ok $@, '$obj->name' . " is undefined";
eval { $kid->name };
ok !$@, '$kid->name' . " is defined";
eval { $kid->dump };
ok !$@, '$kid->dump' . " is defined";
is $kid->name, 'kid', '$kid->name' . " is kid";
is $kid->dump, qq{bless( {'name' => 'kid'}, 'Object::Prototype' )}, $kid->dump;
is $kid->constructor, $obj, '$kid->construct is $obj';

