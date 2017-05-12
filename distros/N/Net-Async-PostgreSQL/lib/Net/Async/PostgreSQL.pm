package Net::Async::PostgreSQL;
# ABSTRACT: PostgreSQL database support for IO::Async
use strict;
use warnings;
our $VERSION = '0.007';

=head1 NAME

Net::Async::PostgreSQL - (preliminary) asynchronous PostgreSQL support for L<IO::Async>

=head1 VERSION

version 0.007

=head1 SYNOPSIS

 use strict; use warnings;
 use IO::Async::Loop;
 use Net::Async::PostgreSQL::Client;

 my $loop = IO::Async::Loop->new;
 my $client = Net::Async::PostgreSQL::Client->new(
	host			=> $ENV{NET_ASYNC_POSTGRESQL_SERVER} || 'localhost',
	service			=> $ENV{NET_ASYNC_POSTGRESQL_PORT} || 5432,
	database		=> $ENV{NET_ASYNC_POSTGRESQL_DATABASE},
	user			=> $ENV{NET_ASYNC_POSTGRESQL_USER},
	pass			=> $ENV{NET_ASYNC_POSTGRESQL_PASS},
 );
 $client->init;

 $client->configure(
 	on_error	=> sub {
 		my ($self, %args) = @_;
 		my $err = $args{error};
 		warn "$_ => " . $err->{$_} . "\n" for sort keys %$err;
 	},
 	on_ready_for_query => sub {
 		my $self = shift;
 		unless($init) {
 			print "Server version " . $status{server_version} . "\n";
 			++$init;
 		}
                 unless(keys %sth) {
                         $self->simple_query(q{begin work});
                         my $sth = $self->prepare_async(
                                 sql => q{insert into sometable(name) values ($1) returning idsometable, name},
 				statement => 'new_value',
 			);
                 }
 		$sth->bind("some more data");
 	},
 	on_parameter_status => sub {
 		my $self = shift;
 		my %args = @_;
 		$status{$_} = $args{status}->{$_} for sort keys %{$args{status}};
 	},
 	on_row_description => sub {
 		my $self = shift;
 		my %args = @_;
 		print '[' . join(' ', map { $_->{name} } @{$args{description}{field}}) . "]\n";
 	},
 	on_data_row => sub {
 		my $self = shift;
 		my %args = @_;
 		print '[' . join(',', map { $_->{data} } @{$args{row}}) . "]\n";
 		$loop->loop_stop;
 	}
 );
 $loop->add($client);
 $client->connect;
 $loop->loop_forever;

=head1 DESCRIPTION

See L<Net::Async::PostgreSQL::Client> or L<Protocol::PostgreSQL>.

=cut

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
