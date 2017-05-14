package Qt::base;

use strict;
use warnings;

sub new {
    # Any direct calls to the 'NEW' function will bypass this code.  It's
    # called that way in subclass constructors, thus setting the 'this' value
    # for that package.

    # Store whatever current 'this' value we've got
    my $packageThis = Qt::this();
    # Create the object, overwriting the 'this' value
    shift->NEW(@_);
    # Get the return value
    my $ret = Qt::this();
    # Restore package's this
    Qt::_internal::setThis($packageThis);
    # Give back the new value
    return $ret;
}

# This subroutine is used to set the context for translation correctly for any
# perl subclasses.  Without it, the context would always be set to the base Qt4
# class.
sub tr {
    if( !Qt::qApp() ) {
        die 'You must create a Qt::Application object before calling tr.';
    }
    my $context = ref Qt::this();
    $context =~ s/^ *//;
    if( !$context ) {
        ($context) = $Qt::AutoLoad::AUTOLOAD =~ m/(.*).:tr$/;
    }
    return Qt::qApp()->translate( $context, @_ );
}

sub getPointer {
    my ( $self ) = @_;
    $self = Qt::this() if !defined $self;
    return Qt::_internal::sv_to_ptr( $self );
}

package Qt::base::_overload;
use strict;

no strict 'refs';
use overload
    'fallback' => 1,
    '==' => 'Qt::base::_overload::op_equal',
    '!=' => 'Qt::base::_overload::op_not_equal',
    '+=' => 'Qt::base::_overload::op_plus_equal',
    '-=' => 'Qt::base::_overload::op_minus_equal',
    '*=' => 'Qt::base::_overload::op_mul_equal',
    '/=' => 'Qt::base::_overload::op_div_equal',
    '>>' => 'Qt::base::_overload::op_shift_right',
    '<<' => 'Qt::base::_overload::op_shift_left',
    '<=' => 'Qt::base::_overload::op_lesser_equal',
    '>=' => 'Qt::base::_overload::op_greater_equal',
    '^=' => 'Qt::base::_overload::op_xor_equal',
    '|=' => 'Qt::base::_overload::op_or_equal',
    '>'  => 'Qt::base::_overload::op_greater',
    '<'  => 'Qt::base::_overload::op_lesser',
    '+'  => 'Qt::base::_overload::op_plus',
    '-'  => 'Qt::base::_overload::op_minus',
    '*'  => 'Qt::base::_overload::op_mul',
    '/'  => 'Qt::base::_overload::op_div',
    '^'  => 'Qt::base::_overload::op_xor',
    '|'  => 'Qt::base::_overload::op_or',
    '--' => 'Qt::base::_overload::op_decrement',
    '++' => 'Qt::base::_overload::op_increment',
    'neg'=> 'Qt::base::_overload::op_negate',
    'eq' => 'Qt::base::_overload::op_ref_equal';

sub op_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator==';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator==';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    return $ret;
}

sub op_not_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator!=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator!=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    return $ret;
}

sub op_plus_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator+=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator+=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    return $ret;
}

sub op_minus_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_mul_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator*=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator*=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_div_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator/=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator/=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_shift_right {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>>';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>>';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_shift_left {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<<';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<<';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    return $ret;
}

sub op_lesser_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_greater_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_xor_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator^=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator^=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_or_equal {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator|=';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return ($_[2] ? $_[1] : $_[0]) unless $err = $@;
    my $ret;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator|=';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@; 
    return $ret;
}

sub op_greater {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator>';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator>';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_lesser {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator<';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator<';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_plus {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator+';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator+';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_minus {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_mul {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator*';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator*';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret     
}

sub op_div {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator/';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator/';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret     
}

sub op_negate {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator-';
    my $autoload = ref($_[0])."::AUTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->($_[0]) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator-';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload($_[0]) };
    die $err.$@ if $@;
    return $ret;
}

sub op_xor {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator^';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator^';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_or {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator|';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my ($ret, $err);
    eval { local $SIG{'__DIE__'}; $ret = $autoload->(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    return $ret unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator|';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; $ret = &$autoload(($_[2] ? (@_)[1,0] : (@_)[0,1])) };
    die $err.$@ if $@;
    $ret    
}

sub op_increment {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator++';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->($_[0]) };
    return $_[0] unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator++';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; &$autoload($_[0]) };
    die $err.$@ if $@; 
    $_[0]
}

sub op_decrement {
    $Qt::AutoLoad::AUTOLOAD = ref($_[0]).'::operator--';
    my $autoload = ref($_[0])."::_UTOLOAD";
    my $err;
    eval { local $SIG{'__DIE__'}; $autoload->($_[0]) };
    return $_[0] unless $err = $@;
    $Qt::AutoLoad::AUTOLOAD = 'Qt::GlobalSpace::operator--';
    $autoload = "Qt::GlobalSpace::_UTOLOAD";
    eval { local $SIG{'__DIE__'}; &$autoload($_[0]) };
    die $err.$@ if $@;
    $_[0]
}

sub op_ref_equal {
    return Qt::_internal::sv_to_ptr( $_[0] ) == Qt::_internal::sv_to_ptr( $_[1] );
}

package Qt::enum::_overload;

use strict;

no strict 'refs';

use overload
    'fallback' => 1,
    '==' => 'Qt::enum::_overload::op_equal',
    '!=' => 'Qt::enum::_overload::op_not_equal',
    '+=' => 'Qt::enum::_overload::op_plus_equal',
    '-=' => 'Qt::enum::_overload::op_minus_equal',
    '*=' => 'Qt::enum::_overload::op_mul_equal',
    '/=' => 'Qt::enum::_overload::op_div_equal',
    '>>' => 'Qt::enum::_overload::op_shift_right',
    '<<' => 'Qt::enum::_overload::op_shift_left',
    '<=' => 'Qt::enum::_overload::op_lesser_equal',
    '>=' => 'Qt::enum::_overload::op_greater_equal',
    '^=' => 'Qt::enum::_overload::op_xor_equal',
    '|=' => 'Qt::enum::_overload::op_or_equal',
    '&=' => 'Qt::enum::_overload::op_and_equal',
    '>'  => 'Qt::enum::_overload::op_greater',
    '<'  => 'Qt::enum::_overload::op_lesser',
    '+'  => 'Qt::enum::_overload::op_plus',
    '-'  => 'Qt::enum::_overload::op_minus',
    '*'  => 'Qt::enum::_overload::op_mul',
    '/'  => 'Qt::enum::_overload::op_div',
    '^'  => 'Qt::enum::_overload::op_xor',
    '|'  => 'Qt::enum::_overload::op_or',
    '&'  => 'Qt::enum::_overload::op_and',
    '~'  => 'Qt::enum::_overload::op_unarynegate',
    '--' => 'Qt::enum::_overload::op_decrement',
    '++' => 'Qt::enum::_overload::op_increment',
    'neg'=> 'Qt::enum::_overload::op_negate';

sub op_equal {
    if( ref $_[0] ) {
        if( ref $_[1] ) {
            return 1 if ${$_[0]} == ${$_[1]};
            return 0;
        }
        else {
            return 1 if ${$_[0]} == $_[1];
            return 0;
        }
    }
    else {
        return 1 if $_[0] == ${$_[1]};
        return 0;
    }
    # Never have to check for both not being references.  If neither is a ref,
    # this function will never be called.
}

sub op_not_equal {
    if( ref $_[0] ) {
        if( ref $_[1] ) {
            return 1 if ${$_[0]} != ${$_[1]};
            return 0;
        }
        else {
            return 1 if ${$_[0]} != $_[1];
            return 0;
        }
    }
    else {
        return 1 if $_[0] != ${$_[1]};
        return 0;
    }
    # Never have to check for both not being references.  If neither is a ref,
    # this function will never be called.
}

sub op_plus_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} += ${$_[1]};
    }
    else {
        return ${$_[0]} += $_[1];
    }
}

sub op_minus_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} -= ${$_[1]};
    }
    else {
        return ${$_[0]} -= $_[1];
    }
}

sub op_mul_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} *= ${$_[1]};
    }
    else {
        return ${$_[0]} *= $_[1];
    }
}

