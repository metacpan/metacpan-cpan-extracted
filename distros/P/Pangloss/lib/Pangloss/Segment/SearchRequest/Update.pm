package Pangloss::Segment::SearchRequest::Update;

use strict;
use warnings;

use Pangloss::Term::Status;
use Pangloss::Search::Request;

use base      qw( OpenFrame::WebApp::Segment::Session Pangloss::Object );
use accessors qw( srequest args );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.9 $ '))[2];
our %STATUS_CODES = Pangloss::Term::Status->status_codes;

sub dispatch {
    my $self     = shift;
    my $request  = $self->store->get('OpenFrame::Request') || return;
    my $srequest = $self->store->get('Pangloss::Search::Request') ||
		   Pangloss::Search::Request->new;

    $self->srequest( $srequest )
         ->args( $request->arguments )
	 ->update_search_request
	 ->srequest( undef )
         ->args( undef );

    return $srequest;
}

sub update_search_request {
    shift->update_categories
         ->update_concepts
         ->update_languages
         ->update_proofreaders
         ->update_translators
         ->update_statuses
         ->update_date_ranges
         ->update_keyword
         ->update_document;
}

sub update_categories   { shift->update_req_items( @_, 'category' ); }
sub update_concepts     { shift->update_req_items( @_, 'concept' ); }
sub update_languages    { shift->update_req_items( @_, 'language' ); }
sub update_translators  { shift->update_req_items( @_, 'translator' ); }
sub update_proofreaders { shift->update_req_items( @_, 'proofreader' ); }

sub update_req_items {
    my $self     = shift;
    my $type     = shift;
    my $srequest = $self->srequest;
    my $args     = $self->args;

    my $toggle_method = "toggle_$type";
    $srequest->$toggle_method( $args->{$_} )
      for ( grep /toggle_$type/, keys(%$args) );

    my %existing_keys = map { $_ => 1 } $srequest->filters->{$type}->keys;
    foreach my $param (keys( %$args )) {
	next unless $param =~ /^$type\_(.+)$/;
	my $key = $1;
	$self->emit( "setting $type $key --> $args->{$param}" );
	$srequest->$type( $key, $args->{$param} =~ /on/i ? 1 : undef );
	delete $existing_keys{$key};
    }

    # unset existing keys:
    ($self->emit( "setting $type $_ --> off" ),
      $srequest->$type( $_, undef )) for keys %existing_keys;

    return $self;
}

sub update_statuses {
    my $self     = shift;
    my $srequest = $self->srequest;
    my $args     = $self->args;

    $srequest->toggle_status( $args->{$_} )
      for ( grep /toggle_status/, keys(%$args) );

    my %existing_keys = map { $_ => 1 } $srequest->filters->{status}->keys;
    foreach my $param (keys( %$args )) {
	next unless $param =~ /^status\_(.+)$/;
	my $key = $STATUS_CODES{$1} || next;
	$srequest->status( $key, $args->{$param} =~ /on/i ? 1 : undef );
	delete $existing_keys{$key};
    }

    # unset existing keys:
    ($self->emit( "setting status $_ --> off" ),
      $srequest->status( $_, undef )) for keys %existing_keys;

    return $self;
}

sub update_date_ranges {
    my $self = shift;
    $self->emit( 'TODO: implement date ranges!' );
    return $self;
}

sub update_keyword {
    my $self = shift;
    my $keyword = $self->args->{keyword} || $self->args->{'q'};
    $self->srequest->keyword( $keyword );
    return $self;
}

sub update_document {
    my $self = shift;

    # $self->emit( "updating document: " . $self->args->{uri} );
    $self->srequest->load_document_from( $self->args->{uri} );

    return $self;
}


1;
