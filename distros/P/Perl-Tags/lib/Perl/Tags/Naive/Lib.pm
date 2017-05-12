package Perl::Tags::Naive::Lib;

use strict; use warnings;
use parent 'Perl::Tags::Naive';

our $VERSION = '0.32';

=head2 C<get_parsers>

The following parsers are defined by this module.

=over 4

=cut

sub get_parsers
{
        my $self = shift;
        return (
                $self->SUPER::get_parsers(),
                $self->can('uselib_line'),
        );
}


=item C<uselib_line>

Parse a use/require lib line
Unshift libraries found onto @INC.

=cut

sub uselib_line {
    my ($self, $line, $statement, $file) = @_;

    my @ret;
    if ($statement=~/^(?:use|require)\s+lib\s+(.*)/) {
        my @libraries = split /\s+/, $1; # may be more than one

        for (@libraries) {
            s/^q[wq]?[[:punct:]]//;
            /((?:\w|:)+)/;
            $1 and unshift @INC, $1;
        }
    }
    return @ret;
}

1;

=back

#package Perl::Tags::Tag::Recurse::Lib;
#
#our @ISA = qw/Perl::Tags::Tag::Recurse/;
#
#=head1 C<Perl::Tags::Tag::Recurse::Lib>
#
#=head2 C<type>: dummy
#
#=head2 C<on_register>
#
#Recurse adding this new module accessible from a use lib statement to the queue.
#
#=cut
#
#package Perl::Tags::Tag::Recurse;
#
#sub on_register {
#    my ($self, $tags) = @_;
#
#    my $name = $self->{name};
#    my $path;
#    my @INC_ORIG = @INC;
#    my @INC = 
#    eval {
#        $path = locate( $name ); # or warn "Couldn't find path for $module";
#    };
#    # return if $@;
#    return unless $path;
#    $tags->queue( { file=>$path, level=>$tags->{current}{level}+1 , refresh=>0} +);
#    return; # don't get added
#}

##

1;

=head1 AUTHOR and LICENSE

    dr bean - drbean at sign cpan a dot org
    osfameron (2006) - osfameron@gmail.com

For support, try emailing me or grabbing me on irc #london.pm on irc.perl.org

This was originally ripped off pltags.pl, as distributed with vim
and available from L<http://www.mscha.com/mscha.html?pltags#tools>
Version 2.3, 28 February 2002
Written by Michael Schaap <pltags@mscha.com>.

This is licensed under the same terms as Perl itself.  (Or as Vim if you +prefer).

=cut
