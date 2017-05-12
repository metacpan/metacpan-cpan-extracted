package Qpsmtpd::Plugin::Queue::HTTPRequest;
use strict;
use warnings;
our $VERSION = '0.02';

use Email::Address;
use Email::Abstract;
use HTTP::Request::Common;
use LWP::UserAgent;
use URI;
use YAML;
use Qpsmtpd::Constants;

use base qw/ Qpsmtpd::Plugin Class::Accessor::Fast /;
__PACKAGE__->mk_accessors(qw( agent config ));

my $CONFIG_FILE = 'queue_httprequest.yaml';

sub init {
    my ($self, $qp, @args) = @_;
    
    my $file = $qp->config_dir($CONFIG_FILE) . "/$CONFIG_FILE";
    my $conf = YAML::LoadFile($file);
    
    for my $handler (@{ $conf->{handlers} ||= [] }) {
        $handler->{rcpt} = qr/$handler->{rcpt}/;
    }
    
    $self->config($conf);
    $self->log(LOGINFO, "config =>\n". YAML::Dump $conf);
    
    $self->agent( LWP::UserAgent->new );
    $self->agent->agent($conf->{global}{user_agent} || __PACKAGE__."/$VERSION");
}

sub hook_queue {
    my ($self, $tx) = @_;
    
    my @rcpts = map { $_->address } $tx->recipients;
    my @task;
    for my $handler (@{ $self->config->{handlers} }) {
        if (grep { $_ =~ $handler->{rcpt} } @rcpts) {
            push @task, $handler->{post};
        }
    }
    
    return DECLINED unless @task;
    
    my $req = $self->_make_request($tx);
     
    for my $url (@task) {
        my $res = $self->agent->request(do {
            $req->uri($url);
            $self->log(LOGDEBUG, "request =>\n". $req->as_string);
            $req;
        });
        
        $self->log(LOGINFO,
            sprintf 'sender:%s, url:%s, status:%s',
                $tx->sender->address, $url, $res->status_line
        );
        $self->log(LOGDEBUG, "response =>\n". $res->content);
    }
     
    return OK;
}

sub _make_request {
    my ($self, $tx) = @_;
    my $email = Email::Abstract->new($tx)->cast('Email::MIME');
    
    my $request_content = [
        sender => $tx->sender->address,
        rcpt   => [ map { $_->address } $tx->recipients ],
        source => $email->as_string,
    ];
    
    for my $header (qw( from to cc )) {
        my @email = Email::Address->parse($email->header($header));
        push @$request_content, ( $header => $_->address ) for @email;
    }
    
    return POST('dummy', $request_content);
}

1;
__END__

=encoding utf-8

=head1 NAME

Qpsmtpd::Plugin::Queue::HTTPRequest - Email to HTTP Request

=head1 SYNOPSIS

  # in /etc/qpsmtpd/plugins
  Qpsmtpd::Plugin::Queue::HTTPRequest
  
  # /etc/qpsmptd/que_httprequest.yaml
  handlers:
    - rcpt: '^test@example\.com'
      post: 'http://localhost/api'

=head1 DESCRIPTION

Qpsmtpd::Plugin::Queue::HTTPRequest is a Qpsmtpd plugin that queues
a mail post as a http request.

=head2 EXAMPLE

=over 4

=item /etc/qpsmtpd/plugins

  plugin_you_like_foo
  plugin_you_like_bar
  plugin_you_like_baz

  Qpsmtpd::Plugin::Queue::HTTPRequest
  
  queue/you_like

=item /etc/qpsmtpd/queue_httprequest.yaml

  handlers:
    - rcpt: 'signup-.+?@example.com'
      post: 'http://localhost/api'
    - rcpt: 'test@example\.com'
      post: 'http://localhost:3000/api'

=item Email

  From: =?ISO-2022-JP?B?GyRCSVpFRBsoQg==?= <tomita@cpan.org>
  To: test api <signup-xxxyyyzzz123@example.com>
  Subject: Hello =?ISO-2022-JP?B?GyRCQCQzJhsoQg==?=
  Cc: bar@example.com, Baz <baz@example.net>
  MIME-Version: 1.0
  Content-Type: text/plain; charset="ISO-2022-JP"
  Content-Transfer-Encoding: 7bit
  
  Can you see me?
  こんにちは

(Note: body is encoding ISO-2022-JP in practice.)

=item HTTP Request

  POST 'http://localhost/api', [
      sender => 'tomita@cpan.org',
      from   => 'tomita@cpan.org',
      rcpt   => 'signup-xxxyyyzzz123@example.com',
      to     => 'signup-xxxyyyzzz123@example.com',
      cc     => 'bar@example.com',
      cc     => 'baz@example.net',
      source => <<'__EOF__'
  From: =?ISO-2022-JP?B?GyRCSVpFRBsoQg==?= <tomita@cpan.org>
  To: test api <signup-xxxyyyzzz123@example.com>
  Subject: Hello =?ISO-2022-JP?B?GyRCQCQzJhsoQg==?=
  Cc: bar@example.com, Baz <baz@example.net>
  MIME-Version: 1.0
  Content-Type: text/plain; charset="ISO-2022-JP"
  Content-Transfer-Encoding: 7bit
  
  Can you see me?
  こんにちは
  __EOF__
      ,
  ];

(Note: source is bytes.)

=back

=head1 TODO

testing.. we need Qpsmtpd testing framework?

=head1 SEE ALSO

L<http://smtpd.develooper.com/>

similar idea: L<http://www.smtp2web.com/>

L<Qpsmtpd::Plugin::EmailAddressLoose>

L<http://coderepos.org/share/browser/lang/perl/Qpsmtpd-Plugin-Queue-HTTPRequest> (repository)

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
