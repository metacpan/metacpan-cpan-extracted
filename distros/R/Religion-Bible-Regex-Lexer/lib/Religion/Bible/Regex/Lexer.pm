package Religion::Bible::Regex::Lexer;

use strict;
use warnings;
use Carp;

# Input/Output files are assumed to be in the UTF-8 strict character encoding.
use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");

use Carp;
use Storable qw(store retrieve freeze thaw dclone);
use Data::Dumper;

use Religion::Bible::Regex::Config;
use Religion::Bible::Regex::Reference;

use version; our $VERSION = '0.85';

# These constants are defined in several places and probably should be moved to a common file
# Move these to Constants.pm
use constant BOOK    => 'BOOK';
use constant CHAPTER => 'CHAPTER';
use constant VERSE   => 'VERSE'; 
use constant UNKNOWN => 'UNKNOWN';
use constant TRUE => 1;
use constant FALSE => 0;

sub new {
    my ($class, $config, $regex, $versification) = @_;
    my ($self) = {};
    $self->{'config'} = $config;
    $self->{'regex'} = $regex;
    $self->{'versification'} = $versification;
    bless $self, $class;
    return $self;
}

# Subroutines related to getting information
sub get_regexes {
    my $self = shift;
    confess "regex is not defined\n" unless defined($self->{regex});
    $self->{regex};
}

# Returns a reference to a Religion::Bible::Regex::Config object.
sub get_configuration {
    my $self = shift;
    confess "config is not defined\n" unless defined($self->{config});
    return $self->{config};
}

# Returns a reference to a Religion::Bible::Regex::Versification object.
sub get_versification {
    my $self = shift;
    return $self->{versification};
}

sub references { 
    shift->{reference_list};
}

sub parse {
    my ($self, $refstr, $con) = @_;
    my $state = "";
    my @result;
    my $r = $self->get_regexes;
    my $previous_reference = (defined($con)) ? $$con : undef;

    # Split the references apart by the separators, which are by default ';' and ','
    my @refs = split/([\s ]*(?:$r->{'cl_ou_vl_separateurs'})[\s ]*)/, $refstr;

    foreach my $token (@refs) {
	# The separator gives a clue as to the state of the next reference
	# If there is a ';' the next reference should have a state of BOOK or CHAPTER
	# If there is a ',' the next reference should have a state of VERSE
	# Of course, you can change these separator values in the configuration file
    if ($token =~ m/$r->{'cl_separateur'}/) {
        $state = CHAPTER; next; 
    } elsif (($token =~ m/$r->{'vl_separateur'}/)) {
        $state = VERSE; next;
	} elsif (($token =~ m/$r->{'separateur'}/)) {
        $state = $previous_reference->context;
        if (!_non_empty($state)) {
            $state = '';
        }
        next;
    }

    # Initialize the reference
    my $ref = new Religion::Bible::Regex::Reference($self->get_configuration, $self->get_regexes);     

	# Parse the reference
    $ref->parse($token, $state);

	# Combine the context of this reference with the previous reference
	$ref = $previous_reference->combine($ref) if defined($previous_reference);

	# Save the current reference as the previous reference
    $previous_reference = $ref; 

	# Save the current reference's state
    $state = $ref->state;

	# This should be rethought
    $$con = $previous_reference;

	# Do the versification 
	$ref = $self->get_versification->decalage($ref) if (defined($self->get_versification) && ref($self->get_versification) eq 'Religion::Bible::Regex::Versification');

	# Push the reference onto an array
        push @result, $ref; 
    } 
    
    $previous_reference = undef;
    $self->{reference_list} = \@result;
    return $self;
}

sub normalize {
    my $self = shift;
    my $ret = "";
    my $count = 0;
    my $next_state = undef;

    foreach my $ref (@{$self->{reference_list}}) {
        my $next = $self->{reference_list}->[++($count)];        

        # Print the formatted reference
        $ret .= $ref->formatted_normalize;

        # If no more refs then exit the loop
        last unless defined($next);

	$next_state = $next->state;
        
        if (defined($next) and $next_state eq VERSE) {
#            $ret .= $refconfig->get('verse_list_separateur');
	    $ret .= ', ';
        } elsif (defined($next) and $next_state eq CHAPTER) {
#            $ret .= $refconfig->get('chapter_list_separateur');
	    $ret .= '; ';
        } elsif (defined($next) and $next_state eq BOOK) {
#            $ret .= $refconfig->get('book_list_separateur');
	    $ret .= ', ';
        } else {
            carp "Reference has an UNKNOWN next_statearsion " . $ref->normalize . " and " . $next->normalize . "\n"; 
#            $ret .= $refconfig->get('book_list_separateur');
        }
    }
    return $ret;
}


