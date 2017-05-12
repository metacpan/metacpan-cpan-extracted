package Report::Generator;

use warnings;
use strict;

use Carp qw(croak);
use Config;
use Config::Any;
use Params::Util qw(_HASH);

=head1 NAME

Report::Generator - utility to generate reports

=cut

our $VERSION = '0.002';

=head1 SYNOPSIS

    Report::Generator->new( { cfg => '/path/to/config/file' } )->genreport();

=head1 DESCRIPTION

C<Report::Generator> provides an infrastructure to generate reports using
render classes based on a configuration file. The render classes require
usually additional configuration - you should consult their documentation
when you're going to use them.

=head1 SUBROUTINES/METHODS

=head2 new

Instantiates a new Report::Generator. Requires an hash reference
containing bootstrap parameters:

=over 4

=item C<cfg>

Must be either a path to a configuration file, which can be read using
L<Config::Any> or a hash with a compatible configuration.

=back

=cut

sub new
{
    my ( $proto, $attr ) = @_;

    if ( ref $proto )
    {
        $attr ||= {};
        $attr->{cfg} ||= $proto->{cfg};
        $proto = ref($proto);
    }

    defined( _HASH($attr) ) and defined( $attr->{cfg} )
      or croak("$proto->new({cfg => 'path/to/config'})");

    my $self = bless( $attr, $proto );

    return $self;
}

sub _loadconfig
{
    my ($self) = @_;

    if ( -f $self->{cfg} )
    {
        my $cfg = Config::Any->load_files(
                                           {
                                             files           => [ $self->{cfg} ],
                                             use_ext         => 1,
                                             flatten_to_hash => 1,
                                           }
                                         );
        $self->{cfg} = $cfg->{ $self->{cfg} };
    }

    defined( _HASH( $self->{cfg} ) ) or croak("Invalid configuration");
}

=head2 generate

Generates the report based on the configuration.

=cut

sub generate
{
    my ($self) = @_;
    $self->_loadconfig();
    my $renderer = $self->{cfg}->{renderer};
    unless ( $renderer->isa('Report::Generator::Render') )
    {
        my $fn = $renderer;
        $fn =~ s|::|/|g;
        $fn .= ".pm";
        local $@ = undef;
        eval { require $fn; };
        $@ and croak "Can't load '$renderer': $@";
    }

    $self->{renderer} = $renderer->new( $self->{cfg}->{$renderer} );
    $self->{rendered} = $self->{renderer}->render();

    if( $self->{rendered} )
    {
	# run post-gen actions
	if ( $self->{cfg}->{post_processing} )
	{
	    system( $self->{cfg}->{post_processing} );
	}
    }
    else
    {
	$self->{error} = $self->{renderer}->{error};
    }

    return $self->{rendered};
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-report-generator at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Report-Generator>.  I
will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Report::Generator

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Report-Generator>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Report-Generator>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Report-Generator>

=item * Search CPAN

L<http://search.cpan.org/dist/Report-Generator/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Report::Generator
