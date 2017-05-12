package Net::FileMaker::XML;
{
  $Net::FileMaker::XML::VERSION = '0.064';
}

use strict;
use warnings;
use Carp;
use Net::FileMaker::Error;

use XML::Twig;

=head1 NAME

Net::FileMaker::XML - Interact with FileMaker Server's XML Interface.

=head1 SYNOPSIS

This module provides the interface for communicating with FileMaker Server's XML service.

You can simply invoke L<Net::FileMaker> directly and specify the 'type' 
key in the constructor as "xml":

    use Net::FileMaker;
    
    my $fms = Net::FileMaker->new(host => $host, type => 'xml');

It's also possible to call this module directly:

    use Net::FileMaker::XML;

    my $fms = Net::FileMaker::XML->new(host => $host);

    my $dbnames = $fms->dbnames;
    my $fmdb = $fms->database(db => $db, user => $user, pass => $pass);


=head1 METHODS

=head2 new(host => $host)

Creates a new object. The specified must be a valid address or host name.

=cut

sub new
{
    my($class, %args) = @_;

    # If the protocol isn't specified, let's assume it's just HTTP.
    if($args{host} !~/^http/x)
    {
        $args{host} = 'http://'.$args{host};
    }
    require LWP::UserAgent;
    my $self = {
        host  => $args{host},
        ua    => LWP::UserAgent->new,
        xml   => XML::Twig->new,
        uri   => URI->new($args{host}),
        resultset => '/fmi/xml/fmresultset.xml', # Entirely for dbnames();
    };

    if($args{error})
    {
        $self->{error} = Net::FileMaker::Error->new(lang => $args{error}, type => 'XML');
    }

    bless $self , $class;
    return $self;

}

=head2 database(db => $database, user => $user, pass => $pass)

Initiates a new database object for querying data in the databse.

=cut

sub database
{
    my($self, %args) = @_;

    require Net::FileMaker::XML::Database;
    return  Net::FileMaker::XML::Database->new(
            host  => $self->{host},
            db    => $args{db},
            user  => $args{user} || '',
            pass  => $args{pass} || ''
        );
}


=head2 dbnames

Returns an arrayref containing all XML/XSLT enabled databases for a given host.
This method requires no authentication.

=cut

sub dbnames
{
    my $self = shift;
    my $xml  = $self->_request(
            resultset => $self->{resultset}, 
            query     =>'-dbnames'
    );

    return $self->_compose_arrayref('DATABASE_NAME', $xml);

}

=head1 COMPATIBILITY

This distrobution is actively tested against FileMaker Advanced Server 10.0.1.59
and 11.0.1.95.  Older versions are not tested at present, but feedback is
welcome. See the messages present in the test suite on how to setup tests
against your server.

=head1 SEE ALSO

L<Net::FileMaker::XML::Database>

=cut

# _request(query => $query, params => $params, resultset => $resultset, user => $user, pass => $pass)
#
# Performs a request to the FileMaker Server. The query and resultset keys are mandatory, 
# however user and pass keys are not. The query should always be URI encoded.
sub _request
{
        my ($self, %args) = @_;

        # Construct the URI
        my $uri = $self->{uri}->clone;
        $uri->path($args{resultset});
        
        my $url;
    # This kind of defeats the purpose of using URI to begin with, but this
    # fault has been reported on rt.cpan.org for over 2 years and many releases
    # with no fix.
        if($args{params})
    {
                $uri->query_form(%{$args{params}});
                $url = $uri->as_string."&".$args{query};
        }
        else
        {
           $url = $uri->as_string."?".$args{query};
        }

        my $req = HTTP::Request->new(GET => $url);

        if($args{user} && $args{pass})
        {       
                $req->authorization_basic( $args{user}, $args{pass});
        }       

        my $res = $self->{ua}->request($req);

    my $xml = $self->{xml}->parse($res->content);
    my $xml_data = $xml->simplify;

    # Inject localised error message
    if($self->{error})
    {
        $xml_data->{error}->{message} = $self->{error}->get_string($xml_data->{error}->{code});
    }

    $xml_data->{http_response} = $res;
    return $xml_data;

}


# _compose_arrayref($field_name, $xml)
# 
# A common occurance is recomposing response data so unnecessary structure is removed.
sub _compose_arrayref
{
    my ($self, $fieldname, $xml) = @_;
    
    if(ref($xml->{resultset}->{record}) eq 'HASH')
    {
        return $xml->{resultset}->{record}->{field}->{$fieldname}->{data};
    }
    elsif(ref($xml->{resultset}->{record}) eq 'ARRAY')
    {
        my @output;

        for my $record (@{$xml->{resultset}->{record}})
        {
            push @output, $record->{field}->{$fieldname}->{data};
        }
        
        return \@output;
    }

}


# _assert_param()
#
# Optional parameters sometimes validation to ensure they are correct.
# Warnings are issued if a parameter name is somehow invalid.
# single param check

sub _assert_param
{
    my($self, $unclean_param, $acceptable_params) = @_;
    my $param;
    # if the param is of private type '-something' let's check, otherwise skip
    # 'cause it could be the name of a field 
    # TODO: we might add a strict control to avoid passing others params than
    # the ones with "-" like in findall etc
    
    if($unclean_param =~ /^-.+$/x)
    {
        if($unclean_param =~/$acceptable_params/x)
        {
            $param = $unclean_param;
        }
        else
        {
            # TODO: Localise this error message
            carp "Invalid parameter specified - $unclean_param";
        }
    }else{
        $param = $unclean_param;
    }

    return $param;
}


# _assert_params
# Optional parameters sometimes validation to ensure they are correct.
# Warnings are issued if a parameter name is somehow invalid.

sub _assert_params
{
    my ($self , %args) = @_;
    
    my $params = $args{def_params};
    my $acceptable_params = $args{acceptable_params};
    my $type = $args{type};
    
    if($args{params} && ref($args{params}) eq 'HASH')
    {
        for my $param(keys %{$args{params}})
        {
            # Perform or skip parameter checking
            if($args{nocheck} && $args{nocheck} == 1)
            {
                $params->{$param} = $args{params}->{$param};
            }
            else
            {
                $params->{$param} = $args{params}->{$param} 
                    if $self->_assert_param($param, $acceptable_params->{$type});
            }
        }
    }
    return $params;
}

1; # End of Net::FileMaker::XML;
