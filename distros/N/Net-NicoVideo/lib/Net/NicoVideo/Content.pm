package Net::NicoVideo::Content;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

sub new {
    my $class = shift;
    $class = ref $class || $class;
    
    my $contents = shift;

    my $self = {
        _decoded_content => undef,
        _status => undef,
    };

    bless $self, $class;
    
    $self->load($contents) if( defined $contents );
    
    return $self;
}

sub _decoded_content {
    my $self = shift;
    return @_ ? $self->{_decoded_content} = shift : $self->{_decoded_content};
}

sub _status {
    my $self = shift;
    return @_ ? $self->{_status} = shift : $self->{_status};
}

sub set_status_success {
    $_[0]->_status(1);
}

sub set_status_error {
    $_[0]->_status(0);
}

sub load {
    my $self = shift;
    my $contents = shift;

    unless( ref($contents) ){
        $self->_decoded_content( $contents );
    }else{
        if( $contents->isa('HTTP::Response') ){
            $self->_decoded_content( $contents->decoded_content );
        }else{
            $self->_decoded_content( $$contents );
        }
    }
    
    return $self;
}

sub members { # interface
    ();
}

sub parse { # interface
    my $self = shift;
    $self->load($_[0]) if( defined $_[0] );

    # here! parse contents and set _status to success or error

    return $self;
}

sub is_success {
    my $self = shift;
    unless( defined $self->_status ){
        die "content is not parsed as @{[ ref($self) ]} yet";
    }
    return $self->_status ? 1 : 0;
}

sub is_error {
    my $self = shift;
    unless( defined $self->_status ){
        die "content is not parsed as @{[ ref($self) ]} yet";
    }
    return $self->_status ? 0 : 1;
}


1;
__END__


=pod

=head1 NAME

Net::NicoVideo::Content - The base class of content objects

=head1 SYNOPSIS

    package Net::NicoVideo::Content::SomePage;
    use parent 'Net::NicoVideo::Content';

=head1 DESCRIPTION

The base class of content objects.

A kind of contents correspond to one page.

=head1 SEE ALSO

L<Net::NicoVideo::Response>

=cut
