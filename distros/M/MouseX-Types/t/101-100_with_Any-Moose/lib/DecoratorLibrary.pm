package DecoratorLibrary;

use Any::Moose 'X::Types::Moose' => [qw( Str ArrayRef HashRef Int Object)];
use Any::Moose 'X::Types' => [
    -declare => [qw(
        MyArrayRefBase
        MyArrayRefInt01
        MyArrayRefInt02
        MyHashRefOfInts
        MyHashRefOfStr
        StrOrArrayRef
        AtLeastOneInt
        Jobs
        SubOfMyArrayRefInt01
        BiggerInt
        isFive
        isTen
        isFifteen
        TwoEqualArrayRefs
        VeryBigInt
        FiveOrTenOrFifteen
        WierdIntergersArrayRef1
        WierdIntergersArrayRef2
    )]
];

subtype MyArrayRefBase,
    as ArrayRef;
    
coerce MyArrayRefBase,
    from Str,
    via {[split(',', $_)]};
    
subtype MyArrayRefInt01,
    as ArrayRef[Int];

subtype BiggerInt,
    as Int,
    where {$_>10};
    
subtype SubOfMyArrayRefInt01,
    as MyArrayRefInt01[BiggerInt];

coerce MyArrayRefInt01,
    from Str,
    via {[split('\.',$_)]},
    from HashRef,
    via {[sort values(%$_)]};
    
subtype MyArrayRefInt02,
    as MyArrayRefBase[Int];
    
subtype MyHashRefOfInts,
    as HashRef[Int];
    
subtype MyHashRefOfStr,
    as HashRef[Str];

coerce MyArrayRefInt02,
    from Str,
    via {[split(':',$_)]},
    from MyHashRefOfInts,
    via {[sort values(%$_)]},
    from MyHashRefOfStr,
    via {[ sort map { length $_ } values(%$_) ]},
    from HashRef[ArrayRef],
    via {[ sort map { @$_ } values(%$_) ]};

subtype StrOrArrayRef,
    as Str|ArrayRef;

subtype AtLeastOneInt,
    as ArrayRef[Int],
    where { @$_ > 0 };
    
enum Jobs,
    (qw/Programming Teaching Banking/);
    
subtype isFive,
 as Int,
 where { $_ == 5};

subtype isTen,
 as Int,
 where { $_ == 10};
 
subtype isFifteen,
 as Int,
 where { $_ == 15};
 
subtype VeryBigInt,
 as BiggerInt,
 where {$_>100};
 
subtype FiveOrTenOrFifteen,
 as isFive|isTen|isFifteen;

subtype WierdIntergersArrayRef1,
 as ArrayRef[FiveOrTenOrFifteen|VeryBigInt];

subtype WierdIntergersArrayRef2,
 as ArrayRef[FiveOrTenOrFifteen|Object];    
1;
