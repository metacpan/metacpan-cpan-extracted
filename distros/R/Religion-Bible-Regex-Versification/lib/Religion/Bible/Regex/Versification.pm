package Religion::Bible::Regex::Versification;

use warnings;
use strict;
use Carp;

use Religion::Bible::Regex::Reference;

use version; our $VERSION = '0.2';

# There are four way to initialize a versification map
# 1. Pass in a string representing the location of a versification file
# 2. Pass in an array of verse pairs. Ex. [['Ge 1:1', 'Ge 1:2']]
# 3. Pass in a hash of vers pairs. Ex. { 'Ge 1:1' => 'Ge 1:2' }
# 4. Put the versification map in the YAML configuration file
sub new {
    my ($class, $config, $regex, $versification_file) = @_;
    my ($self) = {};
    bless $self, $class;

    $self->{config} = $config or confess 'Versification requires a Religion::Bible::Regex::Config object';
    $self->{regex} = $regex   or confess 'Versification requires a Religion::Bible::Regex::Builder object';

    # is the versification map defined in the config object?
    if (defined($config->get_versification_configurations)) {
	# Build the versification map from the configuration object
	$self->{versification} = $self->normalize_map( $config->get_versification_configurations );

    # does $versification_file exist?
    } elsif (-e $versification_file) {
	# Build the versification map from a file
	$self->{versification} = $self->normalize_map( $self->parse_versification_map($versification_file) );

    # if $versification_file is an array or hash
    } elsif (ref($versification_file) eq 'HASH' || ref($versification_file) eq 'ARRAY') {
	$self->{versification} = $self->normalize_map( $versification_file );
    }

    return $self;
}

# Subroutines related to getting information
sub get_regexes {
  my $self = shift;
  confess "regex is not defined\n" unless defined($self->{regex});
  return $self->{regex};
}

# Returns a reference to a Religion::Bible::Regex::Config object.
sub get_configuration {
  my $self = shift;
  confess "config is not defined\n" unless defined($self->{config});
  return $self->{config};
}

sub parse_versification_map {
    my $self = shift;
    my $config = $self->{config};
    my $map = shift;
    my $r1 = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);
    my @versification_array;

    croak "Versification mapping is not defined\n" unless (defined($map));

    if (-e $map) {
	open(my ($list), "<:encoding(UTF-8)", $self->{file}) || croak "Could not open versification mapping file, \'$self->{file})\': $!\n";

	while (<$list>) {
	    chomp;                  # no newline
	    s/[^\\]#.*//;           # no comments si il y a un '\' devant le '#' il n'est pas un commentarie
	    s/^\s+//;               # no leading white
	    s/\s+$//;               # no trailing white
	    next unless length;     # anything left?

	    my ($key, $value) = split /,/;
	    push @versification_array, [$key, $value];
	} 
	close ($list);
    }

    return @versification_array;
}


sub normalize_map {
    my $self = shift;
    my $map = shift;
    my %versification_map; 
   
    # Create a reusable Reference Object
    my $r1 = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);

    # versification_file is an array ... normalize it.
    if ( ref($map) eq 'ARRAY' ) {
	foreach my $c (@{$map}) {
	    my $r2 = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);
	    $r1->parse($c->[0]); 
	    $r2->parse($c->[1]); 
	    $versification_map{ $r1->normalize } = $r2;
	}

    # versification_file is an array ... normalize it.
    } elsif ( ref($map) eq 'HASH' ) {
	while ( my ($key, $value) = each(%$map) ) {   
	    my $r2 = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);
	    $r1->parse($key);
	    $r2->parse($value); 
	    $versification_map{ $r1->normalize } = $r2;
	}
	
    # carp 
    } else {
	carp "versification_map must be either an array or a hash\n" 
	    unless (ref($map) eq 'HASH' || ref($map) eq 'ARRAY');
    }

    # if map is not a HASH or an ARRAY then an empty hash is returned
    return \%versification_map;
}

sub decalage {
    my $self = shift;
    my $reference = shift;

    # Versification can only be done for references with a book, chapter and verse
    return $reference unless ($reference->is_explicit);

    # Since the versification files that we have only contain LCV style references
    # If we have a references like Ps 3:1-9, where Ps 3:1 is not shifted, but Ps 3:9 is shifted
    # then we must break it apart into Ps 3:1 and Ps 3:9, shift both references and recombine them
    if ($reference->has_interval) { 
        my $r1 = $reference->begin_interval_reference;
        my $r2 = $reference->end_interval_reference;

        my $dref1 = $self->decalage($r1);
        my $dref2 = $self->decalage($r2);

        return $dref1->interval($dref2);
    } else {
	my $normalized_reference = $reference->normalize;
        if (defined($self->{versification}->{$normalized_reference})) {
            my $ref_decale = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);

            # Be sure to make a copy of the reference, otherwise changing the reference later would 
            # in the versification map
            $ref_decale->{reference} = &Storable::dclone($self->{versification}->{$normalized_reference}->{reference});
            $ref_decale->set_b($reference->ob);
            $ref_decale->set_b2($reference->ob2);
            return $ref_decale; 
        }
    }
    return $reference;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Religion::Bible::Regex::Versification - Translates Bible references between different versifications

=head1 VERSION

This document describes Religion::Bible::Regex::Versification version 0.0.1


=head1 SYNOPSIS

    use Religion::Bible::Regex::Versification;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.

=head2 new
=head2 normalize_map
=head2 parse_versification_map

=head2	decalage
=head2	get_configuration
=head2 	get_regexes


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
Religion::Bible::Regex::Versification requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-religion-bible-regex-versification@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Daniel Holmlund  C<< <holmlund.dev@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Daniel Holmlund C<< <holmlund.dev@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
