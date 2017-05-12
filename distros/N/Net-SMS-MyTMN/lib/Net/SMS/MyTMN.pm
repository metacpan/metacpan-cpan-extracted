package Net::SMS::MyTMN;

use warnings;
use strict;
require WWW::Mechanize;
require Exporter;

=head1 NAME

Net::SMS::MyTMN - Send SMS trough MyTMN!

=head1 VERSION

Version 0.08

=cut

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.08';
@ISA         = qw(Exporter);
@EXPORT      = qw();
%EXPORT_TAGS = (
    DEFAULT => [qw//],
    VALID   => [qw/sms_mytmn check_sms/],
);
@EXPORT_OK = qw/sms_mytmn check_sms/;

=head1 SYNOPSIS

Quick and dirty way to send SMS trough portuguese mobile operator.
Note: you need to have an account on www.mytmn.pt

	#!/usr/bin/perl
	use strict;
	use warnings;

	use Net::SMS::MyTMN;

	print Net::SMS::MyTMN::sms_mytmn({
			'username' => '960000000',
			'password' => 'password',
			'targets' => [960000000,910000000],
			'message' => 'message goes here!',
		});

	print Net::SMS::MyTMN::check_mytmn({
			'username' => '960000000',
			'password' => 'password',
		});


=head1 EXPORT

sms_mytmn() to send messages and check_sms() to check how many free sms are left
for the current month.

=head1 FUNCTIONS

=head2 sms_mytmn()

The following 4 parameters are *REQUIRED*:

	username : probably your phone number
	password : the password you use to log onto www.mytmn.pt
	targets  : up to five phone numbers
	message  : a string with the message you're about to send

Return a string: "Message sent"

=head2 check_mytmn()

The following 2 parameters are *REQUIRED*:

	username : probably your phone number
	password : the password you use to log onto www.mytmn.pt

Returns the number of messages left.

=cut

sub sms_mytmn {

    my $self = shift;

    my $username = ( $self->{'username'} || undef );
    my $password = ( $self->{'password'} || undef );
    my $targets  = ( $self->{'targets'}  || undef );
    my $message  = ( $self->{'message'}  || undef );

    my $valid = _valid(
        {
            'username' => $username,
            'password' => $password,
            'targets'  => $targets,
            'message'  => $message,
        }
    );

    return $valid unless !$valid;

    my $target_fields = {
        'message' => $message,
        'event'   => 'confirmSend',
    };

    my $i = 1;
    foreach ( @{$targets} ) {
        $target_fields->{ 'phoneNumber' . $i } = $_;
        $i++;
    }

    my $mech = WWW::Mechanize->new();

    $mech->get('http://www.tmn.pt:80/portal/site/tmn');

    $mech->submit_form(
        form_number => 1,
        fields      => {
            'usr' => $username,
            'pwd' => $password,
        },
    );

    sleep 1;

    my $r = $mech->get('http://my.tmn.pt/web/easysms/EasySmsConfirmSend.po');

    my ($idsessao) = $r->content() =~ /\.*tmnsessionid\%3D(\w{32})\.*/gmx;

    die "Cannot read sessionid!\n" unless $idsessao;

    $mech->get(
qq|http://my.tmn.pt/web/easysms/EasySms.po?silentauthdone=1&tmnsessionid=$idsessao|
    );

    my $rr = $mech->submit_form(
        form_name => 'easySmsForm',
        fields    => $target_fields,
    );

    $mech->submit_form( form_name => 'headerForm' );

    undef $mech;

    return qq|Message sent\n|;

}

sub check_mytmn {

    my $self = shift;

    my $username = ( $self->{'username'} || undef );
    my $password = ( $self->{'password'} || undef );

    my $valid = _valid(
        {
            'username' => $username,
            'password' => $password,
            'targets'  => ['960000000'],
            'message'  => '-',
        }
    );

    return $valid unless !$valid;

    my $mech = WWW::Mechanize->new();

    $mech->get('http://www.tmn.pt:80/portal/site/tmn');

    $mech->submit_form(
        form_number => 1,
        fields      => {
            'usr' => $username,
            'pwd' => $password,
        },
    );

    sleep 1;

    my $r = $mech->get('http://my.tmn.pt/web/easysms/EasySmsConfirmSend.po');

    my ($idsessao) = $r->content() =~ /\.*tmnsessionid\%3D(\w{32})\.*/gmx;

    die "Cannot read sessionid!\n" unless $idsessao;

    $r = $mech->get(
qq|http://my.tmn.pt/web/easysms/EasySms.po?silentauthdone=1&tmnsessionid=$idsessao|
    );

    my ($free) = $r->content() =~ /.*messagesCanBeSent">(\d+)<\//igmx;
    $free = q|0| unless $free;

    undef $mech;

    return $free;

}

sub _valid {

    my $self = shift;

    return _errors(1)
      unless $self->{'username'}
          && $self->{'username'} =~ /^96\d{7}$/;

    return _errors(2)
      unless $self->{'password'}
          && $self->{'password'} =~
          /^\w+|\W+$/;    # need to check wich characters are allowed

    return _errors(3)
      unless $self->{'targets'}
          && ref( $self->{'targets'} ) eq 'ARRAY'
          && scalar @{ $self->{'targets'} } >= 1
          && scalar @{ $self->{'targets'} } <= 5;

    return _errors(4)
      unless $self->{'message'}
          && length $self->{'message'} <= 140;

    return undef;
}

sub _errors {

    my $self = shift;
    return if !$self;

    my $errors = {
        1 => qq|Missing or invalid username\n|,
        2 => qq|Missing or invalid password\n|,
        3 => qq|Missing or invalid targets\n|,
        4 => qq|Missing or invalid message\n|,
    };

    return $errors->{$self};
}

=head1 AUTHOR

Miguel Santinho, C<< <msantinho at simplicidade.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-sms-mytmn at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-MyTMN>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

Note that this module requires www::mechanize to automate the proccess of logging in
and sending SMSs trough the www.mytmn.pt. If the operator makes any changes to
the forms they use, this module will stop working.
If that happens, please, report that to the author's e-mail.


=head1 COPYRIGHT & LICENSE

Copyright 2007 Miguel Santinho, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Net::SMS::MyTMN
