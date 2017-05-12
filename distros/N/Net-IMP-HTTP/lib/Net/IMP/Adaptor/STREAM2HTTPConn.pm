use strict;
use warnings;

package Net::IMP::Adaptor::STREAM2HTTPConn;
use base 'Net::IMP::Base';
use Net::IMP::HTTP; # constants
use Net::IMP;       # constants
use Net::Inspect::L7::HTTP;
use Carp;

use fields (
    'inner_factory',  # factory with IMP_DATA_HTTP interface
    'inner_analyzer', # analyzer with IMP_DATA_HTTP interface
    'http_parser',    # HTTP parser based on Net::Inspect::L7::HTTP
    'gap',            # true when last data where a gap, per dir
    'buf',            # data received but not processed by http_parser, per dir
);

sub new_factory {
    my ($class,%args) = @_;
    my $factory = fields::new($class);
    $factory->{inner_factory} = $args{factory};
    $factory->{inner_factory}->set_interface([ IMP_DATA_HTTP, undef ])
	or croak("inner interface does not support http data");
    return  $factory;
}

sub INTERFACE {
    my $factory = shift;
    my @if;
    for my $if ( $factory->get_interface ) {
	my ($dt,$rt) = @$if;
	push @if, [ IMP_DATA_STREAM, $rt ] if $dt == IMP_DATA_HTTP;
    }
    return @if;
}

sub new_analyzer {
    my ($factory,%args) = @_;
    my $analyzer = fields::new(ref($factory));
    %$analyzer = %$factory;

    $analyzer->{inner_analyzer} = $factory->{inner_factory}->new_analyzer(%args);
    $analyzer->{http_parser} = Net::IMP::Adaptor::STREAM2HTTPConn::Conn
	->new(Net::IMP::Adaptor::STREAM2HTTPConn::Request->new)
	->new_connection($args{meta} || {},$analyzer);
    $analyzer->{gap}     = [0,0];
    $analyzer->{buf}     = ['',''];

    return $analyzer;
}

sub data {
    my ($analyzer,$dir,$data,$offset,$type) = @_;
    $type == IMP_DATA_STREAM or 
	croak("invalid type in ${analyzer}::data - $type");

    if ( $offset ) {
	my $gap = $offset - $analyzer->{http_parser}->offset($dir);
	$analyzer->{http_parser}->in($dir,{ gap => $gap });
    }

    $analyzer->{buf}[$dir] .= $data;
    my $processed = $analyzer->{http_parser}->in(
	$dir,$analyzer->{buf}[$dir], $data eq '');
    substr($analyzer->{buf}[$dir],0,$processed,'') if $processed;
}

for my $sub (qw(set_callback poll_results add_results run_callback)) {
    no strict 'refs';
    *$sub = eval "sub { shift->{inner_analyzer}->$sub(\@_); }";
}

sub tell {
    my ($analyzer,$dir) = @_;
    return $analyzer->{http_parser}->offset($dir);
}



# callback from Net::IMP::Adaptor::STREAM2HTTPConn::Request
sub _data {
    my ($analyzer,$dir,$data,$type) = @_;

    if ( ref $data ) { # gap
	my $gapsize = $data->{gap} or die "invalid gapsize";
	$type < 0 or croak("gaps not supported for type $type");
	$analyzer->{gap}[$dir] = 1;
	return;
    }

    if ( $analyzer->{gap}[$dir] ) {
	$analyzer->{gap}[$dir] = 0;
	return $analyzer->{inner_analyzer}->data(
	    $dir,$data,$analyzer->tell($dir)+length($data),$type);
    } else {
	return $analyzer->{inner_analyzer}->data($dir,$data,0,$type);
    }
}


###########################################################################
# interface as request object, called from Net::Inspect::L7::HTTP
# this gets translated to the internal interface, which then calls the
# methods of the official Net::IMP::HTTP::Base API
###########################################################################

package Net::IMP::Adaptor::STREAM2HTTPConn::Conn;
use base 'Net::Inspect::L7::HTTP';
use fields qw(analyzer);

use Scalar::Util 'weaken';

