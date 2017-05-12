use Perlmazing;
use File::Spec;

sub main {
	my ($path, $recursive, $callback);
	my $usage = 'Usage: dir ($path, $boolean_recursive, $coderef_callback)';
	my @coderefs = grep { isa_code $_ } @_;
	my @args = grep { not isa_code $_ } @_;
	croak "More than one coderef received in arguments, don't know which one to use as callback - $usage" if @coderefs > 1;
	croak "Too many non coderef arguments received - $usage" if @args > 2;
	my $wantarray = wantarray;
	$callback = shift @coderefs;
	($path, $recursive) = ('.', 0);
	@_ = @args;
	if (@_ == 1) {
		if (-d $_[0]) {
			$path = $_[0];
		} else {
			$recursive = $_[0] ? 1 : 0;
		}
	} elsif (@_ == 2) {
		if (defined($_[0]) and -d $_[0]) {
			$path = $_[0];
			$recursive = $_[1];
		} elsif (defined($_[1]) and -d $_[1]) {
			$path = $_[1];
			$recursive = $_[0];
		} else {
			croak "None of your parameters seems to be a valid/readable path";
		}
	}
	$path = File::Spec->catdir(File::Spec->splitdir($path));
	_dir($path, $recursive, $callback, $wantarray);
}

sub _dir {
	my ($path, $recursive, $callback, $wantarray) = @_;
	if (opendir my $d, $path) {
		my (@folders, @files, @results);
		my $process = sub {
			my $i = shift;
			$callback->($i) if $callback;
			push (@results, $i) if $wantarray;
		};
		for my $i (sort numeric readdir $d) {
			my $item = File::Spec->catdir($path, $i);
			if (-d $item) {
				next if $i eq '.' or $i eq '..';
				push @folders, $item;
			} else {
				push @files, $item;
			}
		}
		for my $i (@folders) {
			$process->($i);
			if ($recursive) {
				my @r = _dir($i, $recursive, $callback, $wantarray);
				push (@results, @r) if $wantarray;
			}
		}
		for my $i (@files) {
			$process->($i);
		}
		
		return @results if $wantarray
	} else {
		warn "Cannot read path $path: $!";
	}
	return;
}

1;
