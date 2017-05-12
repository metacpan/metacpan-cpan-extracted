use strict;
use warnings;
use Test::More;
use Test::Fatal;
use OptArgs qw/:all/;

#------------------------------------------------------------------------
# subcmd()
#------------------------------------------------------------------------

like exception {
    subcmd;
},
  qr/missing required/,
  'subcmd usage';

like exception {
    subcmd( cmd => 'cmd', comment => 'description' );
}, qr/parent command not found/, 'subcmd before opt/arg';

#------------------------------------------------------------------------
# optargs()
#------------------------------------------------------------------------

@ARGV = ();

like exception {
    optargs;
}, qr/no option or argument defined/, 'no defined';

#------------------------------------------------------------------------
# opt()
#------------------------------------------------------------------------

like exception {
    opt;
}, qr/usage: opt/, 'missing name';

like exception {
    opt undef;
}, qr/usage: opt/, 'missing name';

like exception {
    opt 0 => ();
}, qr/usage: opt/, 'missing name';

like exception {
    opt '' => ();
}, qr/usage: opt/, 'missing name';

like exception {
    opt no_isa => ();
}, qr/missing required parameter/, 'required isa';

like exception {
    opt str => ( isa => 'Str' );
}, qr/missing required parameter/, 'dont have all';

like exception {
    opt str => ( isa => 'Str', comment => 'comment', dummy => 1 );
}, qr/invalid parameter/, 'invalid parameter';

like exception {
    opt no_isa => ( isa => 'NoType', comment => 'comment' );
}, qr/unknown type/, 'unknown type';

like exception {
    opt no_bool => ( isa => 'Str', comment => 'comment', ishelp => 1 );
}, qr/applied to Bool/, 'ishelp only on bools';

opt str => ( isa => 'Str', comment => 'comment' );

like exception {
    opt str => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

#------------------------------------------------------------------------
# arg()
#------------------------------------------------------------------------

like exception {
    arg;
}, qr/usage: arg/, 'missing name';

like exception {
    arg undef;
}, qr/usage: arg/, 'missing name';

like exception {
    arg 0 => ();
}, qr/usage: arg/, 'missing name';

like exception {
    arg '' => ();
}, qr/usage: arg/, 'missing name';

like exception {
    arg no_isa => ();
}, qr/missing required parameter/, 'required isa';

like exception {
    arg no_isa => ( isa => 'Str' );
}, qr/missing required parameter/, 'required both';

like exception {
    arg str => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

like exception {
    arg invalid_param => ( isa => 'Str', comment => 'comment', dummy => 1 );
}, qr/invalid parameter/, 'invalid parameter';

like exception {
    arg bad_type => ( isa => 'NoType', comment => 'comment', );
}, qr/unknown type/, 'unknown type';

like exception {
    arg clash => (
        isa      => 'Str',
        comment  => 'comment',
        required => 1,
        default  => 1,
    );
}, qr/cannot be used together/, 'clash';

like exception {
    arg fallback => (
        isa      => 'Str',
        comment  => 'comment',
        fallback => {
            name    => 'other',
            comment => 'comment',
        },
    );
}, qr/only valid with isa/, 'fallback';

like exception {
    arg fallback => (
        isa      => 'SubCmd',
        comment  => 'comment',
        fallback => 1,
    );
}, qr/must be a hashref/, 'fallback hashref';

arg astr => ( isa => 'Str', comment => 'comment', required => 1 );

#------------------------------------------------------------------------
# opt()
#------------------------------------------------------------------------

# check the opt/arg clash from the other side
like exception {
    opt astr => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

#------------------------------------------------------------------------
# optargs()
#------------------------------------------------------------------------

@ARGV = ();

like exception {
    optargs;
}, qr/^usage:/, 'missing argument';

@ARGV = (qw/x x2/);

like exception {
    optargs;
}, qr/unexpected options or arguments/i, 'unexpected option or argument';

arg int => (
    isa     => 'Int',
    comment => 'comment',
);

@ARGV = qw(x 3.14);

TODO: {
    local $TODO = 'arg types not implemented yet';
    like exception {
        optargs;
    }, qr/not an Int: 3.14/, 'not an Int';
}

opt bool => ( isa => 'Bool', comment => 'comment', );

like exception {
    arg bool => ( isa => 'Str', comment => 'comment', );
}, qr/already defined/, 'already defined';

#------------------------------------------------------------------------
# subcmd()
#------------------------------------------------------------------------

subcmd( cmd => 'cmd', comment => 'description' );

like exception {
    subcmd( cmd => 'cmd', comment => 'description' );
}, qr/already defined/, 'subcmd already defined';

#------------------------------------------------------------------------
# dispatch()
#------------------------------------------------------------------------

like exception {
    dispatch;
}, qr/dispatch/, 'dispatch usage';

like exception {
    dispatch('one only');
}, qr/dispatch/, 'dispatch usage one arg';

like exception {
    dispatch( 'nosub', 'noclass' );
}, qr/locate noclass/, 'noclass';

done_testing;
