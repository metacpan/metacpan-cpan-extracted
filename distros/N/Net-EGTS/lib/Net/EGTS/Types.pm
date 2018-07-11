use utf8;

package Net::EGTS::Types;
use Mouse;
use Mouse::Util::TypeConstraints;
use namespace::autoclean;

subtype 'BOOLEAN',  as 'Bool';
subtype 'BYTE',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 8 };
subtype 'USHORT',   as 'Int',   where { 0 <= $_ && $_ < 2 ** 16 };
subtype 'UINT',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 32 };
subtype 'ULONG',    as 'Int',   where { 0 <= $_ && $_ < 2 ** 64 };
subtype 'SHORT',    as 'Int',   where { -(2 ** 15) <= $_ && $_ < 2 ** 15 };
subtype 'INT',      as 'Int',   where { -(2 ** 31) <= $_ && $_ < 2 ** 31 };
subtype 'FLOAT',    as 'Num';
subtype 'DOUBLE',   as 'Num';
subtype 'STRING',   as 'Str';
subtype 'BINARY',   as 'Str';

subtype 'BINARY3',  as 'Str';#,   where { length($_) == 3 };

subtype 'BIT1',     as 'Bool';
subtype 'BIT2',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 2 };
subtype 'BIT3',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 3 };
subtype 'BIT4',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 4 };
subtype 'BIT5',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 5 };
subtype 'BIT6',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 6 };
subtype 'BIT7',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 7 };
subtype 'BIT8',     as 'Int',   where { 0 <= $_ && $_ < 2 ** 8 };

subtype 'uInt',     as 'Int', where { 0 <= $_ };

__PACKAGE__->meta->make_immutable();
