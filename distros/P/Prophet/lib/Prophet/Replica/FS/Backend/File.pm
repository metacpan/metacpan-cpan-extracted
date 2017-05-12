package Prophet::Replica::FS::Backend::File;
{
  $Prophet::Replica::FS::Backend::File::VERSION = '0.751';
}
use Any::Moose;
use Fcntl qw/SEEK_END/;
use Params::Validate qw/validate validate_pos/;

has url => ( is => 'rw', isa => 'Str');
has fs_root => ( is => 'rw', isa => 'Str');

sub read_file {
    my $self   = shift;
    my ($file) = (@_);    # validation is too heavy to be called here
                          #my ($file) = validate_pos( @_, 1 );
    return eval {
        local $SIG{__DIE__} = 'DEFAULT';
        Prophet::Util->slurp(
            Prophet::Util->catfile( $self->fs_root => $file ) );
    };
}

sub read_file_range {
    my $self = shift;
    my %args = validate( @_, { path => 1, position => 1, length => 1 } );

    if ( $self->fs_root ) {
        my $f = Prophet::Util->catfile( $self->fs_root => $args{path} );
        return unless -e $f;
        if ( $^O =~ /MSWin/ ) {

            # XXX by sunnavy
            # the the open, seek and read below doesn't work on windows, at least with
            # strawberry perl 5.10.0.6 on windows xp
            #
            # the differences:
            # with substr, I got:
            # 0000000: 0000 0004 ecaa d794 a5fe 8c6f 6e85 0d0a  ...........on...
            # 0000010: 7087 f0cf 1e92 b50d f9                   p........
            #
            # the read, I got
            # 0000000: 0000 04ec aad7 94a5 fe8c 6f6e 850d 0d0a  ..........on....
            # 0000010: 7087 f0cf 1e92 b50d f9                   p........
            #
            # seems with read, we got an extra 0d, I dont' know why yet :/
            my $content = Prophet::Util->slurp($f);
            return substr( $content, $args{position}, $args{length} );
        } else {
            open( my $index, "<:bytes", $f ) or return;
            seek( $index, $args{position}, SEEK_END ) or return;
            my $record;
            read( $index, $record, $args{length} ) or return;
            return $record;
        }
    } else {

        # XXX: do range get if possible
        my $content = $self->lwp_get( $self->url . "/" . $args{path} );
        return substr( $content, $args{position}, $args{length} );
    }

}

sub write_file {
    my $self = shift;
    my %args = (@_);   # validation is too heavy to call here
                       #my %args = validate( @_, { path => 1, content => 1 } );

    my $file = Prophet::Util->catfile( $self->fs_root => $args{'path'} );
    Prophet::Util->write_file( file => $file, content => $args{content} );

}

sub append_to_file {
    my $self = shift;
    my ( $filename, $content ) = validate_pos( @_, 1, 1 );
    open( my $file,
        ">>", Prophet::Util->catfile( $self->fs_root => $filename ) )
      || die $!;
    print $file $content || die $!;
    close $file;
}

sub file_exists {
    my $self = shift;
    my ($file) = validate_pos( @_, 1 );

    my $path = Prophet::Util->catfile( $self->fs_root, $file );
    if    ( -f $path ) { return 1 }
    elsif ( -d $path ) { return 2 }
    else               { return 0 }

}

sub can_read {
    1;

}

sub can_write {
    1;

}

no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Replica::FS::Backend::File

=head1 VERSION

version 0.751

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