sub new_connection {
    my ($self,$meta,$analyzer) = @_;
    my $obj = $self->SUPER::new_connection($meta) or return;
    weaken($obj->{analyzer} = $analyzer);
    return $obj;
}

package Net::IMP::Adaptor::STREAM2HTTPConn::Request;
use base 'Net::Inspect::Flow';
use fields qw(conn meta);

use Scalar::Util 'weaken';
use Net::IMP;
use Net::IMP::HTTP; # constants
use Carp;

sub new_request {
    my ($self,$meta,$conn) = @_;
    my $obj = $self->new;
    weaken( $obj->{conn} = $conn );
    $obj->{meta} = $meta;
    return $obj;
}

sub in_request_header {
    my ($self,$hdr) = @_;
    $self->{conn}{analyzer}->_data(0,$hdr,IMP_DATA_HTTP_HEADER);
}

sub in_request_body {
    my ($self,$data,$eof) = @_;
    $self->{conn}{analyzer}->_data(0,$data,IMP_DATA_HTTP_BODY);
    $self->{conn}{analyzer}->_data(0,'',IMP_DATA_HTTP_BODY) 
	if $eof and $data ne '';
}

sub in_response_header {
    my ($self,$hdr) = @_;
    $self->{conn}{analyzer}->_data(1,$hdr,IMP_DATA_HTTP_HEADER);
}

sub in_response_body {
    my ($self,$data,$eof) = @_;
    $self->{conn}{analyzer}->_data(1,$data,IMP_DATA_HTTP_BODY);
    $self->{conn}{analyzer}->_data(1,'',IMP_DATA_HTTP_BODY) 
	if $eof and $data ne '';
}

sub in_chunk_header {
    my ($self,$hdr) = @_;
    $self->{conn}{analyzer}->_data(1,$hdr,IMP_DATA_HTTP_CHKHDR);
}

sub in_chunk_trailer {
    my ($self,$trailer) = @_;
    $self->{conn}{analyzer}->_data(1,$trailer,IMP_DATA_HTTP_CHKTRAILER);
}

sub in_data {
    my ($self,$dir,$data,$eof) = @_;
    $self->{conn}{analyzer}->_data($dir,$data,IMP_DATA_HTTP_DATA);
    $self->{conn}{analyzer}->_data($dir,'',IMP_DATA_HTTP_DATA) 
	if $eof and $data ne '';
}

sub in_junk {
    my ($self,$dir,$data,$eof) = @_;
    return $self->{conn}{analyzer}->_data($dir,$data,IMP_DATA_HTTP_JUNK);
    return $self->{conn}{analyzer}->_data($dir,'',IMP_DATA_HTTP_JUNK) 
	if $eof and $data ne '';
}

sub fatal {
    my ($self,$reason) = @_;
    $self->{conn}{analyzer}->run_callback([ IMP_DENY,0,$reason ]);
}

1;
__END__

=head1 NAME 

Net::IMP::Adaptor::STREAM2HTTPConn - translate IMP_DATA_STREAM data type to HTTP
connection data types

=head1 SYNOPSIS

    # use automatically
    package myHTTP_IMP_Plugin;
    use base 'Net::IMP';
    sub INTERFACE { return (
	[ IMP_DATA_HTTP, \@rtypes ],
	# automatically insert adaptor if we need to use stream data
	[ IMP_DATA_STREAM, \@rtypes, 'Net::IMP::Adaptor::STREAM2HTTPConn' ],
    )}

    # or by hand
    my $stream_factory = Net::IMP::Adaptor::STREAM2HTTPConn->new_factory;
    my $http_factory = Net::IMP::HTTP::someAnalyzer->new_factory;
    # this will create inner analyzer by calling $http_factory->new_analyzer
    my $analyzer = $stream_factory->new_analyzer(
	factory => $http_factory
    );

=head1 DESCRIPTION

This module translates between IMP_DATA_STREAM data type and HTTP connection
specific data types as defined in L<Net::IMP::HTTP> by interpreting the stream
as HTTP requests with the help of L<Net::Inspect::L7::HTTP>.

It works like a normal IMP plugin understanding only IMP_DATA_STREAM types.
C<new_analyzer> gets an argument C<factory> with the factory object for the
inner analyzer.
