use strict;
use warnings;

package Net::IMP::HTTP::Example::BlockContentType;
use base 'Net::IMP::HTTP::Request';
use Net::IMP;  # import IMP_ constants
use Net::IMP::Debug;

sub RTYPES { ( IMP_PASS, IMP_DENY ) }
sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    # request data do not matter
    $self->run_callback([ IMP_PASS,0,IMP_MAXOFFSET ]);
    if ( ! $self->{factory_args}{whiterx} 
	&& ! $self->{factory_args}{blackrx} ) {
	# nothing to analyze
	$self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]);
    }
    return $self;
}

sub validate_cfg {
    my ($class,%cfg) = @_;
    my @err;
    for my $k (qw(whiterx blackrx)) {
	my $rx = delete $cfg{$k} or next;
	ref($rx) and next;
	push @err,"$k is no valid regexp: $@" if ! eval { qr/$rx/ };
    }
    return (@err,$class->SUPER::validate_cfg(%cfg));
}

sub str2cfg {
    my ($class,$str) = @_;
    my %cfg = $class->SUPER::str2cfg($str);
    for my $k (qw(whiterx blackrx)) {
	next if ! $cfg{$k} or ref $cfg{$k};
        $cfg{$k} = eval { qr/$cfg{$k}/ } 
	    or die "invalid rx in $k: $@";
    }
    return %cfg;
}

sub request_hdr {}
sub request_body {}
sub response_body {}
sub any_data {}

sub response_hdr {
    my ($self,$hdr) = @_;
    # we only want selected image/ content types and not too big
    my $ct = $hdr =~m{\nContent-type:[ \t]*([^\s;]+)}i && lc($1) 
	|| 'unknown/unknown';

    my $reason;
    if ( my $white = $self->{factory_args}{whiterx} ) {
	if ( $ct =~ $white ) {
	    debug("allowed $ct because of white list");
	    goto pass;
	} else {
	    debug("denied $ct because not in white list");
	    $reason = "denied $ct because not in white list";
	    goto deny;
	}
    }
    if ( my $black = $self->{factory_args}{blackrx} ) {
	if ( $ct =~ $black ) {
	    debug("denied $ct because in black list");
	    $reason = "denied $ct because in black list";
	    goto deny;
	} else {
	    debug("allow $ct because not in black list");
	    goto pass;
	}
    }

    pass:
    $self->run_callback([ IMP_PASS,1,IMP_MAXOFFSET ]);
    return;

    deny:
    $self->run_callback([ IMP_DENY,1,$reason ]);
    return;
}


1;
__END__

=head1 NAME

Net::IMP::HTTP::Example::BlockContentType - sample IMP plugin to block response
based on given content type 

=head1 SYNOPSIS

    # use proxy from App::HTTP_Proxy_IMP to flip images
    http_proxy_imp --filter Example::BlockContentType listen_ip:port

=head1 DESCRIPTION

This is a sample plugin to block HTTP responses based on the given content-type.
Please note, that the content-type given by the server is not a reliable way to
determine the real content and that browsers ignore the given content-type in
lots of cases, like script includes.

The following arguments can be given:

=over 4

=item whiterx Regexp 

A regexp used for white-listing content-types.
If a content-type is white-listed it is allowed, even if it matches the
blacklist too.
If no blacklist is given only white-listed content-types will be allowed.

=item blackrx Regexp

A regexp used for black-listing content-types.
It does not override matches of whitelist.
If no whitelist is given everything not matching the blacklist will be allowed.

=back

=head1 AUTHOR

Steffen Ullrich <sullr@cpan.org>
