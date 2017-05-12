package Pod::Generate::Recursive;

use strict;
use warnings;

use vars qw{
  $VERSION
  @ISA
  @EXPORT
  @EXPORT_OK
  $source
  $destination
  $debug
  };

BEGIN
{
    require Exporter;

    @ISA       = qw( Exporter );
    @EXPORT    = qw( debug destination source);
    @EXPORT_OK = qw( );
}

use Data::Dumper qw(Dumper);
use File::Find qw( finddepth );
use File::Path qw( make_path );
use Pod::POM;
use Pod::POM::View::Pod;

=head1 NAME

Pod::Generate::Recursive - Generate POD for directory contents. 

=head1 DESCRIPTION

    If you've ever come across a code base and wanted to easily generate
    POD from the source then you've probably written a small script to
    do it for you. You no longer need to do it and can instead point this
    code at you source and have it generate POD from .pl and .pm files.

    Enjoy!

=head1 VERSION

Version 0.5

=cut

our $VERSION = '0.5';

=head1 SYNOPSIS

    use Pod::Generate::Recursive;

    my $pgr = Pod::Generate::Recursive->new();
    $pgr->source("catalyst/");
    $pgr->destination("docs/");
    $pgr->debug(1);
    $pgr->run();

=cut

=head1 SUBROUTINES/METHODS

=cut

my %files = ();

=head2 run

Generate the docs.

=cut

sub run
{
    my ($self) = @_;

    my (
        $directory, $file, $filehandle, $filename,  $newbase,
        $parser,    $pod,  $pom,        $targetdir, $oldfile
       )
      = (undef, undef, undef, undef, undef, undef, undef, undef, undef, undef);

    die "ERROR: Source directory cannot be empty.\n" if !$self->{source};

    die "ERROR: Destination directory cannot be empty.\n"
      if !$self->{destination};

    if (!-d $self->{destination})
    {
        make_path $self->{destination}
          or die "Failed to create $self->{destination}.\n";
    }

    finddepth(\&_wanted, ($self->{source}));

    if ($self->{debug}) { print Dumper(%files) }

    while (($filename, $directory) = each %files)
    {
        $newbase = File::Spec->catdir(($self->{destination}, $directory));
        $oldfile = File::Spec->catdir(($directory, $filename));
        if ($self->{debug}) { print $newbase . "\n" }
        if (!-d $newbase)
        {
            make_path $newbase or die "Failed to create $newbase.\n";
        }

        $pom = $self->{parser}->parse_file($oldfile) || die $parser->error();
        $pod = Pod::POM::View::Pod->print($pom);
        $targetdir = dir($newbase);

        ## Should we change the extension to pod?
        $file = $targetdir->file($filename);

        ## Missing docs
        if ($pod eq "")
        {
            $file = $targetdir->file($filename . ".MISSING");
        }

        $filehandle = $file->openw();
        $filehandle->print($pod . "\n");
        $filehandle->close;
    }

}

=head2 wanted

Find wanted files.

=cut

sub _wanted
{
    ## No hidden files
    return if $_ =~ m/^\./;

    ## Skip dirs
    return if !-f $_;

    print $_ . "\n";

    $files{"$_"} = "$File::Find::dir" if $_ =~ /\.p[ml]/;

}

=head2 debug

Debug output

=cut

sub debug
{
    my ($self, $debug) = @_;
    if ($debug)
    {
        $self->{debug} = $debug;
    }
    return $self->{debug};
}

=head2 destination

Set the destination for docs.

=cut

sub destination
{
    my ($self, $destination) = @_;
    if ($destination)
    {
        $self->{destination} = $destination;
    }
    return $self->{destination};
}

=head2 source

Set the source directory.

=cut

sub source
{
    my ($self, $source) = @_;
    if ($source)
    {
        $self->{source} = $source;
    }
    return $self->{source};
}

=head2 new

Create a new instance.

=cut

sub new
{
    my $class = shift;

    my $self = {};

    bless $self, $class;

    $self->{source}      = undef;
    $self->{destination} = undef;

    ## Parsing files. ##
    $self->{parser} = Pod::POM->new();

    ## Debug
    $self->{debug} = 0;

    return $self;
}

=head1 AUTHOR

Adam M Dutko, C<< <addutko at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-pod-generate-recursive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Pod-Generate-Recursive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Pod::Generate::Recursive


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Pod-Generate-Recursive>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Pod-Generate-Recursive>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Pod-Generate-Recursive>

=item * Search CPAN

L<http://search.cpan.org/dist/Pod-Generate-Recursive/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Adam M Dutko.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;    # End of Pod::Generate::Recursive
