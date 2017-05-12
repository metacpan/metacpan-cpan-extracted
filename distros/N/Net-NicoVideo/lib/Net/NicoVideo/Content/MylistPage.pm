package Net::NicoVideo::Content::MylistPage;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

use base qw(Net::NicoVideo::Content Class::Accessor::Fast);

use vars qw(@Members);
@Members = qw(
token
);

__PACKAGE__->mk_accessors(@Members);

sub members { # implement
    my @copy = @Members;
    @copy;
}

sub parse { # implement
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    my $content = $self->_decoded_content;
    if( $content =~ /NicoAPI\.token\s*=\s*"([-\w]+)"/ ){
        $self->token( $1 );
    }

    # status
    if( $self->token ){
        $self->set_status_success;
    }else{
        $self->set_status_error;
    }
    
    return $self;
}


1;
__END__

=pod

=head1 NAME

Net::NicoVideo::Content::MylistPage - Content of the page

=head1 SYNOPSIS

    Net::NicoVideo::Content::MylistPage->new({
        token => "...",
        });

=head1 DESCRIPTION

Parsed content of the page L<http://www.nicovideo.jp/my/mylist>.
This place is for owner which login Nico Nico Douga.

An important thing that this page is having "NicoAPI.token" to update Mylist.

=head1 SEE ALSO

L<Net::NicoVideo::Response::MylistPage>

=cut
