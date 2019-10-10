package OpenERP::XMLRPC::Client;
# ABSTRACT: XMLRPC Client tweaked for OpenERP interaction.

our $VERSION = '0.25';

use 5.010;
use Moose;
use MIME::Base64;
use failures qw/openerp::fault/;
use RPC::XML qw/RPC_STRING/;


has 'username' 	=> ( is  => 'ro', isa => 'Str', default => 'admin');
has 'password' 	=> ( is  => 'ro', isa => 'Str', default => 'admin');
has 'dbname' 	=> ( is  => 'ro', isa => 'Str', default => 'terp');
has 'host' 		=> ( is  => 'ro', isa => 'Str', default => '127.0.0.1');
has 'port' 		=> ( is  => 'ro', isa => 'Int', default => 8069);
has 'proto'		=> ( is  => 'ro', isa => 'Str', default => 'http');
has use_failures => (is => 'ro', isa => 'Bool', default => 0);

has '_report_report_uri'	=> ( is => 'ro', isa => 'Str', default => 'xmlrpc/report' );
has '_object_execute_uri'	=> ( is => 'ro', isa => 'Str', default => 'xmlrpc/object' );
has '_object_execute_kw_uri'	=> ( is => 'ro', isa => 'Str', default => 'xmlrpc/object' );
has '_object_exec_workflow_uri'	=> ( is => 'ro', isa => 'Str', default => 'xmlrpc/object' );

has 'openerp_uid' 	=> ( is  => 'rw', isa => 'Int' );
has 'base_rpc_uri'	=> ( is  => 'rw', isa => 'Str', default => 'xmlrpc/common');


with 'MooseX::Role::XMLRPC::Client' => 
{ 
	name => 'openerp',
	login_info => 1,
};

sub _build_openerp_userid { shift->username }
sub _build_openerp_passwd { shift->password }
sub _build_openerp_uri
{
	my $self = shift;
	return $self->proto . '://' . $self->host . ':' . $self->port . '/' . $self->base_rpc_uri;
}

sub openerp_login
{
    my $self = shift;

    # call 'login' method to get the uid..
    my $res = $self->openerp_rpc->send_request('login', RPC_STRING($self->dbname), $self->username, \$self->password );

    if ( ! defined $res || ! ref $res )
    {
        die "Failed to log into OpenERP XML RPC service";
    }
    die "Incorrect username or password" if $$res == 0;


    # set the uid we have just had returned from logging in..
    $self->openerp_uid( ${ $res } );
    # NOTE: OpenERP seems to be filling in faultCode not faultString these days
    # (6.1.1) so we need to check for that and display it instead.
    if($self->use_failures)
    {
        $self->openerp_rpc->fault_handler(sub { 
            failure::openerp::fault->throw({
                    msg => $_[0]->{faultCode} ? $_[0]->{faultCode}->value : $_[0]->string, 
                    payload => { original_exception => $_[0]}
                });
        });
    }
    else
    {
        $self->openerp_rpc->fault_handler(sub { 
                confess $_[0]->{faultCode} ? $_[0]->{faultCode}->value : $_[0]->string
            });
    }
}

sub openerp_logout
{
	my $self = shift;
	# do nothing on logout...nothing is required..
}



sub BUILD
{
	my $self = shift;
    $RPC::XML::ENCODING = 'utf-8';
	$self->openerp_login;
}


sub change_uri
{
	my $self = shift;
	my $base_uri = shift;

	my $exsting_base_uri = $self->base_rpc_uri;

	return $exsting_base_uri if $base_uri eq $exsting_base_uri;

	$self->base_rpc_uri( $base_uri );						# change the base path.
	$self->openerp_rpc->uri( $self->_build_openerp_uri ); 	# rebuild and set the new uri.
	return $exsting_base_uri; # return the old uri.
}

