package POEIKC::Plugin::GlobalQueue::ClientLite;

use strict;
use 5.008_001;
our $VERSION = '0.01';
use Sys::Hostname ();
use POE::Component::IKC::ClientLite;

sub new {
    my $class = shift ;
    my $self = {
        	ikc 		=> undef,
        	RaiseError 	=> 0,
        	error => undef,
        	@_
        };
    for (qw(ip port name serialiser timeout connect_timeout block_size)){
		$self->{create_ikc_client}->{$_} = delete $self->{$_} if exists $self->{$_};
    }
    $class = ref $class if ref $class;
    bless  $self,$class ;
    return $self ;
}

sub ikc {
	my $self = shift;
	$self->{ikc} = shift if @_ >= 1;
	return $self->{ikc};
}

sub error {shift->{error}}

sub connect {
	my $self = shift;
	$self->{error} = undef;
	my %param = (
		ip 		=> Sys::Hostname::hostname,
		port 	=> 40101,
		name 	=> join('_'=>Sys::Hostname::hostname, ($0 =~ /(\w+)/g), $$),
		%{$self->{create_ikc_client}},
		@_
	);
	$self->{ikc} = create_ikc_client(%param);
	if (not($self->{ikc})) {
		$self->{error}  = $POE::Component::IKC::ClientLite::error;
		$self->{RaiseError} and die($POE::Component::IKC::ClientLite::error);
	}
	return $self->{ikc};
}

sub enqueue {
	my $self = shift;
	$self->{error} = undef;
	my $capsule = shift;
	$self->{ikc} ||= $self->connect;
	if ( $self->{ikc} ) {
		my $ret = $self->{ikc}->post_respond(
			'GlobalQueue/enqueue_respond' =>$capsule
		);
		return $ret;
	}
	return ;
}

sub dequeue {
	my $self = shift;
	$self->{error} = undef;
	$self->{ikc} ||= $self->connect;
	if ( $self->{ikc} ) {
		my $ret = $self->{ikc}->post_respond(
			'GlobalQueue/dequeue_respond' =>\@_
		);
		return $ret;
	}
	return ;
}

sub length{
	my $self = shift;
	$self->{ikc} ||= $self->connect;
	if ( $self->{ikc} ) {
		my $ret = $self->{ikc}->post_respond(
			'GlobalQueue/length_respond' =>@_
		);
		return $ret;
	}
	return ;
}



1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

POEIKC::Plugin::GlobalQueue::ClientLite - Synchronous interface

=head1 SYNOPSIS

	use Data::Dumper;
	use POEIKC::Plugin::GlobalQueue::ClientLite;

	my $gq = POEIKC::Plugin::GlobalQueue::ClientLite->new(
		ip		=> global_queue_server_host_name,
		port	=> 47301,
		timeout	=> 3,
		RaiseError => 1,
	);
	eval {
		$gq->connect;

		my $re = $gq->enqueue(
			POEIKC::Plugin::GlobalQueue::Capsule->new({foo=>'FOO'})
		);
		$re or die "failed in enqueue";


		print Dumper($gq->length);

		my $data = $gq->dequeue();
		print Dumper($data);

	};if($@){
		warn $@;
	}


=head1 AUTHOR

Yuji Suzuki E<lt>yujisuzuki@mail.arbolbell.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<poeikcd>
L<POEIKC::Plugin::GlobalQueue>
L<POEIKC::Plugin::GlobalQueue::Capsule>

=cut
