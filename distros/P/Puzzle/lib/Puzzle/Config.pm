package Puzzle::Config;

our $VERSION = '0.18';


use Params::Validate qw(:types);;

use base 'Class::Container';

BEGIN {

	__PACKAGE__->valid_params(
		debug		      => { parse => 'boolean', default => 0, type => BOOLEAN},
		debug_path	      => { parse => 'string', default => undef, type => SCALAR | UNDEF},
		cache		      => { parse => 'boolean', default => 0, type => BOOLEAN},
		frames       => { parse => 'boolean', default => 0, type => BOOLEAN},
		frame_top_file     => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		frame_left_file    => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		frame_right_file   => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		frame_bottom_file  => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		exception_file  => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		base          => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		gids          => { parse => 'list',   type => ARRAYREF | UNDEF, default => qw/everybody/ },
		login         => { parse => 'string',  type => SCALAR | UNDEF, default => undef },
		namespace		  => { parse => 'string',  type => SCALAR },
		description   => { parse => 'string',  type => SCALAR, default => '' },
		keywords      => { parse => 'string',  type => SCALAR, default => '' },
		db			      => { parse => 'hash',  type => HASHREF},
		traslation    => { parse => 'hash',  type => HASHREF, optional => 1},
		page		  => { parse => 'hash',  type => HASHREF | UNDEF, optional => 1},
		mail		      => { parse => 'hash',  type => HASHREF, optional => 1,
									default => {server => '', from => ''} },
	);
}

# all new valid_params are read&write methods
use HTML::Mason::MethodMaker(
				read_write => [ map { [ $_ => __PACKAGE__->validation_spec->{$_} ] }
				                     keys(%{__PACKAGE__->allowed_params()}) 
																											                     ]
);

sub new {
    my $class   = shift;
    my $self    = $class->SUPER::new(@_);
	# compatibility with previous version where db connection
	# was mandatory
	$self->db->{enabled} = 1 unless exists $self->db->{enabled};
    return $self;
}

sub as_hashref {
	my $self = shift;
	my %ret = map {$_ => $self->{$_}} keys(%{__PACKAGE__->allowed_params()});
	delete $ret{container};
	return \%ret;
}

1;
