package Net::Whois::Object::Response;

use base qw/Net::Whois::Object/;

__PACKAGE__->attributes( 'mandatory', ['response'] );
__PACKAGE__->attributes( 'optional', ['comment'] );
__PACKAGE__->attributes( 'single',    ['response'] );
__PACKAGE__->attributes( 'multiple',  ['comment'] );


=head1 NAME

Net::Whois::Object::Response - an object representation of the RPSL Response block

=head1 DESCRIPTION

output starting with the % sign is either a server response code or
an informational message. A comment contains a white space after the
% sign, while server messages start right after the % sign. Please
see Appendix A2 "RIPE Database response codes and messages" for more
information.

* An empty line ("\n\n") is an object delimiter. 

* Two empty lines mean the end of a server response. 

=head1 METHODS

=head2 B<new( %options )>

Constructor for the Net::Whois::Object::Response class

=cut

sub new {
    my ( $class, @options ) = @_;

    my $self = bless {}, $class;
    $self->_init(@options);

    return $self;
}

=head2 B<response( [$response] )>

Accessor to the response attribute.
Accepts an optional response, always return the current response.

=head2 B<comment( [$comment] )>

Accessor to the comment attribute.
Accepts an optional comment, always return the current comment.

=cut

1;
