use strict;
use warnings;
package Net::Inspect::Connection;
use base 'Net::Inspect::Flow';
use fields qw(expire);

sub expire {
    my ($self,$time) = @_;
    return $self->{expire} && $time>$self->{expire};
}

1;

__END__

=head1 NAME

Net::Inspect::Connection - base class for connections

=head1 SYNOPSIS

    package Net::Inspect::L7::HTTP;
    use base 'Net::Inspect::Connection';

    sub in {
	my ($self,$dir,$data,$eof,$time) = @_;
	# expire after 2 hours inactivity
	$self->{expire} = $time + 7200;
	...
    }


=head1 DESCRIPTION

Net::Inspect::Connection provides a field expire, which should be set to the
time, when the connection can expire, even if not explicitly closed.

It provides a function which will be regularly called from Net::Inspect::L4::TCP
and Net::Inspect::L4::UDP on all known connections and if it returns true
the connection will be deleted.
