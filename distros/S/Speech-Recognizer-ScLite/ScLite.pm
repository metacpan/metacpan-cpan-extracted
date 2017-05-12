package Speech::Recognizer::ScLite;

use 5.006;
use strict;
use warnings;
use Carp;

# directory maintenance
use Cwd 'cwd', 'chdir';
use File::Spec::Functions 'rel2abs', 'curdir';

our $VERSION = '0.01';
##################################################################
# set up a whole bunch of default object management code.
# ask Class::MethodMaker to build methods:
use Class::MethodMaker
    # constructor that calls 'init'
    new_with_init => 'new',

    # initializer that sets an instance's data from a hash
    new_hash_init => '_hash_init',

    # methods to access/modify scalar data fields
    get_set => [ qw / result_location _invoke_loc / ], 

    static_get_set => [ 'executable' ],

    # scalars must be unique within class:
    key_attrib => 'id',

    # methods to access the internal list of lines
    object_list => [ 'Speech::Recognizer::ScLite::Line' =>
		     { 
			 slot => 'lines',
#			 comp_mthds => [ ]
		     } 
		   ],

    # methods to access internal state
    # (private by convention of leading _)
    boolean => '_scored'; 

##################################################################
# defaults to be overridden during init()
my (%init_defaults) = 
    (result_location => curdir, # default current location
     id => 'ScLite'); # if ya don't like it, change it
##################################################################
sub init($;%) {

    my ($self) = shift;
    my ($class) = ref $self;

    # override init_defaults with user supplied values
    my (%args) = (%init_defaults, @_); 
    
    # any missing error checking?

    if (not defined $class->executable) {
	$class->executable ( 'sclite' );
    }
   
    my ($cwd) = cwd();

    # absolutize the result_location
    $args{result_location} = rel2abs( $args{result_location}, $cwd );

    if ($class->find_id($args{id})) {
	carp "value '" . $args{id} . " already registered, " .
	    "overwriting files";
    }

    # remember directory in which I was invoked
    $args{_invoke_loc} = $cwd;

    # illegal user values will throw exceptions inside _hash_init
    $self->_hash_init(%args);
}
##################################################################
sub clear($) {
    my ($self) = shift;
    croak "expect 0 arguments to ->clear()" if scalar @_;
    
    $self->lines_clear();
}
##################################################################
sub id_keys($) {
    my ($class) = shift;
    return sort keys %{$class->find_id};
}
##################################################################
sub all($) {
    my ($class) = shift;
    return $class->find_id($class->id_keys);
}
##################################################################
sub score($) {
    my ($self) = shift;

    # check for user argument errors
    croak "unexpected arguments to ->score()" if scalar @_;

    # check that $self 's appropriate fields have been set?
    carp "already scored '" . $self->id . "', re-scoring"
	if $self->_scored;
    
    # get a temporary dir
    use File::Temp 'tempdir';
    my ($tempdir) = tempdir(CLEANUP => 1); 

    # hang on to the working directory so we can go back to it.
    my ($wd) = cwd(); 

    # chdir to the tempdir:
    chdir $tempdir or die "couldn't chdir to $tempdir";

    # get filehandles for new files
    my ($reffile) = $self->id . '.ref';
    my ($hypfile) = $self->id . '.hyp';
    my ($refFH) = _getFH($reffile);
    my ($hypFH) = _getFH($hypfile);

    # write the hyp & ref files
    foreach my $l ($self->lines) {
	$l->_write_ref($refFH);
	$l->_write_hyp($hypFH);
    }

    # close the filehandles
    $refFH->close() or die "couldn't close $reffile";
    $hypFH->close() or die "couldn't close $hypfile";
    
    # do the actual scoring
    my ($rc) = system ($self->_get_cmd($reffile, $hypfile, $wd));

    # decide what to do based on return code?

    # chdir back to original working directory
    chdir $wd or die "couldn't chdir back to $wd after scoring";

    # remember that we've done this
    $self->set__scored();

    return $rc << 8;
}
##################################################################
sub score_all {
    my ($class) = shift;
    foreach ($class->all) {
	$_->score();
    }
}    
##################################################################
# private instance method to determine all the necessary command
# options 
sub _get_cmd ($$$$) {
    my ($self) = shift;
    my ($class) = ref ($self);
    my ($ref, $hyp, $wd) = @_;
    confess "bad args to _get_cmd" unless @_ == 3;

    my (@items) = $class->executable;
    
    push @items, '-i', 'swb'; # why do I need this?
    push @items, '-o', 'dtl', 'spk', 'all'; # check these scoring options

    # this makes report() function a no-op in this version
    push @items, '-O', rel2abs( $self->result_location, $self->_invoke_loc );

    push @items, '-r', $ref;
    push @items, '-h', $hyp;

    return @items;
}     
##################################################################
sub _getFH ($) {
    use FileHandle;
    my ($filename) = shift;
    my ($fh) = new FileHandle ">$filename";
    if (not defined $fh) {
	die "couldn't open $filename in " . cwd() . "\n";
    }
    return $fh;
}
##################################################################
sub report() {
#      my ($self) = shift;

#      # check for user argument errors
#      croak "unexpected arguments to ->report()" if scalar @_;

#      # check that $self's appropriate fields have been set
#      if (not defined $self->result_location) {
#  	use Cwd 'cwd';
#  	$self->result_location( '.' );
#  	$self->result_location( rel2abs( $self->result_location )  );
#      }
	

#      # ensure we've actually done the score() call
#      croak "you seem to have called ->report() without calling " .
#  	"->score()." unless $self->_scored;

#      # copy the files to the right location
}
    
##################################################################
1;
__END__
# Documentation below

