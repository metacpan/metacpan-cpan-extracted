package Exception::SendMail;
$Exception::SendMail::VERSION = '0.007';
use base qw(Exception);

package Exception::SendMail::BadAddress;
$Exception::SendMail::BadAddress::VERSION = '0.007';
use base qw(Exception::SendMail);

package QBit::Application::Model::SendMail;
$QBit::Application::Model::SendMail::VERSION = '0.007';
use qbit;
use base qw(QBit::Application::Model);
use MIME::Base64 qw(encode_base64);
use MIME::Lite;

our %MESSAGE_STRUCT = (
    from     => {type => 'email', max      => 1, required => 1},
    to       => {type => 'email', required => 1},
    cc       => {type => 'email'},
    bcc      => {type => 'email'},
    reply_to => {type => 'email'},
    subject      => {type => 'str',         required => 1},
    content_type => {type => 'contenttype', default  => 'text/plain'},
    body         => {type => 'str',         conv_raw => 1, required => 1},
    attachments => {
        type   => 'struct',
        struct => {
            data         => {type => 'str',         conv_raw => 1},
            content_type => {type => 'contenttype', default  => 'application/download'},
            filename     => {type => 'str'},
            content_id   => {type => 'str',         conv_raw => 1},
        }
    },
    source_spot => {type => 'str', conv_raw => 1},
);

our %TEMPLATERS = (
    TT2 => sub {
        my $d = shift;
        use Template;
        my $template = Template->new({});
        my $out      = '';
        $template->process($d->{template}, $d->{vars}, \$out)
          || throw Exception::SendMail gettext('Template process error [%s]', $template->error());
        return $out;
    },
);

our %FIELD_TYPE;

%FIELD_TYPE = (
    email => {
        in => {
            hash => [
                sub {
                    # in:  '', { <email> => <name> }, [{}]
                    # out: [ { name => '', email => '' }, ... ]
                    my ($self, $data, $opt) = @_;
                    my $out = [];

                    if (ref($data) eq 'HASH') {
                        while (my ($email, $name) = each(%$data)) {
                            push(@$out, {name => $name, email => $email});
                        }
                    } elsif (!ref($data) && $data) {
                        push(@$out, {name => '', email => $data});
                    } elsif (ref($data) eq 'ARRAY') {

                        foreach my $d (@$data) {
                            foreach my $sub (@{$FIELD_TYPE{email}->{in}->{hash}}) {
                                my $res = $sub->($self, $d, $opt) if ref($sub) eq 'CODE' && defined($d);
                                if (defined $res) {
                                    push(@$out, @$res);
                                    last;
                                }
                            }
                        }

                    }

                    foreach my $elem (@$out) {
                        $elem->{name} =~ s/(^\s*|\s*$)//g;
                        throw Exception::SendMail::BadAddress gettext('Bad email [%s]', $elem->{email})
                          if grep {!check_email($_)} split(/,\s*/, $elem->{email});
                    }
                    return $out;
                },
            ]
        },
        out => {
            mime => [
                sub {
                    # out:  ''
                    my ($self, $data, $opt) = @_;
                    return join(
                        ', ',
                        map({
                                utf8::encode($_->{'name'});
                                  $_->{'name'}
                                ? '=?UTF-8?B?' . encode_base64($_->{'name'}, '') . '?= <' . $_->{'email'} . '>'
                                : $_->{'email'}
                            } @$data)
                    );
                },
            ],
        },
    },

    contenttype => {
        in => {
            hash => [
                sub {
                    # in:  ''
                    # out: ''
                    my ($self, $data, $opt, $secret) = @_;
                    my $out = lc($data);
                    throw Exception::SendMail gettext('Unknown content type [%s]', $data)
                      if (
                        defined($out)
                        && !in_array(
                            $out,
                            [
                                qw(text/plain text/html application/download image/jpeg image/png image/gif application/pdf application/xhtml+xml application/xml-dtd application/zip application/x-gzip)
                            ]
                        )
                      );
                    return $out;
                },
            ],
        },
        out => {
            mime => [
                sub {
                    # out: ''
                    return $_[1];
                },
            ],
        },
    },

    struct => {
        in => {
            hash => [
                sub {
                    # in:  {}
                    # out: {}
                    # opt: struct
                    my ($self, $data, $opt) = @_;
                    return [
                        map($self->_message_struct_in($_, 'hash', $opt->{struct}),
                            ref($data) eq 'ARRAY' ? @$data : ($data))
                           ];
                },
            ],
        },
        out => {
            mime => [
                sub {
                    # out: {}
                    my ($self, $data, $opt) = @_;
                    return [map($self->_message_struct_out($_, 'mime', $opt->{struct}), @$data)];
                },
            ],
        },
    },

    str => {
        in => {
            hash => [
                sub {
                    # in:  '', \'', {}
                    # out: ''
                    my ($self, $data, $opt) = @_;
                    my $out;
                    if (!ref($data)) {
                        $out = $data;
                    } elsif (ref($data) eq 'SCALAR') {
                        $out = $$data;
                    } elsif (ref($data) eq 'HASH' && $TEMPLATERS{$data->{'type'}}) {
                        $out = $TEMPLATERS{$data->{'type'}}->($data);
                    }
                    return $out;
                },
            ],
        },
        out => {
            mime => [
                sub {
                    # out: ''
                    # opt: conv_raw => 1'
                    my ($self, $data, $opt) = @_;
                    if ($opt->{conv_raw}) {
                        return $data;
                    } else {
                        utf8::encode($data);
                        return '=?UTF-8?B?' . encode_base64($data, '') . '?=';
                    }
                },
            ],
        },
    },
);

