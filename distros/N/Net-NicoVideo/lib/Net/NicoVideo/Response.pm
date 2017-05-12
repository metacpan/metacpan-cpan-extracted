package Net::NicoVideo::Response;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

# NOTE: Never inherit with classes that have "get()" or "set()",
# because these interfere with _component which is decorated with Net::NicoVideo::Decorator
use base qw(Net::NicoVideo::Decorator);

sub is_authflagged {
    my $self = shift;
    $self->headers->header('x-niconico-authflag');
}

# a client has to check is_success and is_content_success
# before calling this
sub parsed_content { # abstract
    my $self = shift;
    Net::NicoVideo::Content->new($self->_component)->parse;
}

# DEPRECATED - use Net::NicoVideo::Content#is_success instead
sub is_content_success { # abstract
    my $self = shift;
    $self->parsed_content->is_success;
}

# DEPRECATED - use Net::NicoVideo::Content#is_error instead
sub is_content_error { # abstract
    my $self = shift;
    $self->parsed_content->is_error;
}


1;
__END__


=pod

=head1 NAME

Net::NicoVideo::Response - Abstract class decorates with HTTP::Response

=head1 SYNOPSIS

    my $response = Net::NicoVideo::Response->new( $ua->request(...) );
    
=head1 DESCRIPTION

Abstract class decorates with L<HTTP::Response>.

=head1 SEE ALSO

L<Net::NicoVideo::Decorator>

=cut
