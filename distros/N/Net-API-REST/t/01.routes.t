#!/usr/bin/perl
BEGIN
{
	use strict;
	use warnings;
	use lib './lib';
    use vars qw( $DEBUG );
	use URI;
	use IO::File;
    use Test::More qw( no_plan );
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

my $url = shift( @ARGV ) || 'http://localhost/jp/org/stock/1234/board/member/5678';
my $api = MyAPI->new( debug => $DEBUG );
my $uri = URI->new( $url );
my $sub = $api->route( $uri );
ok( $sub, "Getting the handler" );
if( !defined( $sub ) )
{
	diag( "An error occurred in getting the handler: ", $api->error );
}
elsif( !length( $sub ) )
{
	diag( "No end point matching the uri path '$uri'" );
}
is( ref( $sub ), 'Net::API::REST::Endpoint', "Handler is a Net::API::REST::Endpoint object" );
my $rv = $sub->handler->( 'argv1' );
is( $rv, 'John Doe', "Checking handler returned value." );
is( $sub->params->{csrf_method} => 'path_info', 'endpoint -> params' );
my $params = $sub->params;
is( $params->{csrf_method}, 'path_info', 'endpoint -> params{auth_method}' );

done_testing();

exit(0);

package MyAPI;
BEGIN
{
	use strict;
	use lib './lib';
	use curry;
	use Test::Mock::Apache2;
	no strict 'subs';
	use Test::MockObject;
	use Net::API::REST;
	use parent qw( Net::API::REST );
	use Net::API::REST::Request;
	use Net::API::REST::Response;
	our $VERSION = '0.1';
};

use strict;
use warnings;

{
	our( @objects ) = &fake_some_more();
}

sub fake_some_more
{
    my $r = Test::MockObject->new();
    $r->fake_module('Apache2::RequestRec',
        headers_in => sub { return( {} ) },
    );
    bless $r, 'Apache2::ServerRec';
    return( $r );
}

sub init
{
	my $self = shift( @_ );
	$self->{routes} =
	{
	1 => 
		{
		auth =>
			{
			## Noop as in nothing to see here
			_handler => $self->curry::noop,
			signin => $self->curry::sign_in,
			signout => $self->curry::sign_out,
			singup => $self->curry::sign_up,
			profile => $self->curry::profile,
			facebook => 
				{
				_handler => $self->curry::oauth('facebook' => 1),
				callback => $self->curry::callback('facebook' => 1),
				},
			google =>
				{
				_handler => $self->curry::oauth('google' => 1),
				callback => $self->curry::callback('google' => 1),
				},
			linkedin =>
				{
				_handler => $self->curry::oauth('linkedin' => 1),
				callback => $self->curry::callback('linkedin' => 1),
				},
			telegram =>
				{
				_handler => $self->curry::oauth('telegram' => 1),
				callback => $self->curry::callback('telegram' => 1),
				},
			},
		jp =>
			{
			_handler => $self->curry::jp_noop,
			org =>
				{
					_handler => $self->curry::jp_orgs,
					stock =>
					{
						_handler => $self->curry::jp_stock,
						_var =>
						{
							_handler => $self->curry::jp_stock,
							_name => 'org_id',
							# arbitrary hash of key-value pairs
							_params => { csrf_method => 'path_info' },
							board =>
							{
								_handler => $self->curry::board,
								member =>
								{
									_handler => $self->curry::board_member,
									_var => 
									{
									#_handler => $self->curry::board_member,
									_handler => 'MyAPI::Processing->process',
									_name => 'person_id',
									}
								}
							}
						}
					}
				}
			}
		}
	};
	$self->SUPER::init( @_ );
	my $r = Apache2::RequestUtil->request();
	# need to produce a Apache2::RequestRec
	$self->request( Net::API::REST::Request->new( $r, checkonly => 1 ) );
	$self->response( Net::API::REST::Response->new( request => $self->request ) );
	return( $self );
}

sub board
{
	my $self = shift( @_ );
	print( "Got here for board with arguments: '", join( "', '", @_ ), "'\n" );
}

sub board_member
{
	my $self = shift( @_ );
	print( "Got here for board_member with arguments: '", join( "', '", @_ ), "'\n" );
}

sub callback
{
	my $self = shift( @_ );
	print( "Got here with callback with arguments: '", join( "', '", @_ ), "'\n" );
}

sub jp_noop
{
	my $self = shift( @_ );
	print( "Got here for jp_noop doing nothing with arguments: '", join( "', '", @_ ), "'\n" );
}

sub jp_orgs
{
	my $self = shift( @_ );
	print( "Got here for jp_orgs with arguments: '", join( "', '", @_ ), "'\n" );
}

sub jp_stock
{
	my $self = shift( @_ );
	print( "Got here for jp_stock with arguments: '", join( "', '", @_ ), "'\n" );
}

sub noop
{
	my $self = shift( @_ );
	print( "Got here for noop with arguments: '", join( "', '", @_ ), "'\n" );
}

sub oauth
{
	my $self = shift( @_ );
	print( "Got here with oauth with arguments: '", join( "', '", @_ ), "'\n" );
}

sub profile
{
	my $self = shift( @_ );
	print( "Got here with profile\n" );
}

sub sign_in
{
	my $self = shift( @_ );
	print( "Got here with signin\n" );
}

sub sign_out
{
	my $self = shift( @_ );
	print( "Got here with signout\n" );
}

sub sign_up
{
	my $self = shift( @_ );
	print( "Got here with signup\n" );
}

package MyAPI::Processing;
BEGIN
{
	use strict;
	use parent qw( Module::Generic );
};

sub process
{
	my $self = shift( @_ );
	return( "John Doe" );
}
