package Queue::Mmap;
use strict;
use warnings;

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Queue::Mmap', $VERSION);

sub new {
	my $class = shift;
	my %p;
	unless(@_ % 2){
		%p = @_;
	}elsif(UNIVERSAL::isa($_[0],"HASH")){
		%p = %{$_[0]};
	}else{
		die "bad params"
	}
	unless($p{file}){
		die "need filename";
	}
	$p{queue} ||= 100;
	$p{length} ||= 100;
	my $self = $class->create(@p{'file','queue','length'});

	if($p{mode}){
		chmod $p{mode},$p{file};
	}
	return $self;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Queue::Mmap - Perl extension for shared queue over mmap-ed file

=head1 SYNOPSIS

	use Queue::Mmap;
	my $q = new Queue::Mmap(
		file => "file.dat",
		queue => 10, # length of queue 
		length => 20, # length one record (if data longer record, data placed in some records)
		mod => 0666, # make mode for file
	);
	unless($q->push("abcdefghijklmnopqrstuvwxyz")){
		die "fail push";
	}
	my $w = $q->push("abcdefghijk");
	printf "%.6f\n",$w;

	my ($t,$l) = $q->push("abcdefghijk");
	printf "total = %.6f, wait lock %.6f\n",$t,$l;
	
	print "length of queue is ",$q->length,"\n";
	
	my $top = $q->top;
	while(defined(my $v = $q->pop)){
		print $v,"\n";
	}
	print "no data\n";

=head1 DESCRIPTION

Queue::Mmap - Shared circle-queue over mmap-ed file.

Usefull for multy process task queue.
One process(es) push task message, and other process(es) pop and execute that tasks.
Access with locking(fcntl) guaranted right order without conflict.
If pushed data has size greater that record len data placed in some records.
If pushed data has size greater that capacity (record * queue) push has return undef.

=item new %params

Create new queue object

	my $q = new Queue::Mmap(
		file => "file.dat",
		queue => 10, # length of queue 
		length => 20, # length one record (if data longer record, data placed in some records)
		mod => 0666, # make mode for file
	);

=item push $string

	push $string into queue with block
	return false on failure
	return ($time_spend,$time_wait_lock) in array context
	return $time_spend in scalar context

=item pop

	poped top value from queue with block
	return C<undef> on empty queue

=item top

	copy top value from queue without block
	return C<undef> on empty queue

=item drop

	drop top value from queue with block

=item length

	return number of records in queue

=item stat

	return array
        top - index top records
        bottom - index last records
        que_len - capacity of queue
        rec_len - lenth one record

=item aligments

Length of record align for 4 bytes.
Length of file align for 4k.

=head1 TODO

Tested only on linux.


=head2 EXPORT

None by default.

=head1 SEE ALSO


=head1 AUTHOR

Ildar Efremov, E<lt>iefremov@2reallife.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ildar Efremov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
