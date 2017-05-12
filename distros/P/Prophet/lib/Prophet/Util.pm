package Prophet::Util;
{
  $Prophet::Util::VERSION = '0.751';
}

# ABSTRACT: Common utility functions.

use strict;
use File::Basename;
use File::Spec;
use File::Path;
use Params::Validate;
use Cwd;


sub updir {
    my $self = shift;
    my ( $path, $depth ) = validate_pos( @_, 1, { default => 1 } );
    die "depth must be positive" unless $depth > 0;

    my ( $file, $dir, undef ) = fileparse( File::Spec->rel2abs($path) );

    $depth-- if $file;    # we stripped the file part

    if ($depth) {
        $dir = File::Spec->catdir( $dir, ( File::Spec->updir ) x $depth );
    }

    # if $dir doesn't exists in file system, abs_path will return empty
    return Cwd::abs_path($dir) || $dir;
}


sub slurp {
    my $self    = shift;
    my $abspath = shift;
    open( my $fh, "<", "$abspath" ) || die "$abspath: $!";

    my @lines = <$fh>;
    close $fh;

    return wantarray ? @lines : join( '', @lines );
}


sub instantiate_record {
    my $self = shift;
    my %args = validate(
        @_,
        {
            class      => 1,
            uuid       => 1,
            app_handle => 1

        }
    );
    die $args{class} . " is not a valid class "
      unless ( UNIVERSAL::isa( $args{class}, 'Prophet::Record' ) );
    my $object =
      $args{class}
      ->new( uuid => $args{uuid}, app_handle => $args{app_handle} );
    return $object;
}


sub escape_utf8 {
    my $ref = shift;
    no warnings 'uninitialized';
    $$ref =~ s/&/&#38;/g;
    $$ref =~ s/</&lt;/g;
    $$ref =~ s/>/&gt;/g;
    $$ref =~ s/\(/&#40;/g;
    $$ref =~ s/\)/&#41;/g;
    $$ref =~ s/"/&#34;/g;
    $$ref =~ s/'/&#39;/g;
}

sub write_file {
    my $self = shift;
    my %args = (@_);  #validate is too heavy to be called here
                      # my %args = validate( @_, { file => 1, content => 1 } );

    my ( undef, $parent, $filename ) = File::Spec->splitpath( $args{file} );
    unless ( -d $parent ) {
        eval { mkpath( [$parent] ) };
        if ( my $msg = $@ ) {
            die "Failed to create directory " . $parent . " - $msg";
        }
    }

    open( my $fh, ">", $args{file} ) || die $!;
    print $fh scalar( $args{'content'} )
      ; # can't do "||" as we die if we print 0" || die "Could not write to " . $args{'path'} . " " . $!;
    close $fh || die $!;
}

sub hashed_dir_name {
    my $hash = shift;

    return ( substr( $hash, 0, 1 ), substr( $hash, 1, 1 ), $hash );
}

sub catfile {
    my $self = shift;

    # File::Spec::catfile is more correct, but
    # eats over 10% of prophet app runtime,
    # which isn't acceptable.
    return join( '/', @_ );

}

1;

__END__

=pod

=head1 NAME

Prophet::Util - Common utility functions.

=head1 VERSION

version 0.751

=head1 METHODS

=head2 updir PATH, DEPTH

Strips off the filename in the given path and returns the absolute path of the
remaining directory.

Default depth is 1. If depth are great than 1, will go up more according to the
depth value.

=head2 slurp FILENAME

Reads in the entire file whose absolute path is given by FILENAME and returns
its contents, either in a scalar or in an array of lines, depending on the
context.

=head2 instantiate_record class => 'record-class-name', uuid => 'record-uuid', app_handle => $self->app_handle

Takes the name of a record class (must subclass L<Prophet::Record>), a uuid,
and an application handle and returns a new instantiated record object of the
given class.

=head1 FUNCTIONS

=head2 escape_utf8 REF

Given a reference to a scalar, escapes special characters (currently just &, <,
>, (, ), ", and ') for use in HTML and XML.

Not an object routine (call as Prophet::Util::escape_utf8( \$scalar) ).

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
