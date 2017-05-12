package Siesta::Plugin::SimpleSig;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';
use Siesta;

sub description {
    'This is a very simple sig plugin, its probably more useful for testing';
}

sub process {
    my $self = shift;
    my $mail = shift;
    my $list = $self->list;

    my $maxlines = $self->pref( 'maxlines' );

    my ( undef, $sig ) = split /^-- $/m, $mail->body, 2;

    # no point going on if there's no sig. Sob. Goodbye, cruel world.
    return 0 unless defined $sig;

    my (@lines) = split /\n/, $sig;
    if ( scalar(@lines) > $maxlines + 1 ) {
        $mail->reply( body => Siesta->bake( 'simplesig_reject',
                                            list     => $self->list,
                                            maxlines => $maxlines,
                                            message  => $mail ),
                     );
        return 1;
    }
    return 0;
}

sub options {
    +{
      'maxlines'
      => {
          'description' =>
          'the maximum number of lines we shoudl allow in the sig before chomping',
          'type'    => 'num',
          'default' => 5,
          'widget'  => 'textbox',
         },
     };
}

1;
