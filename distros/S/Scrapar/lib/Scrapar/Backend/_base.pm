package Scrapar::Backend::_base;

use strict;
use warnings;
use Data::Dumper;
use Digest::MD5 qw(md5_hex);
use base 'Scrapar::Var';
use Scrapar::Mechanize;

sub _make_id {
    my $self = shift;

    return md5_hex $_[0];
}

sub new {
    my $class = shift;
    my $params_ref = shift;

    my $mech = 'Scrapar::Mechanize'->new();
    $mech->cache_expires_in($params_ref->{cache_expires_in});

    return bless {
	start_time => time(),
	start_url => $params_ref->{start_url},
	m => $mech,
	data => undef,
	logger => $ENV{SCRAPER_LOGGER},
    } => ref($class) || $class;
}

sub logger { $_[0]->{logger} }

# Apply extractors and data handlers
sub apply {
    my $self = shift;
    my $data = shift;
    my @filters = @_;

    if (exists $ENV{SCRAPER_MAX_TIME}
	&& time() - $self->{start_time} > $ENV{SCRAPER_MAX_TIME}) {
	print "Time limit is reached. Exiting ...\n";
	exit;
    }

    #
    # The filter args follow two types:
    # 
    # 1. 
    #
    # {
    #   name => 'blah', # module name
    #   new => { },     # the args to new(), 
    #   args => { }     # the args to extract() or to handle() ]
    # }
    # 
    # 2.
    #
    # sub { my $self = shift; my $data = shift; }
    # 

    for my $filter (@filters) {
	eval {
	    if (ref $filter eq 'HASH') {
		my $f;
		my $filter_module;
		if ($filter->{name} =~ m[^E::(.+)]) {
		    $filter_module = 'Scrapar::Extractor::' . ($1 || 'RSS');
		    $filter_module->require or die $@;
		    my $f = $filter_module->new($filter->{new});
		    $data = $f->extract($data, $filter->{args});
		}
		elsif ($filter->{name} =~ m[^D::(.+)]) {
		    $filter_module = 'Scrapar::DataHandler::' . ($1 || 'STDOUT');
		    $filter_module->require or die $@;
		    my $f = $filter_module->new($filter->{new});
		    $data = $f->handle($data, $filter->{args});
		}
	    }
	    elsif (ref $filter eq 'CODE') {
		$data = $filter->($self, $data);
	    }
	}
    }

    return $data;
}


sub data {
    my $self = shift;
    $self->{data} = $_[0] if $_[0];

    return $self->{data};
}

sub extract {
    my $self = shift;
    my $params_ref = shift;

    $self->{data} = $self->apply($self->{data}, $params_ref);
    return $self;
}

sub handle {
    my $self = shift;
    my $params_ref = shift;

    $params_ref->{name} = $ENV{DEFAULT_DATAHANDLER} if $ENV{DEFAULT_DATAHANDLER};
 
    $self->apply($self->{data}, $params_ref);
    return $self;
}

sub handle_one_item {
    my $self = shift;
    my $r = shift;
    my $args = shift;

    $self->{data} = [ $r ];
    $self->handle($args);
}

sub dumper {
    my $self = shift;
    my $data = shift;

    print Dumper $data;
}

sub run {
    die "This method must be overridden";
}

1;

__END__

=pod

=head1 NAME

Scrapar::Backend::_base - The base class for building backends

=head1 COPYRIGHT

Copyright 2009-2010 by Yung-chung Lin

All right reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut
