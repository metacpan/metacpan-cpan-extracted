package Net::YASA;

use warnings;
use strict;
use utf8;

use Encode qw/encode decode/;
use LWP::UserAgent;

=head1 NAME

Net::YASA - Interface to YASA (Yet Another Suffix Array)

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $AUTOLOAD;
our %ok_field;

for my $attr ( qw(content minfreq minlength ) ) { $ok_field{$attr}++; }

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;
    return if $attr eq 'DESTROY';

    if ($ok_field{$attr}) {
	$self->{lc $attr} = shift if @_;
	return $self->{lc $attr};
    } else {
	my $superior = "SUPER::$attr";
	$self->$superior(@_);
    }
}

use constant YASA_WEB_URL => 'http://yasa.newzilla.org/run/';
=head1 SYNOPSIS

This module will submit content to the YASA WebService to return
a list of terms and corresponding frequencies.

    use Net::YASA;

    my $foo = Net::YASA->new();
    my $termset = $foo->extract(<some_of_utf8_words>);
    print 'TermSet 1: ', $$termset[0], "\n";
    print 'TermSet 2: ', $$termset[1], "\n";
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 METHODS

=head2 new

=cut

sub new {
    my $class = shift;
    my $self = {
	_ua => undef,
	minlength => 1,
	minfreq => 2,
	output => 'xml',
	_content => undef
    };
    if(@_) {
	my %arg = @_;

	foreach (keys %arg) {
	    $self->{lc($_)} = $arg{$_};
	}
    }
    $self->{_ua} = LWP::UserAgent->new;
    $self->{_ua}->timeout(30);
    $self->{_ua}->agent('CPAN::Net::YASA');
    bless($self, $class);
    return($self);
}

=head2 extract

=cut

sub extract {
    my ($self, $content) = @_;
    die 'No content specified' unless $content ne "";
    my $ua = $self->{_ua};
    my $response = $ua->post(
	YASA_WEB_URL.$self->{output}."/",
	{   
	    'min' => $self->minlength,
	    'freq' => $self->minfreq,
	    'content' => encode("utf8",$content), 
	}
    );
    die "Error in extracting data from YASA!\n" unless $response->is_success();
    if ($self->{output} eq "json" and eval {
	    require JSON::Any;
	    1;
	}) {
	my $result = $response->content();
        my $j = JSON::Any->new;

	my $data = $j->decode($result);
	return $data;
    } 
    else {
	my $xml = decode("utf8",$response->content());
	my @results = ();
	while ($xml =~ m#<Term>([^<]*)</Term><Freq>(\d+)</Freq>#g) {
	    push @results, $1."\t".$2;
	}
        return \@results;
    }
}

=head1 AUTHOR

Cheng-Lung Sung, C<< <clsung at FreeBSD.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-yasa at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-YASA>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

YASA (Yet Another Suffix Array) web site: L<http://yasa.newzilla.org>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::YASA

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-YASA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-YASA>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-YASA>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-YASA>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Cheng-Lung Sung, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Net::YASA
