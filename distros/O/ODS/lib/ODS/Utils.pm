package ODS::Utils;

use YAOO;
no strict 'refs';
use Data::GUID;
use File::Copy qw/move/;
use Carp qw/croak/;
use Scalar::Util qw//;
use Data::Dumper qw/Dumper/;
use Email::Valid;
use Phone::Valid::International::Loose qw/valid_phone/;

our ( %EX, %EX2);

BEGIN {
	%EX = (
		load => [qw/all/],
		clone => [qw/all/],
		unique_class_name => [qw/all/],
		build_temp_class => [qw/all/],
		move => [qw/all/],
		deep_unblessed => [qw/all/],
		valid_email => [qw/all/],
		valid_phone => [qw/all/],
		reftype => [qw/all/],
		read_file => [qw/all file_dir/],
		write_file => [qw/all file_dir/],
		read_directory => [qw/all file_dir/],
		write_directory => [qw/all file_dir/],
		croak => [qw/error/],
		Dumper => [qw/error/]
	);
	for my $ex (keys %EX) {
		for (@{ $EX{$ex} }) {
			push @{ $EX2{$_} }, $ex;
		}
	}
}

sub import {
	my ($self, @functions) = @_;

	my $caller = caller();

	for my $fun (@functions) {
		if ($EX{$fun}) {
			YAOO::make_keyword($caller, $fun, *{"${self}::${fun}"});
		} elsif ($EX2{$fun}) {
			for (@{ $EX2{$fun} }) {
				YAOO::make_keyword($caller, $_,  *{"${self}::${_}"});
			}
		}
	}

}

sub valid_email {
	Email::Valid->address(shift);
}

sub clone {
	my ($c) = @_;
	my $n = bless YAOO::deep_clone_ordered_hash($c), ref $c;
	return $n;
}

sub load {
	my ($module) = shift;
	(my $require = $module) =~ s/\:\:/\//g;
	require $require . '.pm';
	return $module;
}

sub unique_class_name {
	return 'A' . join("", split("-", Data::GUID->new->as_string()));
}

sub build_temp_class {
	my ($class) = @_;
	load $class;
	my $temp = $class . '::' . unique_class_name();
	my $c = sprintf(
		q|
			package %s;
			use YAOO;
			extends '%s';
			1;
		|, $temp, $class );
	eval $c;
	return $temp;
}

sub deep_unblessed {
	my ($obj) = @_;
	$obj = YAOO::deep_clone($obj);
	return $obj;
}

sub read_file {
	my ($file) = @_;
	open my $fh, '<:encoding(UTF-8)', $file or croak "Cannot open the file for reading: $file $!";
	my $data = do { local $/; <$fh> };
	close $fh;
	return $data;
}

sub write_file {
	my ($file, $data) = @_;
	write_directory($file, 1);
	open my $fh, '>:encoding(UTF-8)', $file or croak "Cannot open the file for writing: $file $!";
	print $fh $data;
	close $fh;
	return $file;
}

sub read_directory {
	my ($directory) = @_;
	opendir(my $dh, $directory) or croak "Cannot open directory: $directory $!";
	my @files = sort { $a cmp $b } grep { $_ !~ m/^\./ } readdir($dh);
	closedir $dh;
	return @files;
}

sub write_directory {
	my ($directory, $pop) = @_;
	my @dir = split "\/", $directory;
	pop @dir if ($pop);
	my $path = '';
	while (@dir) {
		$path .= "/" if $path;
		$path .= shift @dir;
		mkdir $path unless -d $path;
	}
	return $directory;
}

sub reftype {
	Scalar::Util::reftype $_[0];
}

1;
