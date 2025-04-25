package OptArgs2::Pager;
use strict;
use warnings;
use Carp ();
use Exporter::Tidy other => [qw/page start_pager stop_pager/];
use File::Which;
use IO::Handle;
### START Class::Inline ### v0.0.1 Fri Apr 25 08:48:09 2025
require Carp;
our ( @_CLASS, $_FIELDS, %_NEW );

sub new {
    my $class = shift;
    my $CLASS = ref $class || $class;
    $_NEW{$CLASS} //= do {
        my @possible = ($CLASS);
        if ( defined &{"${CLASS}::DOES"} ) {
            push @possible, grep !/^${CLASS}$/, $CLASS->DOES('*');
        }
        my ( @new, @build );
        while (@possible) {
            no strict 'refs';
            my $c = shift @possible;
            push @new,   $c . '::_NEW'  if exists &{ $c . '::_NEW' };
            push @build, $c . '::BUILD' if exists &{ $c . '::BUILD' };
            push @possible, @{ $c . '::ISA' };
        }
        [ [ reverse(@new) ], [ reverse(@build) ] ];
    };
    my $self = { @_ ? @_ > 1 ? @_ : %{ $_[0] } : () };
    bless $self, $CLASS;
    my $attrs = { map { ( $_ => 1 ) } keys %$self };
    map { $self->$_($attrs) } @{ $_NEW{$CLASS}->[0] };
    {
        local $Carp::CarpLevel = 3;
        Carp::carp("OptArgs2::Pager: unexpected argument '$_'")
          for keys %$attrs;
    }
    map { $self->$_ } @{ $_NEW{$CLASS}->[1] };
    $self;
}

sub _NEW {
    CORE::state $fix_FIELDS = do {
        $_FIELDS = { @_CLASS > 1 ? @_CLASS : %{ $_CLASS[0] } };
        $_FIELDS = $_FIELDS->{'FIELDS'} if exists $_FIELDS->{'FIELDS'};
    };
    map { delete $_[1]->{$_} } 'auto', 'encoding', 'pager';
}

