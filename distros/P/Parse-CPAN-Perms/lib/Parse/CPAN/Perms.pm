# ABSTRACT: Parse 06perms.txt.gz

package Parse::CPAN::Perms;

#-----------------------------------------------------------------------------

our $VERSION = '0.004'; # VERSION

#-----------------------------------------------------------------------------

use Moose;
use IO::Zlib;
use File::stat;
use Carp qw(croak);

#-----------------------------------------------------------------------------

has permsfile => (
	is        => 'ro',
	isa       => 'Str',
	required  => 1,
);


has perms => (
	is        => 'ro',
	isa       => 'HashRef',
        builder   => 'build_perms',
        clearer   => 'clear_perms',
        lazy      => 1,
);


has mtime => (
	is        => 'rw',
	isa       => 'Int',
        default   => 0,
);

#-----------------------------------------------------------------------------

around BUILDARGS => sub {
	my ($orig, $class)  = (shift, shift);

        return $class->$orig(@_) unless @_ %2 or ref $_[0] eq 'HASH';

        my $path = shift;
        my $arg = -f $path ? $path : "$path/modules/06perms.txt.gz";

   	return {permsfile => $arg, @_};
 };

#-----------------------------------------------------------------------------

sub build_perms {
    my ($self) = @_;

    my $permsfile = $self->permsfile;

    my $fh = IO::Zlib->new( $permsfile, "rb" );
    croak "Failed to read $permsfile: $!" unless $fh;
    my $perms_data = $self->__read_perms($fh);
    $fh->close;

    my $mtime = (stat $permsfile)->mtime;
    $self->mtime($mtime);

    return $perms_data;
}

#-----------------------------------------------------------------------------

sub __read_perms {
	my ($self, $fh) = @_;

	my $inheader = 1;
	my $perms = {};

    while (<$fh>) {

        if ($inheader) {
            $inheader = 0 if not m/ \S /x;
            next;
        }

    	chomp;
        my ($module, $author, $perm) = split m/\s* , \s*/x;
    	$perms->{$module}->{$author} = $perm;
    }

    return $perms;
}

#-----------------------------------------------------------------------------

sub is_authorized {
    my ( $self, $author, $module ) = @_;

    return 0 unless $author && $module;

    my $perms = $self->perms;

    return 1 if not exists $perms->{$module}; # Old mods may not have perms
    return 1 if exists $perms->{$module}->{$author};
    return 0;
}

#-----------------------------------------------------------------------------

sub refresh {
    my ($self, $force) = @_;

    my $mtime = (stat $self->permsfile)->mtime;
    return $self unless $mtime > $self->mtime or $force;

    $self->clear_perms;

    return $self;
}

#-----------------------------------------------------------------------------
1;

__END__

=pod

=for :stopwords Jeffrey Ryan Thalhammer cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Parse::CPAN::Perms - Parse 06perms.txt.gz

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  # Construction
  my $perms = Parse::CPAN::Perms->new('path/to/06perms.txt.gz');

  # Get all perms data as hash ref
  my $perms_data = $perms->perms;

  # Boolean convenience method
  $perms->is_authorized(AUTHOR => 'Package::Name');

=head1 DESCRIPTION

!! THIS MODULE IS EXPERIMENTAL.  INTERFACE IS SUBJECT TO CHANGE !!

This module parses the F<06perms.txt.gz> file from a CPAN-like repository.
At this time, it only parses the compressed form and it provides no mechanism
for adding new permissions or writing the data back out to a file.  If you
desire those features, please contact the author.

=head1 CONSTRUCTOR

=over 4

=item new('path/to/06perms.txt.gz')

=item new(parmsfile => 'path/to/06perms.txt.gz')

Constructs a new instance of Parse::CPAN::Perms from the specified perms file.
The file must exist and must be readable.

=back

=head2 METHODS

=over 4

=item perms()

Returns all the permission data as a hash reference

=item is_authorized(AUTHOR => 'Package::Name')

Returns true if the author has permission for the package

=item refresh( $force )

Causes the permisions hash to be cleared if the C<permsfile> has
changed since the last time it was read.  The permissions hash will be
lazily re-read from disk the next time it is needed.  If C<$force> is
true, then the permissions hash is cleared unconditionally.

=back

=head1 SEE ALSO

L<CPAN::Repository::Perms> serves a similar purpose, but is a much more robust 
module.  However, it is bundled with several other CPAN-related modules which 
may or may not fit your needs and desires.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Parse::CPAN::Perms

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/Parse-CPAN-Perms>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Parse-CPAN-Perms>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Parse-CPAN-Perms>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/P/Parse-CPAN-Perms>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Parse-CPAN-Perms>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Parse::CPAN::Perms>

=back

=head2 Internet Relay Chat

You can get live help by using IRC ( Internet Relay Chat ). If you don't know what IRC is,
please read this excellent guide: L<http://en.wikipedia.org/wiki/Internet_Relay_Chat>. Please
be courteous and patient when talking to us, as we might be busy or sleeping! You can join
those networks/channels and get help:

=over 4

=item *

irc.perl.org

You can connect to the server at 'irc.perl.org' and join this channel: #pinto then talk to this person for help: thaljef.

=back

=head2 Bugs / Feature Requests

L<https://github.com/thaljef/Parse-CPAN-Perms/issues>

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/thaljef/Parse-CPAN-Perms>

  git clone git://github.com/thaljef/Parse-CPAN-Perms.git

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
