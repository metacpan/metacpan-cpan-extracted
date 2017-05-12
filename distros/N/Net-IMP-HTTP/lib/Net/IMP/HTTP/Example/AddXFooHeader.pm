use strict;
use warnings;

package Net::IMP::HTTP::Example::AddXFooHeader;
use base 'Net::IMP::HTTP::Connection';
use fields qw(pos1);
use Net::IMP;
use Net::IMP::HTTP;

sub RTYPES { ( IMP_PASS, IMP_PREPASS, IMP_REPLACE ) }
sub new_analyzer {
    my ($factory,%args) = @_;
    my $analyzer = $factory->SUPER::new_analyzer(%args);

    # we are not interested in request data, only response
    # but for http we need to see requests to pair with responses
    $analyzer->run_callback([IMP_PREPASS,0,IMP_MAXOFFSET]);
    return $analyzer;
}

# data supports IMP_DATA_HTTP and IMP_DATA_HTTPRQ interface
sub data {
    my ($self,$dir,$data,$offset,$type) = @_;

    # request are handled by the pass maxoffset in new_analyzer
    if ( $dir == 0 ) {
	# if we speak httprq we can make the prepass to a pass
	$self->run_callback([IMP_PASS,0,IMP_MAXOFFSET])
	    if $type == IMP_DATA_HTTPRQ_HEADER;
	return;
    }

    $self->{pos1} += length($data);
    if ( $type == IMP_DATA_HTTP_HEADER
	or $type == IMP_DATA_HTTPRQ_HEADER ) {
	$data =~s{\n}{\nX-Foo: bar\r\n};
	my @rv = [ 
	    IMP_REPLACE,
	    1,
	    $self->{pos1},
	    $data
	];
	if ( $type == IMP_DATA_HTTPRQ_HEADER ) {
	    # for httprq interface we can pass until end of request (maxoffset)
	    push @rv, [ IMP_PASS,1,IMP_MAXOFFSET ];
	}
	$self->run_callback(@rv);

    } else {
	# for http we might get more requests
	# these might be chunking etc so we probably don't know their length
	# therefore we can pass only data we get until we get the next
	# response header
	$self->run_callback([ IMP_PASS,1,$self->{pos1} ]);
    }
}


1;
__END__

=head1 NAME

Net::IMP::HTTP::Example::AddXFooHeader - adds X-Foo header to HTTP response

=head1 DESCRIPTION

This module analyses HTTP streams and adds an X-Foo header add the end of each
HTTP response header it finds in the stream.
This module is not very useful by its own.
It is only used to show, how these kind of manipulations can be done.

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>

=head1 COPYRIGHT

Copyright by Steffen Ullrich.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
