use strict;
package Siesta::Plugin::Resume;
use base 'Siesta::Plugin';
use Digest::MD5 qw(md5_hex);
sub description { "set a deferred message on its way" }

sub process {
    my $self = shift;
    my $mail = shift;

    return unless $mail->body =~ /resume (\d+) (\S+)/;
    my ($id, $hash) = ($1, $2);

    my $deferred = Siesta::Deferred->retrieve( $id ) or return;
    unless ($deferred->who->email eq $mail->from) {
        # you don't own this message, so you can't resume it
        return 1;
    }
    unless ( $deferred->hash eq $hash ) {
        # wrong magic cookie
        return 1;
    }
    $deferred->resume;
    return 1;
}

1;
