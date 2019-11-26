package Pcore::Util::File::TempDir;

use Pcore -class, -const;
use Pcore::Util::Scalar qw[refaddr];

has base  => ( $ENV->{TEMP_DIR} );
has tmpl  => ("temp-$$-XXXXXXXX");
has mode  => ('rwx------');
has umask => ();
has lazy  => ();

has path      => ( is => 'lazy', init_arg => undef );
has owner_pid => ( $$,           init_arg => undef );

use overload    #
  q[""] => sub {
    return $_[0]->path;
  },
  'cmp' => sub {
    return !$_[2] ? $_[0]->path cmp $_[1] : $_[1] cmp $_[0]->path;
  },
  '0+' => sub {
    return refaddr $_[0];
  },
  fallback => undef;

const our $TMPL => [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z' ];

sub DESTROY ( $self ) {

    # do not unlink files, created by others processes
    return if $self->{owner_pid} ne $$;

    local $SIG{__WARN__} = sub { };

    P->file->rmtree( $self->path, safe => 0 );

    return;
}

sub BUILD ( $self, $args ) {
    $self->path if !$self->{lazy};

    return;
}

sub _build_path ($self) {
    my $attempt = 3;

  REDO:
    die q[Can't create temporary directory] if !$attempt--;

    my $dirname = $self->{tmpl} =~ s/X/$TMPL->[rand $TMPL->@*]/smger;

    goto REDO if -e "$self->{base}/$dirname";

    my $umask_guard;

    $umask_guard = P->file->umask( $self->{umask} ) if defined $self->{umask};

    P->file->mkpath( "$self->{base}/$dirname", mode => $self->{mode} );

    return P->path("$self->{base}/$dirname")->to_abs;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::File::TempDir

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut
