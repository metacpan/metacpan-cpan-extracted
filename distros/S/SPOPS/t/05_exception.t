# -*-perl-*-

# $Id: 05_exception.t,v 3.1 2003/02/16 22:01:56 lachoy Exp $

use strict;
use Test::More  tests => 58;

# Test normal base exception

{
    require_ok( 'SPOPS::Exception' );
    my $e_message = 'Error fetching object';
    eval { SPOPS::Exception->throw( $e_message ) };
    my $e = $@;
    is( ref $e, 'SPOPS::Exception', 'Object creation' );
    is( $e->message(), $e_message, 'Message creation' );
    ok( $e->package(), 'Package set' );
    ok( $e->filename(), 'Filename set' );
    ok( $e->line(), 'Line number set' );
    ok( $e->method(), 'Method set' );
    is( ref( $e->trace() ), 'Devel::StackTrace', 'Trace set' );
    is( "$e", $e_message, '$@ stringified' );
    my @stack = $e->get_stack();
    is( scalar @stack, 1, 'Stack set' );
}

# Test the security exception

{
    require_ok( 'SPOPS::Exception::Security' );
    my $s_message = 'Security restrictions violated';
    eval { SPOPS::Exception::Security->throw( $s_message ) };
    my $s = $@;
    is( ref $s, 'SPOPS::Exception::Security', 'Security object creation' );
    is( $s->message(), $s_message, 'Security message creation' );
    ok( $s->package(), 'Security package set' );
    ok( $s->filename(), 'Security filename set' );
    ok( $s->line(), 'Security line number set' );
    ok( $s->method(), 'Security method set' );
    $s->security_required( 4 );
    $s->security_found( 1 );
    is( $s->security_required(), 4, 'Security required set'  );
    is( $s->security_found(), 1, 'Security found set'  );
    is( ref( $s->trace() ), 'Devel::StackTrace', 'Trace set' );
    my $stringified = "Security violation. Object requested [READ] and got [NONE]";
    is( "$s", $stringified, 'Security $@ stringified' );
    my @stack = $s->get_stack();
    is( scalar @stack, 2, 'Stack set' );
}

# Test the DBI exception

{
    require_ok( 'SPOPS::Exception::DBI' );
    my $d_message = 'INSERT failed: Mismatch between number of fields and values';
    my $action = 'insert';
    my $sql    = 'INSERT INTO blah ( f1, f2 ) VALUES ( 5, ?, ? )';
    my $bound  = [ 'Adam', 'Eve' ];

    eval { SPOPS::Exception::DBI->throw( $d_message ) };
    my $d = $@;
    is( ref $d, 'SPOPS::Exception::DBI', 'DBI object creation' );
    is( $d->message(), $d_message, 'DBI message creation' );
    ok( $d->package(), 'DBI package set' );
    ok( $d->filename(), 'DBI filename set' );
    ok( $d->line(), 'DBI line number set' );
    ok( $d->method(), 'DBI method set' );
    $d->action( $action );
    $d->sql( $sql );
    $d->bound_value( $bound );
    is( $d->action(), $action, 'DBI action set'  );
    is( $d->sql(), $sql, 'DBI SQL string set'  );
    is( $d->bound_value()->[0], $bound->[0], 'DBI bound value 1 set' );
    is( $d->bound_value()->[1], $bound->[1], 'DBI bound value 2 set' );
    is( ref( $d->trace() ), 'Devel::StackTrace', 'Trace set' );
    is( "$d", join( "\n", $d_message, $sql ), 'DBI $@ stringified' );
    my @stack = $d->get_stack();
    is( scalar @stack, 3, 'Stack set' );
}

# Test the LDAP exception

{
    require_ok( 'SPOPS::Exception::LDAP' );
    my $l_message = 'Invalid filter: objectclorss not known in schema';
    my $code   = 123;
    my $action = 'insert';
    my $filter = '(objectclorss=inetOrgPerson)';
    my $error_name = 'test';
    eval { SPOPS::Exception::LDAP->throw( $l_message ) };
    my $l = $@;
    is( ref $l, 'SPOPS::Exception::LDAP', 'LDAP object creation' );
    is( $l->message(), $l_message, 'LDAP message creation' );
    ok( $l->package(), 'LDAP package set' );
    ok( $l->filename(), 'LDAP filename set' );
    ok( $l->line(), 'LDAP line number set' );
    ok( $l->method(), 'LDAP method set' );
    $l->code( $code );
    $l->action( $action );
    $l->filter( $filter );
    $l->error_name( $error_name );
    $l->error_text( $l_message );
    is( $l->code(), $code, 'LDAP error code set'  );
    is( $l->action(), $action, 'LDAP action set'  );
    is( $l->filter(), $filter, 'LDAP filter set'  );
    is( $l->error_name(), $error_name, 'LDAP error name set'  );
    is( $l->error_text(), $l_message, 'LDAP error text set'  );
    is( ref( $l->trace() ), 'Devel::StackTrace', 'Trace set' );
    is( "$l", $l_message, 'LDAP $@ stringified' );
    my @stack = $l->get_stack();
    is( scalar @stack, 4, 'Stack set' );
}

# Test backward compatibility with SPOPS::Error

{
    require_ok( 'SPOPS::Error' );
    my $e_message = 'Error fetching object';
    eval { SPOPS::Exception->throw( $e_message ) };
    my $e = $@;
    my $error_info = SPOPS::Error->get;
    is( $e->message(), $error_info->{user_msg}, 'Compatibility: user_msg' );
    is( $e->message(), $error_info->{system_msg}, 'Compatibility: system_msg' );
    is( $e->package(), $error_info->{package}, 'Compatibility: package' );
    is( $e->filename(), $error_info->{filename}, 'Compatibility: filename' );
    is( $e->line(), $error_info->{line}, 'Compatibility: line' );
    is( $e->method(), $error_info->{method}, 'Compatibility: method' );
 }