=head1 NAME

Speech::Recognizer::ScLite - Object-based wrapper around the C<sclite>
tool from the NIST SCTK.

=head1 SYNOPSIS

  # gather the correct and hypothesized readings any way you like. 
  # here I assume you have them in two text files that can be parsed
  # successfully by the toy sub read_trans below.
  my (%correct_readings) = read_trans('correct.txt');
  my (%hyp_readings) = read_trans('hypotheses.txt');

  # real work begins here
  use Speech::Recognizer::ScLite;

  # alter the default ('sclite') executable-name or a path to it
  Speech::Recognizer::ScLite->executable( 
				 '/usr/site/bin/SCTK-1-04/sclite-1-04' );

  my ($scorer) = 
    Speech::Recognizer::ScLite->new( 'result_location' => './test_17',
				     id => 'Sex'); 
                                     # that oughtta increase the CPAN hits

  foreach my $line (sort keys %hyp_readings) {
    # construct an object to represent this version
    # construct any sort key you want. Here we assume that we're
    # interested in breaking out the files based on which directory
    # they're in.
    my ($l) = 
      Speech::Recognizer::ScLite::Line->new( 
					 ref => $correct_readings{$line},
					 hyp => hyp_readings{$line},
					 sort_key => getSort($line)
					 );
					 
    $scorer->lines_push($l);

  } # end of looping over the filenames.

  # computes actual ASR performance, given above information
  $scorer->score();

  # dumps a wordy report into the ->result_location;
  #  $scorer->report(); # currently a no-op since score() invokes
  # reporting function within the sclite utility itself
  

  ################################################################
  # toy subs defined below for the sake of the completeness of the
  # example. 
  sub read_trans {
    my (%transcriptions);
    open (FILE, shift); # or die, of course
    while (<FILE>) {
      chomp;
      my ($trans, $file) = split;
      $transcriptions{$file} = $trans;
    }
    close FILE; # or die, of course
    return %transcriptions;
  }
  # this toy sort routine returns the sex of the speaker as the sort
  # key, rather than the (default) speaker directory.
  sub getSort {
    my ($filename) = shift;
    return ($filename =~ /female/i ? 'Female' : 'Male');
  }

=head1 DESCRIPTION

Provides an object-oriented interface to the C<sclite> tool provided
in the NIST SCTK, which is available from here:

  http://www.nist.gov/speech/tools/index.htm

It is intended to expose all the basic functionality of the C<sclite>
command line and 

This is motivated by several reasons:

=over

=item * 

A few other tools exist, but most of them are explicitly designed to
work with particular input forms, e.g.:

=over

=item *

  http://www.nist.gov/speech/tests/sdr/sdr99/pages/faq/SRT_FAQ.htm#OVERVIEW

=item *

  http://communicator.sourceforge.net/sites/MITRE/distributions/GalaxyCommunicator/ contrib/MITRE/tools/docs/log_tools.html 

=back

=item *

Managing large numbers of commandline options can be painful.

=item *

The C<sclite> tool assumes that one particular sort of the data is
interesting -- sorting by the "speaker" of the waveform. This is not
necessarily the most interesting sort -- and it's certainly not the
only interesting sort.  This tool provides the ability to sort by
whatever sort key I<you're> interested in, not the "speaker".

The sort should be transparent to the user.

=item *

Parsing text data is not really that hard in Perl, but why should more
than one person figure all this out? This will allow other researchers
to easily use the C<sclite> tool with results from any format -- they
need only solve the problem of extracting the text appropriately.

=back

=head1 Methods

=head2 Class methods

=over

=item ->new([ I<attribute> => I<value> ]*)

Class method. Creates a new instance of this class. Takes as arguments
any number of I<attribute>-I<value> pairs, where I<attribute> is one
of the data (see L</Data access methods> below).

=item ->executable()

Gets/sets the location of the executable C<sclite> engine.

=item ->find_id(I<id>)

Returns reference to the object with C<id> == I<id>.

=item ->id_keys()

Returns list of valid ids.

=item ->all()

Returns list of existing instances.

=item ->score_all()

Executes C<score()> on all instances.

=back

=head2 Action methods

=over

=item ->lines_push(I<C<Speech::Recognizer::ScLite::Line> instance>)

Adds a new datum to this C<ScLite> object.

=item ->clear()

Clears list of lines that were added through C<addLine()>.

=item ->score()

Does the work of actually scoring the various C<Line> objects and
computing the summaries. 

Currently, this version shells out in order to execute this
command. It would be nice to fix this.

=item ->report()

Places the score report in the directory previously identified by
C<result_location> (or its default).

It is required that you call C<score()> before you call C<report()> on
a given instance. (This should be obvious to the users.)

NOTE: This function is currently a no-op since early revisions of this code
invoke an option to sclite that dumps a report during C<score()>.

=back

=head2 Data access methods

=over

=item ->result_location()

Gets/sets the directory in which the results are to be put, after
C<score()> is called. Note that this target, in the future, will be
populated with files after C<report()> is called instead.

=item ->id()

Gets/sets the identifier for this score. Results files use this name
as a stem.

=back

=head1 TO DO (planned)

=over

=item *

Implement base code, using assumption that compiled executable
exists. This includes adding the additional features of sort order.

Still remaining at this phase:

=over

=item *

Make sure that functions and options of the C<sclite> executable are
all visible through the OOP interface.

=back

=item *

Add code to parse the output files, and store the data in Perl-ish
data structures, to make it easier to put together reports in
alternate formats.

=item *

Rebuild to use the C<sclite> C code directly (through XS).

=back

=head1 HISTORY

=over 8

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Speech::Recognizer::ScLite

=back


=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut
