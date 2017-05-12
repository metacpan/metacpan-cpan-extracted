package Puzzle::Request;

our $VERSION = '0.01';

use base 'HTML::Mason::Request';

use Params::Validate;

my $ap_req_class = HTML::Mason::Request::Apachehandler::APACHE2 
	? 'Apache2::RequestRec' : 'Apache';


__PACKAGE__->valid_params
        ( ah         => { isa => 'HTML::Mason::ApacheHandler',
                          descr => 'An ApacheHandler to handle web requests',
                          public => 0 },
          apache_req => { isa => $ap_req_class, default => undef,
                          descr => "An Apache request object",
                          public => 0 },
		);



sub new {
	my $class = shift;
	$class->alter_superclass( $HTML::Mason::ApacheHandler::VERSION ?
								'HTML::Mason::Request::ApacheHandler' :
								$HTML::Mason::CGIHandler::VERSION ?
								'HTML::Mason::Request::CGI' :
								'HTML::Mason::Request' );

	my $self = $class->SUPER::new(@_);
	return $self;
}

1;
