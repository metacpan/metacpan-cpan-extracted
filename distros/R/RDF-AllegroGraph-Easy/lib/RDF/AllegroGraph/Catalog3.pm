package RDF::AllegroGraph::Catalog3;

use strict;
use warnings;

require Exporter;
use base qw(RDF::AllegroGraph::Catalog);

=pod

=head1 NAME

RDF::AllegroGraph::Catalog3 - AllegroGraph catalog handle for AGv3

=head1 SYNOPSIS

   # implementation of RDF::AllegroGraph::Catalog

=cut

use RDF::AllegroGraph::Repository3;
use RDF::AllegroGraph::Utils;

use JSON;
use HTTP::Status;
use Fcntl;
use Data::Dumper;

sub new {
    my $class   = shift;
    my %options = @_;
    die "no NAME"   unless $options{NAME};
    die "no SERVER" unless $options{SERVER};
    return bless \%options, $class;
} 

sub repositories {
    my $self = shift;
    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/repositories');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    my $repo = from_json ($resp->content);
    return
	map { RDF::AllegroGraph::Repository3->new (%$_, CATALOG => $self) }
	map { RDF::AllegroGraph::Utils::_hash_to_perl ($_) }
        @$repo;
}

sub repository {
    my $self = shift;
    my $id   = shift;
    my $mode = shift || O_RDONLY;

    if (my ($repo) = grep { $_->id eq $id } $self->repositories) {
	return $repo;
    } elsif ($mode == O_CREAT) {
	(my $repoid = $id) =~ s|^/.+?/|/|;                                                 # get rid of the catalog name
	use HTTP::Request;
	my $requ = HTTP::Request->new (PUT => $self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/repositories' . $repoid);
	my $resp = $self->{SERVER}->{ua}->request ($requ);
	die "protocol error: ".$resp->status_line unless $resp->code == RC_NO_CONTENT;
	return $self->repository ($id);                                                    # recursive, but without forced create
    } else {
	die "cannot open repository '$id'";
    }
}

sub version {
    my $self = shift;
    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/AGVersion');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
}

sub protocol {
    my $self = shift;

    my $resp = $self->{SERVER}->{ua}->get ($self->{SERVER}->{ADDRESS} . '/catalogs' . $self->{NAME} . '/protocol');
    die "protocol error: ".$resp->status_line unless $resp->is_success;
    return $resp->content =~ m/^"?(.*?)"?$/ && $1;
}


our $VERSION  = '0.04';

1;

__END__

