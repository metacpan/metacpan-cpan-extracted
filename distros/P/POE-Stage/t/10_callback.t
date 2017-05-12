#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More ( tests => 4 );

use POE::Callback;

###################
my $code = POE::Callback->new( {
                    name => 'scalar',
                    code => sub {
                        my $arg_scalar;
                        is( $arg_scalar, 'scalar', 'arg_scalar' );
                    }
                } );

$code->( $code, { scalar=>'scalar' } );

###################
$code = POE::Callback->new( {
                    name => 'array',
                    code => sub {
                        my @arg_array;
                        is_deeply( \@arg_array, [ 1..2], 'arg_array' );
                    }
                } );

$code->( $code, { array=>[ 1..2 ]  } );

###################
$code = POE::Callback->new( {
                    name => 'hash',
                    code => sub {
                        my %arg_hash;
                        is_deeply( \%arg_hash, { honk=>1, 
                                                 bonk=>1 
                                               }, 'arg_hash' );
                    }
                } );

$code->( $code, { hash=>{ qw( honk 1 bonk 1 ) } } );


$code = POE::Callback->new({
                    name => 'everything',
                    code => sub {
                            my $self;
                            my $rsp;
                            my $req;
                            my $rsp_scalar;
                            my @rsp_array;
                            my %rsp_hash;
                            my $req_scalar;
                            my @req_array;
                            my %req_hash;
                            my $arg_scalar;
                            my @arg_array;
                            my %arg_hash;
                         }
                    } );

pass( 'everything' );

exit 0;

__DATA__
