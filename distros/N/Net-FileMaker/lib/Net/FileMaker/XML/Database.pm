package Net::FileMaker::XML::Database;
{
  $Net::FileMaker::XML::Database::VERSION = '0.064';
}

use strict;
use warnings;
use Net::FileMaker::XML::ResultSet;
use Carp;

use base qw(Net::FileMaker::XML);

# Particular methods have specific parameters that are optional, but need to be
# validated to mitigate sending bad parameters to the server.
my $acceptable_params = {
    'find'    => '-recid|-lop|-op|-max|-skip|-sortorder|-sortfield|-script|-script\.prefind|-script\.presort',    
    'findall' => '-recid|-lop|-op|-max|-skip|-sortorder|-sortfield|-script|-script\.prefind|-script\.presort',
    'findany' => '-recid|-lop|-op|-max|-skip|-sortorder|-sortfield|-script|-script\.prefind|-script\.presort',
    'delete'  => '-db|-lay|-recid|-script',
    'dup'     => '-db|-lay|-recid|-script',
    'edit'    => '-db|-lay|-recid|-modid|-script',
    'new'     => '-db|-lay|-script'
};

=head1 NAME

Net::FileMaker::XML::Database

=head1 SYNOPSIS

This module handles all the tasks with XML data. Don't call this module
directly, instead use L<Net::FileMaker::XML>.

    use Net::FileMaker::XML;
    my $fm = Net::FileMaker::XML->new(host => $host);
    my $db = $fm->database(db => $db, user => $user, pass => $pass);
    
    my $layouts = $db->layoutnames;
    my $scripts = $db->scriptnames;
    my $records = $db->findall( layout => $layout, params => { '-max' => '10'});
    my $records = $db->findany( layout => $layout, params => { '-skip' => '10'});

=head1 METHODS

=cut

sub new
{
    my($class, %args) = @_;

    my $self = {
        host      => $args{host},
        db        => $args{db},
        user      => $args{user},
        pass      => $args{pass},
        resultset => '/fmi/xml/fmresultset.xml',
                ua        => LWP::UserAgent->new,
                xml       => XML::Twig->new,
        uri => URI->new($args{host}),
    };

    bless $self , $class;
    return $self;
}

=head2 layoutnames

Returns an arrayref containing layouts accessible for the respective database.

=cut

sub layoutnames
{
    my $self = shift;
        my $xml = $self->_request(
                user      => $self->{user},
                pass      => $self->{pass},
                resultset => $self->{resultset},
                query     => '-layoutnames',
                params    => { '-db' => $self->{db} }
        );   


    return $self->_compose_arrayref('LAYOUT_NAME', $xml);
}

=head2 scriptnames

Returns an arrayref containing scripts accessible for the respective database.

=cut

sub scriptnames
{
    my $self = shift;
        my $xml = $self->_request(
                user      => $self->{user},
                pass      => $self->{pass},
                resultset => $self->{resultset},
                query     => '-scriptnames',
                params    => { '-db' => $self->{db} }
        );   


    return $self->_compose_arrayref('SCRIPT_NAME', $xml);
}

=head2 find(layout => $layout, params => { parameters })

Returns a L<Net::FileMaker::XML::ResultSet> for a specific database and layout.

=cut

sub find
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };

    $params = $self->_assert_params(
        type              => 'find',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params,
    );
    
    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-find',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}


=head2 findall(layout => $layout, params => { parameters }, nocheck => 1)

Returns a L<Net::FileMaker::XML::ResultSet> of all rows on a specific database
and layout. C<nocheck> is an optional argument that will skip checking of
parameters if set to 1.

=cut

sub findall
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };

    $params = $self->_assert_params(
        type              => 'findall',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params
    );

    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-findall',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}

=head2 findany(layout => $layout, params => { parameters }, nocheck => 1)

Returns a L<Net::FileMaker::XML::ResultSet> of random rows on a specific
database and layout. C<nocheck> is an optional argument that will skip checking
of parameters if set to 1.

=cut

sub findany
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };

    $params = $self->_assert_params(
        type              => 'findany',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params, 
    );

    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-findany',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}



=head2 edit(layout => $layout , recid => $recid , params => { params })

Updates the row with the fieldname/value pairs passed to params.
Returns a L<Net::FileMaker::XML::ResultSet> object.

=cut

#TODO: add tests to /t/01_xml

sub edit
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };
    
    # just to make the recid param more visible than putting it into the params
    croak 'recid must be defined' if(! defined $args{recid});
    $params->{'-recid'}  = $args{recid};
    
    $params = $self->_assert_params(
        type              => 'edit',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params
    );
    
    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-edit',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}

=head2 remove(layout => $layout , recid => $recid , params => { params })

Deletes the record with that specific record id and returns a
L<Net::FileMaker::XML::ResultSet> object.

=cut

sub remove
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };
    
    # just to make the recid param more visible than putting it into the params
    croak 'recid must be defined' if(! defined $args{recid});
    $params->{'-recid'}  = $args{recid};
    
    $params = $self->_assert_params(
        type              => 'delete',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params
    );
    
    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-delete',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}



=head2 insert(layout => $layout , recid => $recid , params => { params })

Creates a new record and populates that record with the fieldname/value pairs passed to params.

Returns an L<Net::FileMaker::XML::ResultSet> object.

=cut

sub insert
{
    my ($self, %args) = @_;

    my $params = { 
        '-lay' => $args{layout},
        '-db'  => $self->{db}
    };
    
    $params = $self->_assert_params(
        type              => 'new',
        def_params        => $params,
        params            => $args{params},
        acceptable_params => $acceptable_params
    );
    
    my $xml = $self->_request(
            resultset => $self->{resultset}, 
            user      => $self->{user}, 
            pass      => $self->{pass}, 
            query     => '-new',
            params    => $params
    );

    return Net::FileMaker::XML::ResultSet->new(rs => $xml , db => $self);
}



=head2 total_rows(layout => $layout)

Returns a scalar with the total rows for a given layout.

=cut

sub total_rows
{
    my($self, %args) = @_;

    # Just do a findall with 1 record and parse the result. This might break on an empty database.
    my $xml = $self->_request(
        user      => $self->{user},
        pass      => $self->{pass},
        resultset => $self->{resultset},
        params    => {
            '-db'  => $self->{db}, 
            '-lay' => $args{layout}, 
            '-max' => '1' 
        },
        query     => '-findall'
    );

    return $xml;
}


1; # End of Net::FileMaker::XML::Database;

