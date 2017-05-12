package Pcore::SMTP::Message;

use Pcore -class;

# NOTE
# http://foundation.zurb.com/emails.html
# https://habrahabr.ru/post/317810/

sub sendmail ( $self, $smtp, @ ) {
    my $cb = $_[-1];

    my $args;

    $args = $_[2] if @_ == 4;

    ...;

    return;
}

# sub send_mail (@) {
#     use Net::SMTP;
#
#     my %args = (
#         host         => undef,
#         port         => undef,
#         username     => undef,
#         password     => undef,
#         ssl          => undef,                           # undef, ssl, starttls
#         debug        => 0,
#         content_type => 'text/plain; charset="UTF-8"',
#         from         => q[],
#         reply_to     => q[],
#         @_,
#     );
#
#     my $h = Net::SMTP->new(
#         Host  => $args{host},
#         Port  => $args{port},
#         SSL   => $args{ssl},
#         Debug => $args{debug},
#     ) or die 'Could not connect to mail server ' . $args{host};
#
#     $h->auth( $args{username}, $args{password} ) or die 'SMTP authentication failed for username ' . $args{username};
#
#     encode_utf8 $args{subject};
#
#     encode_utf8 $args{body};
#
#     # create arbitrary boundary text used to seperate different parts of the message\n
#     my ( $bi, @bchrs );
#     my $boundary = q[];
#     for my $bn ( 48 .. 57, 65 .. 90, 97 .. 122 ) {
#         $bchrs[ $bi++ ] = chr $bn;
#     }
#     for my $bn ( 0 .. 20 ) {
#         $boundary .= $bchrs[ rand $bi ];
#     }
#
#     $h->mail("$args{from}$CRLF");
#
#     if ( $args{to} ) {
#         $args{to} = [ $args{to} ] if ref $args{to} ne 'ARRAY';
#
#         $h->to( $args{to}->@* );
#     }
#
#     if ( $args{cc} ) {
#         $args{cc} = [ $args{cc} ] if ref $args{cc} ne 'ARRAY';
#
#         $h->cc( $args{cc}->@* );
#     }
#
#     if ( $args{bcc} ) {
#         $args{bcc} = [ $args{bcc} ] if ref $args{bcc} ne 'ARRAY';
#
#         $h->bcc( $args{bcc}->@* );
#     }
#
#     $h->data();
#     $h->datasend("Reply-To: $args{reply_to}$CRLF") if $args{reply_to};
#     $h->datasend("From: $args{from}$CRLF");
#     $h->datasend("To: @{[ join q[, ], $args{to}->@* ]}$CRLF");
#     $h->datasend("Subject: $args{subject}$CRLF");
#
#     $h->datasend("MIME-Version: 1.0$CRLF");
#     $h->datasend("Content-Type: multipart/mixed; BOUNDARY=\"$boundary\"$CRLF");
#
#     $h->datasend("$CRLF--$boundary$CRLF");
#     $h->datasend("Content-Type: $args{content_type}$CRLF");
#     $h->datasend("$CRLF");
#     $h->datasend("$args{body}$CRLF$CRLF");
#
#     # send attachments
#     if ( $args{attachments} ) {
#         if ( ref $args{attachments} eq 'HASH' ) {
#             my $path = $args{attachments}->{path};
#             my $name = $args{attachments}->{name} || q[];
#             _send_attachment( $h, $boundary, $path, $name );
#         }
#         elsif ( ref $args{attachments} eq 'ARRAY' ) {
#             for my $item ( @{ $args{attachments} } ) {
#                 if ( ref $item eq 'HASH' ) {
#                     my $path = $item->{path};
#                     my $name = $item->{name} || q[];
#                     _send_attachment( $h, $boundary, $path, $name );
#                 }
#                 else {
#                     _send_attachment( $h, $boundary, $item );
#                 }
#             }
#         }
#         else {
#             _send_attachment( $h, $boundary, $args{attachments} );
#         }
#     }
#
#     $h->datasend("$CRLF--$boundary--$CRLF");
#     $h->datasend("$CRLF");
#
#     $h->dataend;
#
#     $h->quit;
#
#     return;
# }
#
# sub _send_attachment {
#     my $h        = shift;
#     my $boundary = shift;
#     my $file     = shift;
#     my $filename = shift || q[];
#
#     die qq[Unable to find attachment file $file] unless -f $file;
#
#     my $path = P->path($file);
#
#     my $data = P->file->read_bin($path);
#
#     my $mimetype = $path->mime_type;
#     $filename = $path->filename unless $filename;
#     encode_utf8 $filename;
#
#     if ($data) {
#         $h->datasend("--$boundary$CRLF");
#         $h->datasend("Content-Type: $mimetype; name=\"$filename\"$CRLF");
#         $h->datasend("Content-Transfer-Encoding: base64$CRLF");
#         $h->datasend("Content-Disposition: attachment; =filename=\"$filename\"$CRLF$CRLF");
#         $h->datasend( P->data->to_b64( ${$data} ) );
#         $h->datasend("--$boundary$CRLF");
#     }
#
#     return;
# }

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 16                   | ControlStructures::ProhibitYadaOperator - yada operator (...) used                                             |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::SMTP::Message

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
