package PHP::Functions::Mail;

use strict;

use vars qw(@ISA @EXPORT_OK $VERSION);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(mail mb_send_mail);
$VERSION = '0.04';

use Carp qw(carp croak);
use Net::SMTP;

sub mail {
    my $to = shift;
    my $subject = shift;
    my $body = shift;
    my $headers = shift;
    my $options = shift;

    eval {
	my $option = $options->{NetSmtpOption} ? $options->{NetSmtpOption} : undef;
	my $host = $options->{Host} ? $options->{Host} : 'localhost';
	my $smtp = Net::SMTP->new($host);

	my $send_header;
	my $in_subject = 0;
	my $in_from = 0;

	#From head check
	foreach my $header (split("\n", $headers)) {
	    unless ($header =~ /^([^:]+):(.+)$/) {
		next;
	    }
	    my $name = $1;
	    my $value = $2;
	    my $ns_value = $value;
	    $ns_value =~ s/\s/ /g;
	    $ns_value =~ s|\=\?ISO-2022-JP\?B\?.*?\?\=||g;

	    if (uc($name) eq 'FROM') {
		$smtp->mail(split(",", $ns_value));
		$in_from = 1;
	    }
	    $in_subject = 1 if uc($name) eq 'SUBJECT';
	}
	unless ($in_from) {
	    croak "no From header";
	    return 1;
	}

	$send_header .= "To: $to\n";
	$send_header .= "Subject: $subject\n"unless $in_subject;
	$smtp->to($to);

	$headers =~ s/\n\t/\t/mg;
	foreach my $header (split("\n", $headers)) {
	    unless ($header =~ /^([^:]+):(.+)$/) {
		carp "header format error: $header";
		next;
	    }
	    my $name = $1;
	    my $value = $2;
	    my $ns_value = $value;
	    $ns_value =~ s/\s/ /g;
	    $ns_value =~ s|\=\?ISO-2022-JP\?B\?.*?\?\=||ig;
	    $smtp->to(split(",", $ns_value)) if uc($name) eq 'TO';
	    $smtp->cc(split(",", $ns_value)) if uc($name) eq 'CC';
	    $smtp->bcc(split(",", $ns_value)) if uc($name) eq 'BCC';
	    $value =~ s/\t/\n\t/g;
	    $send_header .= "$name:$value\n";
	}
	$smtp->data;
	$body =~ s/\n\r/\n/g;
	$smtp->datasend("$send_header\n$body");
	$smtp->dataend;
	$smtp->quit;
    };
    croak "mail error: $@" if $@;

    return 0;
}

sub mb_send_mail {
    my $to = shift;
    my $subject = shift;
    my $body = shift;
    my $headers = shift;
    my $options = shift;
    use Jcode;

    my $send_header;
    $headers =~ s/\n\t/\t/mg;
    foreach my $header (split("\n", $headers)) {
	unless ($header =~ /^([^:]+):(.+)$/) {
	    carp "header format error: $header";
	    next;
	}
	my $name  = $1;
	my $value = $2;
	my $len   = 76 - (length($name) + 1);
	$len = 32 if $len < 32;
	$send_header .= "$name:" . mime_encode($value, $len) . "\n";
    }
    $send_header .= "Content-type: text/plain; charset=iso-2022-jp\n";

    mail(mime_encode($to, 72),
	 mime_encode($subject, 66),
	 Jcode->new($body)->iso_2022_jp,
	 $send_header,
	 $options);
}

sub mime_encode {
    use Jcode;
    my $str = Jcode->new(shift)->euc;
    my $len = shift;

    $str =~ s/([\x80-\xff]+)/Jcode->new($1)->mime_encode("\n", $len)/eg;
    $str =~ s/\n /\n\t/g;

    $str =~ s|(\=\?ISO-2022-JP\?B\?)|\n$1|ig;
    $str =~ s|(\?\=)|$1\n|ig;

    $str =~ s/^\s+//m;
    $str =~ s/\s+$//m;

    $str =~ s/\n\n/\n/gm;
    $str =~ s/\n\t\n/\n/gm;
    $str =~ s/\n/\n\t/gm;
    $str =~ s/\n\t$//m;

    return $str;
}

1;
__END__
=head1 NAME

PHP::Functions::Mail - Transplant of mail function of PHP

=head1 SYNOPSIS

  #simple mail send
  use PHP::Functions::Mail qw(mail);
  mail('ToAddress@example.com', 'subject', 'body of message', 'From: FromAddress@example.com');

  #When you enhance the header and Option specification  
  #Host specifiles the smtp server (default 'localhost')
  use PHP::Functions::Mail qw(mail);
  mail('ToAddress@example.com', 'subject', 'body of message',
    join("\n",
      'From: from user <FromAddress@example.com>',
      'Cc: CcAddress@example.com, cc user <CcAddress2@example.com>'),
    {Host => 'smtp.example.com'} );


  #for Japanese
  use PHP::Functions::Mail qw(mb_send_mail);
  mb_send_mail('Japanese Strings <ToAddress@example.com>',
    'subject of Japanese Strings', 'body of Japanese message',
    'From: Japanese Strings <FromAddress@example.com>');


=head1 DESCRIPTION

This module offers perl the function equal with the mail function and the mb_send_mail function mounted with PHP.

=head2 EXPORT

=over 4

=item mail ( TO, SUBJECT, MESSAGE [, HEADERS [, OPTIONS]] )

send of mail.
use 

=item mb_send_mail ( TO, SUBJECT, MESSAGE [, HEADERS [, OPTIONS]] )

send of mail for Japanese.
L<Jcode> is used.

=head1 SEE ALSO

L<http://www.php.net/manual/en/function.mail.php>
L<http://www.php.net/manual/en/function.mb-send-mail.php>
L<Net::SMTP>

=head1 AUTHOR

Kazuhiro, Osawa E<lt>ko@yappo.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kazuhiro Osawa

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either at your option,
any later version of Perl 5 you may have available.

=cut
