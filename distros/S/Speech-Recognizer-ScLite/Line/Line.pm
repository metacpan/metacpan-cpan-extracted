package Speech::Recognizer::ScLite::Line;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.01';

##################################################################
# set up a whole bunch of default object management code.
# ask Class::MethodMaker to build methods:
use Class::MethodMaker 

    # constructor that calls 'init'
    new_with_init => 'new',

    # initializer that sets an instance's data from a hash
    # (private by convention of leading _)
    new_hash_init => '_hash_init',

    # methods to access/modify scalar data fields
    get_set => [ qw / ref hyp wf_id sort_key / ];

##################################################################
# if new() gets any arguments, they'll be passed here.
# Regardless of whether it does, we want to initialize at least a few
# fields in the instance.
sub init ($;%) {
    my ($self) = shift;
    my (%args) = @_;

    # check for abuse
    if (not defined $args{wf_id}) {
	croak "->new() invoked without (wf_id => ...) argument pair";
    }

    # set default values for some data fields
    if (not defined $args{sort_key}) {
	use File::Basename 'dirname';
	$args{sort_key} = dirname('wf_id');
    }

    # force users to defined all fields at initialization:
    if (not defined $args{ref}) {
	croak "'ref' => ...  not specified to new()";
    }
    if (not defined $args{hyp}) {
	croak "'hyp' => ...  not specified to new()";
    }
    # invoke the appropriate initializers
    $self->_hash_init(%args);
}
##################################################################
# shared only out to clan (Speech::Recognizer::ScLite::*)
sub _write_hyp ($$) {
    my ($self) = shift;
    my ($fh) = shift;
    croak "_write_hyp expects exactly 1 filehandle arg" 
	if not defined $fh or scalar @_;
    $self->_write_line($fh, $self->hyp);
}
##################################################################
# shared only out to clan (Speech::Recognizer::ScLite::*)
sub _write_ref ($$) {
    my ($self) = shift;
    my ($fh) = shift;
    croak "_write_ref expects exactly 1 filehandle arg" 
	if not defined $fh or scalar @_;
    $self->_write_line($fh, $self->ref);
}
##################################################################
# generic function, shared only internally
sub _write_line($$$) {
    my ($self) = shift;
    my ($fh) = shift;
    my ($text) = shift;
    print { $fh } $text, "\t(", $self->sort_key, '_', $self->wf_id, ")\n";
}
##################################################################

1;
__END__
# Documentation below.

=head1 NAME

Speech::Recognizer::ScLite::Line - Stores a single datum for use in
C<Speech::Recognizer::ScLite>

=head1 SYNOPSIS

See L<Speech::Recognizer::ScLite>.

=head1 DESCRIPTION

Data-bearing class for C<Speech::Recognizer::ScLite> speech
recognition scoring utility.

=head1 Methods

=head2 Class methods

=over

=item ->new(C<wf_id> => I<unique-string>, [ I<attribute> => I<value> ]*)

Class method. Creates a new instance of this class. Takes as
arguments:

=over

=item C<wf_id> => I<unique-string>

C<new()> always requires you to identify the wf_id when you call it.

=item I<attribute> => I<value>

C<new()> allows any number of additional I<attribute>-I<value> pairs,
where I<attribute> is one of the data fields of this object (see
L</Data access methods> below).

=back

=head2 Data access methods

=over

=item ->ref()

Gets sets the I<reference> text. This should be the correct
transcription (for some values of "correct").

=item ->hyp()

Gets/sets the I<hypothesized> text. This should be what your reco system
thought was the right transcription.

=item ->wf_id()

Gets/sets the waveform ID of the datum. This should probably be some
unique key to the line. Usually, this is the full path to the waveform
you tested.  This should probably not be altered after setting it in
the C<new()> call, but the function is available for those who wish to
work such black magic.

=item ->sort_key()

Gets/sets the I<sort group> for this key. This reflects the membership
in an arbitrary group.  

If not specified by argument to C<new()> or by calling this function,
the default sort_key will be the directory name of the C<wf_id>
you pass in. 

See L<Speech::Recognizer::ScLite/SYNOPSIS> for an example of an
alternate C<sort_key> setting.

=back

=head2 Clan methods

The following methods are intended to be called by very friendly
classes (e.g. C<Speech::Recognizer::ScLite>) -- hence the leading
underscores. But since they are not strictly private methods, they are
documented below.

=over

=item ->_write_hyp(I<Filehandle>)

Writes a "hyp" line to the I<Filehandle> provided, in the format that
C<Speech::Recognizer::ScLite> expects.

=item ->_write_ref(I<Filehandle>)

Writes a "ref" line to the I<Filehandle> provided, in the format that
C<Speech::Recognizer::ScLite> expects.

=back

=head1 HISTORY

=over

=item 0.01

Original version; created by h2xs 1.21 with options

  -CAX
	Speech::Recognizer::ScLite::Line

=back

=head1 AUTHOR

Jeremy Kahn, E<lt>kahn@cpan.orgE<gt>

=head1 SEE ALSO

L<Speech::Recognizer::ScLite>.

L<perl>.

=cut