# Dynamically call a formatter
sub format {
    my $self = shift;
    my $func = shift || 'normalize';

    {
        no strict ;
        return &{$func}($self);
    }
}

###################################################################################################################
# grouping: for the Bible Online (BOL) this can have the following values: BOOK, CHAPTER, VERSE, NONE
# For example when giving a reference these transformations take place:
#    BOOK Grouping    : Mt 1:1, 2, 3; 4:5; Jn 3:16  ==> \\Mt 1:1, 2, 3; 4:5; Jn 3:16\\
#    CHAPTER Grouping : Mt 1:1, 2, 3; 4:5; Jn 3:16  ==> \\Mt 1:1, 2, 3; 4:5\\; \\Jn 3:16\\
#    VERSE Grouping   : Mt 1:1, 2, 3; 4:5; Jn 3:16  ==> \\Mt 1:1, 2, 3\\; \\Mt 4:5\\; \\Jn 3:16\\
#    NONE Grouping    : Mt 1:1, 2, 3; 4:5; Jn 3:16  ==> \\Mt 1:1\\, \\Mt 1:2\\, \\Mt 1:3\\; \\Mt 4:5\\; \\Jn 3:16\\
###################################################################################################################

sub bol {
    my $self = shift;
    my $ret = "";
    my $count = 0;
    my $state = undef;
    my $inside = FALSE; 
    
    foreach my $ref (@{$self->{reference_list}}) {
        my $next = $self->{reference_list}->[++($count)];        

	  if (defined($ref->context_words) && !($ref->context_words =~ m/(?:@{[$self->get_regexes->{'livres_et_abbreviations'}]})/) ) {
	      $ret .= $ref->context_words || '';
	      $ret .= ' ' if defined($ref->s2);
  	}
     
    unless ($inside) {
      $ret .= '\\\\#'; 
      $inside = TRUE;
    }
	
     my $tmp = $ref->bol($state);
  	($tmp = $tmp) =~ s/^(?:@{[$self->get_regexes->{'chapitre_mots'}]}|@{[$self->get_regexes->{'verset_mots'}]})//g;	

	  $tmp =~ s/^[\s ]*//g;
  	$tmp =~ s/[\s ]*$//g;

  	$ret .= $tmp;

    if (!defined($next)) {
      $ret .= '\\\\';
	    last;
    }

    # If no more refs then exit the loop
    # last unless defined($next);

    # if (_non_empty($next->context_words)) {
        if (_non_empty($next->context_words) && !($next->context_words =~ m/(?:@{[$self->get_regexes->{'livres_et_abbreviations'}]})/)) {
            $ret .= '\\\\';
            $inside = FALSE;
            $state = BOOK;
        } else {
            $state = $ref->shared_state($next) || $next->state;
        }

        if (defined($next) and $state eq VERSE) {
#           $ret .= $refconfig->get('verse_list_separateur');
	          $ret .= ', ';
        } elsif (defined($next) and $state eq CHAPTER) {
#            $ret .= $refconfig->get('chapter_list_separateur');
             $ret .= '; ';
        } elsif (defined($next) and $state eq BOOK) {
#            $ret .= $refconfig->get('book_list_separateur');
             $ret .= '; ';
        } else {
            carp "Reference has an UNKNOWN comparsion " . $ref->normalize . " and " . $next->normalize . "\n"; 
#            $ret .= $refconfig->get('book_list_separateur');
        }
    }
    return $ret;
}


sub _non_empty {
    my $value = shift;
    return (defined($value) && $value ne '');
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Religion::Bible::Regex::Lexer - [One line description of module's purpose here]


=head1 VERSION

This document describes Religion::Bible::Regex::Lexer version 0.0.1


=head1 SYNOPSIS

    use Religion::Bible::Regex::Lexer;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=head2 	get_configuration
=head2 	get_regexes
=head2  get_versification
=head2 	new
=head2 	parse
=head2  normalize
=head2 	bol
=head2 	bol_test
=head2 	format
=head2  references

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
  
Religion::Bible::Regex::Lexer requires no configuration files or environment variables.


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
C<bug-religion-bible-regex-lexer@rt.cpan.org>, or through the web interface at
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
