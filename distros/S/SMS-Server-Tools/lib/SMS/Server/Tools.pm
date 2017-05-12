package SMS::Server::Tools;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($ERROR);

use warnings;
use strict;

=head1 NAME

SMS::Server::Tools - parse SMS Server Tools files

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

Read file with SMS text message received by SMS Server Tools.

    use SMS::Server::Tools;

    my $file = "/path/to/smsfile";
    my $sms  = SMS::Server::Tools->new({SMSFile => $file});

    $sms->parse;

    my $sender_number      = $sms->From;
    my $datetime_sent      = $sms->Sent;
    my $datetime_received  = $sms->Received;
    my $sms_text           = $sms->Text;

=head1 DESCRIPTION

SMS::Server::Tools provides an object-oriented interface to access sms files used by the SMS Server Tools. 

The C<SMS Server Tools> send and receive short messages through GSM modems or mobile phones L<http://smstools3.kekekasvi.com>.

=head1 SMS File Format Getter

SMS::Server::Tool parse the sms file and give the access to the following sms file fields.

    $sms->Text;
    $sms->From;    
    $sms->Sent;
    $sms->Received;
    $sms->IMSI;
    $sms->From_TOA;    
    $sms->From_SMSC;
    $sms->Subject;
    $sms->Report;
    $sms->Alphabet;
    $sms->UDH;

For the complete SMS file format used by SMS Server Tools see L<http://smstools3.kekekasvi.com/index.php?p=fileformat>

=cut

use base 'Class::Accessor';

SMS::Server::Tools->mk_accessors(qw/
    SMSFile Text From To Sent Received IMSI From_TOA From_SMSC Subject Report
    Alphabet UDH
/);

=head1 METHODS

=head2 new

Create an new sms object.

=head2 SMSFile

Set path to sms file.

=head2 parse

The parse method read the sms file.

=cut

sub parse {

    my $self  = shift;

    ( ERROR "No SMSFile defined!" and die ) unless $self->SMSFile;
    
    DEBUG "start slurping -> ", $self->SMSFile;

    my @sms = _slurp($self->SMSFile);

    DEBUG "finished slurping -> ", $self->SMSFile;

    DEBUG "start parsing";

    chomp @sms; # remove last linefeed

    # We find the index of the first void line, before the text
    my $idx = (grep { $sms[$_] =~ /^$/ } 0..$#sms)[0];

    # We collect the multiple lines into text
    $self->{'Text'} = join("\n", @sms[$idx+1..$#sms]);
    
    DEBUG "parsed Text: $self->{'Text'}";

    foreach (@sms[0..$idx-1]) {
		            
        # get sms header fields
        my ($key, $value) = split/: /;
        $self->{$key} = $value;
        DEBUG "parsed $key: $self->{$key}";

    }

    DEBUG "finished parsing";
}

=head2 write

The write method write the sms file.

=cut

sub write {

    my $self  = shift;

    ( ERROR "No SMSFile defined!" and die ) unless $self->SMSFile;
    ( ERROR "No To defined!" and die )      unless $self->To;
    ( ERROR "No Text defined!" and die )    unless $self->Text;

    # check 160 chars of Text
    # SMS Server Tools can split large message
    my $text_length = length($self->Text);
    my $length_error = "Text has More than 160 chars!";
    ( ERROR $length_error and die ) unless ( $text_length <= 160 );

    my $outfile = $self->SMSFile;

    open(SMS, '>', $outfile) or die "can't open $outfile";

    print SMS "To: ", $self->To, "\n";
    print SMS "\n";
    print SMS $self->Text, "\n";

    close(SMS);

}

sub _slurp {

    local( $/, @ARGV ) = ( wantarray ? $/ : undef, @_ );
    return <ARGV>;

}

=head1 AUTHOR

Thomas Lenz, C<< <tholen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-sms-server-tools at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SMS-Server-Tools>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

For more Information about SMS Server Tools follow this links.

L<http://smstools3.kekekasvi.com/>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SMS::Server::Tools


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SMS-Server-Tools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SMS-Server-Tools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SMS-Server-Tools>

=item * Search CPAN

L<http://search.cpan.org/dist/SMS-Server-Tools/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Thomas Lenz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of SMS::Server::Tools
