package Mojo::CSV;

use Carp qw/croak/;
use Mojo::Collection qw/c/;
use Text::CSV;
use Scalar::Util qw/reftype/;

use Moo;
use MooX::ChainedAttributes;
use strictures 2;
use namespace::clean;

our $VERSION = '1.001003'; # VERSION

has in  => (
    is      => 'rw',
    chained => 1,
    coerce => sub { __get_fh( $_[0], '<' ); }
);
has out  => (
    is      => 'rw',
    chained => 1,
    coerce => sub { __get_fh( $_[0], '>' ); }
);
has _obj => (
    is      => 'ro',
    default => sub { Text::CSV->new({ binary => 1 }) },
);

sub __get_fh {
    my ( $what, $how ) = @_;;

    my $fh;
    if ( ref $what eq 'Mojo::Asset::File' ) {
        $fh = $what->handle;
    }
    elsif ( ref $what eq 'Mojo::Asset::Memory' ) {
        open $fh, $how, \ $what->slurp or die $!;
    }
    elsif ( ref $what ) {
        $fh = $what;
    }
    elsif ( defined $what ) {
        open $fh, $how, $what or croak "Failed to open CSV file ($what): $!";
    }
    else {
        croak 'Could not figure out how to access resource';
    }

    return $fh;
}

sub flush {
    my $self = shift;
    close $self->out;

    $self;
}

sub row {
    my $self = shift;
    my $in = $self->in or croak 'You must specify what to read from';
    my $row = $self->_obj->getline( $in ) or return;
    return $row;
}

sub slurp {
    my $self = shift;
    @_ and $self->in( shift );

    my @rows;
    while ( my $r = $self->row ) {
        push @rows, $r;
    }

    return c @rows;
}

sub slurp_body {
    my $self = shift;
    my $r = $self->slurp( @_ );
    return $r->slice( 1 .. $r->size-1 );
}

sub spurt {
    my $self = shift;
    my $what = shift;
    @_ and $self->out( shift );
    $self->trickle( $_ ) for @$what;
    $self->flush;

    $self;
}

sub text {
    my $self = shift;
    my $what = shift or return '';

    my @out;
    my $obj = $self->_obj;
    if (    reftype $what
            and reftype $what eq 'ARRAY'
            and reftype $what->[0]
            and reftype $what->[0] eq 'ARRAY'
    ) {
        for my $row ( @$what ) {
            $obj->combine( @$row ) or next;
            push @out, $obj->string;
        }
    }
    else {
        $obj->combine( @$what ) and push @out, $obj->string;
    }

    return join "\n", @out;
}

sub trickle {
    my $self = shift;
    my $what = shift or return $self;
    my $out = $self->out or croak 'You must specify where to write';
    my $obj = $self->_obj;
    $obj->combine( @$what ) or return $self;
    print $out $obj->string . "\n";

    $self;
}

q|
    Computers are like air conditioners.
    They work fine until you start opening windows.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix Mojotastic CSV

=head1 NAME

Mojo::CSV - no-nonsense CSV handling

=head1 SYNOPSIS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    # Just convert data to CSV and gimme it
    say Mojo::CSV->new->text([
        [ qw/foo bar baz/ ],
        [ qw/moo mar mer/ ],
    ]);

    my $data = Mojo::CSV->new->slurp('file.csv') # returns a Mojo::Collection
        ->grep(sub{ $_->[0] eq 'Zoffix' });

    my $csv = Mojo::CSV->new( in => 'file.csv' );
    while ( my $row = $csv->row ) {
        # Read row-by-row
    }

    # Write CSV file in one go
    Mojo::CSV->new->spurt( $data => 'file.csv' );

    # Write CSV file row-by-row
    my csv = Mojo::CSV->new( out => 'file.csv' );
    $csv->trickle( $row ) for @data;

=for html  </div></div>

=head1 DESCRIPTION

Read and write CSV (Comma Separated Values) like a boss, Mojo style.

=head1 METHODS

Unless otherwise indicated, all methods return their invocant.

=head2 C<flush>

    $csv->flush;

Flushes buffer and closes L</out> filehandle. Call this when you're done
L<trickling|/trickle> data. This will be done automatically when the
C<Mojo::CSV> object is destroyed.

=head2 C<in>

    my $csv = Mojo::CSV->new( in => 'file.csv' );

    $csv->in('file.csv');

    open my $fh, '<', 'foo.csv' or die $!;
    $csv->in( $fh );
    $csv->in( Mojo::Asset::File->new(path => 'file.csv') );
    $csv->in( Mojo::Asset::Memory->new->add_chunk('foo,bar,baz') );

Specifies the input for L</slurp>, L</slurp_body> and L</row>.
Takes a filename, an opened filehandle, a L<Mojo::Asset::File> object, or
a L<Mojo::Asset::Memory> object.

=head2 C<new>

    Mojo::CSV->new;
    Mojo::CSV->new( in => 'file.csv', out => 'file.csv' );

Creates a new C<Mojo::CSV> object. Takes two optional arguments. See
L</in> and L</out> for details.

=head2 C<out>

    my $csv = Mojo::CSV->new( out => 'file.csv' );

    $csv->out('file.csv');

    open my $fh, '>', 'foo.csv' or die $!;
    $csv->out( $fh );

Specifies the output for L</spurt> and L</trickle>. Takes either
a filename or an opened filehandle.

=head2 C<row>

    my $row = $csv->row;

Returns an arrayref, which is a row of data from the CSV. The thing
to read must be first set with L<in method|/in> or C<in> argument to
L</new>

=head2 C<slurp>

    my $data = Mojo::CSV->new->slurp('file.csv');
    my $data = Mojo::CSV->new( in => 'file.csv' )->slurp;

Returns a L<Mojo::Collection> object, each item of which is an arrayref
representing a row of CSV data.

=head2 C<slurp_body>

    my $data = Mojo::CSV->new->slurp_body('file.csv');

A shortcut for calling L</slurp> and discarding the first row
(use this for CSV with headers you want to get rid of).

=head2 C<spurt>

    Mojo::CSV->new->spurt( $data => 'file.csv');
    Mojo::CSV->new( out => 'file.csv' )->spurt( $data );

Writes a data structure into CSV. C<$data> is an arrayref of rows, which
are themselves arrayrefs (each item is a cell data). It will call
L</flush> on completion. See also L</trickle>.

=head2 C<text>

    say Mojo::CSV->new->text([qw/foo bar baz/]);

    say Mojo::CSV->new->text([
        [ qw/foo bar baz/ ],
        [ qw/moo mar mer/ ],
    ]);

Returns a CSV string. Takes either a single arrayref to encode just a single
row or an arrayref of arrayrefs to include multiple rows.
L<Arrayref-like things|Mojo::Collection> should work too.

=head2 C<trickle>

    my $csv = Mojo::CSV->new( out => 'file.csv' );
    $csv->trickle( $_ ) for @data;

Writes out a single row of CSV. Takes an arrayref of cell values. Note that
the writes may be buffered (see L</flush>)

=head1 SEE ALSO

L<Text::CSV>, L<Text::xSV>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/Mojo-CSV>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/Mojo-CSV/issues>

If you can't access GitHub, you can email your request
to C<bug-Mojo-CSV at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for html  </div></div>

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut