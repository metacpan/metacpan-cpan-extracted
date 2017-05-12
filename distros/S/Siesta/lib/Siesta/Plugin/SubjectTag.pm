package Siesta::Plugin::SubjectTag;
use strict;
use Siesta::Plugin;
use base 'Siesta::Plugin';


sub description {
    'allows you to add something to the start of the subject line of each outgoing mail';
}

sub process {
    my $self = shift;
    my $mail = shift;

    my $munge = $self->pref('subjecttag');

    return unless $munge;

    my $subject = $mail->subject || 'no subject';
    my $list_name = $self->list->name;
    $mail->subject("$munge $subject")
      unless $subject =~ /\Q$munge/;
    return;
}

sub options {
    +{
      'subjecttag'
      => {
          'description' =>
          'Add something to the start of the subject line of each out going mail.',
          'type'    => 'string',
          'default' => '',
          'widget'  => 'textbox',
         },
     };
}


1;
__END__
