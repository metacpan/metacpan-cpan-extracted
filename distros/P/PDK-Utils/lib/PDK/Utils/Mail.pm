package PDK::Utils::Email;

use v5.30;
use Moose;

use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP;
use Email::Simple;

use namespace::autoclean;

has smtp => (is => 'ro', isa => 'Str',);

has port => (is => 'ro', isa => 'Int', default => 465,);

has username => (is => 'ro', isa => 'Str',);

has password => (is => 'ro', isa => 'Str',);

has subject => (is => 'ro', isa => 'Str',);

has from => (is => 'ro', isa => 'Str',);

sub send_mail {
  my $self = shift;

  my %params;
  if (ref($_[0]) eq 'HASH') {
    %params = %{$_[0]};
  }
  else {
    %params = @_;
  }

  confess("请提供收件人地址") if not defined $params{to};
  confess("必须提供邮件内容") if not defined $params{body};

  my $to
    = join(',', keys %{{map { lc($_) => undef } grep { defined $_ and $_ !~ /^\s*$/ } split(/[,;|，]/, $params{to})}});

  my $from    = $self->{from}    || $params{from} || $ENV{PDK_SMTP_SENDER};
  my $subject = $params{subject} || $ENV{PDK_SMTP_SUBJECT};

  confess("构造函数必须填写 from, subject，或设置相应的环境变量：PDK_SMTP_SENDER, PDK_SMTP_SUBJECT") unless ($from and $subject);

  my $email = Email::Simple->create(header => [To => $to, From => $from, Subject => $subject,], body => $params{body},);

  my $transport = Email::Sender::Transport::SMTP->new(
    hosts         => [$self->smtp || $ENV{PDK_SMTP_SERVER}],
    port          => $self->port || $ENV{PDK_SMTP_PORT},
    ssl           => 1,
    sasl_username => $self->username || $ENV{PDK_SMTP_USERNAME},
    sasl_password => $self->password || $ENV{PDK_SMTP_PASSWORD},
  );

  eval { sendmail($email, {transport => $transport}); };

  if ($@) {
    chomp($@);
    confess("发送邮件失败: $@");
  }
}

__PACKAGE__->meta->make_immutable;

1;
