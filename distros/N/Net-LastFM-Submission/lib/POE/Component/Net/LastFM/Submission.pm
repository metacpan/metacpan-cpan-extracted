package POE::Component::Net::LastFM::Submission;
use strict;
use warnings;

use Carp 'croak';
use POE::Session;
use POE::Component::Client::HTTP;
use Net::LastFM::Submission 0.5; # support generate requests and parse response

use constant TRACE => $ENV{'SUBMISSION_TRACE'} || 0;

our $VERSION = 0.24;

sub spawn {
	my $type  = shift;
	my $param =  {@_};
	
	my $mi    = $type.'->spawn()'; # hi, Rocco Caputto!
	croak "$mi requires an even number of parameters" if @_ & 1;
	
	my $client;
	if ($param->{'Client'}) {
		$client = $param->{'Client'};
	} else {
		$client = join '_', __PACKAGE__, 'HTTP_CLIENT';
		POE::Component::Client::HTTP->spawn(
			Alias => $client,
			map { $_ => $param->{$_} } 'Agent', 'Timeout',
		);
	}
	
	POE::Session->create(
		options       => { trace => TRACE },
		inline_states => {
			_start   => sub {
				$_[KERNEL]->alias_set($param->{'Alias'} || 'LASTFM_SUBMISSION');
				$_[HEAP]->{'submit'} = Net::LastFM::Submission->new($param->{'LastFM'});
				$_[HEAP]->{'client'} = $client;
			},
			
			(map {
				my $m = $_;
				$m => sub {
					my $data    = {'session' => $_[SENDER], 'event' => $_[ARG0], 'method' => $m, 'arg' => $_[ARG2]};
					my $request = $_[HEAP]->{'submit'}->${\"_request_$m"}($_[ARG1]);
					
					return $_[KERNEL]->post($data->{'session'} => $data->{'event'}, $request => $data->{'method'})
						unless ref $request eq 'HTTP::Request';
					
					$_[KERNEL]->post(
						$_[HEAP]->{'client'} => 'request' => 'response',
						$request => $data,
					);
				};
			} 'handshake', 'now_playing', 'submit'),
			
			response => sub {
				my $data     = $_[ARG0]->[1];
				my $response = $_[HEAP]->{'submit'}->_response($_[ARG1]->[0]);
				
				$_[HEAP]->{'submit'}->_save_handshake($response) if $data->{'method'} eq 'handshake';
				
				$_[KERNEL]->post(
					$data->{'session'} => $data->{'event'},
					$response => $data->{'arg'} => $data->{'method'}
				);
			},
		}
	);

}

1;

__END__
=head1 NAME

POE::Component::Net::LastFM::Submission - non-blocking wrapper around Net::LastFM::Submission

