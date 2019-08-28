package Puppet::DB;

use 5.10.0;
use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Request;
use JSON;
use Time::Local;
use Moose;
use Moose::Exporter;
use String::ShortHostname;
use Module::Load::Conditional qw[ check_install ];
use Data::Dumper;

#ABSTRACT: Object for easily getting Puppet DB data (e.g. facts, reports, etc)


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( server_name => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

# We only need to activate storage when someone using us has already installed the module
# otherwise the following code can silently fail
#eval {
#require MooseX::Storage;
#with Storage('format' => 'JSON', 'io' => 'File', traits => ['DisableCycleDetection']);
#1;
#};
if ( check_install( module => 'MooseX::Storage' ) ) {
    require MooseX::Storage;
    MooseX::Storage->import();
    with Storage(
        'format' => 'JSON',
        'io'     => 'File',
        traits   => ['DisableCycleDetection']
    );
}


# Connect to the Puppet DB server on localhost by default - this can be overidden when consumed
has 'server_name' => (
    is        => 'rw',
    isa       => 'Str',
    required  => 1,
    default   => 'localhost',
    predicate => 'has_server_name',
);


# Connect to the Puppet DB server on port 8080 by default - this can be overidden when consumed
has 'server_port' => (
    is        => 'rw',
    isa       => 'Int',
    required  => 1,
    default   => 8080,
    predicate => 'has_server_port',
);


sub refresh {
    my $self       = shift;
    my $api_server = $self->server_name;
    my $api_port   = $self->server_port;
    my $action     = shift;
    $action = 'facts' if !$action;
    my $data = shift;
    $data = {} if !$data;
    $data = encode_json($data);
    my $uri = "http://$api_server:$api_port/pdb/query/v4/$action";
    my $req = HTTP::Request->new( 'POST', $uri );
    $req->header( 'Content-Type' => 'application/json' );
    $req->content($data);
    my $ua       = LWP::UserAgent->new();
    my $response = $ua->request($req);
    my $output;

    if ( $response->is_success ) {
        $output = $response->decoded_content;
    }
    else {
        die $response->status_line . "\n" . $response->decoded_content;
    }
    $data = decode_json($output);
    $self->results($data);
}


sub refresh_facts {
    my $self  = shift;
    my $query = shift;
    $query = {} if !$query;
    $self->refresh( 'facts', $query );
    $self->facts( $self->results );

}


# property to store more generic results
has 'results' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    predicate => 'has_results',
);


# property to store facts
has 'facts' => (
    is        => 'rw',
    isa       => 'ArrayRef',
    default   => sub { [] },
    predicate => 'has_facts',
);


sub allfacts_by_certname {
    my $self  = shift;
    my $facts = $self->facts;
    my $data  = {};
    for my $fact_element (@$facts) {
        $data->{ $fact_element->{certname} }{ $fact_element->{name} } =
          $fact_element->{value};
    }
    return $data;
}


sub allfacts_by_hostname {
    my $self  = shift;
    my $facts = $self->facts;
    my $data  = {};
    for my $fact_element (@$facts) {
        $data->{ short_hostname( $fact_element->{certname} ) }
          { $fact_element->{name} } = $fact_element->{value};
    }
    return $data;
}


sub get_fact {
    return get_fact_by_certname( shift, shift, shift );
}


sub get_fact_by_certname {
    my $self     = shift;
    my $facts    = $self->facts;
    my $fact     = shift;
    my $certname = shift;
    for my $fact_element (@$facts) {
        if (    $fact eq $fact_element->{name}
            and $certname eq $fact_element->{certname} )
        {
            return $fact_element->{value};
        }
    }
}


sub get_fact_by_short_hostname {
    my $self      = shift;
    my $facts     = $self->facts;
    my $fact      = shift;
    my $shortname = shift;
    for my $fact_element (@$facts) {
        if (    $fact eq $fact_element->{name}
            and $fact_element->{certname} =~ /$shortname(\..+)*$/ )
        {
            return $fact_element->{value};
        }
    }
}


sub is_certname_in_puppetdb {
    my $self  = shift;
    my $name  = shift;
    my $found = 0;

    my $rule = { 'query' => [ "=", "certname", $name ] };
    $self->refresh_facts( $rule );
    my $nodes = $self->facts;

    for my $node (@$nodes) {
        if ( $name eq $node->{certname} ) { $found = 1; last }
    }
    return $found;
}


sub is_node_in_puppetdb {
    my $self = shift;
    my $name = shift;
    return $self->is_certname_in_puppetdb($name);
}


