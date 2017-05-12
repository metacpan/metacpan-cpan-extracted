package Net::PSYC::FileShare;

use base 'Exporter';
use Net::PSYC::Tie::AbbrevHash;
use Net::PSYC qw(W send_file);
use Fcntl qw(:seek :DEFAULT);

use strict;

# to some extend similar to Net::PSYC::Client. offers simple functions 
my (%method, @share_dir, @temp_dir, $store_dir);
our @EXPORT = qw(set_store_dir msg);

sub set_store_dir {
    my $dir = shift;
    return 0 unless (-d $dir && -w $dir);

    $store_dir = $dir;
    return $dir;
}

sub msg {
    my ($source, $mc, $data, $vars) = @_;
    
    if (exists $method{$mc}) {
	return $method{$mc}->(@_);
    }
    return;
}

tie %method, 'Net::PSYC::Tie::AbbrevHash';

%method = (
'_data_file' => sub {
    my ($source, $mc, $data, $vars) = @_;

    my $filename = $vars->{'_name_file'};
    my $hash = $vars->{'_hash'};
    my $t;
    my $seek = int($vars->{'_seek_resume'});
    my $size = int($vars->{'_size_file'});
    my $range = int($vars->{'_size_resume'});

    if ($seek + $range > $size) {
	sendmsg($source, '_error_file_size', 'Something is very wrong about the size of your file.');
	return 0;
    }

    unless ($filename ||= $hash) {
	sendmsg($source, '_error_file_identification', 'Your fancy file of yours does not have any name!??');
	return 0;
    }

    if (length($data) != ($range || ($size - $seek))) {
	sendmsg($source, '_error_file_size', 'Something is very wrong about the size of the data you sent.');
	return 0;
    }

    unless ($range || $seek) {
	while (-e $store_dir.'/'.$filename.$t) {
	    $t++;
	}
	$filename = $store_dir.'/'.$filename.$t;
	$t = O_EXCL;
    } else {
	$filename = $store_dir.'/'.$filename;
	if (-e $filename && -s $filename != $size) {
	    W0('the actual size of %s on your hd does not match the transfered file', $filename);
	    return 0;
	}
	$t = 0;
    }
    
    # this is blocking and evil. but i dont care for now.
    # we could use buffered writes.. and still use sysopen. maybe
    # a very good idea ,)
    local *FH;
    sysopen(*FH, $filename, O_WRONLY|O_NOFOLLOW|O_CREAT|$t) or do {
	W0('Could not open file %s. sysopen said: %s', $filename, $!);
	return 0;
    };
    binmode(*FH);

    if ($seek) {
	sysseek(*FH, $seek, SEEK_SET);
    }

    syswrite(*FH, $data);
    close(*FH);
},

);

