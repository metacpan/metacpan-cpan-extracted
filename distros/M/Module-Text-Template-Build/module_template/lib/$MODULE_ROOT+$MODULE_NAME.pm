{{
$|++ ;
unless(defined $MODULE_DESCRIPTION)
	{
	print q{'MODULE_DESCRIPTION' needed for template: '} . __FILE__ . "'.\n" ;
	print STDOUT "Please input module description: " ;
	$MODULE_DESCRIPTION = <STDIN> ;
	
	chomp $MODULE_DESCRIPTION ;
	}
	
undef ; # do not return last evaluated expression
}}
package {{$FULL_MODULE_NAME}} ;
#use base ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
#~ use Exporter ;
#~ use vars qw ($VERSION @ISA @EXPORT_OK @EXPORT_OK %EXPORT_TAGS);
#~ @ISA = qw(Exporter);
#~ @EXPORT_OK   = qw ();
#~ %EXPORT_TAGS = (all => [@EXPORT_OK]);

use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.01';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Carp qw(carp croak confess) ;

#-------------------------------------------------------------------------------

=head1 NAME

{{$FULL_MODULE_NAME}} - {{$MODULE_DESCRIPTION}}

=head1 SYNOPSIS


=head1 DESCRIPTION

This module implements ...

=head1 DOCUMENTATION

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => [qw(NAME INTERACTION)] ;

sub new
{

=head2 new( xxx )

Create a {{$FULL_MODULE_NAME}} .  

  my $object = {{$FULL_MODULE_NAME}}->new() ;

I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 Setup

Helper sub called by new. This is a private sub.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

if (@setup_data % 2)
	{
	croak "Invalid number of argument '$file_name, $line'!" ;
	}

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;
$self->{NAME} = 'Anonymous';
$self->{FILE} = $file_name ;
$self->{LINE} = $line ;

$self->CheckOptionNames($NEW_ARGUMENTS, @setup_data) ;

%{$self} = 
	(
	NAME                   => 'Anonymous',
	FILE                   => $file_name,
	LINE                   => $line,
	
	@setup_data,
	) ;

my $location = "$self->{FILE}:$self->{LINE}" ;

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::confess ;


if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 CheckOptionNames

Verifies the named options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. This shall not be used directly.

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	my @valid_options =  @{$valid_options} ;
	$valid_options = {map{$_ => 1} @valid_options} ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("Invalid argument '$valid_options'!") ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->
				(
				"$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'\nValid options:\n\t"
				.  join("\n\t", sort keys %{$valid_options}) . "\n"
				);
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub A
{

=head2 A( xxx )

xxx description

  xxx some code

I<Arguments>

=over 2 

=item * $xxx - 

=back

I<Returns> - Nothing

I<Exceptions>

See C<xxx>.

=cut

my ($self) = @_ ;

if(defined $self && __PACKAGE__ eq ref $self)
	{
	# object sub
	my ($var, $var2) = @_ ;
	
	}
else	
	{
	# class sub
	unshift @_, $self ;
	}

return(0) ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

#MODIFY_ME_BEFORE_FIRST_RUN

	your name here
	CPAN ID: 
	mailto:

=head1 COPYRIGHT AND LICENSE

#MODIFY_ME_BEFORE_FIRST_RUN

Copyright {{$YEAR}} .

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc {{$FULL_MODULE_NAME}}

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/{{$DISTRIBUTION}}>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-{{$RT_NAME}}@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/{{$DISTRIBUTION}}>

=back

=head1 SEE ALSO


=cut
