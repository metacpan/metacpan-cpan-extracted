package PEF::Front::File;
use strict;
use warnings;
use File::Basename;
use PEF::Front::Config;

my $uid_func = $INC{'Coro/AnyEvent.pm'}
	? sub {
	no warnings 'once';
	"$Coro::current" =~ /(0x[0-9a-f]+)/i;
	$$ . '-' . hex $1;
	}
	: sub {
	$$
	};

sub new {
	my ($class, %args) = @_;
	my $upload_path = cfg_upload_dir . '/' . $uid_func->();
	if (!-d $upload_path) {
		mkdir($upload_path, 0700)
			or die {
			result => 'INTERR',
			answer => "Misconfigured upload directory: $!"
			};
	}
	my $fname = $args{filename} || 'unknown_upload';
	my ($name, $path, $suffix) = fileparse($fname, q|\.[^\.]*|);
	if (-e "$upload_path/$name$suffix") {
		my $i = 1;
		++$i while -e "$upload_path/$name.$i$suffix";
		$fname = "$name.$i$suffix";
	}
	my $self = bless {
		content_type => $args{content_type},
		upload_path  => $upload_path,
		size         => (delete $args{size}) || -1,
		filename     => $fname,
	}, $class;
	open(my $fh, "+>", "$self->{upload_path}/$self->{filename}")
		or die {
		result => 'INTERR',
		answer => "Misconfigured upload directory: $!"
		};
	binmode $fh;
	$self->{fh} = $fh;
	$self;
}

sub filename     {$_[0]->{filename}}
sub size         {$_[0]->{size}}
sub content_type {$_[0]->{content_type}}
sub upload_path  {$_[0]->{upload_path}}

sub append {
	my $self = $_[0];
	return if $_[1] eq '';
	my $rc = syswrite($self->{fh}, $_[1]);
	die {result => 'INTERR', answer => "Failed upload: $!"} if not defined $rc;
	die {
		result => 'INTERR',
		answer => "Partial upload write: $rc != " . length $_[1]
		}
		if $rc != length $_[1];
}

sub finish {
	my $self = $_[0];
	my $size = sysseek($self->{fh}, 0, 2);
	$self->{size} = $size;
}

sub value {
	my $self = $_[0];
	sysseek($self->{fh}, 0, 0);
	my $ret = '';
	sysread($self->{fh}, $ret, -s $self->{fh});
	return $ret;
}

sub fh {$_[0]->{fh}}

sub DESTROY {
	my $self = $_[0];
	close($self->{fh});
	$self->{fh} = undef;
	unlink "$self->{upload_path}/$self->{filename}";
	my $dir;
	opendir $dir, $self->{upload_path} and do {
		my @rest = grep {$_ ne '.' and $_ ne '..'} readdir $dir;
		rmdir $self->{upload_path} if !@rest;
	};
}

1;

__END__

=head1 NAME

B<PEF::Front::File> - File class for uploaded files

=head1 DESCRIPTION

This class is used to handle uploaded files.

=head1 FUNCTIONS

=head2 new(%args)

This is constructor. Following arguments are supported:

=over

=item filename

Name of file.

=item content_type

Content-Type from HTTP headers.

=item size

Content-Length from HTTP headers.

=back

It creates file in some subdirectory in B<cfg_upload_dir>.

=head2 content_type

Returns Content-Type.

=head2 size

Returns size of file. It returns actual size when upload is finished.

=head2 fh

Returns file handle.

=head2 filename

Returns filename.

=head2 finish

This function is called when upload is finished.

=head2 upload_path

Returns subdirectory where file is located.

=head2 value

Reads the whole file in variable and returns it.

=head2 append

Appends file content.

=head1 AUTHOR
 
This module was written and is maintained by Anton Petrusevich.

=head1 Copyright and License
 
Copyright (c) 2016 Anton Petrusevich. Some Rights Reserved.
 
This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
