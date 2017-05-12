#
# Properties allow the user to store setting.
#

package Shell::Properties;
use Tk;
use Tk::Pretty;

use strict;
use Carp;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');


my $save;  # Temp storage for current options
my $state = 1;
eval qq{ use Storable qw{nstore retrieve} };
$state = 0 if $@;

sub state {
	$state;
}

# Disable menu pick, if $state is 0
sub new {
   my ($proto, $parent) = @_;
   my $class = ref($proto) || $proto;
   my $self  = {
			file => qq{$main::orac_home/options},
			parent => $parent,
    };

   bless($self, $class);

   return $self;
}

# Displays a dialog box with options.
sub display {
	my ($self) = @_;
	my $d = $self->parent->dbiwd->Dialog( -title => 'Review Options:',
		-buttons => [ qw{Save Restore Cancel} ],
		-default_button => q{Save},
	 );

	foreach my $x ($self->parent->options->opt_keys) {
		$save->{$x} = $self->parent->options->{$x};
		my $f = $d->Frame()->pack( -side => 'top' );
		my $l = $f->Label( -text => "$x: ", 
			-relief => 'groove',
			-width => 20 );
		my $e = $f->Entry( -width => 20, -textvariable => \$save->{$x} );
		$l->pack( -side => 'left' );
		$e->pack( -side => 'right' );
		$e->bind( '<FocusOut>', 
			sub {
				$self->check_change( $x, $self->parent->options->{$x});
 			}
		 );
	}
	my $ans = $d->Show;
	$self->save()   if $ans =~ /save/i;
	$self->load()   if $ans =~ /restore/i;
	$self->cancel() if $ans =~ /cancel/i;
	return;

}

# Store default values for options.
sub save {
	my $self = shift;
	nstore( \$save, $self->file );
	return $self->load();
}

# Retrieve values for options.
sub load {
	my $self = shift;
	eval {
	my $tmp = ${retrieve( $self->file )};
	foreach my $key (keys %$tmp){
		$self->parent->options->${key}($tmp->{$key});
	}
	};
	warn $@ if $@;
}

sub cancel {
	my $self = shift;
	return;
}

sub check_change {
	my ($self, $col, $pv) = @_;
}


sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}
1;