sub _message_struct_out {
    my ($self, $data, $media, $struct) = @_;
    my $out;
    $struct //= \%MESSAGE_STRUCT;
    while (my ($name, $opt) = each(%$struct)) {
        # call export
        my $sub = $FIELD_TYPE{$opt->{type}}->{out}->{$media}->[0]
          if ($FIELD_TYPE{$opt->{type}}->{out}->{$media}
            && ref($FIELD_TYPE{$opt->{type}}->{out}->{$media}->[0]) eq 'CODE');
        my $d = $data ? $data->{$name} : $self->{ucfirst($name)};
        next if !defined($d);
        $out->{$name} = $sub ? $sub->($self, $d, $opt) : undef;
    }
    return $out;
}

sub _message_struct_in {
    my ($self, $data, $media, $struct) = @_;
    my $level = $struct ? 1 : 0;
    $struct ||= \%MESSAGE_STRUCT;
    $media  ||= 'hash';
    my $out;
    while (my ($name, $opt) = each(%$struct)) {
        # call import
        my $res;
        foreach my $sub (@{$FIELD_TYPE{$opt->{type}}->{in}->{$media}}, @{$FIELD_TYPE{$opt->{type}}->{in}->{''}}) {
            # call field convertor
            $res = $sub->($self, $data->{$name}, $opt, {in => $data, out => $out})
              if ref($sub) eq 'CODE' && defined($data->{$name});
            last if defined($res);
        }
        $res = $opt->{default} if (!defined($res));    # move 'defatult' behavior into convertor?
                                                       # check limits
        throw Exception::SendMail gettext('No mandatory field [%s]', $name)
          if ($opt->{required} && (!defined($res) || (ref($res) eq 'ARRAY' && @$res == 0)));
        throw Exception::SendMail gettext('Too many fields [%s]', $name)
          if ($opt->{max} && (ref($res) eq 'ARRAY' && @$res > $opt->{max}));
        # result
        $out->{$name} = $res;
    }
    return $out;
}

sub _mail_create {
    my ($self, $hash) = @_;
    my $mail;
    my $data;

    # create message data
    $data = $self->_message_struct_out($self->_message_struct_in($hash, 'hash'), 'mime');
    my $msg;
    $msg->{headers} = {
        hash_transform(
            $data,
            [],
            {
                from        => 'From',
                to          => 'To',
                subject     => 'Subject',
                cc          => 'Cc',
                bcc         => 'Bcc',
                source_spot => 'X-Source-Spot',
                reply_to    => 'Reply-To',
            }
        )
    };
    $msg->{headers}->{'Message-ID'} = '<'
      . (time() . '_' . sprintf("%09d", rand(999999999))) . '.'
      . $self->get_option('message_id', 'framework@qbit.ru') . '>';

    if ($data->{attachments}) {
        $msg->{content_type} = 'multipart/related';
        $msg->{attachments}  = [
            {
                data         => $data->{body},
                content_type => $data->{content_type},
            },
            @{$data->{attachments}},
        ];
        delete($msg->{body});
    } else {
        $msg->{content_type} = $data->{content_type};
        $msg->{attachments}  = [];
        $msg->{body}         = $data->{body};
    }

    # create mail message
    if ($msg->{body}) {
        utf8::encode($msg->{body}) if (utf8::is_utf8($msg->{body}));
        $mail = new MIME::Lite(
            %{$msg->{headers}},
            Type       => $msg->{content_type},
            'Encoding' => 'base64',
            'Data'     => $msg->{body},
        );
    } else {
        $mail = new MIME::Lite(%{$msg->{headers}}, Type => $msg->{content_type},);
    }
    $mail->attr("content-type.charset" => "UTF-8");

    foreach my $attach (@{$msg->{'attachments'}}) {
        utf8::encode($attach->{data}) if (utf8::is_utf8($attach->{data}));
        my $att = $mail->attach(
            Type     => $attach->{content_type},
            Encoding => 'base64',
            Data     => $attach->{data},
            Filename => $attach->{filename},
            Id       => $attach->{content_id},
        );
        $att->attr("content-type.charset" => "UTF-8");
    }

    return $mail;
}

sub send {
    my ($self, %hash) = @_;

    my $mail = $self->_mail_create(\%hash);

    $self->_before_send($mail);

    if ($self->get_option('via', 'sendmail') eq 'sendmail') {
        $mail->send_by_sendmail(%{$self->get_option('sendmail')})
          || throw Exception::SendMail gettext("Can't send message");
    } elsif ($self->get_option('via') eq 'smtp') {
        $mail->send_by_smtp(%{$self->get_option('smtp')});
    } elsif ($self->get_option('via') eq 'testfile') {
        $mail->send_by_testfile($self->get_option('testfile'));
    }

    $self->_after_send($mail);
}

sub _before_send { }
sub _after_send  { }

TRUE;

__END__

=encoding utf8

=head1 Name

QBit::Application::Model::SendMail - Class to send E-Mail.

=head1 GitHub

https://github.com/QBitFramework/QBit-Application-Model-SendMail

=head1 Install

=over

=item *

cpanm QBit::Application::Model::SendMail

=item *

apt-get install libqbit-application-model-sendmail-perl (http://perlhub.ru/)

=back

For more information. please, see code.

=cut
