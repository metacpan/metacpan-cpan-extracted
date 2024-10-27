#!/usr/bin/perl

use strict;
use warnings;
use 5.030;
use Test::More;
use Data::Printer;

use PDK::Utils::Email;

my $mail;

plan skip_all => 'Skipping this test file';

ok(
  do {
    eval { $mail = PDK::Utils::Email->new(); };
    warn $@ if $@;
    $mail->isa('PDK::Utils::Email');
  },
  '生成 PDK::Utils::Email 对象'
);

ok(
  eval {
    $mail->send_mail(to => '968828@gmail.com，968826@gmail.com', subject => '你好', body => '抠脚大汉');
    1;
  } || do {
    warn "发送邮件失败: $@";
    0;
  },
  '发送邮件'
);

done_testing();

