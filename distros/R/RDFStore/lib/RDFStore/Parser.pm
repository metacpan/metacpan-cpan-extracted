# *
# *     Copyright (c) 2000-2006 Alberto Reggiori <areggiori@webweaving.org>
# *                        Dirk-Willem van Gulik <dirkx@webweaving.org>
# *
# * NOTICE
# *
# * This product is distributed under a BSD/ASF like license as described in the 'LICENSE'
# * file you should have received together with this source code. If you did not get a
# * a copy of such a license agreement you can pick up one at:
# *
# *     http://rdfstore.sourceforge.net/LICENSE
# *
# * Changes:
# *     version 0.1 - Tue Dec 16 00:51:44 CET 2003
# *     version 0.2
# *		- updated wget() adding Accept: HTTP header and use LWP::UserAgent if available
# *

package RDFStore::Parser;
{
use vars qw ( $VERSION %Built_In_Styles );
use strict;
 
$VERSION = '0.2';

use Carp;

eval { require LWP::UserAgent; };
$RDFStore::Parser::hasLWPUserAgent = ($@) ? 0 : 1;

sub new {
	my ($pkg, %args) = @_;

        my $style = $args{Style};

	my $nonexopt = $args{Non_Expat_Options} ||= {};

        $nonexopt->{Style}             = 1;
        $nonexopt->{Non_Expat_Options} = 1;
        $nonexopt->{Handlers}          = 1;
        $nonexopt->{_HNDL_TYPES}       = 1;

        $args{_HNDL_TYPES} = {};
        $args{_HNDL_TYPES}->{Init} = 1;
        $args{_HNDL_TYPES}->{Assert} = 1;
        $args{_HNDL_TYPES}->{Start_XML_Literal} = 1;
        $args{_HNDL_TYPES}->{Stop_XML_Literal} = 1;
        $args{_HNDL_TYPES}->{Char_Literal} = 1;
	$args{_HNDL_TYPES}->{manage_bNodes} = 1; #used only on RDF/XML SiRPAC parser
        $args{_HNDL_TYPES}->{Final} = 1;

	$args{'warnings'} = [];

        $args{'Handlers'} ||= {};
        my $handlers = $args{'Handlers'};
        if (defined($style)) {
                my $stylepkg = $style;
                if ($stylepkg !~ /::/) {
                        $stylepkg = "\u$style";
                        croak "Undefined style: $style" 
                                unless defined($Built_In_Styles{$stylepkg});
                        $stylepkg = 'RDFStore::Parser::NTriples::' . $stylepkg;
                	};

                # load the requested style
                eval "use $stylepkg;";
                if($@) {
                        warn "Cannot load parser style '$stylepkg'" if($pkg->{Warnings});
                        exit(1);
                        };

                my $htype;
                foreach $htype (keys %{$args{_HNDL_TYPES}}) {
                        # Handlers explicity given override
                        # handlers from the Style package
                        unless (defined($handlers->{$htype})) {
                                # A handler in the style package must either have
                                # exactly the right case as the type name or a
                                # completely lower case version of it.
                                my $hname = "${stylepkg}::$htype";
                                if (defined(&$hname)) {
                                        $handlers->{$htype} = \&$hname;
                                        next;
                                	};
                                $hname = "${stylepkg}::\L$htype";
                                if (defined(&$hname)) {
                                        $handlers->{$htype} = \&$hname;
                                        next;
                                	};
                        	};
                	};
        	};
        $args{Pkg} ||= caller;

	$args{'options'} = {};

	$args{'_Source'} = 'STDIN:';

        bless \%args, $pkg;
	};

sub setProperty {
	my ($class, $name, $value) = @_;
	
	$class->{'options'}->{ $name } = $value;
	};

sub getProperty {
	my ($class, $name) = @_;
	
	return $class->{'options'}->{ $name };
	};

sub setHandlers {
        my ($class, @handler_pairs) = @_;

        croak("Uneven number of arguments to setHandlers method") 
                if (int(@handler_pairs) & 1);

        my @ret;
        while (@handler_pairs) {
                my $type = shift @handler_pairs;
                my $handler = shift @handler_pairs;
                unless (defined($class->{_HNDL_TYPES}->{$type})) {
                        my @types = sort keys %{$class->{_HNDL_TYPES}};
                        croak("Unknown Parser handler type: $type\n Valid types are : @types");
                	};
                push(@ret, $type, $class->{Handlers}->{$type});
                $class->{Handlers}->{$type} = $handler;
        	};

        return @ret;
	};

sub setSource {
        my ($class,$file_or_uri)=@_;

	$class->{'_Source'} = $file_or_uri
		if(defined $file_or_uri);

        return $file_or_uri;
	};

sub getSource {
	return $_[0]->{'_Source'};
	};

sub parse { };

sub parsestring { };

sub parsestream { };

sub parsefile {
	my ($class) = shift;

	$class->setSource( $_[0] );
	};

sub read {
	my ($class) = shift;

	$class->parse( @_ );
	};

sub readstring {
	my ($class) = shift;

	$class->parsestring( @_ );
	};

sub readstream {
	my ($class) = shift;

	$class->parsestream( @_ );
	};

sub readfile {
	my ($class) = shift;

	$class->parsefile( @_ );
	};

sub wget {
        my ($class,$uri) = @_;

        croak "RDFStore::Parser::wget: input url is not an instance of URI"
                unless( (defined $uri) && ($uri->isa("URI")) );

        no strict;

	if($RDFStore::Parser::hasLWPUserAgent) {
		# HTTP GET it
		my $ua = LWP::UserAgent->new( timeout => 60 );

		my %headers = ( "User-Agent" => "rdfstore\@asemantics.com/$VERSION" );
		$headers{'Accept'} = 'application/rdf+xml,application/xml;q=0.9,*/*;q=0.5'
			if($class->isa("RDFStore::Parser::SiRPAC"));

                my $response = $ua->get( $uri->as_string, %headers );

                unless($response) {
			my $msg = "RDFStore::Parser::wget: Cannot HTTP GET $uri->as_string\n";
			push @{ $class->{warnings} },$msg;
			return;
			};

                return $response->content;
	} else {
        	require IO::Socket;

        	local($^W) = 0;
        	my $sock = IO::Socket::INET->new(       PeerAddr => $uri->host,
                                                	PeerPort => $uri->port,
                                                	Proto    => 'tcp',
                                                	Timeout  => 60) || return undef;
        	$sock->autoflush;
        	my $netloc = $uri->host;
        	$netloc .= ":".$uri->port if $uri->port != 80;

        	my $path = $uri->as_string;

        	#HTTP/1.0 GET request
        	print $sock join("\015\012" =>
                    "GET $path HTTP/1.0",
                    "Host: $netloc",
                    "User-Agent: rdfstore\@asemantics.com/$VERSION",
		    ($class->isa("RDFStore::Parser::SiRPAC")) ? "Accept: application/rdf+xml,application/xml;q=0.9,*/*;q=0.5" : "",
                    "", "");

        	my $line = <$sock>;

		if ($line !~ m,^HTTP/\d+\.\d+\s+(\d\d\d)\s+(.+)$,m) {
                	my $msg = "RDFStore::Parser::wget: (10 Did not get HTTP/x.x header back...$line";
                	push @{ $class->{warnings} },$msg;
                	warn $msg;
                	return;
                	};
        	my $status = $1;
        	my $reason = $2;
        	if ( ($status != 200) && ($status != 302) ) {
                	my $msg = "Error MSG returned from server: $status $reason\n";
                	push @{ $class->{warnings} },$msg;

                	#try HTTP/1.1 GET request
                	print $sock join("\015\012" =>
                                 "GET $path HTTP/1.1",
                                 "Host: $netloc",
                                 "User-Agent: rdfstore\@asemantics.com/$VERSION",
		    		($class->isa("RDFStore::Parser::SiRPAC")) ? "Accept: application/rdf+xml,application/xml;q=0.9,*/*;q=0.5" : "",
                                 "Connection: close",
                                 "", "");

                	$line = <$sock>;

                	if ($line !~ m,^HTTP/\d+\.\d+\s+(\d\d\d)\s+(.+)$,m) {
                        	my $msg = "RDFStore::Parser::wget: Did not get HTTP/x.x header back...$line";
                        	push @{ $class->{warnings} },$msg;
                        	warn $msg;
                        	return;
                        	};
                	$status = $3;
                	$reason = $4;

			if ( ($status != 200) && ($status != 302) ) {
                        	my $msg = "RDFStore::Parser::wget: Error MSG returned from server: $status $reason\n";
                        	push @{ $class->{warnings} },$msg;
                        	return;
                        	};
                	};

        	while(<$sock>) {
                	chomp;
                	if( m,^Location:\s(.*)$,) {
                        	if( (   (exists $class->{HTTP_Location}) &&
                                	(defined $class->{HTTP_Location}) && ($class->{HTTP_Location} ne $1)    ) || 
                                        (!(defined $class->{HTTP_Location})) ) {
                                	$class->{HTTP_Location} = $1;
                                	my $s = $class->wget(new URI($class->{HTTP_Location}));
                                	$sock = $s
                                        	if(defined $s);
                                	last;
                                	};
                        	};
                	last if m/^\s+$/;
                	};

		my $content='';
		while(<$sock>) {
			$content.=$_;
			};

        	return $content;
		};
        };

1;
};

__END__

=head1 NAME

RDFStore::Parser - Interface to an RDF parser

=head1 SYNOPSIS

	use RDFStore::Parser;

	my $parser = new RDFStore::Parser(
			ErrorContext => 3, 
                        Style => 'RDFStore::Parser::Styles::RDFStore::Model'
			);

	# or...
	use RDFStore::Model;

	my $model= new RDFStore::Model();
	$parser = $model->getReader;

	my $rdfstring = qq|

<rdf:RDF
        xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
        xmlns:a='http://description.org/schema/'>
<rdf:Description rdf:about='http://www.w3.org'>
        <a:Date>1998-10-03T02:27</a:Date>
</rdf:Description>

</rdf:RDF>|;

	$model = $parser->parsestring($rdfstring);
	$model = $parser->parsefile('http://www.w3.org/1999/02/22-rdf-syntax-ns#');
	$model = $parser->parsestream(*RDFSTREAM);

=head1 DESCRIPTION

An RDFStore::Model parser.

=head1 SEE ALSO

RDFStore::Model(3) RDFStore::Parser::SiRPAC(3) RDFStore::Parser::NTriples(3)

=head1 AUTHOR

	Alberto Reggiori <areggiori@webweaving.org>