sub op_div_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} /= ${$_[1]};
    }
    else {
        return ${$_[0]} /= $_[1];
    }
}

sub op_shift_right {
    if ( ref $_[1] ) {
        return ${$_[0]} >> ${$_[1]};
    }
    else {
        return ${$_[0]} >> $_[1];
    }
}

sub op_shift_left {
    if ( ref $_[1] ) {
        return ${$_[0]} << ${$_[1]};
    }
    else {
        return ${$_[0]} << $_[1];
    }
}

sub op_lesser_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} <= ${$_[1]};
    }
    else {
        return ${$_[0]} <= $_[1];
    }
}

sub op_greater_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} >= ${$_[1]};
    }
    else {
        return ${$_[0]} >= $_[1];
    }
}

sub op_xor_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} ^= ${$_[1]};
    }
    else {
        return ${$_[0]} ^= $_[1];
    }
}

sub op_or_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} |= ${$_[1]};
    }
    else {
        return ${$_[0]} |= $_[1];
    }
}

sub op_and_equal {
    if ( ref $_[1] ) {
        return ${$_[0]} &= ${$_[1]};
    }
    else {
        return ${$_[0]} &= $_[1];
    }
}

sub op_greater {
    if ( ref $_[1] ) {
        return ${$_[0]} > ${$_[1]};
    }
    else {
        return ${$_[0]} > $_[1];
    }
}

sub op_lesser {
    if ( ref $_[1] ) {
        return ${$_[0]} < ${$_[1]};
    }
    else {
        return ${$_[0]} < $_[1];
    }
}

sub op_plus {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} + ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} + $_[1]), ref $_[0] );
    }
}

sub op_minus {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} - ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} - $_[1]), ref $_[0] );
    }
}

sub op_mul {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} * ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} * $_[1]), ref $_[0] );
    }
}

sub op_div {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} / ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} / $_[1]), ref $_[0] );
    }
}

sub op_xor {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} ^ ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} ^ $_[1]), ref $_[0] );
    }
}

sub op_or {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} | ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} | $_[1]), ref $_[0] );
    }
}

sub op_and {
    if ( ref $_[1] ) {
        return bless( \(${$_[0]} & ${$_[1]}), ref $_[0] );
    }
    else {
        return bless( \(${$_[0]} & $_[1]), ref $_[0] );
    }
}

sub op_unarynegate {
    return bless( \(~${$_[0]}), ref $_[0] );
}

sub op_decrement {
    return --${$_[0]};
}

sub op_increment {
    return ++${$_[0]};
}

sub op_negate {
    return -${$_[0]};
}

package Qt::GlobalSpace;

use strict;
use warnings;

our @EXPORT_OK;

push @EXPORT_OK, qw(
LicensedActiveQt
LicensedCore
LicensedDBus
LicensedDeclarative
LicensedGui
LicensedHelp
LicensedMultimedia
LicensedNetwork
LicensedOpenGL
LicensedOpenVG
LicensedQt3Support
LicensedQt3SupportLight
LicensedScript
LicensedScriptTools
LicensedSql
LicensedSvg
LicensedTest
LicensedXml
LicensedXmlPatterns
qAcos
qAddPostRoutine
qAppName
qAsin
qAtan
qAtan2
qbswap_helper
qCeil
qChecksum
Q_COMPLEX_TYPE
qCompress
qCos
qCritical
qDebug
Q_DUMMY_TYPE
qExp
qFabs
qFastCos
qFastSin
qFlagLocation
qFloor
qFree
qFreeAligned
qFuzzyCompare
qFuzzyIsNull
qgetenv
qHash
qInf
qInstallMsgHandler
qIntCast
qIsFinite
qIsInf
qIsNaN
qIsNull
qLn
qMalloc
qMallocAligned
qMemCopy
qMemSet
Q_MOVABLE_TYPE
qPow
Q_PRIMITIVE_TYPE
qputenv
qQNaN
qrand
qRealloc
qReallocAligned
qRegisterStaticPluginInstanceFunction
qRemovePostRoutine
qRound
qRound64
qSetFieldWidth
qSetPadChar
qSetRealNumberPrecision
qSharedBuild
qSin
qSNaN
qSqrt
qsrand
Q_STATIC_TYPE
qstrcmp
qstrcpy
qstrdup
qstricmp
qStringComparisonHelper
qstrlen
qstrncmp
qstrncpy
qstrnicmp
qstrnlen
qTan
qt_assert
qt_assert_x
qt_check_pointer
QtCriticalMsg
QtDebugMsg
qt_error_string
QtFatalMsg
qt_message_output
qt_noop
qt_qFindChild_helper
qt_qFindChildren_helper
QtSystemMsg
qtTrId
QtWarningMsg
qUncompress
qvariant_cast_helper
qVersion
qvsnprintf
qWarning
);

unless(exists $::INC{'Qt/GlobalSpace.pm'}) {
    $::INC{'Qt/GlobalSpace.pm'} = $::INC{'QtCore4.pm'};
}

sub import {
    my $class = shift;
    my $caller = (caller)[0];
    $caller .= '::';

    foreach my $subname ( @_ ) {
        next unless grep( $subname, @EXPORT_OK );
        Qt::_internal::installSub( $caller.$subname, sub {
            $Qt::AutoLoad::AUTOLOAD = "Qt::GlobalSpace::$subname";
            my $autoload = 'Qt::GlobalSpace::_UTOLOAD';
            no strict 'refs';
            return &$autoload(@_);
        } );
    }
}

package Qt::_internal;

use strict;
use warnings;
use Scalar::Util qw( blessed );
use List::MoreUtils qw( any );

