package IKC_d_Localtime;

our $timelocal = scalar(localtime);

sub timelocal {
	return $timelocal;
}

1;
