
use strict;

use Class::Generate qw(class);

class 'Nmap::Scanner::Service' => {
    qw(name      $
       proto     $
       rpcnum    $
       lowver    $
       highver   $
       method    $
       service   $
       version   $
       extrainfo $
       tunnel    $
       product   $
       conf      $),
    '&as_xml' => q!

    my @entities = qw(name proto rpcnum lowver highver version 
                      method conf);

    my $body = '';

    for my $e (@entities) {
        $body .= qq($e="$self->{$e}" ) if $self->{$e};
    }

    for my $ee (qw(product extrainfo)) {
        next unless $self->{$ee};
        my $encoded = encode_entities($self->{$ee});
        $body .= qq($ee="$encoded" );
    }

    return "<service ${body}/>";

    !
},
'-use' => 'HTML::Entities'
;

=pod

=head1 DESCRIPTION

This class represents a service as represented by the scanning output from
nmap.

=head2 name()

=head2 proto()

=head2 rpcnum()

=head2 lowver()

=head2 highver()

=head2 method()

=head2 conf()

=head2 tunnel()

=head1 VERSION SCANNING MUTATORS

Information will be present for this only if -sV is used.

=head2 product()

=head2 version()

=head2 extrainfo()

=cut

1;
