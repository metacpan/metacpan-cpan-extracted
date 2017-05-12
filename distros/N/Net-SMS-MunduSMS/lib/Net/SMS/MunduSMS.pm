package Net::SMS::MunduSMS;

use 5.008008;
use strict;
use warnings;
use WWW::Mechanize;

our $VERSION = '0.021';

sub new {
    my $class = shift;
    my %args  = @_;

    $class = ref $class || $class;

    my %params = %args;

    $params{sms} = [];
    $params{mech} = WWW::Mechanize->new( onerror => sub { } );
    $params{mech}->agent_alias('Windows IE 6');

    return bless \%params, $class;
}

sub _login {
    my $self = shift;

    $self->{mech}->get(q[http://www.mundusms.com/web/Login.aspx]);
    $self->{mech}->form_number(1);

    map { $_->value( $self->{username} ); } $self->{mech}->find_all_inputs(
        type       => 'text',
        name_regex => qr/user_login$/,
    );

    map { $_->value( $self->{password} ); } $self->{mech}->find_all_inputs(
        type       => 'password',
        name_regex => qr/user_pass$/,
    );

    $self->{mech}->submit_form(
        fields => {
            '__EVENTARGUMENT'                                    => '',
            '__EVENTTARGET'                                      => '',
            '__LASTFOCUS'                                        => '',
            'ctl00$ContentPlaceHolderMasterLogin$button_login.x' => 10,
            'ctl00$ContentPlaceHolderMasterLogin$button_login.y' => 14,
            'ctl00$dropCulture'                                  => 1
        }
    );

    return ( $self->{mech}->uri =~ /UserHome.aspx$/ ) ? 1 : 0;

    return 0 unless ( $self->{mech}->find_link( url_regex => qr/sendsms.aspx/i ) && $self->{mech}->follow_link( url_regex => qr/sendsms.aspx/i ) );
}

sub add_sms {
    my $self = shift;
    my %args = @_;

    push( @{ $self->{sms} }, \%args );

    return 1;
}

sub send_sms {
    my $self = shift;

    $self->{logged_in} = $self->_login unless ( $self->{logged_in} );

    while ( my $sms = pop( @{ $self->{sms} } ) ) {
        $self->{mech}->follow_link( url_regex => qr/sendsms.aspx/i ) unless ( $self->{mech}->uri =~ /sendsms.aspx/i );

        $self->{mech}->form_number(1);

        map { $_->value( $sms->{to} ); } $self->{mech}->find_all_inputs(
            type       => 'textarea',
            name_regex => qr/mobileno$/,
        );

        map { $_->value( $sms->{message} ); } $self->{mech}->find_all_inputs(
            type       => 'textarea',
            name_regex => qr/msg$/,
        );

        my $len = sprintf( '%d characters, %d SMS', length( $sms->{message} ), ( int( length( $sms->{message} ) ) / 160 ) + 1 );

        $self->{mech}->submit_form(
            fields => {
                '__EVENTARGUMENT'                                     => '',
                '__EVENTTARGET'                                       => '',
                '__LASTFOCUS'                                         => '',
                'ctl00$ContentPlaceHolderContent$button_submit_sms.x' => 15,
                'ctl00$ContentPlaceHolderContent$button_submit_sms.y' => 6,
                'ctl00$ContentPlaceHolderContent$InfoCharCounter'     => $len,
                'ctl00$ContentPlaceHolderContent$hiddenCharCount'     => $len,
                'ctl00$ContentPlaceHolderContent$Hiddenselected'      => 0,
                'ctl00$ContentPlaceHolderContent$HiddenUnicode'       => 0,
                'ctl00$ContentPlaceHolderContent$DropDown_groups'     => 0,
                'ctl00$ContentPlaceHolderContent$Cal_to_ClientStat'   => '',
                'ctl00$ContentPlaceHolderContent$HiddenScheduled_id'  => '',
                'ctl00$ContentPlaceHolderContent$Hidden_date'         => '',
                'ctl00$ContentPlaceHolderContent$Hidden_time'         => '',
                'ctl00$ContentPlaceHolderContent$Drop_repeat'         => '',
                'ctl00$ContentPlaceHolderContent$hidden_charcount'    => length( $sms->{message} ),
                'ctl00$ContentPlaceHolderContent$txt_date'            => '',
                'ctl00$ContentPlaceHolderContent$txt_time'            => '',
                'hiddenInputToUpdateATBuffer_CommonToolkitScripts'    => 0
            }
        );
    }

    return 1;
}

1;

__END__

=head1 NAME

Net::SMS::MunduSMS - Perl interface for sending SMS using the mundusms.com service.

=head1 VERSION

Version 0.021

=head1 SYNOPSIS

  use Net::SMS::MunduSMS;
  my $m = Net::SMS::MunduSMS->new(username => '919988445566' ,password => 'passme' );

  $m->add_sms(to => '+919866544992', message => 'hello');
  $m->send_sms;

=head1 DESCRIPTION

The Net::SMS::MunduSMS Perl module allows you to send SMS in your Perl code, using the paid service of mundusms.com

=head2 METHODS

=item new

Constructor, requires two named arguments namely the username & the password for the mundusms.com account.

=item add_sms

Add sms to the internal queue, it take two named arguments, to & message.

=item send_sms

Send the queued messages stored internally.

=head1 REQUIRES

L<WWW::Mechanize>

=head1 SEE ALSO

L<Net::SMS::WAY2SMS>

=head1 AUTHOR

S Pradeep, E<lt>spradeep@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-sms-mundusms at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-SMS-MunduSMS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SOURCE

Git repository at http://github.com/spradeep/Perl-Net-SMS-MunduSms

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::SMS::MunduSMS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-SMS-MunduSMS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-SMS-MunduSMS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-SMS-MunduSMS>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-SMS-MunduSMS/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by S Pradeep

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
