package PagSeguro::Status;

use Moose;
use WWW::Mechanize;
use DateTime;

has 'mechanize' => (
    isa     => 'Object',
    is      => 'ro',
    default => sub { WWW::Mechanize->new( agent_alias => 'Windows IE 6' ) }
);

=head1 NAME

PagSeguro::Status - To know informations about PagSeguro payments!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use PagSeguro::Status;
    my $a = PagSeguro::Status->new(
        paglogin => 'youruser@...',
        pagpass  => 'youpass...'
		from_date => dd/mm/yyyy
		to_date => dd/mm/yyyy
    );
    print $a->fetch_xml #returns a XML;

If you do not give the argument "from_date" and "to_date" the default is 1 month.

=cut

has 'paglogin' => ( is => 'rw', required => 1, isa => 'Str' );
has 'pagpass'  => ( is => 'rw', required => 1, isa => 'Str' );
has 'from_date' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { DateTime->now->subtract( months => 1 )->dmy('/') }
);
has 'to_date' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { DateTime->now->dmy('/') }
);

=head2 login

Do the login

=cut

sub login {
    my $self = shift;
    $self->mechanize->get('https://pagseguro.uol.com.br/');
    $self->mechanize->submit_form(
        form_number => 1,
        fields      => {
            userName => $self->paglogin,
            password => $self->pagpass,
        }
    );
}

=head2 get_days

Get the information between from_date and to_date.

=cut

sub get_days {
    my $self = shift;
    $self->mechanize->get(
        'https://pagseguro.uol.com.br/transaction/search.jhtml');
    $self->mechanize->submit_form(
        form_number => 1,
        fields      => {
            dateFrom => $self->from_date,
            dateTo   => $self->to_date
        }
    );
    return 1;
}

=head2 xml_generate

To generate the XML

=cut

sub xml_generate {
    my $self = shift;
    $self->mechanize->get(
        'https://pagseguro.uol.com.br/transaction/createFile.jhtml?fileType=xml'
    );
    if ( $self->mechanize->content =~ /ok\|(.+?)\n/ ) {
        my $xml_name = $1;
        return $xml_name;
    }
    else {
        die "could not take the xml name";
    }
}

before 'fetch_xml' => sub { my $self = shift; $self->login; $self->get_days };

=head2 fetch_xml

Fetch the xml, returns a XML :D

=cut

sub fetch_xml {
    my $self     = shift;
    my $xml_name = $self->xml_generate;

    # PagSeguro is really sux, maybe have to wait some seconds
    # to generate de XML
    sleep 5;

    $self->mechanize->get(
        'https://pagseguro.uol.com.br/transaction/sendFile.jhtml?fileName='
          . $xml_name );
    return $self->mechanize->content;
}

=head1 AUTHOR

Daniel de Oliveira Mantovani, C<< <daniel.oliveira.mantovani at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pagseguro-status at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=PagSeguro-Status>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PagSeguro::Status


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=PagSeguro-Status>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/PagSeguro-Status>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PagSeguro-Status>

=item * Search CPAN

L<http://search.cpan.org/dist/PagSeguro-Status/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Daniel de Oliveira Mantovani.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

666;    # PagSeguro is the devil!
