package OpenSSH::Fingerprint;

use 5.006;
use strict;
use warnings;
use Digest::MD5;
use MIME::Base64;
use Crypt::Digest::SHA256;

our @ISA    = qw(Exporter);
our @EXPORT = qw(unbase64 md5_sum sub sha256);

=head1 NAME

OpenSSH::Fingerprint - The great new OpenSSH::Fingerprint!

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

     use OpenSSH::Fingerprint;
     use use MIME::Base64;

     my $file=shift;
     my $resutlt= unbase64($file);

     print "md5 fingerpint: ",md5_sum($_ ),"\n" for(@{$resutlt}); 
     print "sha265 fingleprint: ",encode_base64(sha256($_ )) for(@{$resutlt});


The result

   perl sshfingerprint.pl aaa.pub

   md5 fingerpint: 4b:12:23:8a:95:rt:ec:da:43:fc:aa:0b:1a:e6:6a:2f
   sha265 fingleprint: sfeQQGLlTi5j69KMzEkLmK9f78/CGtVk2a8N8pDfV88=...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut
sub unbase64 {

    my ( $file_name) = @_;
    my ( $FD, $mydstr, $md5 );
    open( $FD, $file_name ) or warn  "Can't open $file_name !";

    while(<$FD>) {
    next if /#^/;
    next unless (split)[1];
    push  @{$mydstr},decode_base64((split)[1]);

    }
    
return $mydstr;
}


sub md5_sum {

    my $key = shift;
    my  $ctx = Digest::MD5->new;
    $ctx->add($key);
    my  $md5 = $ctx->hexdigest;
    $md5=~s/(..)/$1:/g;
    $md5=~s/:$//;
   return $md5;
}

sub sha256 {

    my $key = shift;
    my  $ctx =  Crypt::Digest::SHA256->new;
    $ctx->add($key);
    my  $md5 = $ctx->digest;
   return $md5;
}


=head1 AUTHOR

ORANGE, C<< <bollwarm at ijz.me> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-openssh-fingerprint at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=OpenSSH-Fingerprint>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc OpenSSH::Fingerprint


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=OpenSSH-Fingerprint>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/OpenSSH-Fingerprint>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/OpenSSH-Fingerprint>

=item * Search CPAN

L<http://search.cpan.org/dist/OpenSSH-Fingerprint/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 ORANGE.

This program is released under the following license: Perl


=cut

1; # End of OpenSSH::Fingerprint
