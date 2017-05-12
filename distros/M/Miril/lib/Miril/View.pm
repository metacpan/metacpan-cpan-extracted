package Miril::View;

use strict;
use warnings;
use autodie;

use HTML::Template::Pluggable;
use HTML::Template::Plugin::Dot;

### ACCESSORS ###

use Object::Tiny qw(theme pager is_authenticated fatal miril);

### CONSTRUCTOR ###

sub new {
	my $class = shift;
	return bless { @_ }, $class;
}


### PUBLIC METHODS ###

sub load {
	my $self = shift;
	my $name = shift;
	my %options = @_;

	my $text = $self->theme->get($name);
	
	# get css
	my $css_text = $self->theme->get('css');
	my $css = HTML::Template::Pluggable->new( scalarref => \$css_text, die_on_bad_params => 0 );

	# get header
	my $header_text = $self->theme->get('header');
	my $header = HTML::Template::Pluggable->new( scalarref => \$header_text, die_on_bad_params => 0 );
	$header->param('authenticated', $self->is_authenticated ? 1 : 0);
	$header->param('css', $css->output);

	if ($self->miril->warnings or $self->fatal) {
		$header->param('has_error', 1 );
		$header->param('warnings', [$self->miril->warnings] ) if $self->miril->warnings;
		$header->param('fatals', [$self->fatal] ) if $self->fatal;
	}

	# get sidebar
	my $sidebar_text = $self->theme->get('sidebar');
	my $sidebar = HTML::Template::Pluggable->new( scalarref => \$sidebar_text, die_on_bad_params => 0 );
	$sidebar->param('latest', $self->miril->store->get_latest);

	# get footer
	my $footer_text = $self->theme->get('footer');
	my $footer = HTML::Template::Pluggable->new( scalarref => \$footer_text, die_on_bad_params => 0 );
	$footer->param('authenticated', $self->is_authenticated ? 1 : 0);
	$footer->param('sidebar', $sidebar->output);
	
	my $tmpl = HTML::Template::Pluggable->new( scalarref => \$text, die_on_bad_params => 0, case_sensitive => 1);
	$tmpl->param('authenticated', $self->is_authenticated ? 1 : 0);
	$tmpl->param('header' => $header->output, 'footer' => $footer->output );

	if ($self->pager) {

		my $pager_text = $self->theme->get('pager');
		my $pager = HTML::Template::Pluggable->new( scalarref => \$pager_text, die_on_bad_params => 0 );
		$pager->param('first', $self->pager->{first});
		$pager->param('last', $self->pager->{last});
		$pager->param('previous', $self->pager->{previous});
		$pager->param('next', $self->pager->{next});

		
		$tmpl->param('pager' => $pager->output );
	}

	return $tmpl;
}

1;