sub is_hostname_in_puppetdb {
    my $self  = shift;
    my $name  = shift;
    my $found = 0;

    my $rule = { 'query' => [ "~", "certname", '^'.$name.'\.' ] };

    # If we receive a name with dots - assume someone accidentally passed a certname instead of hostname
    if( $name =~ /\./ ){
        $rule = { 'query' => [ "=", "certname", $name ] };
    }

    $self->refresh_facts( $rule );
    my $nodes = $self->facts;

    for my $node (@$nodes) {
        if ( $node->{certname} =~ /^$name(\..+)*$/ ) { $found = $node->{certname}; last }
    }
    return $found;
}


Moose::Exporter->setup_import_methods( as_is => [ 'parse_puppetdb_time' ]);


sub parse_puppetdb_time {
    my $self    = shift;
    my $in_time = shift;
    my $time;

    # 2016-02-08T02:21:04.417Z
    if ( $in_time =~ /(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d\.*\d*)Z/ ) {
        my ( $year, $mon, $mday, $hour, $min, $sec ) =
          ( $1, $2, $3, $4, $5, $6 );
        $time = timegm( $sec, $min, $hour, $mday, $mon - 1, $year );
    }
    else {
        $time = 0;
    }
    return $time;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Puppet::DB - Object for easily getting Puppet DB data (e.g. facts, reports, etc)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

This module provides methods to make it easy to connect to the Puppet DB and to put the data into a form where it can
be manipulated more readily.

It can extract anything from the Puppet DB that is supported by the API.  See the Puppet docs for more information on
the API: L<https://puppet.com/docs/puppetdb/latest/api/index.html>.  Although this module tries to make it easier and 
more approachable by abstracting away some complexity, it still requires a basic understanding of how the API works.  
There is a bunch of Perl scripts I have created that consumes this and other Puppet Perl modules I have written. They 
provide some examples of what can be done.  They are distributed in a Puppet module as they are generally only 
useful in a Puppet environment. Consequently the best way to install them is via the module.  The module can be found 
here: L<https://github.com/Q-Technologies/puppet-utility_scripts>.

Here is an example of how to use C<Puppet::DB>:

    use Puppet::DB;

    my $puppet_db = Puppet::DB->new;

    $puppet_db->refresh_facts;
    my $facts = $puppet_db->allfacts_by_certname;

    say $facts->{testhost.example.com}{osfamily};

Would output C<Suse> if there was a SLES system called C<testhost.example.com>

The AST query system of the Puppet DB is supported: L<https://puppet.com/docs/puppetdb/latest/api/query/v4/ast.html>.
Rather than specifying it in JSON, specify it as Perl data structures. This module will convert it to JSON when it
communicates with the Puppet DB.  Some sample queries:

    use Puppet::DB;
    use Data::Dumper;

    my $mode = "facts";
    my $fact = 'osfamily';
    my $value = 'RedHat';
    my $rule = { 'query'    => [ "and", ["=","name", $fact], 
                                        ["~", "value", $value ] ], 
                 "order_by" => [{"field" => "certname"}] };
   
    my $puppet_db = Puppet::DB->new;
    $puppet_db->refresh($mode, $rule);
    print Dumper( $puppet_db->results );

    my $fact = 'os.family';
    $mode = "fact-contents";
    $rule = { 'query'    => [ "and", ["=","path", [split( /\./, $fact)] ], 
                                     ["~", "value", $value ] ], 
              "order_by" => [{"field" => "certname"}] };
    $puppet_db->refresh($mode, $rule);
    print Dumper( $puppet_db->results );

The second example demonstrates how to search via a complex fact.

This is how to access the reports:

    $rule = ['=', 'job_id', $opt_j ];
    $puppet_db->refresh( "reports", $rule );
    print Dumper( $puppet_db->results );

    $node_rule = ['=', 'certname', 'testhost.example.com' ];
    $rule = [ 'and', ['=', 'latest_report?', 'true' ],
                     $node_rule,
            ];
    $puppet_db->refresh( "reports", $rule );
    print Dumper( $puppet_db->results );

=head1 METHODS

=head2 new

Create a new C<Puppet::DB> object connecting to L<http://localhost:8080>:

    my $puppet_db = Puppet::DB->new;

or, Connect to a Puppet DB host called L<puppet>

    my $puppet_db = Puppet::DB->new( 'puppet' );

or, connect to a non standard port:

    my $puppet_db = Puppet::DB->new( server_name => 'puppet', server_port => '1234');

=head3 server_name

If you did not specify the server to connect when the object was created you can set it with this method.
The default value is C<localhost>.

    $puppet_db->server_name( 'puppet' );

This can be changed at any time for subsequent queries if you need to connect to another Puppet DB.

=head3 server_port

If you did not specify the port to connect when the object was created you can set it with this method.
The default value is C<8080>.

    $puppet_db->server_port( '1234' );

This can be changed at any time for subsequent queries if you need to connect to another Puppet DB.

=head2 Data Loading Methods

=head3 refresh

This method needs to be called to populate the C<Puppet::DB> object with data from the Puppet DB.  This needs to be 
called everytime you change the query.

    $puppet_db->refresh( 'facts' );

or

    my $query = { 'query' => ["~","certname", '.*\.example.com'], "order_by" => [{"field" => "certname"}] };
    $puppet_db->refresh( 'facts', $query );

No data will be returned.  The data can be accessed through one of the accessor methods.

=head3 refresh_facts

This method can to be called to populate the L<Puppet::DB> object with facts data from the Puppet DB.  It does the same as C<$puppet_db-E<gt>refresh( 'facts' ); $puppet_db-E<gt>facts( $puppet_db-E<gt>results );> - 
i.e. it populates the L<facts> property as well as the L<results> property.

    $puppet_db->refresh_facts; # Load all facts from the Puppet DB (will be slow for a large instance)

or

    my $query = { 'query' => ["~","certname", '.*\.example.com'], "order_by" => [{"field" => "certname"}] };
    $puppet_db->refresh_facts( $query );

No data will be returned.  The data can be accessed through one of the accessor methods.

=head2 Accessor Methods

=head3 results

Return all the results gathered from the last L</refresh> (including anything that calls L<refresh> indirectly - i.e. it can only be trusted if used immediately after calling L<refresh>).

    my $results = $puppet_db->results;

=head3 facts

Return all the facts gathered from the last L</refresh_facts>

    my $facts = $puppet_db->facts;

This returns the data in the form that the Puppet DB provides it as. The other fact accessor methods manipulate 
it for easier consumption.

=head3 allfacts_by_certname

Get all the facts for the specified C<certname>.

    $puppet_db->allfacts_by_certname( 'testhost.example.com' );

The facts will be returned as complex data (i.e hash ref).

=head3 allfacts_by_hostname

Get all the facts for the specified C<hostname>.

    $puppet_db->allfacts_by_hostname( 'testhost.example.com' );

The facts will be returned as complex data (i.e hash ref).

I<Note> that it will match the last C<hostname> found by looking at the first field in the C<certname>.  Basically, 
if you have two nodes with a different C<certname>, but the same hostname, you may not get the intended host.  If 
this is a risk, then always use the C<certname>.

=head3 get_fact

This will return a fact value matching the specified C<certname> and C<fact>.  It is a shortcut for L</get_fact_by_certname>.

    $puppet_db->get_fact( 'testhost.example.com', 'osfamily' );

The fact value may be a string or complex data (i.e hash or array ref).

=head3 get_fact_by_certname

This will return a fact value matching the specified C<certname> and C<fact>.

    $puppet_db->get_fact_by_certname( 'testhost.example.com', 'osfamily' );

The fact value may be a string or complex data (i.e hash or array ref).

=head3 get_fact_by_short_hostname

This will return a fact value matching the specified C<hostname> and C<fact>.  Note that it will match the first C<hostname> found by looking at the first field in the C<certname>.

    $puppet_db->get_fact_by_short_hostname( 'testhost', 'osfamily' );

The fact value may be a string or complex data (i.e hash or array).

=head3 is_certname_in_puppetdb

This will return true or false based on whether the specified certname can be found in the Puppet DB.

    $puppet_db->is_certname_in_puppetdb( 'testhost.example.com' );

=head3 is_node_in_puppetdb

This will return true or false based on whether the specified node can be found in the Puppet DB.  This is a synonym of L</is_certname_in_puppetdb>.

    $puppet_db->is_node_in_puppetdb( 'testhost.example.com' );

=head3 is_hostname_in_puppetdb

This will return the I<certname> if the I<hostname> of a node can be found in the Puppet DB. It will match
the first I<certname> where the first field matches the I<hostname>.

    $puppet_db->is_hostname_in_puppetdb( 'testhost' );

If a hostname is provided with dots in it, it will be assumed to be a I<certname> and simply returned back if 
it is found in the PuppetDB.

False (i.e. 0) is returned if it is not found in the PuppetDB.

=head1 FUNCTIONS

=head2 parse_puppetdb_time

Puppet DB time is always stored and reported as GM time in a text string.  This method will convert it 
into a L<time(2)> value in seconds since the system epoch (Midnight, January 1, 1970 GMT on Unix).

    my $time = parse_puppetdb_time( '2016-02-08T02:21:04.417Z' );

=head1 BUGS/FEATURES

Please report any bugs or feature requests in the issues section of GitHub: 
L<https://github.com/Q-Technologies/perl-Puppet-DB>. Ideally, submit a Pull Request.

=head1 AUTHOR

Matthew Mallard <mqtech@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Matthew Mallard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
