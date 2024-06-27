#! /usr/bin/env perl

use v5.22;
use warnings;
use experimental 'refaliasing';
use Scalar::Util 1.14 'looks_like_number';

use Multi::Dispatch;
use Types::Standard qw< Num Object >;

# Create a mini Data::Dumper clone that outputs in void context...
multi dd :before :where(VOID) (@data)  { say &next::variant }

# Format pairs and array/hash references...
multi dd ($k, $v)  { dd($k) . ' => ' . dd($v) }
multi dd (\@data)  { '[' . join(', ', map {dd($_)}                 @data) . ']' }
multi dd (\%data)  { '{' . join(', ', map {dd($_, $data{$_})} keys %data) . '}' }

# Format strings, numbers, regexen...
multi dd ($data)                             { '"' . quotemeta($data) . '"' }
multi dd ($data :where(\&looks_like_number)) { $data }
multi dd ($data :where(Regexp))              { 'qr{' . $data . '}' }

# Format objects...
multi dd (Object $data)               { '<' .ref($data).' object>' }
multi dd (Object $data -> can('dd'))  { $data->dd(); }

# Format typeglobs...
multi dd (GLOB $data)                { "" . *$data }


dd( 3.1415926 );
dd( 'string' );
dd( qr{ \A \d* \h (?= \d) }xms );
dd( [0..2]);
dd( { a=>1, b=>2, z=>[3, 'three', 3] } );
dd( \*STDERR );

BEGIN{ package MyClass; sub dd() { return '(MyClass)' } }

dd( bless {}, 'MyClass' );
dd( Object );

dd('label' => { a=>1, b=>2, z=>[3, 'three', 3] });




