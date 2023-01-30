use 5.010001;
use strict;
use warnings;

package Story::Interact::Harness::Terminal;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.001006';

use Story::Interact::State ();
use Term::Choose qw( choose );
use Text::Wrap ();

use Moo;
use Types::Common -types;
use namespace::clean;

use constant DEBUG       => !!$ENV{PERL_STORY_INTERACT_DEBUG};
use constant FIRST_PAGE  => $ENV{PERL_STORY_INTERACT_START} // 'main';

has 'state' => (
	is        => 'ro',
	isa       => Object,
	builder   => sub { Story::Interact::State->new },
);

has 'page_source' => (
	is        => 'ro',
	isa       => Object,
	required  => 1,
);

has 'paragraph_formatter' => (
	is        => 'ro',
	isa       => CodeRef,
	builder   => 1,
);

sub get_page {
	my ( $self, $page_id ) = @_;
	my $page = $self->page_source->get_page( $self->state, $page_id );
	if ( DEBUG ) {
		if ( @{ $page->next_pages } > 0 ) {
			$page->add_next_page( ':debug', 'DEBUG INTERFACE' );
		}
	}
	return $page;
}

sub run {
	my ( $self ) = @_;

	my $page = $self->get_page( FIRST_PAGE );

	while ( 1 ) {
		$self->display_page( $page );
		my $chosen = $self->prompt_next( $page ) or last;
		if ( DEBUG and $chosen eq ':debug' ) {
			$page = $self->run_debugger( $page );
			next;
		}
		$page = $self->get_page( $chosen );
	}
}

sub display_page {
	my ( $self, $page ) = @_;
	my $f = $self->paragraph_formatter;
	for my $paragraph ( @{ $page->text } ) {
		print $f->( $paragraph ), "\n\n";
	}
}

sub prompt_next {
	my ( $self, $page ) = @_;

	my @next = @{ $page->next_pages };

	if ( @next == 0 ) {
		print ">> Finished!\n\n";
		return undef;
	}

	my @descs = map { $_->[1] } @next;

	if ( @next == 1 ) {
		choose( \@descs, { index => 1, layout => 2, prompt => '' } );
		print ">> ", $descs[0], "\n\n";
		return $next[0][0];
	}
	else {
		my $got = choose( \@descs, { index => 1, layout => 2, prompt => 'Next?' } );
		defined $got or return undef;
		print ">> ", $descs[$got], "\n\n";
		return $next[$got][0];
	}
}

sub _build_paragraph_formatter {
	my ( $self ) = @_;
	if ( eval "use String::Tagged::Markdown; use String::Tagged::Terminal; 1" ) {
		return sub {
			my ( $p ) = @_;
			my $st   = String::Tagged::Markdown->parse_markdown( $p );
			my $fmt  = String::Tagged::Terminal->new_from_formatting( $st->as_formatting );
			my $term = $fmt->build_terminal( no_color => $ENV{NO_COLOR} );
			local $Text::Wrap::columns = 78;
			return Text::Wrap::wrap( q{}, q{}, $term ); # Gasp!
		};
	}
	return sub {
		my ( $p ) = @_;
		local $Text::Wrap::columns = 78;
		Text::Wrap::wrap( q{}, q{}, $p );
	};
}

# Useful for debugging. I'm sure a better debugger is possible.
sub run_debugger {
	my ( $self, $page ) = @_;
	print "Next page options: \n";
	print "Now entering DEBUG mode.\n";
	Story::Interact::Syntax::START( $self->state, ':debug' );
	for my $next ( @{ $page->next_pages } ) {
		Story::Interact::Syntax::next_page( $next->[0], $next->[1], %{ $next->[2] // {} } );
	}
	if ( $page->has_location ) {
		Story::Interact::Syntax::at( $page->location );
	}
	while ( my $line = <> ) {
		Story::Interact::Syntax::DEBUG( $line );
	}
	return Story::Interact::Syntax::FINISH();
}

1;
