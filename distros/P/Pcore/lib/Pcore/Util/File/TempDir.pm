package Pcore::Util::File::TempDir;

use Pcore -class, -const;
use Pcore::Util::Scalar qw[refaddr];

has base  => ( is => 'lazy', isa => Str );
has tmpl  => ( is => 'lazy', isa => Str );
has mode  => ( is => 'lazy', isa => Maybe [ Int | Str ], default => 'rwx------' );
has umask => ( is => 'ro',   isa => Maybe [ Int | Str ] );
has lazy  => ( is => 'ro',   isa => Bool, default => 0 );

has path => ( is => 'lazy', isa => Str, init_arg => undef );
has owner_pid => ( is => 'ro', isa => Str, default => $$, init_arg => undef );

use overload    #
  q[""] => sub {
    return $_[0]->path;
  },
  q[cmp] => sub {
    return !$_[2] ? $_[0]->path cmp $_[1] : $_[1] cmp $_[0]->path;
  },
  q[0+] => sub {
    return refaddr $_[0];
  },
  fallback => undef;

const our $TMPL => [ 0 .. 9, 'a' .. 'z', 'A' .. 'Z' ];

sub DESTROY ( $self ) {

    # do not unlink files, created by others processes
    return if $self->owner_pid ne $$;

    local $SIG{__WARN__} = sub { };

    P->file->rmtree( $self->path, safe => 0 );

    return;
}

sub BUILD ( $self, $args ) {
    $self->path if !$self->lazy;

    return;
}

sub _build_base ($self) {
    return "$ENV->{TEMP_DIR}";
}

sub _build_tmpl ($self) {
    return 'temp-' . $$ . '-XXXXXXXX';
}

sub _build_path ($self) {
    my $attempt = 3;

  REDO:
    die q[Can't create temporary directory] if !$attempt--;

    my $dirname = $self->tmpl =~ s/X/$TMPL->[rand $TMPL->@*]/smger;

    goto REDO if -e $self->base . q[/] . $dirname;

    my $umask_guard;

    $umask_guard = P->file->umask( $self->umask ) if defined $self->umask;

    P->file->mkpath( $self->base . q[/] . $dirname, mode => $self->mode );

    return P->path( $self->base . q[/] . $dirname, is_dir => 1 )->realpath->to_string;
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