sub __RO {
    my ( undef, undef, undef, $sub ) = caller(1);
    Carp::confess("attribute $sub is read-only");
}
sub auto { __RO() if @_ > 1; $_[0]{'auto'} //= $_FIELDS->{'auto'}->{'default'} }

sub encoding {
    __RO() if @_ > 1;
    $_[0]{'encoding'} //= $_FIELDS->{'encoding'}->{'default'};
}

sub fh {
    if ( @_ > 1 ) { $_[0]{'fh'} = $_[1]; }
    $_[0]{'fh'} //= $_FIELDS->{'fh'}->{'default'}->( $_[0] );
}

sub orig_fh {
    __RO() if @_ > 1;
    $_[0]{'orig_fh'} //= $_FIELDS->{'orig_fh'}->{'default'}->( $_[0] );
}

sub pager {
    __RO() if @_ > 1;
    $_[0]{'pager'} //= $_FIELDS->{'pager'}->{'default'}->( $_[0] );
}

sub pid {
    if ( @_ > 1 ) { $_[0]{'pid'} = $_[1]; }
    $_[0]{'pid'} // undef;
}

sub _dump {
    my $self = shift;
    my $x    = do {
        require Data::Dumper;
        no warnings 'once';
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Maxdepth = ( shift // 2 );
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper($self);
    };
    $x =~ s/.*?{/{/;
    $x =~ s/}.*?\n$/}/;
    my $i = 0;
    my @list;
    do {
        @list = caller( $i++ );
    } until $list[3] eq __PACKAGE__ . '::_dump';
    warn "$self $x at $list[1]:$list[2]\n";
}

@_CLASS = grep 1,### END Class::Inline ###


  # User provided arguments
  auto     => { default => 1, },
  encoding => { default => ':utf8', },
  pager    => { default => \&_build_pager, },

  # Attributes
  fh => {
    init_arg => undef,
    is       => 'rw',
    default  => sub { IO::Handle->new },
  },
  orig_fh => {
    init_arg => undef,
    default  => sub { select },
  },
  pid => {
    init_arg => undef,
    is       => 'rw',
    init_arg => undef,
  },
  ;

our $VERSION  = 'v2.0.15';
our @CARP_NOT = (__PACKAGE__);

sub _build_pager {
    my $self = shift;

    if ( exists $ENV{PAGER} ) {
        return unless length( $ENV{PAGER} );

        # Explicit pager defined
        my ( $pager, @options ) = split ' ', $ENV{PAGER};
        my $path = File::Which::which($pager);
        Carp::croak("pager not found: $pager") unless $path;
        return join( ' ', $path, @options );
    }

    # Otherwise take the first from our own list
    foreach my $pager (qw/pager less most w3m lv pg more/) {
        my $path = File::Which::which($pager);
        return $path if $path;
    }

    Carp::croak("no suitable pager found");
}

sub BUILD {
    my $self = shift;
    $self->open;
    select $self->fh if $self->auto;
}

sub open {
    my $self = shift;

    return $self->fh if $self->fh->opened;

    if ( not -t $self->orig_fh ) {
        $self->fh( $self->orig_fh );
        return;
    }

    my $pager = $self->pager || return;

    local $ENV{LESS} = $ENV{LESS} // '-FSXeR';
    local $ENV{MORE} = $ENV{MORE} // '-FXer' unless $^O eq 'MSWin32';

    $self->pid( CORE::open( $self->fh, '|-', $pager ) )
      or Carp::croak "Could not pipe to PAGER ('$pager'): $!\n";

    binmode( $self->fh, $self->encoding ? $self->encoding : () )
      or Carp::cluck "Could not set bindmode: $!";

    $self->fh->autoflush(1);
}

sub close {
    my $self = shift;
    return unless $self->fh && $self->fh->opened;

    select $self->orig_fh;
    $self->fh->close if $self->fh ne $self->orig_fh;
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

# Functions
my $pager;

sub start_pager {
    $pager //= __PACKAGE__->new(@_);
    $pager->open;
    select $pager->fh;
}

sub stop_pager {
    $pager // return;
    $pager->close;
    select( $pager->orig_fh );
}

sub page {
    my $text  = shift;
    my $close = not $pager;

    $pager //= __PACKAGE__->new( @_, auto => 0 );
    $pager->open;
    my $ok = $pager->fh->printflush($text);
    $pager->close if $close;
    $ok;
}

1;

__END__

=head1 NAME

=for bif-doc #perl

OptArgs2::Pager - pipe output to a system (text) pager

=head1 VERSION

v2.0.15 (2025-04-25)

=head1 SYNOPSIS

    use OptArgs2::Pager 'start_pager', 'page', 'stop_pager';

    # One-shot output to a pager
    page("this goes to a page with page()\n" x 50);

    # Or make the pager filehandle the default
    start_pager();
    print "This text also goes pager by default\n" x 50;

    stop_pager();
    print "This text goes straight to STDOUT\n";

    # Scoped
    {
        my $pager = OptArgs2::Pager->new;
        print "Back to a pager by default\n" x 50;
    }
    print "Back to STDOUT\n";

=head1 DESCRIPTION

B<OptArgs2::Pager> opens a connection to a system pager and makes it
the default filehandle so that by default any print statements are sent
there.

When the pager object goes out of scope the previous default filehandle
is selected again.

=head1 FUNCTIONS

=head2 page($string, [%ARGS])

An all-in-one function to start a pager (using the optional C<%ARGS>
passed directly to C<new()> below), send it a C<$string>, and close it.
If a pager is already running when this is called (due to a previous
C<start_pager()>) it will reused and left open. Returns the response
from the underlying printflush().

=head2 start_pager(%ARGS)

Create a pager using C<%ARGS> (passed directly to C<new()> below) and
makes it the default output file handle.

=head2 stop_pager()

Make the original file handle (usually STDOUT) the default again.
Closes the pager input, letting it know that no more content is coming.

=head1 CONSTRUCTOR

The C<new()> constuctor takes the following arguments.

=over

=item C<< auto => 1 >>

By default the pager is selected as the default filehandle when the
object is created. Set C<auto> to a false value to inhibit this
behaviour.

=item C<< encoding => ':utf8' >>

The Perl IO layer encoding to set after the pager has been opened. This
defaults to ':utf8'. Set it to 'undef' to get binary mode.

=item C<< pager => undef >>

The pager executable to run. The default is to check the PAGER
environment variable, and if that is not set then the following
programs will be searched for using L<File::Which>: pager, less, most,
w3m, lv, pg, more.

You can set PAGER to nothing to temporarily disable B<OptArgs2::Pager>:

    $ PAGER= your_cmd --your --options

=back

=head1 ATTRIBUTES

=over

=item C<fh>

The underlying filehandle of the pager.

=item C<pid>

The process ID of the pager program (only set on UNIX systems)

=item C<orig_fh>

The original filehandle that was selected before the pager was started.

=back

=head1 METHODS

=over

=item C<close>

Explicitly close the pager. This is useful if you want to keep the
object around to start and stop the pager multiple times. Can be called
safely when no pager is running.

=item C<open>

Open the pager if it is not running. Can be called safely when the
pager is already running.

=back

=head1 ENVIRONMENT

Already mentioned above is the check for C<$PAGER> when choosing which
pager to run. Additionally, OptArgs2 temporarily sets C<$LESS> to
C<-FSXeR> and C<$MORE> to C<-FXer> if they are unset at the time the
pager is opened.

=head1 SEE ALSO

L<IO::Pager> - does something similar by mucking directly with STDOUT
in a way that breaks fork/exec, and I couldn't for the life of me
decipher the code style enough to fix it.

=head1 AUTHOR

Mark Lawrence E<lt>mark@rekudos.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2025 Mark Lawrence <mark@rekudos.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

