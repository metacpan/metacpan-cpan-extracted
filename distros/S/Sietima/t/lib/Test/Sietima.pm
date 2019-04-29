package Test::Sietima;
use lib 't/lib';
use Import::Into;
use Email::Stuffer;
use Email::Sender::Transport::Test;
use Data::Printer;
use Sietima;
use Test2::V0;
use Test2::API qw(context);
use Sietima::Policy;
use namespace::clean;

sub import {
    my $target = caller;
    Test2::Bundle::Extended->import::into($target);
    Test2::Plugin::DieOnFail->import::into($target);
    Data::Printer->import::into($target);
    Sietima::Policy->import::into($target);

    for my $function (qw(transport make_sietima make_mail
                         deliveries_are test_sending
                         run_cmdline_sub)) {
        no strict 'refs';
        "${target}::${function}"->** = __PACKAGE__->can($function);
    }
    return;
}

my $return_path = 'sietima-test@list.example.com';

sub transport {
    state $transport = Email::Sender::Transport::Test->new;
    return $transport;
}

sub make_sietima (%args) {
    my $class = 'Sietima';
    if (my $traits = delete $args{with_traits}) {
        $class = $class->with_traits($traits->@*);
    }

    $class->new({
        return_path => $return_path,
        %args,
        transport => transport(),
    });
}

my $maybe = sub ($obj,$method,$arg) {
    return $obj unless $arg;
    return $obj->$method($arg);
};

my $mapit = sub ($obj,$method,$arg) {
    return $obj unless $arg;
    for my $k (keys $arg->%*) {
        $obj = $obj->$method($k, $arg->{$k});
    }
    return $obj;
};

sub make_mail (%args) {
    Email::Stuffer
          ->from($args{from}||'someone@users.example.com')
          ->to($args{to}||$return_path)
          ->$maybe(cc => $args{cc})
          ->$mapit(header => $args{headers})
          ->subject($args{subject}||'Test Message')
          ->text_body($args{body}||'some simple message')
          ->email;
}

sub deliveries_are (%args) {
    my $ctx = context();

    my $checker;
    if (my @mails = ($args{mails}||[])->@*) {
        $checker = bag {
            for my $m (@mails) {
                item hash {
                    if (ref($m) eq 'HASH') {
                        field email => object {
                            call [cast=>'Email::MIME'] => $m->{o};
                        };
                        field envelope => hash {
                            field to => bag {
                                item $_ for $m->{to}->@*;
                            } if $m->{to};
                            field from => $m->{from} if $m->{from};
                            etc();
                        };
                    }
                    else {
                        field email => object {
                            call [cast=>'Email::MIME'] => $m;
                        };
                    }
                    etc();
                };
            }
            end();
        };
    }
    elsif (my @recipients = do {my $to = $args{to}; ref($to) ? $to->@* : $to // () }) {
        $checker = array {
            item hash {
                field envelope => hash {
                    field from => $args{from}||$return_path;
                    field to => bag {
                        for (@recipients) {
                            item $_;
                        }
                        end();
                    };
                    etc();
                };
                etc();
            };
            end();
        };
    }
    else {
        $checker = [];
    }

    my @deliveries = transport->deliveries;
    is(
        \@deliveries,
        $checker,
        $args{test_message}//'the deliveries should be as expected',
        np @deliveries,
    );
    $ctx->release;
}

sub test_sending (%args) {
    my $ctx = context();

    my $sietima = delete $args{sietima};
    if (!$sietima or ref($sietima) eq 'HASH') {
        $sietima = make_sietima(%{$sietima||{}});
    }
    my $mail = delete $args{mail};
    if (!$mail or ref($mail) eq 'HASH') {
        $mail = make_mail(
            to => $sietima->return_path,
            %{$mail||{}},
        );
    }

    transport->clear_deliveries;

    ok(
        lives { $sietima->handle_mail($mail) },
        'should handle the mail',
        $@,
    );

    $args{from} ||= $sietima->return_path;
    $args{to} ||= [ map { $_->address} $sietima->subscribers->@* ];
    deliveries_are(%args);

    $ctx->release;
}

sub run_cmdline_sub($sietima,$method,$options={},$parameters={}) {
    require Sietima::Runner;
    my $r = Sietima::Runner->new({
        options => $options,
        parameters => $parameters,
        cmd => $sietima,
        op => $method,
    });
    $r->response(App::Spec::Run::Response->new(buffered=>1));
    ok(
        lives { $sietima->$method($r) },
        "calling $method should live",
    );
    my %ret;
    for my $output ($r->response->outputs->@*) {
        $ret{
            $output->error ? 'error' : 'output'
        } .= $output->content;
    }
    $ret{exit} = $r->response->exit();
    return \%ret;
}

1;
