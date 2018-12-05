package DBI::Gofer::Transport::psgi;

use strict;
use warnings;

our $VERSION = 0.001;

use DBI 1.605;
use parent qw/DBI::Gofer::Transport::Base/;

my @config_keys = qw/
	gofer_execute_class
	check_request_sub 
	check_response_sub 
	forced_connect_dsn 
	default_connect_dsn 
	forced_connect_attributes 
	default_connect_attributes 
	max_cached_dbh_per_drh 
	max_cached_sth_per_dbh 
	forced_single_resultset 
	forced_response_attributes 
	forced_gofer_random
/;

__PACKAGE__->mk_accessors(@config_keys, '_executor');

sub executor {
    my ($self) = @_;
	my %config = map +( $_ => $self->$_ ), grep defined, @config_keys;
	my $gofer_execute_class = $self->gofer_execute_class || 'DBI::Gofer::Execute';

	return defined $self->_executor 
		? $self->_executor
		: scalar( $self->_executor( $gofer_execute_class->new(\%config) ), $self->_executor );
}

# --------------------------------------------------------------------------------

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBI::Gofer::Transport::psgi - server side http transport for DBI-Gofer using PSGI

=head1 SYNOPSIS

	use Plack::App::DBI::Gofer;
	my $app = Plack::App::DBI::Gofer->new( config => {
		%DBI_Gofer_Execute_config_params
	})->to_app;
	
	# or map a path to a forced dsn
	use Plack::Builder;
	builder {
		mount '/mydb' => Plack::App::DBI::Gofer->new( config => {
			forced_connect_dsn => 'dbi:SQLite:dbname=mydb.db',
		})->to_app;
	};

For a corresponding client-side transport see L<DBD::Gofer::Transport::http>.

=head1 DESCRIPTION

See L<Plack::App:DBI::Gofer> for details

Please report any bugs or feature requests to
C<bug-plack-app-dbi-gofer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Tim Bunce, L<http://www.linkedin.com/in/timbunce>

James Wright L<https://metacpan.org/author/JWRIGHT>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Tim Bunce, Ireland. All rights reserved.

Copyright (c) 2018, James Wright, United States.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

=over

=item * L<Plack::App::DBI::Gofer>

=item * L<DBD::Gofer>

=item * L<Plack>

=back

=cut

