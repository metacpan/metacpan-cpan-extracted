#!perl

use Test::More;
use strict;
use warnings;
our $es;
my $r;

### BULK ERROR HANDLERS ###
drop_indices();
$es->create_index( index => 'es_test_1' );
wait_for_es();
$es->put_mapping(
    index   => 'es_test_1',
    type    => 'test',
    mapping => {
        properties => {
            text => { type => 'string' },
            num  => { type => 'integer' }
        }
    }
);

wait_for_es();

# Prepare data
ok $r= $es->bulk_index(
    index   => 'es_test_1',
    type    => 'test',
    refresh => 1,
    docs    => [
        { id => 1, data => { text => 'foo', num => 1 } },
        { id => 2, data => { text => 'bar', num => 2 } },
    ]
    ),
    'Prepare bulk data';

my %args = (
    index   => 'es_test_1',
    type    => 'test',
    refresh => 1,
    actions => [
        {   index => {
                id       => 1,
                data     => { text => 'foo', num => 1 },
                _version => 2
            }
        },
        { index  => { id => 2, data => { text => 'bar', num => 'xxx' } } },
        { create => { id => 1, data => { text => 'foo', num => 1 } } },
    ]
);

# Conflict handler
my $conflict = 0;
my $general  = 0;
my $i        = 0;

# No handlers
ok $r = $es->bulk(%args), 'No handlers';
check_errors( $r, [ 'conflict', 'general', 'conflict' ], {} );

# On conflict handler
ok $r = $es->bulk( %args, on_conflict => \&on_conflict ), 'Conflict handler';
check_errors( $r, ['general'], { conflict => 2 } );

# On error handler
ok $r = $es->bulk( %args, on_error => \&on_error ), 'Error handler';
check_errors( $r, [], { general => 3 } );

# Both handlers
ok $r = $es->bulk(
    %args,
    on_error    => \&on_error,
    on_conflict => \&on_conflict
    ),
    'Both handlers';
check_errors( $r, [], { conflict => 2, general => 1 } );

# Ignore conflict
ok $r = $es->bulk( %args, on_conflict => 'IGNORE' ), 'Ignore conflict ';
check_errors( $r, ['general'], {} );

# Ignore error
ok $r = $es->bulk( %args, on_error => 'IGNORE' ), 'Ignore error handler';
check_errors( $r, [], {} );

# Ignore both
ok $r = $es->bulk( %args, on_error => 'IGNORE', on_conflict => 'IGNORE' ),
    'Ignore both handlers';
check_errors( $r, [], {} );

# Ignore conflict, handle error
ok $r = $es->bulk(
    %args,
    on_error    => \&on_error,
    on_conflict => 'IGNORE'
    ),
    'Ignore conflict, handle error';
check_errors( $r, [], { conflict => 0, general => 1 } );

# Handle conflict, ignore error
ok $r = $es->bulk(
    %args,
    on_error    => 'IGNORE',
    on_conflict => \&on_conflict
    ),
    'Handle conflict, ignore error';
check_errors( $r, [], { conflict => 2, general => 0 } );

#===================================
sub on_conflict {
#===================================
    my ( $action, $doc, $error, $i ) = @_;
    $conflict++;
    ok defined $i, " - on_error doc[i] defined";
    if ( $action eq 'index' ) {
        is $action, 'index', ' - on_conflict action';
        is $doc->{_version}, 2, ' - on_conflict version';
        like $error, qr/VersionConflictEngineException/,
            ' - on_conflict error';
    }
    else {
        is $action, 'create', ' - on_conflict action';
        like $error, qr/DocumentAlreadyExistsException/,
            ' - on_conflict error';

    }
}

#===================================
sub on_error {
#===================================
    my ( $action, $doc, $error, $i ) = @_;
    $general++;
    ok defined $i, " - on_error doc[i] defined";
    if ( $action eq 'index' ) {
        is $action, 'index', ' - on_error action';
        ok $doc->{data}{num}, ' - on_error data';
        like $error, qr/
            MapperParsingException
          | VersionConflictEngineException
        /x, ' - on_error error';
    }
    else {
        is $action, 'create', ' - on_error action';
        ok $doc->{data}{num}, ' - on_error data';
        like $error, qr/DocumentAlreadyExistsException/, ' - on_error error';
    }
}

#===================================
sub check_errors {
#===================================
    my ( $r, $errors, $handled ) = @_;
    is @{ $r->{errors} }, @$errors, ' - unhandled errors: ' . scalar @$errors;

    my $i = 0;
    for (@$errors) {
        my $re
            = $_ eq 'conflict'
            ? qr/VersionConflictEngineException|DocumentAlreadyExistsException/
            : qr/NumberFormatException/;

        like $r->{errors}[ $i++ ]{error}, $re, " - $_ error";
    }

    is $conflict, $handled->{conflict} || 0,
        $handled->{conflict}
        ? ' - on_conflict called'
        : ' - on_conflict not called';

    is $general, $handled->{general} || 0,
        $handled->{general}
        ? ' - on_error called'
        : ' - on_error not called';

    $conflict = 0;
    $general  = 0;
}

1