# These 2 hashes provide lookups from a perl package name to a smoke
# classid, and vice versa
our %package2classId;
our %classId2package;

# This hash stores integer pointer address->perl SV association.  Used for
# overriding virtual functions, where all you have as an input is a void* to
# the object who's method is being called.  Made visible here for debugging
# purposes.
our %pointer_map;

our %customClasses;

our %vectorTypes;

our %arrayTypes = (
    'const QList<QVariant>&' => {
        value => [ 'QVariant' ]
    },
    'const QStringList&' => {
        value => [ 's', 'Qt::String' ],
    },
);

our %hashTypes = (
    'const QHash<QString,QVariant>&' => {
        keys => [ 's', 'Qt::String' ],
        values => [ 'QVariant' ]
    },
    'const QMap<QString,QVariant>&' => {
        keys => [ 's', 'Qt::String' ],
        values => [ 'QVariant' ]
    },
);

sub arrayByName {
    my $name = shift;
    no strict 'refs';
    return \@{$name};
}

sub hashByName {
    my $name = shift;
    no strict 'refs';
    return \%{$name};
}

sub installSub {
    my ($subname, $subref) = @_;
    no strict 'refs';
    *{$subname} = $subref unless defined &{$subname};
    return;
}

sub unique {
    my %uniq;          # Use keys of this hash to track unique values
    @uniq{@_} = ();    # use the args as those keys
    return keys %uniq; # Return unique values
}

