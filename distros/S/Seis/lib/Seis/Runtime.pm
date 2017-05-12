package Seis::Runtime;
use strict;
use warnings;
use utf8;
use 5.010_001;

use Seis::Bool;
use Seis::Object;
use Seis::Array;
use Seis::Int;
use Seis::Real;
use Seis::Exceptions;
use Seis::Str;
use Seis::Hash;
use Seis::MetaClass;
use Seis::Class;
use Seis::Range;
use Seis::Undef;
use Seis::Buf;
use Seis::Whatever;
use Seis::Pair;
use Seis::IO;
use Seis::IO::Handle;
use Seis::IO::Path;
use Seis::Instant;
use Seis::Duration;
use Seis::Any;
use Seis::Socket;
use Seis::Any;
use Seis::Order;
use Seis::List;
use Seis::Sub;

use Seis::BuiltinFunctions;
use Scalar::Util ();
use B ();
use Cwd(); # for $*CWD

{
    package # hide from PAUSE
        Complex;
    sub new {
        my ($class, $x, $y) = @_;
        bless {x => $x, y => $y}, $class;
    }
}

sub builtin_eval {
    my ($code) = @_;
    my $compiler = Seis::Compiler->new();
    my $compiled = $compiler->compile($code);
    my $ret = eval $compiled;
    if ($@) {
        Seis::Exception::CompilationFailed->throw("$@");
    }
    return $ret;
}

sub builtin_elems { 0+@_ }

{
    package Seis::Match;
    sub DESTROY { }
    sub TIEARRAY {
        my $class = shift;
        bless {}, $class;
    }
    sub FETCHSIZE {
        1 + @-;
    }
    sub FETCH($$) {
        my ($self, $index) = @_;
        return ${^MATCH} if $index == 0;
        return $-[$index-1];
    }
}

# This variable emulates $/ in Perl6.
our @REGEXP_MATCH;
tie @REGEXP_MATCH, 'Seis::Match';

{
    my $Int = Seis::Class->_new(name => 'Int');
    sub Int() { $Int }
    my $Mu = Seis::Class->_new(name => 'Mu');
    sub Mu() { $Mu }
    my $Array = Seis::Class->_new(name => 'Array');
    sub Array() { $Array }
}

sub stringify {
    my $stuff = shift;
    return join(' ', @$stuff) if ref $stuff eq 'ARRAY';
    return ''.$stuff;
}

*boolean = *Bool::boolean;

sub _not {
    my $stuff = shift;
    return Bool::boolean(!0+@$stuff) if ref $stuff eq 'ARRAY';
    return Bool::boolean(!$stuff);
}

1;

