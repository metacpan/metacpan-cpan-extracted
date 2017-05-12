package Template::Context::Cacheable;

use warnings;
use strict;

=head1 NAME

Template::Context::Cacheable - profiling/caching-aware version of Template::Context

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS
    use My::Favourite::Cache::Engine;
    use Template::Context::Cacheable;

    Template::Context::Cacheable::configure_caching(
	\&My::Favourite::Cache::Engine::get,
	\&My::Favourite::Cache::Engine::put,
    );

=head1 DESCRIPTION

Enables profiling and caching of Template-Toolkit subtemplates, that can improve
template processing speed many times.

=head2 Using in templates

Inside any template you can use cached subtemplates. See example:

 [% PROCESS subtemplate.tt
    param_name_1 = 'value_1'
    param_name_2 = 'value_2'
    __cache_time = 60
 %]

Here __cache_time parameter enables caching and sets caching time in seconds.
If __cache_time value is negative, subtemplated will be cached forever
(actually it will be cached for 12 hours ;)

param_name_X is examples of parameters, which combination will be used as a hash key.

=cut

use base qw(Template::Context);
use Digest::MD5;
use Time::HiRes qw/time/;

use Data::Dumper;

use lib '/www/srs/lib';

our $DEBUG = 0;
our $CACHE_GET; # GET subroutine reference
our $CACHE_PUT; # PUT subroutine reference

my @stack;
my %totals;

=head1 FUNCTIONS / METHODS

The following functions / methods are available:

=head2 configure_caching ( cache_get_ref, cache_put_ref )

Install cache get / put handlers.

Here are protypes for get / put handlers which illustrates parameters which they will receive:

sub get {
    my ($key) = @_;

    ...
}

sub set {
    my ($code, $key, $keep_in_seconds) = @_;

    ...
}

=cut

sub configure_caching {
    ($CACHE_GET, $CACHE_PUT) = @_;
}

=head2 process ( self )

Overloaded Template::Context::process method

=cut

sub process {
    my $self = shift;

    my $template = $_[0];
    if (UNIVERSAL::isa($template, "Template::Document")) {
        $template = $template->name || $template;
    }

    my @result;

    if ($DEBUG) {
	push @stack, [ time, times ];
	print STDERR Dumper( @_ ) if $DEBUG >= 2;
    }

    unless ($CACHE_GET && $CACHE_PUT) {
	@result = wantarray ?
	    $self->SUPER::process(@_) :
	    scalar $self->SUPER::process(@_);

	goto SKIP_CACHING;
    }

    # subtemplates caching

    my $cache_key = '';
    my $cache_time;

    my $param_ref = $_[1];

    if (exists $param_ref->{__cache_time} && !$param_ref->{__cache_time}) {
	delete $param_ref->{__cache_time};
    }
    if ($param_ref && ref $param_ref eq 'HASH' && $param_ref->{__cache_time}) {
	$cache_time = delete $param_ref->{__cache_time};
	$cache_time = $cache_time < 0  ? 3600 * 12 : $cache_time;

	$cache_key =  join '_', map { ($_, $param_ref->{$_}) } sort keys %$param_ref;

	print STDERR "RAW KEY: $cache_key\n" if $DEBUG >= 2;

	$cache_key = $template . '__' . Digest::MD5::md5_hex( $cache_key );

	# ”далим ненужные дл€ обработки шаблона ключи
	# (которые €вл€ютс€ исключительно ключами кэшировани€)
	foreach my $key (keys %{$param_ref}) {
	    delete $param_ref->{$key} if $key =~ /^__nocache_/;
	}
    }
    print STDERR "HASHED KEY: $cache_key\n" if $DEBUG >= 2 && $cache_key;

    my $cached_data;
    if ($cache_key && ($cached_data = $CACHE_GET->($cache_key))) {
	print STDERR "$template: CACHED ($cache_key)\n" if $DEBUG >= 2;
	@result = @{ $cached_data };
    }
    else {
	print STDERR "$template: NON_CACHED ($cache_key)\n" if $DEBUG >= 2;
	@result = wantarray ?
	    $self->SUPER::process(@_) :
	    scalar $self->SUPER::process(@_);
	$CACHE_PUT->( $cache_key, \@result, $cache_time ) if $cache_key;
    }

    # / subtemplates caching
SKIP_CACHING:

    if ($DEBUG) {
	my @delta_times = @{pop @stack};
	@delta_times = map { $_ - shift @delta_times } time, times;
	for (0..$#delta_times) {
	    $totals{$template}[$_] += $delta_times[$_];
	    for my $parent (@stack) {
		$parent->[$_] += $delta_times[$_] if @stack; # parent adjust
	    }
	}
	$totals{$template}[5] ++; # count of calls
	$totals{$template}[6] = $cached_data ? 1 : 0;

	unless (@stack) {
	    ## top level again, time to display results
	    print STDERR "-- $template at ". localtime, ":\n";
	    printf STDERR "%4s %6s %6s %6s %6s %6s %s\n",
		qw(cnt clk user sys cuser csys template);

	    my @totals = (0) x 6;

	    for my $template (sort keys %totals) {
		my @values = @{$totals{$template}};
		printf STDERR "%4d %6.4f %6.4f %6.4f %6.4f %6.4f %s\n",
		    $values[5],
		    @values[0..4],
		    $template .($values[6] ? '  CACHED' : '');

		for my $i (0..5) { $totals[$i] += $values[$i] };
	    }

	    printf STDERR "%4d %6.4f %6.4f %6.4f %6.4f %6.4f %s\n",
		$totals[5],
		@totals[0..4],
		'TOTAL';

	    print STDERR "-- end\n";
	    %totals = (); # clear out results
	}
    }

    # return value from process:
    wantarray ? @result : $result[0];
}

$Template::Config::CONTEXT = __PACKAGE__;

=head1 EXPORT

No functions is exported.

=head1 AUTHOR

Walery Studennikov, C<< <despair at cpan.org> >>

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
