package LWP::UserAgent::AG;

use LWP::UserAgent;
use base 'LWP::UserAgent';

#use LWP::Debug qw(+ -conns);
#use LWP::Debug qw(+);

sub new {
    my $class = shift;
    my %options = @_;
    my $self  = $class->SUPER::new;
    $self->timeout(10);
    $self->env_proxy;
    $self->default_header('Accept' => "application/json");
    if ($options{AUTHENTICATION}) {
	( $self->{USERNAME}, $self->{PASSWORD} ) = ($options{AUTHENTICATION} =~ /^(.+):(.*)$/);
    }
    return $self;
}

sub get_basic_credentials {
    my $self = shift;
    return ($self->{USERNAME}, $self->{PASSWORD});
}

sub xrequest {
    my $self = shift;
    my $req  = shift;
    warn $req->as_string;
#    warn "requesting ". $req->method . ' ' . $req->uri ;
#    $req->header( 'Connection' => 'close' );
    $self->SUPER::request ($req, @_);
}

package RDF::AllegroGraph::Server;

use strict;
use warnings;

require Exporter;
use base qw(Exporter);

use feature 'switch';

=pod

=head1 NAME

RDF::AllegroGraph::Server - AllegroGraph server handle

=head1 SYNOPSIS

  #-- orthodox approach
  my $server = new RDF::AllegroGraph::Server (ADDRESS        => 'http://localhost:8080',
                                              AUTHENTICATION => 'joe:secret');
  my @catalogs = $server->catalogs;

  #-- commodity
  # get handles to all models (repositories) at the server
  my @models = $server->models;

  # get one in particular
  my $model  = $server->model ('/testcat/testrepo');

=head1 DESCRIPTION

Objects of this class represent handles to a remote AllegroGraph HTTP server. Such a server can hold
several I<catalogs> and each of them can hold I<repositories>. Here we also use the orthodox concept
of a I<model> which is simply one particular repository in one particular catalog.

For addressing one model we use a simple path structure, such as C</testcat/testrepo>.

All methods die with C<protocol error> if they do not receive an expected success.

=head1 INTERFACE

=head2 Constructor

To get a handle to the AG server, you can instantiate this class. The following options are
recognized:

=over

=item C<ADDRESS> (no default)

Specifies the REST HTTP address. Must be an absolute URL, without a trailing slash. The
constructor dies otherwise.

=item C<AUTHENTICATION> (no default)

String which must be of the form C<something:somethingelse> (separated by C<:>). That will be interpreted
as username and password to do basic HTTP authentication against the server.

=back

=cut

sub new {
    my $class   = shift;
    my %options = @_;
    die "no HTTP URL as ADDRESS specified" unless $options{ADDRESS} =~ q|^http://|;
    my $self = bless \%options, $class;
    $self->{ua} = new LWP::UserAgent::AG (AUTHENTICATION => $options{AUTHENTICATION});
    my $version = $self->protocol;                    # try to figure out the version
    if ($version =~ /^3/) {                           # version 3.x
	$self->{ua}->timeout(10);
	use RDF::AllegroGraph::Server3;
	return bless $self, "${class}3";
    } elsif ($version =~ /^4/) {
	$self->{ua}->timeout(120);                   # NOTA BENE: v4 can be really slow when creating/deleting repos
	use RDF::AllegroGraph::Server4;
	return bless $self, "${class}4";
    } else {
	die "cannot handle protocol version ($version)";
    }
    return $self;
}

=pod

=head2 Methods

=over

=item B<protocol>

This method tries to figure out which protocol version the server talks. As the
AG 3.x servers do not seem to support a dedicated endpoint, some guesswork is involved.

=cut

sub protocol {
    my $self = shift;
    my $resp = $self->{ua}->get ($self->{ADDRESS} . '/protocol');
    use HTTP::Status;
    if ($resp->is_success) {
	return $resp->content;
    } elsif ($resp->code == RC_NOT_FOUND) {                            # heuristics: we are just guessing now, that this is a 3.x version
	return 3;
    } else {                                                             # this is really an error
	die "protocol error: ".$resp->status_line;
    }
}

=pod

=item B<ping>

I<$server>->ping

This method tries to connect to the server and will return C<1> on success. Otherwise an exception
will be raised.

=cut

sub ping {
    my $self = shift;
    $self->catalogs and return 1;                                    # even if there are no catalogs, we survived the call
}

=pod

=item B<catalogs>

I<@cats> = I<$server>->catalogs

This method lists the catalogs available on the remote server. The result is a list of relative
paths. 

=item B<models>

I<%models> = I<$server>->models

This method lists all models available on the server. Returned is a hash reference. The keys are the
model identifiers, all of the form C</somecatalog/somerepository>. The values are repository objects.

=item B<model>

I<$server>->model (I<$mod_id>, I<option1> => I<value1>, ...)

This method tries to find an repository in a certain catalog. This I<model id> is always of the form
C</somecatalog/somerepository>. The following options are understood:

=over

=item C<MODE> (default: C<O_RDONLY>)

This POSIX file mode determines how the model will be opened.

=back

If the model already does exist, then an L<RDF::AllegroGraph::Repository> object will be
returned. If the specified catalog does not exist, then a C<no catalog> exception will be raised.
Otherwise, if the repository there does not exist and the C<MODE> option is C<O_CREAT>, then it will
be generated. Otherwise an exception C<cannot open repository> will be raised.


=back

=head1 AUTHOR

Robert Barta, C<< <rho at devc.at> >>

=head1 COPYRIGHT & LICENSE

Copyright 20(09|11) Robert Barta, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

L<RDF::AllegroGraph>, L<RDF::AllegroGraph::Server4>

=cut

our $VERSION  = '0.04';

1;

__END__


