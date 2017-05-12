# $Id: IDspace.pm 2011-09-29 erick.antezana $
#
# Module  : IDspace.pm
# Purpose : A mapping between a "local" ID space and a "global" ID space.
# License : Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.
#           This program is free software; you can redistribute it and/or
#           modify it under the same terms as Perl itself.
# Contact : Erick Antezana <erick.antezana -@- gmail.com>
#
package OBO::Core::IDspace;

use Carp;
use strict;
use warnings;

sub new {
	my $class                   = shift;
	my $self                    = {};

	$self->{LOCAL_IDSPACE}      = '';    # required, scalar (1)
	$self->{URI}                = '';    # required, scalar (1)
	$self->{DESCRIPTION}        = undef; # optional scalar (0..1)
        
	bless ($self, $class);
	return $self;
}

=head2 local_idspace

  Usage    - print $idspace->local_idspace() or $idspace->local_idspace($local_idspace)
  Returns  - the local ID space (string)
  Args     - the local ID space (string)
  Function - gets/sets the local ID space
  
=cut

sub local_idspace {
	if ($_[1]) {
		$_[0]->{LOCAL_IDSPACE} = $_[1];
	} else { # get-mode
		croak 'The local ID space of this ID space is not defined.' if (!defined($_[0]->{LOCAL_IDSPACE}));
	}
	return $_[0]->{LOCAL_IDSPACE};
}

=head2 uri

  Usage    - print $idspace->uri() or $idspace->uri($uri)
  Returns  - the URI (string) of this ID space
  Args     - the URI (string) of this ID space
  Function - gets/sets the URI of this ID space
  
=cut

sub uri {
	if ($_[1]) {
		$_[0]->{URI} = $_[1];
	} else { # get-mode
		croak 'The URI of this ID space is not defined.' if (!defined($_[0]->{URI}));
	}
	return $_[0]->{URI};
}

=head2 description

  Usage    - print $idspace->description() or $idspace->description($description)
  Returns  - the idspace description (string)
  Args     - the idspace description (string)
  Function - gets/sets the idspace description
  
=cut

sub description {
	if ($_[1]) { 
		$_[0]->{DESCRIPTION} = $_[1];
	} else { # get-mode
		croak 'Neither the local idspace nor the URI of this idspace is defined.' if (!defined($_[0]->{LOCAL_IDSPACE}) || !defined($_[0]->{URI}));
	}
	return $_[0]->{DESCRIPTION};
}

=head2 as_string

  Usage    - print $idspace->as_string()
  Returns  - returns this idspace (local_idspace uri "description") as string if it is defined; otherwise, undef
  Args     - none
  Function - returns this idspace as string
  
=cut

sub as_string {
	if ($_[1] && $_[2]){
		$_[0]->{LOCAL_IDSPACE} = $_[1];
		$_[0]->{URI}           = $_[2];
		$_[0]->{DESCRIPTION}   = $_[3] if ($_[3]);
		return; # set mode
	} else {
		croak 'Neither the local idspace nor the URI of this idspace is defined.' if (!defined($_[0]->{LOCAL_IDSPACE}) || !defined($_[0]->{URI}));
		my $result = $_[0]->{LOCAL_IDSPACE}.' '.$_[0]->{URI};
		$result   .= ' "'.$_[0]->{DESCRIPTION}.'"' if (defined $_[0]->{DESCRIPTION} && $_[0]->{DESCRIPTION} ne '');
		$result    = '' if ($result =~ /^\s*$/);
		return $result;
	}
}

=head2 equals

  Usage    - print $idspace->equals($another_idspace)
  Returns  - either 1(true) or 0 (false)
  Args     - the idspace (OBO::Core::IDspace) to compare with
  Function - tells whether this idspace is equal to the parameter
  
=cut

sub equals {
	if ($_[1] && eval { $_[1]->isa('OBO::Core::IDspace') }) {
		
		croak 'Neither the local idspace or the URI of this idspace is defined.' if (!defined($_[0]->{LOCAL_IDSPACE}) || !defined($_[0]->{URI}));
		croak 'Neither the local idspace or the URI of this idspace is defined.' if (!defined($_[1]->{LOCAL_IDSPACE}) || !defined($_[1]->{URI}));
		my $result = ((defined $_[0]->{DESCRIPTION} && defined $_[1]->{DESCRIPTION}) && ($_[0]->{DESCRIPTION} eq $_[1]->{DESCRIPTION}));
		return $result && (($_[0]->{LOCAL_IDSPACE} eq $_[1]->{LOCAL_IDSPACE}) &&
							($_[0]->{URI} eq $_[1]->{URI}));
	} else {
		croak "An unrecognized object type (not a OBO::Core::IDspace) was found: '", $_[1], "'";
	}
	return 0;
}

1;

__END__


=head1 NAME

OBO::Core::IDspace - A mapping between a "local" ID space and a "global" ID space.
    
=head1 SYNOPSIS

use OBO::Core::IDspace;

use strict;

my $idspace = OBO::Core::IDspace->new();


$idspace->local_idspace("APO");

$idspace->uri("http://www.cellcycleontology.org/ontology/APO");

$idspace->description("cell cycle ontology terms);

=head1 DESCRIPTION

An IDSpace is a mapping between a "local" ID space and a "global" ID space.

This object captures: 

	a local idspace, 
	a URI,
	quote-enclosed description (optional).
	
Example:

	GO urn:lsid:bioontology.org:GO: "gene ontology terms"

=head1 AUTHOR

Erick Antezana, E<lt>erick.antezana -@- gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006-2015 by Erick Antezana. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut