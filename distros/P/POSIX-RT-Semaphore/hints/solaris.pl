# Adapted from Time::HiRes
use POSIX qw(uname);
if (substr((uname())[2], 2) <= 6) {
	$self->{LIBS} = ['-lposix4'];
	$self->{DEFINE} = psem_define('-lposix4');
}
