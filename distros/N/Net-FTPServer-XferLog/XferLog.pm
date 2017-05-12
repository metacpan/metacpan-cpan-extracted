package Net::FTPServer::XferLog;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::FTPServer::XferLog ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '1.5';


# Preloaded methods go here.

# unused. was going to be strict about the parse. but it is
# time-consuming and harder to debug.

my $day_name  = qr/\w{3}/;      my $month     = qr/\w{3}/;
    my $day       = qr/\d{1,2}/;    my $time      = qr/\d{2}:\d{2}\d{2}/;
    my $year      = qr/\d{4}/;      my $xfer_time   = qr/\d+/;
    my $remote_host = qr/.*/;       my $bytes_xfer  = qr/\d+/;
    my $filename    = qr/(\w|[.])+/;my $xfer_type   = qr/([ab])/;
    my $special_act = qr/([CUT_])+/;my $direction   = qr/(o|i)/;
    my $access_mode = qr/(a|g|r)/;  my $user_name   = qr/\w+/;
    my $svc_name    = qr/ftp/;      my $auth_method = qr/(0|1)/;
    my $auth_userid = qr/([*]|\w+)/;my $status      = qr/(c|i)/;


our @field = qw(day_name month day current_time  year  transfer_time
		   remote_host     file_size  filename   transfer_type   
		   special_action_flag    direction access_mode username   
		   service_name    authentication_method  authenticated_user_id
		   completion_status);


sub parse_line {
    my $self = shift;   my $line = shift or die "must supply xferlog line";

    my %field;

    my @field = @field;

    my @tmp = split /\s+/, $line;
    if (scalar @tmp == scalar @field) {
	@field{@field} = @tmp;
    } else {
	for (@field) {
	    last if $_ eq 'filename';
	    $field{$_} = shift @tmp;
	}
		
	@field = reverse @field;
	@tmp   = reverse @tmp;

	for (@field) {
	    last if $_ eq 'filename';
	    $field{$_} = shift @tmp;
	}

	@tmp = reverse @tmp ;
	$field{filename} = "@tmp";
    }



#    map { print "$_ => $field{$_} \n" } @field;
#    print "-------------------";
    \%field;
}
		   

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::FTPServer::XferLog - parse FTP server xfer logs.

=head1 SYNOPSIS

# XFERLOG file:

 Mon Oct  1 17:09:23 2001 0 127.0.0.1 2611 1774034 a _ o r tmbranno ftp 0 * c
 Mon Oct  1 17:09:27 2001 0 127.0.0.1 22 1774034 a _ o r tmbranno ftp 0 * c
 Mon Oct  1 17:09:31 2001 0 127.0.0.1 7276 p1774034_11i_zhs.zip a _ o r tmbranno ftp 0 * c

# parse xfer log PROGRAM:

 use Net::FTPServer::XferLog;
 open T, 'test.xlog' or die $!;
 my $hashref;
 while (<T>) {
   $hashref = Net::FTPServer::XferLog->parse_line($_);
   map { print "$_ => $hashref->{$_} \n" } @Net::FTPServer::XferLog::field;
   print "-------------------";

 }

# OUTPUT

 day_name => Mon 
 month => Oct 
 day => 1 
 current_time => 17:09:23 
 year => 2001 
 transfer_time => 0 
 remote_host => 127.0.0.1 
 file_size => 2611 
 filename => 1774034 
 transfer_type => a 
 special_action_flag => _ 
 direction => o 
 access_mode => r 
 username => tmbranno 
 service_name => ftp 
 authentication_method => 0 
 authenticated_user_id => * 
 completion_status => c 
 -------------------
 day_name => Mon 
 month => Oct 
 day => 1 
 current_time => 17:09:27 
 year => 2001 
 transfer_time => 0 
 remote_host => 127.0.0.1 
 file_size => 22 
 filename => 1774034 
 transfer_type => a 
 special_action_flag => _ 
 direction => o 
 access_mode => r 
 username => tmbranno 
 service_name => ftp 
 authentication_method => 0 
 authenticated_user_id => * 
 completion_status => c 
 -------------------
 day_name => Mon 
 month => Oct 
 day => 1 
 current_time => 17:09:31 
 year => 2001 
 transfer_time => 0 
 remote_host => 127.0.0.1 
 file_size => 7276 
 filename => p1774034_11i_zhs.zip 
 transfer_type => a 
 special_action_flag => _ 
 direction => o 
 access_mode => r 
 username => tmbranno 
 service_name => ftp 
 authentication_method => 0 
 authenticated_user_id => * 
 completion_status => c 
 -------------------



=head1 DESCRIPTION

This parses xferlog(5) files into Perl hashrefs. The fields returned are
shown in the synopsis. Note that the standard C<current-time> field is
returned as 5 separate fields here: day_name, month, day, current_time,
year.

=head2 EXPORT

None by default.


=head1 AUTHOR

T. M. Brannon <tbone@cpan.org>

Thanks to 

=over 4 

=item * Nic Heier for a doc fix.

=item * Mike Edwards for pointing out a bug when parsing files with spaces in their name.

=item * Zoltan Monori for pointing a bug in my code which parsed files with spaces in them the very next day!

=back

=head1 SEE ALSO

=over 4

=item * Net::FTPServer - secure, extensible Perl FTP Server

=item * www.FAQS.org - FTP RFC is here

=item * wu-ftpd, proftpd. These FTP servers started this xferlog syntax,
Net::FTPServer supports it.

=item * slicker solutions to dealing with filenames with many spaces

L<http://perlmonks.org/?node_id=632864>

=back

=cut