=head1 SYNOPSIS

    use strict;
    use POE qw(Component::Net::LastFM::Submission);
    use Data::Dumper;
    
    POE::Component::Net::LastFM::Submission->spawn(
        Alias  => 'LASTFM_SUBMIT',
        LastFM => {
            user     => 'net_lastfm',
            password => '12',
       },
    );
    
    POE::Session->create(
        options       => { trace => 1 },
        inline_states => {
            _start => sub {
                $_[KERNEL]->post('LASTFM_SUBMIT' => 'handshake' => 'np');
                $_[KERNEL]->yield('_delay');
            },
            _delay => sub { $_[KERNEL]->delay($_[STATE] => 5) },
            
            np => sub {
                warn Dumper @_[ARG0..$#_];
                $_[KERNEL]->post(
                    'LASTFM_SUBMIT' => 'now_playing' => 'np',
                    {'artist' => 'ArtistName', 'title'  => 'TrackTitle'},
                    'job_id'
                );
            },
        }
    );
    
    POE::Kernel->run;


=head1 DESCRIPTION

The module is a non-blocking wrapper around Net::LastFM::Submission module, it is truelly asynchronously.
Net::LastFM::Submission contains methods for generate requests and parse response (version >= 0.5).
See documentation L<Net::LastFM::Submission>.

POE::Component::Net::LastFM::Submission start own POE::Component::Client::HTTP when the user didn't supply the parameter I<Client>.
It lets other sessions run while HTTP transactions are being processed, and it lets several HTTP transactions be processed in parallel.

=head1 METHODS

=head2 spawn


    POE::Component::Net::LastFM::Submission->spawn(
        Alias  => 'LASTFM_SUBMIT',
        LastFM => {
            user     => 'net_lastfm',
            password => '12',
        },
    );
    
    # or
    
    POE::Component::Client::HTTP->spawn(
       Alias => 'HTTP_CLIENT',
       ...
    );

    POE::Component::Net::LastFM::Submission->spawn(
       Alias  => 'LASTFM_SUBMIT',
       Client => 'HTTP_CLIENT', # alias or session id of PoCo::Client::HTTP
       LastFM => {
           user     => 'net_lastfm',
           password => '12',
       },
    );

PoCo::Net::LastFM::Submission's spawn method takes a few named parameters:

=over 5

=item * I<Alias>

Alias sets the name by which the session will be known. If no alias is given, the component defaults is LASTFM_SUBMISSION.
The alias lets several sessions interact with HTTP components without keeping (or even knowing) hard references to them.
It's possible to spawn several Submission components with different names.

This is a constructor for Net::LastFM::Submission object. It takes list of parameters or hashref parameter.

=item * I<LastFM>

The data for Net::LastFM::Submission constructor. It's hashref of data. Required.
See L<Net::LastFM::Submission>.

=item * I<Client>

The alias or session id of an existing PoCo::Client::HTTP. Optional. See L<POE::Component::Client::HTTP>.

=item * I<Agent>

The user agent of the client. Optional.
It is a agent of own PoCo::Client::HTTP. See L<POE::Component::Client::HTTP>.

=item * I<Timeout>

The timeout of the client. Optional.
It is a timeout of own PoCo::Client::HTTP. See L<POE::Component::Client::HTTP>.

=back

=head1 ACCEPTED EVENTS

Sessions communicate asynchronously with PoCo::Net::LastFM::Submission. They post requests to it, and it posts responses back.

Events have syntax like PoCo::Client::HTTP.

First param is a alias of submission session.

Second param is accepted event such as I<handshake>, I<now_playing> and I<submit>.

Third param is a event for return after execute request.

Forth param is hashref param for the accepted event (for real method of Net::LastFM::Submission).

Fiveth param is a tag to identify the request.


=head2 handshake

    $_[KERNEL]->post('LASTFM_SUBMIT' => 'handshake' => 'np');


=head2 now_playing

     $_[KERNEL]->post(
        'LASTFM_SUBMIT' => 'now_playing' => 'np',
        {'artist' => 'ArtistName', 'title'  => 'TrackTitle'}, # params of now_playing
        'job_id'
    );

See params of I<now_playing> in L<Net::LastFM::Submission>.


=head2 submit

    $_[KERNEL]->post(
        'LASTFM_SUBMIT' => 'submit' => 'sb',
        {'artist' => 'ArtistName', 'title'  => 'TrackTitle', 'time'   => time - 10*60}, # params of submit
        'job_id'
    );

See params of I<submit> in L<Net::LastFM::Submission>.


=head1 TRACE MODE

The module supports trace mode - trace POE session.

    BEGIN { $ENV{SUBMISSION_TRACE}++ };
    use POE::Component::Net::LastFM::Submission;

=head1 EXAMPLES

See I<examples/poe*.pl> in this distributive.


=head1 SEE ALSO

L<POE> L<Net::LastFM::Submission>

=head1 DEPENDENCIES

L<Net::LastFM::Submission> L<POE::Component::Client::HTTP> L<POE::Session> L<Carp>

=head1 AUTHOR

Anatoly Sharifulin, C<< <sharifulin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-lastfm-submission at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-LastFM-Submission>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT & DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc Net::LastFM::Submission
    perldoc POE::Component::Net::LastFM::Submission

You can also look for information at:

=over 6

=item * Github

L<http://github.com/sharifulin/net-lastfm-submission/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-LastFM-Submission>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-LastFM-Submission>

=item * CPANTS: CPAN Testing Service

L<http://cpants.perl.org/dist/overview/Net-LastFM-Submission>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-LastFM-Submission>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-LastFM-Submission>

=back

=head1 COPYRIGHT & LICENSE

Copyright (C) 2009 Anatoly Sharifulin

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