sub object_execute
{
	my $self = shift;

	my $method 		= shift;	# eg. 'search'
	my $relation 	= shift;	# eg. 'res.partner'
	my @args 		= @_;		# All other args we just pass on.

	# change the uri to base uri we are going to query..
    $self->change_uri( $self->_object_execute_uri );

    $self->simple_request
	(
		'execute',
		RPC_STRING($self->dbname),
		$self->openerp_uid,
		\$self->password,
		$relation,
		$method,
		@args
	);

}

sub object_execute_kw
{
	my $self = shift;

	my $method 		= shift;	# eg. 'search'
	my $relation 	= shift;	# eg. 'res.partner'
	my @args 		= @_;		# All other args we just pass on.

	# change the uri to base uri we are going to query..
    $self->change_uri( $self->_object_execute_kw_uri );

    $self->simple_request
	(
		'execute_kw',
		RPC_STRING($self->dbname),
		$self->openerp_uid,
		\$self->password,
		$relation,
		$method,
		@args,
	);

}

sub object_exec_workflow
{
	my $self = shift;

	my $method 		= shift;	# eg. 'search'
	my $relation 	= shift;	# eg. 'res.partner'
	my @args 		= @_;		# All other args we just pass on.

	# change the uri to base uri we are going to query..
    $self->change_uri( $self->_object_exec_workflow_uri );

    $self->simple_request
	(
		'exec_workflow',
		RPC_STRING($self->dbname),
		$self->openerp_uid,
		\$self->password,
		$relation,
		$method,
		@args
	);

}

sub report_report
{
	my $self = shift;

	my $report_id 	= shift;	# eg. 'purchase.quotation'
    my $object_id   = shift;
	my $parameters  = shift;	# eg.  model, id and report_type

	# change the uri to base uri we are going to query..
    $self->change_uri( $self->_report_report_uri );

    return $self->simple_request
	(
		'report',
		RPC_STRING($self->dbname),
		$self->openerp_uid,
		\$self->password,
		$report_id,
        [$object_id],
        $parameters,
        @_
	);
}

sub report_report_get
{
	my $self = shift;

	my $report_id	= shift;	# eg. 123

	# change the uri to base uri we are going to query..
    $self->change_uri( $self->_report_report_uri );

    my $object = $self->simple_request
	(
		'report_get',
		RPC_STRING($self->dbname),
		$self->openerp_uid,
		\$self->password,
		$report_id,
	);

    if($object->{state})
    {
        my $data = $object->{result};
        return decode_base64($data);
    }

    return;
}

sub simple_request
{
    my $self = shift;

    # I haven't forced dbname to be passed as string in here because it's possible other consumers of this class have
    # used it in other ways where the dbname wasn't necessarily the second argument.  Therefore I've done it in
    # each of its callers I know about.

    local *RPC::XML::boolean::value = sub {
        my $self = shift;
        # this fudges the false so it's not 0
        # which means if it was used to indicate null is probably going to work better.
        # the downside is that we presumably lose some precision when it comes to bools
        # and nulls.
        return undef unless ${$self};
        return 1;
    };

    return $self->openerp_rpc->simple_request(@_);
}

sub create
{
    return shift->_three_arg_execute('create', @_);
}

sub read
{
    my ($self, $object, $ids, $context, $fields) = @_;
    
    $ids = [ $ids ] unless ( ref $ids eq 'ARRAY' );
    
    if ($context) {
	return $self->object_execute('read', $object, $ids, $fields, $context);
    } else {
	return $self->object_execute('read', $object, $ids);
    }
}

