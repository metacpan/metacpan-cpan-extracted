

package Net::FTP::blat;

use strict;
use Carp;

use vars '$VERSION';

$VERSION = 0.03;

sub Net::FTP::slurp
# store a remote file to a scalar
# syntax: $ftpobj->slurp($remote_file_name [, $lvalue ] )
{
 my($ftp,$remote) = @_[0,1];
 my $target = ( exists($_[2])? \$_[2] : \(my $foo));

 my($len,$buf,$resp,$data);

 croak("Bad remote filename '$remote'\n")
	if $remote =~ /[\r\n]/s;

 delete ${*$ftp}{'net_ftp_port'};
 delete ${*$ftp}{'net_ftp_pasv'};

 unless( $data = $ftp->retr($remote)){
 	$^W and carp "could not retr [$remote]";
	$$target=undef;
	return undef;
 };

 $buf = '';
 my($count) = (0);

 my $blksize = ${*$ftp}{'net_ftp_blksize'};
 local $\; # Just in case

 my @pieces = ();
 while(
   $data->read($buf,$blksize)
 ){
   push @pieces, $buf;
  };

  $data->close(); # implied $ftp->response
  if (defined(wantarray)){
  $$target = my $result =  join('',@pieces);
  return $result
  };

  $$target = join('',@pieces);

};

sub Net::FTP::blat 
# STOR a scalar to a remote file
# syntax: $ftpobj->blat($value,$remote)
{
 my($ftp,$remote) = @_[0,2];
 my $value = \$_[1];
 
 my($sock,$len,$buf);

 unless(defined $remote)
  {
   croak 'Must specify remote filename with stream input';
  };

 # ALLO
 $ftp->_ALLO( length $$value);
  
 croak("Bad remote filename '$remote'\n")
	if $remote =~ /[\r\n]/s;

 delete ${*$ftp}{'net_ftp_port'};
 delete ${*$ftp}{'net_ftp_pasv'};

 $sock = $ftp->_data_cmd('STOR', $remote) or 
 	croak "failure of STOR [$remote] data_cmd";

 #
 #chunking really only makes sense when we're reading
 #from disk and sending. Since we're sending a scalar,
 #we can avoid multiple substr calls , each of which
 #will need to do a full FETCH on a tied scalar, and just
 #write the whole thing at once.
 #
 # my $blksize = ${*$ftp}{'net_ftp_blksize'};
 #
 # my($pos) = (0);
 #
 # while(
 #   $len = length ( $buf = substr ( $$value, $pos, $blksize))
 #  ){
 # 
 #    my $wlen;
 #    unless(defined($wlen = $sock->write($buf,$len)) && $wlen == $len)
 #     {
 #      $sock->abort;
 #      croak "only wrote $wlen of $len  data to FTP data channel at [$remote]:$pos\n";
 #     }
 #     $pos += $len;
 #   }

     $len = length $$value;
     my $wlen;
     unless(defined($wlen = $sock->write($$value,$len))
         && $wlen == $len)
      {
       $sock->abort;
       croak "only wrote $wlen of $len  data to FTP data channel at [$remote] ";
      }
      
 $sock->close();

 $$value;
 
}


__END__

=head1 NAME

Net::FTP::blat - more methods for Net::FTP Client class

=head1 SYNOPSIS

    use Net::FTP;
    use Net::FTP::blat;

    # See Net::FTP for how to set up connection
    
    # get a remote file to a scalar
    $ftp->slurp(README => my $readme);

    # put a scalar to a remote file
    $ftp->blat( $blog_entry_text, "entry: ".localtime );

=head1 DESCRIPTION

C<Net::FTP::blat> contains two additional methods for L<Net::FTP>.

=head1 OVERVIEW

C<slurp> and C<blat> were written by altering C<get> and C<put> from
Net::FTP to use a scalar instead of a local file for the local side
of the transfer.


=head1 METHODS

=over 4

=item slurp ( REMOTE_FILE [, LOCAL_SCALAR ] )

Slurp C<REMOTE_FILE> from the server and store locally, into a scalar
variable. Returns the value too, if you don't want to pass the
destination in. Croaks on all errors. Warns on file-not-found before
assigning undef, if warnings are in effect.

=item blat ( LOCAL_SCALAR, REMOTE_FILE )

Blat the local scalar into the named file on the remote server. The
remote name is required. Returns the scalar, for use in assignment
chaining.  Croaks on errors.

=back

=head1 Net::FTP error messages

Net::FTP error messages are not imported into the croak exceptions
at this version.  They may be in the future.

=head1 The Future

I would like to see C<slurp> and C<blat> included in the Net::FTP
distribution.  I was surprised that they (or equivalents)
were not included.

=head1 AUTHOR

David Nicol <davidnico@cpan.org>

=head1 SEE ALSO

L<Net::FTP>

L<Tie::FTP>

L<Net::FTP::Common>

L<IO::FTP>

=head1 CREDITS

These methods are derived from the get and put methods in Net::FTP, 
by Graham Barr.

=head1 COPYRIGHT

Copyright 2003,2013 David Nicol

These methods are free software; you can redistribute and/or modify
them under the same terms as Perl itself.

Version 0.03 issues a spurious PASS for all tests when the hardcoded
FTP server that has been getting small test files blatted to it for
the last decade is down.

If you would like to propose modifications (such as integrating
a pure-perl FTP server running on localhost into the testing) this
module may be cloned from https://github.com/davidnicol/cpan-Net-FTP-blat


=cut
