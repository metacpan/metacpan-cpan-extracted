package Report_HTML_DB::Clients::BlastClient;
use Moose;
use HTTP::Request;
use LWP::UserAgent;
use Report_HTML_DB::Models::Services::BaseResponse;
use Report_HTML_DB::Models::Services::PagedResponse;

=pod

This class have the objective to represent the layer of access between any application and services

=cut

has rest_endpoint => ( is => 'ro', isa => 'Str' );

sub search {
	my ( $self, $parameters ) = @_;

	my $response = makeRequest( $self->{rest_endpoint},
		"/Blast/search", $parameters, "POST" );
	return Report_HTML_DB::Models::Services::BaseResponse->thaw($response);
}

sub fancy {
	my ( $self, $blast ) = @_;
	my $response = makeRequest(
		$self->{rest_endpoint}, "/Blast/fancy",
		\%{ { blast => $blast } }, "POST"
	);
	return Report_HTML_DB::Models::Services::BaseResponse->thaw($response);
}

sub makeRequest {
	my ( $rest_endpoint, $action, $parameters, $method ) = @_;
	my $user_agent = LWP::UserAgent->new;
	my $url        = "";
	if ( $method eq "GET" ) {
		$url =
		  $rest_endpoint . $action . "?" . stringifyParameters($parameters);
		my $request = HTTP::Request->new( GET => $url );
		$request->header( 'Content-Type' => 'application/json' );
		my $response = $user_agent->request($request);
		return $response->content;
	}
	elsif ( $method eq "POST" ) {
		$url = $rest_endpoint . $action;
		my $request = HTTP::Request->new( "POST", $url );

		#		use Data::Dumper;
		#		$request->content(Dumper($parameters));
		use JSON;
		$request->content( encode_json($parameters) );
		$request->header(
			'Content-Type' => 'application/json',
			'Accept'       => 'application/json'
		);
		my $response = $user_agent->request($request);
		return $response->content;
	}

}

sub stringifyParameters {
	my ($parameters) = @_;
	my $result = "";
	foreach my $key ( keys %{$parameters} ) {
		$result .= "$key=" . $parameters->{$key} . "&";
	}
	chop($result);
	return $result;
}


=head1 NAME

Report_HTML_DB::BlastClient - Executes BLAST requests for service application

=head1 DESCRIPTION

This is a stub module, see F<script/report_hml_db.pl> for details of the app.

=head1 AUTHOR

Wendel Hime Lino Castro

=head1 LICENSE

GNU General Public License v3.0

=cut

1;