sub argmatch {
    my ( $methodIds, $args, $argNum ) = @_;
    my %match;

    my $argType = getSVt( $args->[$argNum] );

    my $explicitType = 0;
               #index into methodId array
    foreach my $methodIdIdx ( 0..$#{$methodIds} ) {
        my $moduleId = $methodIds->[$methodIdIdx];
        my $smokeId = $moduleId->[0];
        my $methodId = $moduleId->[1];
        my $typeName = getTypeNameOfArg( $smokeId, $methodId, $argNum );
        #ints and bools
        if ( $argType eq 'i' ) {
            if( $typeName =~ m/^(?:bool|(?:(?:un)?signed )?(?:int|(?:long )?long)|uint)[*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        # floats and doubles
        elsif ( $argType eq 'n' ) {
            if( $typeName =~ m/^(?:float|double)$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        # enums
        elsif ( $argType eq 'e' ) {
            my $refName = ref $args->[$argNum];
            if( $typeName =~ m/^(?:QFlags<)?$refName[s]?[>]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        # strings
        elsif ( $argType eq 's' ) {
            if( $typeName =~ m/^(?:(?:const )?u?char\*|(?:const )?(?:(QString)|QByteArray)[\*&]?)$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        # arrays
        elsif ( $argType eq 'a' ) {
            next unless defined $arrayTypes{$typeName};
            my @subArgTypes = unique( map{ getSVt( $_ ) } @{$args->[$argNum]} );
            my @validTypes = @{$arrayTypes{$typeName}->{value}};
            my $good = 1;
            foreach my $subArgType ( @subArgTypes ) {
                if ( !grep{ $_ eq $subArgType } @validTypes ) {
                    $good = 0;
                    last;
                }
            }
            if( $good ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        elsif ( $argType eq 'h' ) {
            next unless defined $hashTypes{$typeName};
            my @keyArgTypes = unique( map{ getSVt( $_ ) } keys %{$args->[$argNum]} );
            my @valueArgTypes = unique( map{ getSVt( $_ ) } values %{$args->[$argNum]} );
            my @validKeyTypes = @{$hashTypes{$typeName}->{keys}};
            my @validValueTypes = @{$hashTypes{$typeName}->{values}};
            my $good = 1;
            foreach my $keyArgType ( @keyArgTypes ) {
                if ( !grep{ $_ eq $keyArgType } @validKeyTypes ) {
                    $good = 0;
                    last;
                }
            }
            foreach my $valueArgType ( @valueArgTypes ) {
                if ( !grep{ $_ eq $valueArgType } @validValueTypes ) {
                    $good = 0;
                    last;
                }
            }
            if( $good ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
        }
        elsif ( $argType eq 'r' or $argType eq 'U' ) {
            $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
        }
        elsif ( $argType eq 'Qt::String' ) {
            if( $typeName =~m/^(?:const )?QString[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::CString' ) {
            if( $typeName =~m/^(?:const )?char ?\*[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Int' ) {
            if( $typeName =~ m/^int[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Uint' ) {
            if( $typeName =~ m/^unsigned int[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Bool' ) {
            if( $typeName eq 'bool' ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Short' ) {
            if( $typeName =~ m/^short[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Ushort' ) {
            if( $typeName =~ m/^unsigned short[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        elsif ( $argType eq 'Qt::Uchar' ) {
            if( $typeName =~ m/^u(?:nsigned )?char[\*&]?$/ ) {
                $match{$methodIdIdx} = [0,[$smokeId,$methodId]];
            }
            else {
                $explicitType = 1;
            }
        }
        # objects
        else {
            # Optional const, some words, optional & or *.  Note ?: does not
            # make a backreference, (\w*) is the only thing actually captured.
            my $isConst = ($typeName =~ m/const/);
            $typeName =~ s/^(?:const\s+)?(\w*)[&*]?$/$1/g;
            my $isa = classIsa( $argType, $typeName );
            if ( $isa != -1 ) {
                ++$isa if $isConst;
                $match{$methodIdIdx} = [-$isa, [$smokeId,$methodId]];
            }
        }
    }

    if ( !%match && $explicitType ) {
        return [undef,-1];
    }

    return map{ $match{$_}->[1] }
        sort { $match{$b}[0] <=> $match{$a}[0] or $match{$a}[1] <=> $match{$b}[1] } keys %match;
}

sub dumpArgs {
    return join ', ', map{
        my $refName = ref $_;
        $refName =~ s/^ *//;
        if($refName) {
            $refName;
        }
        else {
            $_;
        }
    } @_;
}

sub dumpCandidates {
    my ( $classname, $methodname, $moduleIds ) = @_;
    my @methods;
    foreach my $moduleId ( @{$moduleIds} ) {

        my $smokeId = $moduleId->[0];
        my $methodId = $moduleId->[1];

        my $numArgs = getNumArgs( $smokeId, $methodId );
        my $method = "$classname\::$methodname( ";
        $method .= join ', ', map{ getTypeNameOfArg( $smokeId, $methodId, $_ ) } ( 0..$numArgs-1 );
        $method .= " )";
        push @methods, $method;
    }
    return @methods;
}

sub uniqMethods {
    my ($methodIds, $numArgs) = @_;
    my %hash;
    foreach my $moduleId ( reverse @{$methodIds} ) {
        my $smokeId = $moduleId->[0];
        my $methodId = $moduleId->[1];
        my $sig = join ',', map{
            my $str = getTypeNameOfArg( $smokeId, $methodId, $_ );
            $str =~ s/^const //;
            $str =~ s/[*&]$//;
            $str} ( 0..$numArgs-1 );
        $hash{$sig} = $moduleId;
    }
    return values %hash;
}

# Args: @_: the args to the method being called
#       $classname: the c++ class being called
#       $methodname: the c++ method name being called
#       $classId: the smoke class Id of $classname
# Returns: A disambiguated method id
# Desc: Examines the arguments of the method call to build a method signature.
#       From that signature, it determines the appropriate method id.
sub getSmokeMethodId {
    my $classname = pop;
    my $methodname = pop;
    my $classId = pop;
    my $smokeId = $classId->[0];

    # Loop over the arguments to determine the type of args
    my @mungedMethods = ( $methodname );
    foreach my $arg ( @_ ) {
        if (!defined $arg) {
            # An undefined value requires a search for each type of argument
            @mungedMethods = map { $_ . '#', $_ . '?', $_ . '$' } @mungedMethods;
        } elsif(isObject($arg)) {
            @mungedMethods = map { $_ . '#' } @mungedMethods;
        } elsif((ref $arg) =~ m/HASH|ARRAY/) {
            @mungedMethods = map { $_ . '?' } @mungedMethods;
        } else {
            @mungedMethods = map { $_ . '$' } @mungedMethods;
        }
    }
    my @methodIds = map { findMethod( $classname, $_ ) } @mungedMethods;

    my $cacheLookup = 1;

    # If we got more than 1 method id, resolve it
    if (@methodIds > 1) {
        foreach my $argNum (0..$#_) {
            my @matching = argmatch( \@methodIds, \@_, $argNum );
            if (@matching) {
                # if the methodid of the first one returned is -1, we got no
                # matches back
                if ($matching[0]->[1] == -1) {
                    @methodIds = ();
                }
                else {
                    @methodIds = @matching;
                }
            }
        }

        @methodIds = uniqMethods( \@methodIds, scalar @_ );

        # If we still have more than 1 match, use the first one.
        if ( @methodIds > 1 ) {
            # Keep in sync with debug.pm's $channel{ambiguous} value
            if ( debug() & 0x01 ) {
                # A constructor call will be 4 levels deep on the stack, everything
                # else will be 2
                my $stackDepth = ( $methodname eq $classname ) ? 4 : 2;
                my @caller = caller($stackDepth);
                while ( $caller[1] =~ m/QtCore4\.pm$/ || $caller[1] =~ m/QtCore4\/isa\.pm/ ) {
                    ++$stackDepth;
                    @caller = caller($stackDepth);
                }
                my $msg = "--- Ambiguous method ${classname}::$methodname\n";
                $msg .= "Candidates are:\n\t";
                $msg .= join "\n\t", dumpCandidates( $classname, $methodname, \@methodIds );
                $msg .= "\nChoosing first one... " .
                    ' at ' . $caller[1] .
                    ' line ' . $caller[2] . "\n";
                warn $msg;
            }
            @methodIds = $methodIds[0];

            # Since a call to this same method with different args may resolve
            # differently, don't cache this lookup
            $cacheLookup = 0;
        }
    }
    elsif ( @methodIds == 1 and @_ ) {
        # We have one match and arguments.  We need to make sure our input
        # arguments match what the method is expecting.  Clear methodIds if
        # args don't match
        if (!objmatch( $methodIds[0], \@_)) {
            my $stackDepth = ( $methodname eq $classname ) ? 4 : 2;
            my @caller = caller($stackDepth);
            while ( $caller[1] =~ m/QtCore4\.pm$/ || $caller[1] =~ m/QtCore4\/isa\.pm/ ) {
                ++$stackDepth;
                @caller = caller($stackDepth);
            }
            my $errStr = '--- Arguments for method call ' .
                "$classname\::$methodname did not match C++ method ".
                "signature\n";
            $errStr .= "Method call was:\n\t";
            $errStr .= "$classname\::$methodname( " . dumpArgs(@_) . " )\n";
            $errStr .= "C++ signature is:\n\t";
            $errStr .= (dumpCandidates( $classname, $methodname, \@methodIds ))[0] . "\n" .
                ' at ' . $caller[1] .
                ' line ' . $caller[2] . "\n";
            @methodIds = ();
            print STDERR $errStr and die;
        }
    }

    if ( !@methodIds ) {
        if ( debug() & 0x01 ) {
            # The findAnyPossibleMethod is expensive, only do it if debugging is on.
            my $smokeId = $classId->[0];
            @methodIds = findAnyPossibleMethod( $classname, $methodname, @_ );
            if( @methodIds ) {
                die reportAlternativeMethods( $classname, $methodname, \@methodIds, @_ );
            }
            else {
                die reportNoMethodFound( $classname, $methodname, @_ );
            }
        }
        else {
            my $noMethodFound = reportNoMethodFound( $classname, $methodname, @_ );
            $noMethodFound .= "'use QtCore4::debug qw(ambiguous)' for more information.\n";
            die $noMethodFound;
        }
    }

    return @{$methodIds[0]}, $cacheLookup;
}

sub getMetaObject {
    my $class = shift;

    my $meta = hashByName($class . '::META');

    # If no signals/slots/properties have been added since the last time this
    # was asked for, return the saved one.
    return $meta->{object} if $meta->{object} and !$meta->{changed};

    # If this is a native Qt4 class, call metaObject() on that class directly
    if ( $package2classId{$class} ) {
        my $moduleId = $package2classId{$class};
        my $cxxClass = classFromId( $moduleId );
        my ( $smokeId, $methodId ) = getSmokeMethodId( $moduleId, 'staticMetaObject', $cxxClass );
        return $meta->{object} = getNativeMetaObject( $smokeId, $methodId );
    }

    # Get the super class's meta object for sig/slot inheritance
    # Look up through ISA to find it
    my $parentMeta = undef;
    my $parentModuleId;

    # This seems wrong, it won't work with multiple inheritance
    my $parentClass = arrayByName($class."::ISA")->[0]; 

    if ( !$parentClass ) {
        die "Request for metaObject for class $class, which has no base class";
    }

    if( !$package2classId{$parentClass} ) {
        # The parent class is a custom Perl class whose metaObject was
        # constructed at runtime, so we can get it's metaObject from here.
        $parentMeta = getMetaObject( $parentClass );
    }
    else {
        $parentModuleId = $package2classId{$parentClass};
    }

    # Generate data to create the meta object
    my( $stringdata, $data ) = makeMetaData( $class );
    $meta->{object} = Qt::_internal::make_metaObject(
        $parentModuleId,
        $parentMeta,
        $stringdata,
        $data );

    $meta->{changed} = 0;
    return $meta->{object};
}

# Does the method exist, but the user just gave bad args?
sub findAnyPossibleMethod {
    my $classname = shift;
    my $methodname = shift;

    my @last = '';
    my @mungedMethods = ( $methodname );
    # 14 is the max number of args, but that's way too many permutations.
    # Keep it short.
    foreach ( 0..7 ) { 
        @last = permateMungedMethods( ['$', '?', '#'], @last );
        push @mungedMethods, map{ $methodname . $_ } @last;
    }

    return map { findMethod( $classname, $_ ) } @mungedMethods;
}

sub init_class {
    my ($class, $cxxClassName) = @_;

    my $perlClassName = $class->normalize_classname($cxxClassName);
    my ($classId, $smokeId) = findClass($cxxClassName);
    my $moduleId = [$smokeId, $classId];

    my @isa;
    if ( $classId ) {
        # Save the association between this perl package and the cxx classId.
        $package2classId{$perlClassName} = $moduleId;
        my $moduleIdBitwise = ($classId<<8)+$smokeId;
        $classId2package{$moduleIdBitwise} = $perlClassName;

        # Define the inheritance array for this class.
        @isa = getIsa($moduleId);
    }

    @isa = $customClasses{$perlClassName}
        if defined $customClasses{$perlClassName};

    # We want the isa array to be the names of perl packages, not c++ class
    # names
    foreach my $super ( @isa ) {
        $super = $class->normalize_classname($super);
    }

    # The root of the tree will be Qt::base, so a call to
    # $className::new() redirects there.
    @isa = ('Qt::base') unless @isa;
    @{arrayByName($perlClassName.'::ISA')} = @isa;

    # Define overloaded operators
    if ( exists $vectorTypes{$perlClassName} ) {
        push @{arrayByName(" $perlClassName\::ISA")}, "$perlClassName\::_overload";
        setIsArrayType( " $perlClassName" );
    }
    push @{arrayByName(" $perlClassName\::ISA")}, 'Qt::base::_overload';

    foreach my $sp ('', ' ') {
        my $where = $sp . $perlClassName;
        installautoload($where);
        # Putting this in one package gives XS_AUTOLOAD one spot to look for
        # the autoload variable
        package Qt::AutoLoad;
        my $autosub = \&{$where . '::_UTOLOAD'};
        Qt::_internal::installSub( $where.'::AUTOLOAD', sub{&$autosub} );
    }

    installSub("$perlClassName\::NEW", sub {
        # Removes $perlClassName from the front of @_
        my $perlClassName = shift;

        # If we have a cxx classname that's in some other namespace, like
        # QTextEdit::ExtraSelection, remove the first bit.
        $cxxClassName =~ s/.*://;
        $Qt::AutoLoad::AUTOLOAD = "$perlClassName\::$cxxClassName";
        my $_utoload = \&{"$perlClassName\::_UTOLOAD"};
        setThis( bless &$_utoload, " $perlClassName" );
    }) unless(defined &{"$perlClassName\::NEW"});

    # Make the constructor subroutine
    installSub($perlClassName, sub {
        # Adds $perlClassName to the front of @_
        $perlClassName->new(@_);
    }) unless(defined &{$perlClassName});

    Qt::_internal::installSub( " ${perlClassName}::isa", \&Qt::_internal::isa );
}

sub permateMungedMethods {
    my $sigils = shift;
    my @output;
    while( defined( my $input = shift ) ) {
        push @output, map{ $input . $_ } @{$sigils};
    }
    return @output;
}

sub reportAlternativeMethods {
    my $classname = shift;
    my $methodname = shift;
    my $methodIds = shift;
    # @_ now equals the original argument array of the method call
    my $stackDepth = ( $methodname eq $classname ) ? 5 : 3;
    my @caller = caller($stackDepth);
    while ( $caller[1] =~ m/QtCore4\.pm$/ || $caller[1] =~ m/QtCore4\/isa\.pm/ ) {
        ++$stackDepth;
        @caller = caller($stackDepth);
    }
    my $errStr = '--- Arguments for method call ' .
        "$classname\::$methodname did not match any known C++ method ".
        "signature," .
        ' called at ' . $caller[1] .
        ' line ' . $caller[2] . "\n";
    $errStr .= "Method call was:\n\t";
    $errStr .= "$classname\::$methodname( " . dumpArgs(@_) . " )\n";
    $errStr .= "Possible candidates:\n\t";
    $errStr .= join( "\n\t", dumpCandidates( $classname, $methodname, $methodIds ) ) . "\n";
    return $errStr;
}

sub reportNoMethodFound {
    my $classname = shift;
    my $methodname = shift;
    # @_ now equals the original argument array of the method call

    my $stackDepth = ( $methodname eq $classname ) ? 5 : 3;

    # Look up the stack to find who called us.  We don't care if it was
    # called from QtCore4.pm or isa.pm
    my @caller = caller($stackDepth);
    while ( $caller[1] =~ m/QtCore4\.pm$/ || $caller[1] =~ m/QtCore4\/isa\.pm/ ) {
        ++$stackDepth;
        @caller = caller($stackDepth);
    }
    my $errStr = '--- Error: Method does not exist or not provided by this ' .
        "binding:\n";
    $errStr .= "$classname\::$methodname(),\n";
    $errStr .= 'called at ' . $caller[1] . ' line ' . $caller[2] . "\n";
    return $errStr;
}

sub init_enum {
    my ( $class, $enumName ) = @_;
    $enumName =~ s/^const //;
    if(@{arrayByName("${enumName}::ISA")}) {
        #$enumName = $class->normalize_classname( $enumName );
        @{arrayByName("${enumName}Enum::ISA")} = ('Qt::enum::_overload');
    }
    else {
        #$enumName = $class->normalize_classname( $enumName );
        @{arrayByName("${enumName}::ISA")} = ('Qt::enum::_overload');
    }
}

# Args: none
# Returns: none
# Desc: sets up each class
sub init {
    $Qt::_internal::vectorTypes{'Qt::XmlStreamAttributes'} = undef;
    my $classes = getClassList();
    Qt::_internal->init_class($_) for(@$classes);

    my $enums = getEnumList();
    Qt::_internal->init_enum($_) for(@$enums);
}

sub makeMetaData {
    my ( $classname ) = @_;

    my $meta = hashByName($classname . '::META');

    my $classinfos = $meta->{classinfos};
    my $signals = $meta->{signals};
    my $slots = $meta->{slots};

    @{$classinfos} = () if !defined @{$classinfos};
    @{$signals} = () if !defined @{$signals};
    @{$slots} = () if !defined @{$slots};

    # Each entry in 'stringdata' corresponds to a string in the
    # qt_meta_stringdata_<classname> structure.

    #
    # From the enum MethodFlags in qt-copy/src/tools/moc/generator.cpp
    #
    my $AccessPrivate = 0x00;
    my $AccessProtected = 0x01;
    my $AccessPublic = 0x02;
    my $MethodMethod = 0x00;
    my $MethodSignal = 0x04;
    my $MethodSlot = 0x08;
    my $MethodCompatibility = 0x10;
    my $MethodCloned = 0x20;
    my $MethodScriptable = 0x40;

    my $numClassInfos = scalar @{$classinfos};
    my $numSignals = scalar @{$signals};
    my $numSlots = scalar @{$slots};

    my $data = [
        1,                           #revision
        0,                           #str index of classname
        $numClassInfos,              #number of classinfos
        $numClassInfos > 0 ? 10 : 0, #have classinfo?
        $numSignals + $numSlots,     #number of sig/slots
        10 + (2*$numClassInfos),     #have methods?
        0, 0,                        #no properties
        0, 0,                        #no enums/sets
    ];

    my $stringdata = "$classname\0";
    my $nullposition = length( $stringdata ) - 1;

    # Build the stringdata string, storing the indexes in data
    foreach my $classinfo ( @{$classinfos} ) {
        foreach my $keyval ( %{$classinfo} ) {
            my $curPosition = length $stringdata;
            push @{$data}, $curPosition;
            $stringdata .= $keyval . "\0";
        }
    }

    foreach my $signal ( @$signals ) {
        my $curPosition = length $stringdata;

        # Add this signal to the stringdata
        $stringdata .= $signal->{signature} . "\0" ;

        push @$data, $curPosition; #signature
        push @$data, $nullposition; #parameter names
        push @$data, $nullposition; #return type, void
        push @$data, $nullposition; #tag
        if ( $signal->{public} ) {
            push @$data, $MethodScriptable | $MethodSignal | $AccessPublic; # flags
        }
        else {
            push @$data, $MethodSignal | $AccessPrivate; # flags
        }
    }

    foreach my $slot ( @$slots ) {
        my $curPosition = length $stringdata;

        # Add this slot to the stringdata
        $stringdata .= $slot->{signature} . "\0";
        push @$data, $curPosition; #signature

        push @$data, $nullposition; #parameter names

        if ( defined $slot->{returnType} ) {
            $curPosition = length $stringdata;
            $stringdata .= $slot->{returnType} . "\0";
            push @$data, $curPosition; #return type
        }
        else {
            push @$data, $nullposition; #return type, void
        }
        push @$data, $nullposition; #tag
        if ( $slot->{public} ) {
            push @$data, $MethodScriptable | $MethodSlot | $AccessPublic; # flags
        }
        else {
            push @$data, $MethodSlot | $AccessPrivate; # flags
        }
    }

    push @$data, 0; #eod

    return ($stringdata, $data);
}

# Args: $cxxClassName: the name of a Qt4 class
# Returns: The name of the associated perl package
# Desc: Given a c++ class name, determine the perl package name
sub normalize_classname {
    my $cxxClassName = $_[1];

    return 'Qt' if $cxxClassName eq 'Qt';

    my $perlClassName = $cxxClassName;

    if ($cxxClassName =~ m/^Q3/) {
        # Prepend Qt3:: if this is a Qt3 support class
        $perlClassName =~ s/^Q3(?=[A-Z])/Qt3::/;
    }
    elsif ($cxxClassName =~ m/^Q/) {
        # Only prepend Qt:: if the name starts with Q and is followed by
        # an uppercase letter
        $perlClassName =~ s/^Q(?=[A-Z])/Qt::/;
    }

    return $perlClassName;
}

sub objmatch {
    my ( $moduleId, $args ) = @_;
    my $smokeId = $moduleId->[0];
    my $methodId = $moduleId->[1];
    foreach my $i ( 0..$#$args ) {
        # Compare our actual args to what the method expects
        my $argtype = getSVt($args->[$i]);

        # argtype will be only 1 char if it is not an object. If that's the
        # case, don't do any checks.
        next if length $argtype == 1 || grep( $argtype eq $_,
            qw( Qt::String Qt::CString Qt::Int Qt::Uint Qt::Bool Qt::Short Qt::Ushort Qt::Uchar ) );

        my $typename = getTypeNameOfArg( $smokeId, $methodId, $i );

        # We don't care about const or [&*]
        $typename =~ s/^const\s+//;
        $typename =~ s/(?<=\w)[&*]$//g;

        return 0 if classIsa( $argtype, $typename) == -1;
    }
    return 1;
}

sub Qt::CoreApplication::NEW {
    my $class = shift;
    my $argv = shift;
    unshift @$argv, $0;
    my $count = scalar @$argv;
    my $retval = Qt::CoreApplication::QCoreApplication( $count, $argv );
    bless( $retval, " $class" );
    setThis( $retval );
    setQApp( $retval );
    shift @$argv;
}

sub Qt::Application::NEW {
    my $class = shift;
    my $argv = shift;
    unshift @$argv, $0;
    my $count = scalar @$argv;
    my $retval = Qt::Application::QApplication( $count, $argv );
    bless( $retval, " $class" );
    setThis( $retval );
    setQApp( $retval );
    shift @$argv;
}

sub isa {
    my ( $class, $baseClass ) = @_;
    if ( blessed( $class ) ) {
        $class = ref $class;
        $class =~ s/^ //;
    }
    return $class->isa( $baseClass );
}

package QtCore4;

use 5.008006;
use strict;
use warnings;

require Exporter;
require XSLoader;

our $VERSION = '0.96';

our @EXPORT = qw( SIGNAL SLOT emit CAST qApp );

XSLoader::load('QtCore4', $VERSION);

Qt::_internal::init();

sub SIGNAL ($) { '2' . $_[0] }
sub SLOT ($) { '1' . $_[0] }
sub emit (@) { return pop @_ }
sub CAST ($$) {
    my( $var, $class ) = @_;
    if( ref $var ) {
        if ( $class->isa( 'Qt::base' ) ) {
            $class = " $class";
        }
        return bless( $var, $class );
    }
    else {
        return bless( \$var, $class );
    }
}

sub import { goto &Exporter::import }

sub qApp {
    &Qt::qApp
}

package Qt;

use strict;
use warnings;

# Called in the DESTROY method for all QObjects to see if they still have a
# parent, and avoid deleting them if they do.
sub Qt::Object::ON_DESTROY {
    package Qt::_internal;
    my $parent = Qt::this()->parent;
    if( defined $parent ) {
        my $ptr = sv_to_ptr(Qt::this());
        ${ $parent->{'hidden children'} }{ $ptr } = Qt::this();
        Qt::this()->{'has been hidden'} = 1;
        return 1;
    }
    return 0;
}

# Never save a QApplication from destruction
sub Qt::Application::ON_DESTROY {
    return 0;
}

Qt::_internal::installSub(' Qt::Variant::value', sub {
    my $this = shift;
    my $type = $this->type();
    if( $type == Qt::Variant::Invalid() ) {
        return;
    }
    elsif( $type == Qt::Variant::Bitmap() ) {
    }
    elsif( $type == Qt::Variant::Bool() ) {
        return $this->toBool();
    }
    elsif( $type == Qt::Variant::Brush() ) {
        return Qt::qVariantValue($this, 'Qt::Brush');
    }
    elsif( $type == Qt::Variant::ByteArray() ) {
        return $this->toByteArray();
    }
    elsif( $type == Qt::Variant::Char() ) {
        return Qt::qVariantValue($this, 'Qt::Char');
    }
    elsif( $type == Qt::Variant::Color() ) {
        return Qt::qVariantValue($this, 'Qt::Color');
    }
    elsif( $type == Qt::Variant::Cursor() ) {
        return Qt::qVariantValue($this, 'Qt::Cursor');
    }
    elsif( $type == Qt::Variant::Date() ) {
        return $this->toDate();
    }
    elsif( $type == Qt::Variant::DateTime() ) {
        return $this->toDateTime();
    }
    elsif( $type == Qt::Variant::Double() ) {
        return $this->toDouble();
    }
    elsif( $type == Qt::Variant::Font() ) {
        return Qt::qVariantValue($this, 'Qt::Font');
    }
    elsif( $type == Qt::Variant::Hash() ) {
        return $this->toHash();
    }
    elsif( $type == Qt::Variant::Icon() ) {
        return Qt::qVariantValue($this, 'Qt::Icon');
    }
    elsif( $type == Qt::Variant::Image() ) {
        return Qt::qVariantValue($this, 'Qt::Image');
    }
    elsif( $type == Qt::Variant::Int() ) {
        return $this->toInt();
    }
    elsif( $type == Qt::Variant::KeySequence() ) {
        return Qt::qVariantValue($this, 'Qt::KeySequence');
    }
    elsif( $type == Qt::Variant::Line() ) {
        return $this->toLine();
    }
    elsif( $type == Qt::Variant::LineF() ) {
        return $this->toLineF();
    }
    elsif( $type == Qt::Variant::List() ) {
        return $this->toList();
    }
    elsif( $type == Qt::Variant::Locale() ) {
        return Qt::qVariantValue($this, 'Qt::Locale');
    }
    elsif( $type == Qt::Variant::LongLong() ) {
        return $this->toLongLong();
    }
    elsif( $type == Qt::Variant::Map() ) {
        return $this->toMap();
    }
    elsif( $type == Qt::Variant::Palette() ) {
        return Qt::qVariantValue($this, 'Qt::Palette');
    }
    elsif( $type == Qt::Variant::Pen() ) {
        return Qt::qVariantValue($this, 'Qt::Pen');
    }
    elsif( $type == Qt::Variant::Pixmap() ) {
        return Qt::qVariantValue($this, 'Qt::Pixmap');
    }
    elsif( $type == Qt::Variant::Point() ) {
        return $this->toPoint();
    }
    elsif( $type == Qt::Variant::PointF() ) {
        return $this->toPointF();
    }
    elsif( $type == Qt::Variant::Polygon() ) {
        return Qt::qVariantValue($this, 'Qt::Polygon');
    }
    elsif( $type == Qt::Variant::Rect() ) {
        return $this->toRect();
    }
    elsif( $type == Qt::Variant::RectF() ) {
        return $this->toRectF();
    }
    elsif( $type == Qt::Variant::RegExp() ) {
        return $this->toRegExp();
    }
    elsif( $type == Qt::Variant::Region() ) {
        return Qt::qVariantValue($this, 'Qt::Region');
    }
    elsif( $type == Qt::Variant::Size() ) {
        return $this->toSize();
    }
    elsif( $type == Qt::Variant::SizeF() ) {
        return $this->toSizeF();
    }
    elsif( $type == Qt::Variant::SizePolicy() ) {
        return $this->toSizePolicy();
    }
    elsif( $type == Qt::Variant::String() ) {
        return $this->toString();
    }
    elsif( $type == Qt::Variant::StringList() ) {
        return $this->toStringList();
    }
    elsif( $type == Qt::Variant::TextFormat() ) {
        return Qt::qVariantValue($this, 'Qt::TextFormat');
    }
    elsif( $type == Qt::Variant::TextLength() ) {
        return Qt::qVariantValue($this, 'Qt::TextLength');
    }
    elsif( $type == Qt::Variant::Time() ) {
        return $this->toTime();
    }
    elsif( $type == Qt::Variant::UInt() ) {
        return $this->toUInt();
    }
    elsif( $type == Qt::Variant::ULongLong() ) {
        return $this->toULongLong();
    }
    elsif( $type == Qt::Variant::Url() ) {
        return $this->toUrl();
    }
    else {
        return Qt::qVariantValue($this);
    }
});

sub String {
    if ( @_ ) {
        return bless \shift, 'Qt::String';
    } else {
        return bless '', 'Qt::String';
    }
}

sub CString {
    if ( @_ ) {
        return bless \shift, 'Qt::CString';
    } else {
        return bless '', 'Qt::CString';
    }
}

sub Int {
    if ( @_ ) {
        return bless \shift, 'Qt::Int';
    } else {
        return bless '', 'Qt::Int';
    }
}

sub Uint {
    if ( @_ ) {
        return bless \shift, 'Qt::Uint';
    } else {
        return bless '', 'Qt::Uint';
    }
}

sub Bool {
    if ( @_ ) {
        return bless \shift, 'Qt::Bool';
    } else {
        return bless '', 'Qt::Bool';
    }
}

sub Short {
    if ( @_ ) {
        return bless \shift, 'Qt::Short';
    } else {
        return bless '', 'Qt::Short';
    }
}

sub Ushort {
    if ( @_ ) {
        return bless \shift, 'Qt::Ushort';
    } else {
        return bless '', 'Qt::Ushort';
    }
}

sub Uchar {
    if ( @_ ) {
        return bless \shift, 'Qt::Uchar';
    } else {
        return bless '', 'Qt::Uchar';
    }
}

1;

package Qt::String;

use strict;
use warnings;

use overload
    '""' => 'Qt::String::toString';

sub arg {
    my $string = shift;
    my @fields = @_;

    my $stringRef = ${$string};

    my $escapeNum = 1;
    while ( $escapeNum < 99 && $stringRef !~ m/%$escapeNum/ ) {
        ++$escapeNum;
    }
    while ( @fields ) {
        my $field = shift @fields;
        ${$string} =~ s/%$escapeNum/$field/;
        ++$escapeNum;
    }
    return $string;
}

sub toString {
    return ${$_[0]};
}

package Qt::XmlStreamAttributes;

sub EXTEND {
}

package Qt::XmlStreamAttributes::_overload;

use overload
    '==' => \&op_equality;

=pod

=head1 NAME

QtCore4 - Perl bindings for the QtCore version 4 library

=head1 SYNOPSIS

  use QtCore4;
  use QtGui4;
  my $app = Qt::Application(\@ARGV);
  my $button = Qt::PushButton( 'Hello, World!', undef);
  $button->show();
  exit $app->exit();

=head1 DESCRIPTION

This module provides a Perl interface to the QtCore version 4 library.

=head2 EXPORTS

=over

Each of the exported subroutines is prototyped.

=over

=item qApp

Returns a reference to the Qt::CoreApplication/Qt::Application object.  This
mimics Qt's global qApp variable.

=item SIGNAL, SLOT

Used to format arguments to be passed to Qt::Object::connect().

=item emit

This subroutine is actually syntactic sugar.  It is used to signify that the
following subroutine call is activating a signal.

=item CAST REF,CLASSNAME

Serves a similar function to bless(), but takes care of Qt's specific quirks.

=back

=back

=head2 INTRODUCTION

This module provides bindings to the QtCore module of the Qt library from Perl.
There are separate Perl modules for each Qt module, including QtGui, QtNetwork,
QtXml, and QtTest.  This document applies to all Qt4 and KDE4 modules.

The module has been designed to work like writing Qt applications in C++.
However, a few things have been renamed.  Everything is in the Qt:: namespace.
This means that the first 'Q' in the Qt class name has been replaced with
Qt::.  So QWidget becomes Qt::Widget, QListView becomes Qt::ListView, etc.
Also, for classes that use public data members, like QStyleOption and its
subclasses, a set<PropertyName> method is defined to assign to those variables.
For instance, QStyleOption has a 'version' property.  To assign to it, call
$option->setVersion( $value );

=head2 CONSTRUCTOR SYNTAX

A Qt object is constructed by calling a function called Qt::<ClassName>(), not
Qt::<ClassName>->new().  For instance, to make a QApplication, call
Qt::Application( \@ARGV );

=head2 SUBCLASSING

To create a subclass of a Qt class, declare a package, and then declare that
package's base class by using QtCore4::isa and passing it an argument.
Multiple inheritance is not supported.  This package must implement a
subroutine called NEW.  The NEW method is the constructor for that class.  The
first argument to this method will be the name of the class being constructed,
followed by the arguments passed to the constructor (just like in normal
object-oriented Perl).  The first thing that this method should do is call
$class->SUPER::NEW().  This call constructs that parent's base class, and also
sets the special this() value.  You don't need to return anything from NEW(),
PerlQt will return the value of this() to the caller, regardless of what is
returned from NEW().  Any package that wants to use your subclass should
explicitly 'use' it, even if the two packages are defined in the same file.

This is a stub of a class called 'MyWidget', that subclasses Qt::Widget:
    package MyWidget;
    use QtCore4;
    use QtCore4::isa qw( Qt::Widget );

    sub NEW {
        my ( $class, $parent ) = @_;
        $class->SUPER::NEW( $parent );
    }

    package main;
    use QtCore4;
    use MyWidget;

    my $app = Qt::Application(\@ARGV);
    my $widget = MyWidget();
    $widget->show();
    exit $app->exec();

=head2 THE this() VALUE

In a subclass, you don't get a reference to $self.  Instead, you use 'this'.
Not '$this', just 'this'.  In reality, it is a prototyped subroutine that
returns a hash reference, but you should use it any place you would use $self.
Since it is a hash reference, you can create hash keys and assign to them just
like you would any other hashref.

=head2 REIMPLEMENTING C++ FUNCTIONS

To reimplement a C++ function in Perl, just declare a subroutine with the same
name.  Since that instance of the class can already get a reference to itself
by calling 'this', it is not passed in as the first argument.  If the C++
function takes 2 arguments, @_ will contain 2 items.

=head2 ABSTRACT CLASSES

You can subclass from an abstract class, but you must ensure that you implement
all pure virtual methods.  If a pure virtual function is called, and is not
implemented, PerlQt will die with an error message telling you which function
needs to be implemented.

=head2 PERL-SPECIFIC DOCUMENTATION

The following is a list of Perl-specific implementation details, broken up by
class.

=over

=item Global methods to all classes

=item getPointer

This method is used to retrieve an object's numeric memory location.  It is
defined in the Qt::base class, which all Qt objects inherit.

Currently, none of the classes that provided by this binding implement a method
called getPointer().  But if one did, calling $object->getPointer() would not
end up calling this method.  To force this method to be called, you can call
$object->Qt::base::getPointer().

=back

=item Qt::Object

=over

=item Qt::Object::findChildren()

Returns:
An array reference of Qt::Objects

Args:
$type: A string containing the Perl type name
$name: The Qt::Object name to search for.

Description:
Returns all children of this object with the given $name that inherit from
type $type, or an empty list if there are no such objects. Omitting the $name
argument causes all object names to be matched. The search is performed
recursively.  $type should be the Perl name for the type, not the C++ one (i.e.
'Qt::Object', not 'QObject').

=back

=item Qt::Variant

According to the Qt documentation:

    Because QVariant is part of the QtCore library, it cannot provide
    conversion functions to data types defined in QtGui, such as QColor,
    QImage, and QPixmap.  In other words, there is no toColor() function.
    Instead, you can use the QVariant::value() or the qVariantValue() template
    function.

PerlQt4 implements this functionality by supplying 2 functions,
Qt::qVariantValue() and Qt::qVariantFromValue().  These two functions, in
addition to handling the QtGui types, can also handle Perl hash references and
array references.  To accomplish this, 2 metatypes have been declared, called
'HV*' and 'AV*'.

=over

=item Qt::qVariantValue()

Returns:
An object of type $typename, or undef if the conversion cannot be made.

Args:
$variant: A Qt::Variant object.
$typename: The name of the type of data you want out of the Qt::Variant.  This
parameter is optional if the variant contains a Perl hash or array ref.

Description:
Equivalent to Qt's qVariantValue() function.  It is often easier to call
value() on the Qt::Variant object, and let PerlQt return the correct type based
on the Qt::Variant's type.

=item Qt::qVariantFromValue()

Returns:
A Qt::Variant object containing a copy of the given value on success, undef on
failure.

Args:
$value: The value to place into the Qt::Variant.

Description:
Equivalent to Qt's qVariantFromValue() function.  If $value is a hash or array
ref, and is not a PerlQt object, the resulting Qt::Variant will have it's
typeName set to 'HV*' or 'AV*', respectively.

=item Qt::Variant::value()

Returns:
The data contained within a Qt::Variant

Description:
PerlQt reimplements this function to make it easier to all data types out of a
variant (i.e. it is not limited to returning types from the QtCore module).

=back

=back

=head1 EXAMPLES

This module ships with a large number of examples.  These examples have been
directly translated to Perl from the C++ examples that ship with the Qt
library.  They can be accessed in the examples/ directory in the source tree.

=head1 SEE ALSO

The existing Qt documentation is very complete.  Use it for your reference.

Get the project's current version at http://code.google.com/p/perlqt4/

=head1 AUTHOR

Chris Burel, E<lt>chrisburel@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Chris Burel

Based on PerlQt3,
Copyright (C) 2002, Ashley Winters <jahqueel@yahoo.com>
Copyright (C) 2003, Germain Garand <germain@ebooksfrance.org>

Also based on QtRuby,
Copyright (C) 2003-2004, Richard Dale

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

# vim:ts=4:sw=4:et:sta