sub search
{
    my ($self, $object, $args, $context, $offset, $limit, $order) = @_;
    
    if ($context) {
	return $self->object_execute('search', $object, $args, $offset // 0, $limit, $order, $context);
    } else {
	return $self->object_execute('search', $object, $args);
    }
}

sub field_info
{
    return shift->_three_arg_execute('fields_view_get', @_);
}

sub model_fields
{
    return shift->_three_arg_execute('fields_get', @_);
}

sub update
{
    return shift->_array_execute('write', @_);
}

sub get_defaults
{
    return shift->_array_execute('default_get', @_);
}

sub delete
{
    return shift->_array_execute('unlink', @_);
}

sub copy
{
    return shift->_three_arg_execute('copy', @_);
}

sub _three_arg_execute
{
	my $self 	= shift;
    my $verb    = shift;
	my $object 	= shift;
	my $args 	= shift;
	return $self->object_execute($verb, $object, $args, @_ );
}

sub _array_execute
{
	my $self 	= shift;
    my $verb    = shift;
	my $object 	= shift;
	my $ids 	= shift;
	my $args 	= shift;

    # ensure we pass an array of IDs to the RPC..
    $ids = [ $ids ] unless ( ref $ids eq 'ARRAY' );

	return $self->object_execute($verb, $object, $ids, $args, @_ );
}

sub search_detail
{
	my ($self, $object, $args, $context, $offset, $limit) = @_;

	# search and get ids..
	my $ids = $self->search( $object, $args, $context, $offset, $limit );
	return unless ( defined $ids && ref $ids eq 'ARRAY' && scalar @$ids >= 1 );

	# read data from all the ids..
    # FIXME: I'm fairly sure context is in the wrong place.
	return $self->read( $object, $ids, $context );
}

sub read_single
{
	my $res = shift->read( @_ );
	return unless ( defined $res && ref $res eq 'ARRAY' && scalar @$res >= 1 );
	return $res->[0];
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OpenERP::XMLRPC::Client - XMLRPC Client tweaked for OpenERP interaction.

=head1 VERSION

version 0.25

=head1 SYNOPSIS

	my $erp = OpenERP::XMLRPC::Client->new( dbname => 'terp', username => 'admin', password => 'admin', host => '127.0.0.1', port => '8069' )	
	my $partner_ids = $erp->object_execute( 'res.partner', 'search', [ 'name', 'ilke', 'abc' ] );

	# READ a res.partner object
	my $partner = $erp->read( 'res.partner', $id );

	print "You Found Partner:" . $partner->{name} . "\n";

=head1 DESCRIPTION

I have tried to make this extendable so made use of moose roles to structure the calls to the
different methods available from the openerp rpc.

This makes use of the L<MooseX::Role::XMLRPC::Client> to communicate via rpc.

This module was built to be used by another L<OpenERP::XMLRPC::Simple> and handles 
openerp specific rpc interactions. It could be used by something else to access 
openerp rpc services.

=head1 NAME

OpenERP::XMLRPC::Client - XMLRPC Client tweaked for OpenERP interaction.

=head1 NAME

OpenERP::XMLRPC::Client - XML RPC Client for OpenERP

=head1 Parameters

	username		- string - openerp username (default: 'admin')
	password		- string - openerp password (default: 'admin')
	dbname			- string - openerp database name (default: 'terp')
	host			- string - openerp rpc server host (default: '127.0.0.1' )
	port			- string - openerp rpc server port (default: 8069)
	proto			- string - openerp protocol (default: http) .. untested anything else.

=head1 Attributes 	

	openerp_uid		- int 		- filled when the connection is logged in.
	base_rpc_uri	- string	- used to hold uri the rpc is currently pointing to.
	openerp_rpc		- L<RPC::XML::Client> - Provided by L<MooseX::Role::XMLRPC::Client>

=head1 METHODS

These methods re-present the OpenERP XML RPC but in a slightly more user friendly way.

The methods have been tested using the 'res.partner' object name and the demo database
provided when you install OpenERP. 

=head2 BUILD

When the object is instanciated, this method is run. This calls openerp_login.

=head2 openerp_login

Logs the client in.  Called automatically when the object is created.

=head2 openerp_logout

Basically a no-op.

=head2 object_execute

Low level method for making a call to the Open ERP server.  Normally called by a 
wrapper function like L<create> or L<read>.

=head2 object_exec_workflow

Makes an 'exec_workflow' call to Open ERP.

=head2 report_report

Sends a 'report' call to Open ERP.

=head2 report_report_get

Sends a 'report_get' call to Open ERP.

=head2 change_uri

OpenERP makes methods available via different URI's, this method is used to change which
URI the rpc client is pointing at. 

Arguments:
	$_[0]	- object ref. ($self)
	$_[1]	- string (e.g. "xmlrpc/object") base uri path.

Returns:
	string	- the old uri - the one this new one replaced.

=head2 read ( OBJECTNAME, [IDS] )

Can pass this a sinlge ID or an ARRAYREF of ID's, it will return an ARRAYREF of 
OBJECT records (HASHREF's).

Example:
	$partner = $erp->read('res.partner', 1 );
	print "This is the returned record name:" .  $partner->[0]->{name} . "\n";

	$partners = $erp->read('res.partner', [1,2] );
	print "This is the returned record 1:" .  $partners->[0]->{name} . "\n";
	print "This is the returned record 2:" .  $partners->[1]->{name} . "\n";

Returns: ArrayRef of HashRef's - All the objects with IDs passed.

=head2 search ( OBJECTNAME, [ [ COLNAME, COMPARATOR, VALUE ] ] )

Used to search and return IDs of objects matching the searcgh.

Returns: ArrayRef of ID's - All the objects ID's matching the search.

Example:
	$results = $erp->search('res.partner', [ [ 'name', 'ilke', 'abc' ] ] );
	print "This is the 1st ID found:" .  $results->[0] . "\n";

=head2 copy ( model, id )

Copies the object specified, returning the id of the new object.

=head2 create ( OBJECTNAME, { COLNAME => COLVALUE } )

Returns: ID	- the ID of the object created.

Example:
	$new_id = $erp->create('res.partner', { 'name' => 'new company name' } );

=head2 update ( OBJECTNAME, ID, { COLNAME => COLVALUE } )

Returns: boolean	 - updated or not.

Example:
	$success = $erp->update('res.partner', 1, { 'name' => 'changed company name' } );

=head2 delete ( OBJECTNAME, ID )

Returns: boolean	 - deleted or not.

Example:
	$success = $erp->delete('res.partner', 1 );

=head2 field_info ( OBJECTNAME )

Returns: hash containing all field info, this contains field names and field types.

=head2 model_fields ( OBJECTNAME )

Returns: hash containing all the models fields.

=head2 get_defaults ( OBJECTNAME, [ FIELDS ] )

Returns: hash containing the default values for those fields.

=head2 search_detail ( OBJECTNAME, [ [ COLNAME, COMPARATOR, VALUE ] ], CONTEXT )

Used to search and read details on a perticular OBJECT. This uses 'search' to find IDs,
then calls 'read' to get details on each ID returned.

Returns: ArrayRef of HashRef's - All the objects found with all their details.

Example:
	$results = $erp->search_detail('res.partner', [ [ 'name', 'ilke', 'abc' ] ] );
	print "This is the 1st found record name:" .  $results->[0]->{name} . "\n";

The C<CONTEXT> argument is optional. This allows a hasref containing the current
search context to be provided, e.g.

 my $results = $erp->search_detail(
     'stock.location',
     [
	 ['usage' => '=' => 'internal']
     ],
     {
         active_id => $self->id,
         active_ids => [$self->id],
         active_model => 'product.product',
         full => 1,
         product_id => $self->id,
         search_default_in_location => 1,
         section_id => undef,
         tz => undef,
     }
 )

=head2 read_single ( OBJECTNAME, ID )

Pass this a sinlge ID and get a single OBJECT record (HASHREF).

Example:
	$partner = $erp->read_single('res.partner', 1 );
	print "This name of partner with ID 1:" .  $partner->{name} . "\n";

Returns: HashRef 	- The objects data

=head1 SEE ALSO

L<RPC::XML::Client>

=head1 AUTHORS

=over 4

=item *

Benjamin Martin <ben@madeofpaper.co.uk>

=item *

Colin Newell <colin@opusvl.com>

=item *

Jon Allen (JJ) <jj@opusvl.com>

=item *

Nick Booker <nick.booker@opusvl.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by OpusVL <community@opusvl.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
