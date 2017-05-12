package SAL::Base;

# This module is licensed under the FDL (Free Document License)
# The complete license text can be found at http://www.gnu.org/copyleft/fdl.html
# Contains excerpts from various man pages, tutorials and books on perl
# BOILER-PLATE FOR NEW MODULES

use strict;
use Carp;

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
	$VERSION = '3.03';
	@ISA = qw(Exporter);
	@EXPORT = qw();
	%EXPORT_TAGS = ();
	@EXPORT_OK = qw();
}
our @EXPORT_OK;

END { }

our %Base = (
######################################
######################################
);

# Setup accessors via closure (from perltooc manpage)
sub _classobj {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	no strict "refs";
	return \%$class;
}
 
for my $datum (keys %{ _classobj() }) {
	no strict "refs";
	*$datum = sub {
		my $self = shift->_classobj();
		$self->{$datum} = shift if @_;
		return $self->{$datum};
	}
}
 

############################################################################
# Constructors (Public)
sub new {
	my $obclass = shift || __PACKAGE__;
	my $class = ref($obclass) || $obclass;
	my $self = {};
 
	bless($self, $class);
 
	# Set default object properties
 
	return $self;
}


############################################################################
# Destructor (Public)
sub destruct {
	my $self = shift;
}

 
############################################################################
# Public Methods


############################################################################
# Private Methods

 
1;
