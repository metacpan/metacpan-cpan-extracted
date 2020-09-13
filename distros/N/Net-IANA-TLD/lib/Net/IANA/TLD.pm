package Net::IANA::TLD;

use 5.006;
use strict;
use warnings;
use LWP::Simple;

=head1 NAME

Net::IANA::TLD - IANA TLDs database

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

IANA TLDs database


    use Net::IANA::TLD;

    # for each new(), the latest TLD data will be downloaded from IANA's website
    # you should cache the object
    my $tld = Net::IANA::TLD->new();

    print $tld->version, "\n";
    print $tld->date, "\n";
    print $tld->size, "\n";

    # validate if a given TLD exists
    my $given_tld = "com";
    print "The TLD $given_tld exists\n" if $tld->has_tld($given_tld);


    # dump all tlds
    use Data::Dumper;
    my $hash_ref = $tld->tlds;
    print Dumper $hash_ref;


=head1 SUBROUTINES/METHODS

=head2 new

    my $tld = Net::IANA::TLD->new();

=cut

sub new {

    my $class = shift;
    my $iana_data = "http://data.iana.org/TLD/tlds-alpha-by-domain.txt";
    my $res = get($iana_data) || die "can't fetch $iana_data";

    my %hash;
    my $version = "";
    my $date = "";

    my @res = split/\n/,$res;
    my $copyright = shift @res;

    if ($copyright =~ /Version (\d+), Last Updated (.*)$/) {
        $version = $1;
        $date = $2;
    }

    my $size = scalar @res;

    for (@res) {    
        next if /^#/;
        $hash{$_}=1;
    }

    bless {version=>$version, date=>$date, size=>$size, tlds=>\%hash}, $class;
}


=head2 verison

    $tld->version;

=cut

sub version {

    my $self = shift;
    $self->{'version'};

}

=head2 date

    $tld->date;

=cut

sub date {

    my $self = shift;
    $self->{'date'};

}

=head2 size

    $tld->size;

=cut

sub size {

    my $self = shift;
    $self->{'size'};

}


=head2 tlds

    # fetch all tlds
    my $hash_ref = $tld->tlds;

=cut

sub tlds {

    my $self = shift;
    $self->{'tlds'};

}

=head2 has_tld

    # return undef if given tld not exists
    my $res = $tld->has_tld($given_tld);

=cut

sub has_tld {
    my $self = shift;
    my $key = shift;
    $key = uc($key);

    return exists($self->{tlds}->{$key}) ? 1 : undef;
}


=head1 AUTHOR

Wesley Peng, C<< <wesley at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-iana-tld at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-IANA-TLD>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::IANA::TLD


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-IANA-TLD>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Net-IANA-TLD>

=item * Search CPAN

L<https://metacpan.org/release/Net-IANA-TLD>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2020 by Wesley Peng.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Net::IANA::TLD
