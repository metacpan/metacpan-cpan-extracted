package Prophet::Replica::file;
{
  $Prophet::Replica::file::VERSION = '0.751';
}
use Any::Moose;
extends 'Prophet::Replica::prophet';
sub scheme {'file'}

sub replica_exists {
    my $self = shift;
    return 0 unless defined $self->fs_root && -d $self->fs_root;
    return 0
      unless -e Prophet::Util->catfile( $self->fs_root => 'database-uuid' );
    return 1;
}

sub new {
    my $class = shift;
    my %args  = @_;

    my @probe_types =
      ( $args{app_handle}->default_replica_type, 'file', 'sqlite' );

    my %possible;
    for my $type (@probe_types) {
        my $ret;
        eval {
            my $other = "Prophet::Replica::$type";
            Prophet::App->try_to_require($other);
            $ret = $type eq "file" ? $other->SUPER::new(@_) : $other->new(@_);
        };
        next if $@ or not $ret;
        return $ret if $ret->replica_exists;
        $possible{$type} = $ret;
    }
    if ( my $default_type =
        $possible{ $args{app_handle}->default_replica_type } )
    {
        return $default_type;
    } else {
        $class->log_fatal( "I don't know what to do with the Prophet replica "
              . "type you specified: "
              . $args{app_handle}->default_replica_type
              . "\nIs your URL syntax correct?" );
    }
}

no Any::Moose;
1;

__END__

=pod

=head1 NAME

Prophet::Replica::file

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
