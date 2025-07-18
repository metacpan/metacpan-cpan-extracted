package Net::SimpleMail;

use strict;
use warnings;

our $VERSION = '0.22';

use Net::SMTP::SSL;
use Authen::SASL;
use Encode;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(simplemail);

my $DEFAULT_HOST = 'space.hostcache.com';
my $DEFAULT_PORT = 465;


sub simplemail {
    my ( $recipient, $subject, $message ) = @_;

    # 检查环境变量
    my $username = $ENV{SM_USER};
    my $password = $ENV{SM_PASS};

    unless ( defined $username && defined $password ) {
        die "Error: SM_USER and SM_PASS environment variables must be set.\n";
    }

    # 连接到 SMTP 服务器
    my $smtp = Net::SMTP::SSL->new(
        $DEFAULT_HOST,
        Port    => $DEFAULT_PORT,
        Timeout => 30,
        # Debug   => 1,
    ) or die "Could not connect to SMTP server: $!\n";

    # 认证
    $smtp->auth( $username, $password )
        or die "Authentication failed: " . $smtp->message() . "\n";

    # 构造邮件
    my $sender = $username; 
    $smtp->mail($sender);
    $smtp->to($recipient);

    # 准备邮件头
    $smtp->data();
    $smtp->datasend("To: $recipient\n");
    $smtp->datasend("From: $sender\n");
    $smtp->datasend("Subject: " . Encode::encode( 'MIME-Header', $subject ) . "\n");
    $smtp->datasend("Content-Type: text/plain; charset=UTF-8\n");
    $smtp->datasend("Content-Transfer-Encoding: 8bit\n");
    $smtp->datasend("\n");

    # 发送邮件内容 (确保使用 UTF-8 编码)
    $smtp->datasend( Encode::encode( 'UTF-8', $message ) );
    $smtp->datasend("\n");
    $smtp->dataend();

    # 关闭连接
    $smtp->quit();

    #    print "Email sent successfully to $recipient\n";
    return 1;
}

1;

=encoding utf8

=head1 NAME

Net::SimpleMail - A simple module to send emails via simplemail.co.in

=head1 DESCRIPTION

This module provides a simple way to send emails using the simplemail.co.in email service.
It requires the environment variables C<SM_USER> and C<SM_PASS> to be set with your username
and password, respectively.

=head1 FUNCTIONS

=head2 simplemail( $recipient, $subject, $message )

Sends an email to the specified recipient with the given subject and message.

=head1 EXAMPLES

    use Net::SimpleMail;
    use utf8;

    # Send a simple email
    simplemail("test@example.com", "Test Email", "This is a test email message.");

    # Send an email with Chinese characters
    simplemail("test@example.com", "中文邮件", "这是一封包含中文的邮件。");

=head1 AUTHOR

ypeng at t-online.de

=cut
