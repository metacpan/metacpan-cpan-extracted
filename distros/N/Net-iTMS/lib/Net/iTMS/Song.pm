package Net::iTMS::Song;
#
# Written by Thomas R. Sibley, <http://zulutango.org:82/>
#
use warnings;
use strict;

use vars '$VERSION';
$VERSION = '0.13';

use Net::iTMS::Error;

use overload
	'""'     => sub { shift->as_string },
	fallback => 1;

sub as_string {
    my $self = shift;
    
    return defined $self
            ? $self->name
            : undef;
}

=head1 NAME

Net::iTMS::Song - Represents a song in the iTunes Music Store

=head1 DESCRIPTION

A Net::iTMS::Song object represents a single song in the iTMS.  Currently,
it's only a shell object, but in future releases it may have extra
functionality other than a convenient data store.

=head2 Methods

Most of the methods should be pretty self-explanatory.  Except for C<new>,
they all return the information they're named after.

=over 12

=item new($itms, $songId)

The first argument must be an instance of Net::iTMS, the second an
iTMS song ID.

Returns a blessed hashref (object) for Net::iTMS::Song.

=cut
sub new {
    my ($class, $itms, $id, %prefill) = @_;
    
    my $self = bless {
        id    => $id,
        error => '',
        debug => defined $itms->{debug} ? $itms->{debug} : 0,
        _itms => $itms,
    }, $class;
    
    if (%prefill) {
        $self->{$_} = $prefill{$_}
            for keys %prefill;
    }
    
    return $self;
}

=item id

=item title

=item name

=item artist

=item album

=item genre

=item year

=item number

=item count

=item disc_number

=item disc_count

=item explicit

=item comments

=item copyright

=item preview_url

=item released

=item price

=cut
sub id          { return $_[0]->{id} }
sub title       { return $_[0]->{title} }
sub name        { return $_[0]->{title} }
sub artist      { return $_[0]->{artist} }
sub album       { return $_[0]->{album} }
sub genre       { return $_[0]->{genre} }
sub year        { return $_[0]->{year} }
sub number      { return $_[0]->{number} }
sub track       { return $_[0]->{number} }
sub count       { return $_[0]->{count} }
sub disc_number { return $_[0]->{disc_number} }
sub disc_count  { return $_[0]->{disc_count} }
sub explicit    { return $_[0]->{explicit} }
sub comments    { return $_[0]->{comments} }
sub copyright   { return $_[0]->{copyright} }
sub preview_url { return $_[0]->{preview_url} }
sub released    { return $_[0]->{released} }
sub price       { return $_[0]->{price} }

=back

=head1 LICENSE

Copyright 2004, Thomas R. Sibley.

You may use, modify, and distribute this package under the same terms as Perl itself.

=head1 AUTHOR

Thomas R. Sibley, L<http://zulutango.org:82/>

=head1 SEE ALSO

L<Net::iTMS>, L<Net::iTMS::Album>, L<Net::iTMS::Artist>, L<Net::iTMS::Genre>

=cut

42;
